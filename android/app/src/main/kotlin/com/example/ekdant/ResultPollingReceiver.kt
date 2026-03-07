package com.example.ekdant

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.util.Log

class ResultPollingReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_START_POLLING = "com.ekdant.app.START_POLLING"
        const val ACTION_STOP_POLLING = "com.ekdant.app.STOP_POLLING"
        const val ACTION_POLL_TICK = "com.ekdant.app.POLL_TICK"

        private const val TAG = "ResultPollingReceiver"
        private const val POLL_INTERVAL_MS = 5 * 60 * 1000L
        private const val REQUEST_CODE = 9001

        fun schedulePoll(context: Context) {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val pi = buildPollIntent(context)

            am.setInexactRepeating(
                    AlarmManager.ELAPSED_REALTIME_WAKEUP,
                    SystemClock.elapsedRealtime() + POLL_INTERVAL_MS,
                    POLL_INTERVAL_MS,
                    pi
            )

            Log.d(TAG, "Poll alarm scheduled")
        }

        fun cancelPoll(context: Context) {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            am.cancel(buildPollIntent(context))
            Log.d(TAG, "Poll alarm cancelled")
        }

        private fun buildPollIntent(context: Context): PendingIntent {
            val intent = Intent(ACTION_POLL_TICK).setPackage(context.packageName)

            return PendingIntent.getBroadcast(
                    context,
                    REQUEST_CODE,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }
    }

    override fun onReceive(context: Context, intent: Intent) {

        when (intent.action) {
            ACTION_START_POLLING -> {
                Log.d(TAG, "Start polling requested")
                schedulePoll(context)
                context.startService(Intent(context, ResultPollingService::class.java))
            }
            ACTION_STOP_POLLING -> {
                Log.d(TAG, "Stop polling requested")
                cancelPoll(context)
                context.stopService(Intent(context, ResultPollingService::class.java))
            }
            ACTION_POLL_TICK -> {
                Log.d(TAG, "Poll tick received")

                context.startService(
                        Intent(context, ResultPollingService::class.java)
                                .putExtra("trigger", "alarm")
                )
            }
        }
    }
}
