package com.example.ekdant

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * MainActivity Wires a MethodChannel so Flutter can start/stop the background polling service via
 * ResultPollingReceiver.
 *
 * Flutter usage (e.g. in auth_service.dart):
 *
 * static const _channel = MethodChannel('com.ekdant.app/polling'); await
 * _channel.invokeMethod('startPolling'); // after login await _channel.invokeMethod('stopPolling');
 * // after logout
 */
class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.ekdant.app/polling"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call,
                result ->
            when (call.method) {
                "startPolling" -> {
                    sendBroadcast(
                            Intent(ResultPollingReceiver.ACTION_START_POLLING)
                                    .setPackage(packageName)
                    )
                    result.success(true)
                }
                "stopPolling" -> {
                    sendBroadcast(
                            Intent(ResultPollingReceiver.ACTION_STOP_POLLING)
                                    .setPackage(packageName)
                    )
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
