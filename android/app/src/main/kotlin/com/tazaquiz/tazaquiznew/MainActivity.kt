package com.tazaquiz.quiz

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "tazaquiz/notification"
    private var channel: MethodChannel? = null
    private var pendingData: HashMap<String, Any?>? = null
    private var flutterReady = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )

        channel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "flutterReady" -> {
                    flutterReady = true
                    android.util.Log.d("MainActivity", "✅ Flutter is ready")
                    pendingData?.let {
                        android.util.Log.d("MainActivity", "📤 Sending pending data to Flutter: $it")
                        channel?.invokeMethod("onNotificationClick", it)
                        pendingData = null
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Store cold-start intent — Flutter not ready yet
        extractData(intent)?.let {
            android.util.Log.d("MainActivity", "💾 Stored cold-start pending data: $it")
            pendingData = it
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)

        extractData(intent)?.let { data ->
            if (flutterReady) {
                android.util.Log.d("MainActivity", "📤 Sending onNewIntent data to Flutter: $data")
                channel?.invokeMethod("onNotificationClick", data)
            } else {
                pendingData = data
            }
        }
    }

    private fun extractData(intent: Intent?): HashMap<String, Any?>? {
        if (intent?.getBooleanExtra("from_notification", false) != true) {
            android.util.Log.d("MainActivity", "⛔ Not a notification intent, skipping")
            return null
        }

        val bundle = intent.extras ?: return null
        val data = HashMap<String, Any?>()
        for (key in bundle.keySet()) {
            data[key] = bundle.get(key)?.toString()
        }

        android.util.Log.d("MainActivity", "✅ Extracted notification data: $data")
        return data
    }
}