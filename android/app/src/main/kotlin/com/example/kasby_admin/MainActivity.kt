package com.example.kasby_admin

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.kasby.admin/native_config"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getNativeConfig") {
                // Return basic config to satisfy the plugin timeout
                val config = mapOf(
                    "environment" to "production",
                    "version" to "1.0.0"
                )
                result.success(config)
            } else {
                result.notImplemented()
            }
        }
    }
}
