package com.example.ekdant

import android.app.Application
import android.util.Log

/**
 * EkdantApplication
 * ─────────────────────────────────────────────────────────────
 * Custom Application class.
 *
 * Register in AndroidManifest.xml:
 *   <application android:name=".EkdantApplication" ...>
 *
 * Responsibilities:
 *   • Creates all notification channels on first run (Android 8+).
 *   • Nothing else — keep it lean.
 */
class EkdantApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        Log.d("EkdantApp", "Application onCreate")

        // Create notification channels once — safe to call repeatedly
        NotificationHelper.createChannels(this)
    }
}