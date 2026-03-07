package com.example.ekdant

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/**
 * NotificationHelper
 * Central helper for ALL app notifications.
 * Channels:
 *   • WIN_CHANNEL      — user wins a bid (high priority, sound + vibrate)
 *   • RESULT_CHANNEL   — market result declared (default priority)
 *   • SERVICE_CHANNEL  — silent foreground-service keep-alive
 */
object NotificationHelper {

    // ── Channel IDs ──────────────────────────────────────────
    const val WIN_CHANNEL_ID     = "ekdant_win"
    const val RESULT_CHANNEL_ID  = "ekdant_result"
    const val SERVICE_CHANNEL_ID = "ekdant_service"

    // ── Notification IDs ─────────────────────────────────────
    const val SERVICE_NOTIF_ID = 1001

    // ── Vibration patterns ───────────────────────────────────
    private val WIN_VIBRATE    = longArrayOf(0, 300, 150, 300, 150, 600)
    private val RESULT_VIBRATE = longArrayOf(0, 200, 100, 200)

    // ─────────────────────────────────────────────────────────
    // createChannels() — call once in Application.onCreate()
    // ─────────────────────────────────────────────────────────
    fun createChannels(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE)
                as NotificationManager

        // Win channel — high importance (heads-up banner in foreground)
        nm.createNotificationChannel(
            NotificationChannel(
                WIN_CHANNEL_ID,
                "Win Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description      = "Alerts when you win a bid"
                enableLights(true)
                lightColor       = Color.parseColor("#D4A843")
                enableVibration(true)
                vibrationPattern = WIN_VIBRATE
                setShowBadge(true)
            }
        )

        // Result channel — default importance
        nm.createNotificationChannel(
            NotificationChannel(
                RESULT_CHANNEL_ID,
                "Result Notifications",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description      = "Market result declared alerts"
                enableLights(true)
                lightColor       = Color.parseColor("#3D8BF8")
                enableVibration(true)
                vibrationPattern = RESULT_VIBRATE
                setShowBadge(true)
            }
        )

        // Service channel — min importance, no sound
        nm.createNotificationChannel(
            NotificationChannel(
                SERVICE_CHANNEL_ID,
                "Background Service",
                NotificationManager.IMPORTANCE_MIN
            ).apply {
                description = "Keeps result polling alive"
                setShowBadge(false)
            }
        )
    }

    // ─────────────────────────────────────────────────────────
    // showWinNotification()
    // ─────────────────────────────────────────────────────────
    fun showWinNotification(
        context: Context,
        amount: Double,
        gameName: String,
        marketName: String,
        session: String
    ) {
        val pi = buildLaunchPendingIntent(context)

        val amountStr = "₹%.2f".format(amount)
        val title     = "🎉 You Won $amountStr!"
        val body      = "$gameName · $marketName ($session)\n$amountStr has been credited to your wallet."

        val notif = NotificationCompat.Builder(context, WIN_CHANNEL_ID)
            // Uses the app launcher icon — no custom drawable needed
            .setSmallIcon(context.applicationInfo.icon)
            .setContentTitle(title)
            .setContentText("$gameName · $marketName")
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setColor(Color.parseColor("#D4A843"))
            .setVibrate(WIN_VIBRATE)
            .setAutoCancel(true)
            .setContentIntent(pi)
            .build()

        val id = (System.currentTimeMillis() % 90_000).toInt() + 10_000
        NotificationManagerCompat.from(context).notify(id, notif)
    }

    // ─────────────────────────────────────────────────────────
    // showResultNotification()
    // ─────────────────────────────────────────────────────────
    fun showResultNotification(
        context: Context,
        marketName: String,
        openResult: String,
        closeResult: String,
        openPana: String,
        closePana: String
    ) {
        val pi = buildLaunchPendingIntent(context)

        val title = "📊 Result Declared: $marketName"
        val body  = buildString {
            if (openResult.isNotEmpty())  appendLine("Open  : $openResult  ($openPana)")
            if (closeResult.isNotEmpty()) appendLine("Close : $closeResult  ($closePana)")
        }.trimEnd()

        val notif = NotificationCompat.Builder(context, RESULT_CHANNEL_ID)
            .setSmallIcon(context.applicationInfo.icon)
            .setContentTitle(title)
            .setContentText("Open $openResult · Close $closeResult")
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setColor(Color.parseColor("#3D8BF8"))
            .setVibrate(RESULT_VIBRATE)
            .setAutoCancel(true)
            .setContentIntent(pi)
            .build()

        val id = (System.currentTimeMillis() % 80_000).toInt() + 20_000
        NotificationManagerCompat.from(context).notify(id, notif)
    }

    // ─────────────────────────────────────────────────────────
    // buildServiceNotification() — for foreground service
    // ─────────────────────────────────────────────────────────
    fun buildServiceNotification(context: Context): android.app.Notification {
        val pi = buildLaunchPendingIntent(context)

        return NotificationCompat.Builder(context, SERVICE_CHANNEL_ID)
            .setSmallIcon(context.applicationInfo.icon)
            .setContentTitle("Ekdant")
            .setContentText("Watching for results...")
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setOngoing(true)
            .setContentIntent(pi)
            .build()
    }

    // ─────────────────────────────────────────────────────────
    // Private helpers
    // ─────────────────────────────────────────────────────────
    private fun buildLaunchPendingIntent(context: Context): PendingIntent {
        val intent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?.apply { flags = Intent.FLAG_ACTIVITY_SINGLE_TOP }

        return PendingIntent.getActivity(
            context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}
