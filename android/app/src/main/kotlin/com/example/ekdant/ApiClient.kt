package com.example.ekdant

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL

/**
 * ApiClient
 * ─────────────────────────────────────────────────────────────
 * Minimal HTTP client for the background polling service.
 * Uses only java.net (no OkHttp dependency needed in Kotlin layer).
 */
object ApiClient {

    private const val BASE_URL = "https://api.ekadantaa.in/api"
    private const val TIMEOUT  = 15_000  // 15 s

    // ── SharedPreferences key where Flutter stores the JWT ───
    private const val PREFS_NAME  = "FlutterSharedPreferences"
    private const val TOKEN_KEY   = "flutter.auth_token"
    private const val USER_ID_KEY = "flutter.user_id"

    // ─────────────────────────────────────────────────────────
    // Stored credentials helpers
    // ─────────────────────────────────────────────────────────
    fun getToken(context: Context): String? {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(TOKEN_KEY, null)
    }

    fun getUserId(context: Context): String? {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(USER_ID_KEY, null)
    }

    // ─────────────────────────────────────────────────────────
    // getAllResults() → list of result objects
    // ─────────────────────────────────────────────────────────
    fun getAllResults(token: String): JSONArray? {
        return try {
            val json = get("$BASE_URL/result", token) ?: return null
            when {
                json.trim().startsWith("[") -> JSONArray(json)
                else -> {
                    val obj = JSONObject(json)
                    obj.optJSONArray("results") ?: obj.optJSONArray("data")
                }
            }
        } catch (e: Exception) {
            null
        }
    }

    // ─────────────────────────────────────────────────────────
    // getAllBids() → list of bid objects for a user
    // ─────────────────────────────────────────────────────────
    fun getAllBids(token: String): JSONArray? {
        return try {
            val json = get("$BASE_URL/bid", token) ?: return null
            when {
                json.trim().startsWith("[") -> JSONArray(json)
                else -> {
                    val obj = JSONObject(json)
                    obj.optJSONArray("bids") ?: obj.optJSONArray("data")
                }
            }
        } catch (e: Exception) {
            null
        }
    }

    // ─────────────────────────────────────────────────────────
    // getAllGames() → list of game objects
    // ─────────────────────────────────────────────────────────
    fun getAllGames(token: String): JSONArray? {
        return try {
            val json = get("$BASE_URL/game", token) ?: return null
            when {
                json.trim().startsWith("[") -> JSONArray(json)
                else -> {
                    val obj = JSONObject(json)
                    obj.optJSONArray("games") ?: obj.optJSONArray("data")
                }
            }
        } catch (e: Exception) {
            null
        }
    }

    // ─────────────────────────────────────────────────────────
    // updateUserWallet()  — credits win amount
    // ─────────────────────────────────────────────────────────
    fun updateUserWallet(userId: String, newAmount: Double, token: String): Boolean {
        return try {
            val body = JSONObject().put("walletAmount", "%.2f".format(newAmount)).toString()
            val code = put("$BASE_URL/user/$userId", body, token)
            code == 200
        } catch (e: Exception) {
            false
        }
    }

    // ─────────────────────────────────────────────────────────
    // updateBidWinStatus()
    // ─────────────────────────────────────────────────────────
    fun updateBidWinStatus(bidId: String, status: String, token: String): Boolean {
        return try {
            val body = JSONObject().put("win", status).toString()
            val code = put("$BASE_URL/bid/$bidId", body, token)
            code == 200
        } catch (e: Exception) {
            false
        }
    }

    // ─────────────────────────────────────────────────────────
    // Private HTTP helpers
    // ─────────────────────────────────────────────────────────
    private fun get(url: String, token: String): String? {
        var conn: HttpURLConnection? = null
        return try {
            conn = (URL(url).openConnection() as HttpURLConnection).apply {
                requestMethod   = "GET"
                connectTimeout  = TIMEOUT
                readTimeout     = TIMEOUT
                setRequestProperty("Authorization", "Bearer $token")
                setRequestProperty("Content-Type", "application/json")
            }
            if (conn.responseCode != 200) return null
            BufferedReader(InputStreamReader(conn.inputStream)).use { it.readText() }
        } catch (e: Exception) {
            null
        } finally {
            conn?.disconnect()
        }
    }

    private fun put(url: String, body: String, token: String): Int {
        var conn: HttpURLConnection? = null
        return try {
            conn = (URL(url).openConnection() as HttpURLConnection).apply {
                requestMethod   = "PUT"
                doOutput        = true
                connectTimeout  = TIMEOUT
                readTimeout     = TIMEOUT
                setRequestProperty("Authorization", "Bearer $token")
                setRequestProperty("Content-Type", "application/json")
            }
            conn.outputStream.use { it.write(body.toByteArray()) }
            conn.responseCode
        } catch (e: Exception) {
            -1
        } finally {
            conn?.disconnect()
        }
    }
}