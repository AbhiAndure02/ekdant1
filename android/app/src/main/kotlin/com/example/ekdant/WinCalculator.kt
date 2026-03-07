package com.example.ekdant

import org.json.JSONObject

/**
 * WinCalculator
 * ─────────────────────────────────────────────────────────────
 * Pure Kotlin port of the Flutter win-calculation logic.
 * Kept in sync with home_screen.dart _calculateWinnings().
 *
 * SP / DP / TP detection uses the same pana classification:
 *   Triple Pana → 600x   (111, 222, 333 … 999, 000)
 *   Double Pana → 300x   (all panas where 2 digits repeat)
 *   Single Pana → 150x   (all panas where all 3 digits differ)
 */
object WinCalculator {

    data class WinResult(val isWin: Boolean, val amount: Double)

    private val LOSS = WinResult(false, 0.0)

    // ─────────────────────────────────────────────────────────
    // Top-level entry point
    // ─────────────────────────────────────────────────────────
    fun calculate(bid: JSONObject, result: JSONObject, game: JSONObject): WinResult {
        val marketId = bid.optString("marketId")
        val gameId   = bid.optString("gameId")

        if (marketId != result.optString("marketId")) return LOSS
        if (gameId   != game.optString("id"))         return LOSS

        return when (bid.optString("session")) {
            "Open"  -> calcOpen(bid, result, game)
            "Close" -> calcClose(bid, result, game)
            else    -> LOSS
        }
    }

    // ─────────────────────────────────────────────────────────
    // Open session
    // ─────────────────────────────────────────────────────────
    private fun calcOpen(bid: JSONObject, result: JSONObject, game: JSONObject): WinResult {
        val gn   = game.optString("gameName")
        val d    = bid.optString("digit").trim()
        val p    = bid.optString("pana").trim()
        val pts  = bid.optString("points").toDoubleOrNull() ?: return LOSS
        val oR   = result.optString("openResult").trim()
        val cR   = result.optString("closeResult").trim()
        val oP   = result.optString("openPana").trim()
        val cP   = result.optString("closePana").trim()

        return when (gn) {
            "SINGLE DIGIT"    -> if (d == oR)           WinResult(true, pts * 10)    else LOSS
            "JODI DIGIT"      -> if (d == "$oR$cR")     WinResult(true, pts * 100)   else LOSS
            "RED JODI FAMILY" -> if (d == "$oR$cR")     WinResult(true, pts * 100)    else LOSS
            "RED JODI"        -> if (d == "$oR$cR")     WinResult(true, pts * 100)    else LOSS
            "JODI FAMILY"     -> if (d == "$oR$cR")     WinResult(true, pts * 100)    else LOSS
            "SINGLE PANNA"    -> if (p == oP)           WinResult(true, pts * 150)   else LOSS
            "DUBBLE PANNA"    -> if (p == oP)           WinResult(true, pts * 300)   else LOSS
            "TRIPLE PANNA"    -> if (p == oP)           WinResult(true, pts * 600)   else LOSS
            "CYCLE PATTI"     -> if (p == oP)           WinResult(true, pts * 140)   else LOSS
            "FAMILY PANNA"    -> if (p == oP)           WinResult(true, pts * 150)   else LOSS
            "SP DP TP"        -> calcSpDpTp(p, oP, pts)
            "HALF SANGAM"     -> if (p == "$oP-$cR")    WinResult(true, pts * 1200)  else LOSS
            "FULL SANGAM"     -> if (p == "$oP-$cP")    WinResult(true, pts * 12000) else LOSS
            else              -> LOSS
        }
    }

    // ─────────────────────────────────────────────────────────
    // Close session
    // ─────────────────────────────────────────────────────────
    private fun calcClose(bid: JSONObject, result: JSONObject, game: JSONObject): WinResult {
        val gn   = game.optString("gameName")
        val d    = bid.optString("digit").trim()
        val p    = bid.optString("pana").trim()
        val pts  = bid.optString("points").toDoubleOrNull() ?: return LOSS
        val oR   = result.optString("openResult").trim()
        val cR   = result.optString("closeResult").trim()
        val cP   = result.optString("closePana").trim()

        return when (gn) {
            "SINGLE DIGIT"  -> if (d == cR)            WinResult(true, pts * 10)   else LOSS
            "SINGLE PANNA"  -> if (p == cP)            WinResult(true, pts * 150)  else LOSS
            "DUBBLE PANNA"  -> if (p == cP)            WinResult(true, pts * 300)  else LOSS
            "TRIPLE PANNA"  -> if (p == cP)            WinResult(true, pts * 600)  else LOSS
            "CYCLE PATTI"   -> if (p == cP)            WinResult(true, pts * 140)  else LOSS
            "FAMILY PANNA"  -> if (p == cP)            WinResult(true, pts * 150)  else LOSS
            "SP DP TP"      -> calcSpDpTp(p, cP, pts)
            "HALF SANGAM"   -> if (p == "$oR-$cP")     WinResult(true, pts * 1200) else LOSS
            else            -> LOSS
        }
    }

    // ─────────────────────────────────────────────────────────
    // SP DP TP — classify pana type, apply correct multiplier
    // ─────────────────────────────────────────────────────────
    private fun calcSpDpTp(bidPana: String, resultPana: String, pts: Double): WinResult {
        if (bidPana != resultPana) return LOSS
        return when {
            isTriplePana(bidPana) -> WinResult(true, pts * 600)
            isDoublePana(bidPana) -> WinResult(true, pts * 300)
            isSinglePana(bidPana) -> WinResult(true, pts * 150)
            else                  -> LOSS
        }
    }

    // ─────────────────────────────────────────────────────────
    // Pana type detection
    // ─────────────────────────────────────────────────────────

    /** Triple pana: all three digits are the same. e.g. "000", "111" … "999" */
    private fun isTriplePana(pana: String): Boolean {
        if (pana.length != 3) return false
        return pana[0] == pana[1] && pana[1] == pana[2]
    }

    /** Double pana: exactly two digits are the same. e.g. "100", "211", "344" */
    private fun isDoublePana(pana: String): Boolean {
        if (pana.length != 3) return false
        val (a, b, c) = pana.map { it }
        return (a == b && b != c) || (a == c && a != b) || (b == c && a != b)
    }

    /** Single pana: all three digits are different. e.g. "123", "456" */
    private fun isSinglePana(pana: String): Boolean {
        if (pana.length != 3) return false
        return pana[0] != pana[1] && pana[1] != pana[2] && pana[0] != pana[2]
    }

    // ─────────────────────────────────────────────────────────
    // isResultReadyForBid() — mirrors Flutter logic
    // ─────────────────────────────────────────────────────────
    fun isResultReady(bid: JSONObject, result: JSONObject, game: JSONObject): Boolean {
        val session  = bid.optString("session")
        val gameName = game.optString("gameName")
        val oR = result.optString("openResult")
        val oP = result.optString("openPana")
        val cR = result.optString("closeResult")
        val cP = result.optString("closePana")

        return when (session) {
            "Open" -> when (gameName) {
                "JODI DIGIT", "FULL SANGAM", "HALF SANGAM" ->
                    cR.isNotEmpty() && cP.isNotEmpty()
                else ->
                    oR.isNotEmpty() || oP.isNotEmpty()
            }
            "Close" -> cR.isNotEmpty() || cP.isNotEmpty()
            else    -> false
        }
    }
}