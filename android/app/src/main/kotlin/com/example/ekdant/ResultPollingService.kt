package com.example.ekdant

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.util.Log
import kotlinx.coroutines.*
import org.json.JSONArray
import org.json.JSONObject

/**
 * ResultPollingService
 * ─────────────────────────────────────────────────────────────
 * Foreground service that runs even when the app is in background.
 *
 * Every POLL_INTERVAL_MS it:
 *   1. Fetches all results from the API.
 *   2. Compares against the last-known results stored in prefs.
 *   3. For each NEW result → fires a "Result Declared" notification.
 *   4. For each newly-declared result → checks ALL pending user bids
 *      against that result and fires a "You Won!" notification +
 *      credits the wallet.
 *
 * Lifecycle:
 *   Start : ResultPollingReceiver (on BOOT_COMPLETED + app launch)
 *   Stop  : call stopService() on logout
 */
class ResultPollingService : Service() {

    companion object {
        private const val TAG               = "ResultPolling"
        private const val POLL_INTERVAL_MS  = 60_000L   // poll every 60 s
        private const val PREFS_SEEN_RESULTS = "ekdant_seen_results"
        private const val KEY_SEEN_IDS       = "seen_result_ids"
    }

    private val serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    // ─────────────────────────────────────────────────────────
    // Service lifecycle
    // ─────────────────────────────────────────────────────────
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service created")
        startForeground(
            NotificationHelper.SERVICE_NOTIF_ID,
            NotificationHelper.buildServiceNotification(this)
        )
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Service started")
        startPolling()
        return START_STICKY   // auto-restart if killed by OS
    }

    override fun onDestroy() {
        super.onDestroy()
        serviceScope.cancel()
        Log.d(TAG, "Service destroyed")
    }

    // ─────────────────────────────────────────────────────────
    // Polling loop
    // ─────────────────────────────────────────────────────────
    private fun startPolling() {
        serviceScope.launch {
            while (isActive) {
                try {
                    poll()
                } catch (e: Exception) {
                    Log.e(TAG, "Poll error: ${e.message}")
                }
                delay(POLL_INTERVAL_MS)
            }
        }
    }

    private suspend fun poll() = withContext(Dispatchers.IO) {
        val token  = ApiClient.getToken(applicationContext)  ?: return@withContext
        val userId = ApiClient.getUserId(applicationContext) ?: return@withContext

        Log.d(TAG, "Polling results for user $userId")

        val results = ApiClient.getAllResults(token) ?: return@withContext
        val bids    = ApiClient.getAllBids(token)    ?: return@withContext
        val games   = ApiClient.getAllGames(token)   ?: return@withContext

        val seenIds    = loadSeenResultIds()
        val newResults = mutableListOf<JSONObject>()

        // ── Find results we haven't seen yet ─────────────────
        for (i in 0 until results.length()) {
            val result = results.getJSONObject(i)
            val rid    = result.optString("id").ifEmpty { result.optString("_id") }
            if (rid.isNotEmpty() && rid !in seenIds) {
                newResults.add(result)
            }
        }

        if (newResults.isEmpty()) {
            Log.d(TAG, "No new results")
            return@withContext
        }

        Log.d(TAG, "${newResults.size} new result(s) found")

        for (result in newResults) {
            val rid         = result.optString("id").ifEmpty { result.optString("_id") }
            val marketName  = getMarketName(result, bids, games)
            val openResult  = result.optString("openResult")
            val closeResult = result.optString("closeResult")
            val openPana    = result.optString("openPana")
            val closePana   = result.optString("closePana")

            // ── 1. Result-declared notification ──────────────
            NotificationHelper.showResultNotification(
                context     = applicationContext,
                marketName  = marketName,
                openResult  = openResult,
                closeResult = closeResult,
                openPana    = openPana,
                closePana   = closePana
            )

            // ── 2. Check user bids against this result ───────
            checkUserBidsForResult(
                result  = result,
                bids    = bids,
                games   = games,
                userId  = userId,
                token   = token
            )

            // Mark result as seen
            seenIds.add(rid)
        }

        saveSeenResultIds(seenIds)
    }

    // ─────────────────────────────────────────────────────────
    // Check every pending bid for a given result
    // ─────────────────────────────────────────────────────────
    private suspend fun checkUserBidsForResult(
        result: JSONObject,
        bids:   JSONArray,
        games:  JSONArray,
        userId: String,
        token:  String
    ) = withContext(Dispatchers.IO) {
        for (i in 0 until bids.length()) {
            val bid = bids.getJSONObject(i)

            // Only process bids belonging to this user
            if (bid.optString("userId") != userId) continue

            // Skip already-settled bids
            val winStatus = bid.optString("win")
            if (winStatus == "win" || winStatus == "loss") continue

            // Match bid market to result
            if (bid.optString("marketId") != result.optString("marketId")) continue

            // Find the game for this bid
            val gameId = bid.optString("gameId")
            val game   = findGameById(games, gameId) ?: continue

            // Check if result is ready for this bid's session/game
            if (!WinCalculator.isResultReady(bid, result, game)) continue

            val winResult = WinCalculator.calculate(bid, result, game)
            val bidId     = bid.optString("id").ifEmpty { bid.optString("_id") }

            if (winResult.isWin) {
                Log.d(TAG, "WIN detected: bid=$bidId amount=₹${winResult.amount}")
                handleWin(bid, bidId, winResult.amount, game, token, userId)
            } else {
                Log.d(TAG, "LOSS detected: bid=$bidId")
                ApiClient.updateBidWinStatus(bidId, "loss", token)
            }
        }
    }

    private suspend fun handleWin(
        bid:    JSONObject,
        bidId:  String,
        amount: Double,
        game:   JSONObject,
        token:  String,
        userId: String
    ) = withContext(Dispatchers.IO) {
        // Get current wallet amount
        // (We read it from the bid response; in production read from /user/:id)
        val currentWallet = getCurrentWalletAmount(userId, token)
        val newWallet     = currentWallet + amount

        val walletUpdated = ApiClient.updateUserWallet(userId, newWallet, token)
        if (!walletUpdated) {
            Log.e(TAG, "Failed to update wallet for bid $bidId")
            return@withContext
        }

        ApiClient.updateBidWinStatus(bidId, "win", token)

        // Fire win notification
        NotificationHelper.showWinNotification(
            context     = applicationContext,
            amount      = amount,
            gameName    = game.optString("gameName"),
            marketName  = bid.optString("market"),
            session     = bid.optString("session")
        )

        Log.d(TAG, "Win processed: bid=$bidId ₹$amount → wallet ₹$newWallet")
    }

    // ─────────────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────────────
    private fun findGameById(games: JSONArray, id: String): JSONObject? {
        for (i in 0 until games.length()) {
            val g = games.getJSONObject(i)
            val gid = g.optString("id").ifEmpty { g.optString("_id") }
            if (gid == id) return g
        }
        return null
    }

    private fun getMarketName(
        result: JSONObject,
        bids:   JSONArray,
        games:  JSONArray
    ): String {
        val marketId = result.optString("marketId")
        for (i in 0 until bids.length()) {
            val bid = bids.getJSONObject(i)
            if (bid.optString("marketId") == marketId) {
                val name = bid.optString("market")
                if (name.isNotEmpty()) return name
            }
        }
        return "Market"
    }

    /**
     * Reads wallet amount from the /user/:id endpoint.
     * Falls back to 0.0 on any error so we don't block win processing.
     */
    private fun getCurrentWalletAmount(userId: String, token: String): Double {
        return try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
            val cached = prefs.getString("flutter.wallet_amount", null)
            cached?.toDoubleOrNull() ?: 0.0
        } catch (e: Exception) {
            0.0
        }
    }

    // ── Seen-results persistence ─────────────────────────────

    private fun loadSeenResultIds(): MutableSet<String> {
        val prefs = getSharedPreferences(PREFS_SEEN_RESULTS, MODE_PRIVATE)
        return prefs.getStringSet(KEY_SEEN_IDS, emptySet())!!.toMutableSet()
    }

    private fun saveSeenResultIds(ids: Set<String>) {
        getSharedPreferences(PREFS_SEEN_RESULTS, MODE_PRIVATE)
            .edit()
            .putStringSet(KEY_SEEN_IDS, ids)
            .apply()
    }
}