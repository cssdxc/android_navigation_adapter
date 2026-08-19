package com.cssdxc.android_navigation_adapter

import android.content.Context
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class AndroidNavigationAdapterPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            GET_NAVIGATION_MODE -> result.success(currentNavigationMode())
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private fun currentNavigationMode(): Int {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return NAVIGATION_MODE_UNKNOWN
        }

        val mode = Settings.Secure.getInt(
            context.contentResolver,
            NAVIGATION_MODE_SETTING,
            NAVIGATION_MODE_UNKNOWN,
        )
        return if (mode in NAVIGATION_MODE_THREE_BUTTON..NAVIGATION_MODE_GESTURE) {
            mode
        } else {
            NAVIGATION_MODE_UNKNOWN
        }
    }

    companion object {
        private const val CHANNEL_NAME = "android_navigation_adapter"
        private const val GET_NAVIGATION_MODE = "getNavigationMode"
        private const val NAVIGATION_MODE_SETTING = "navigation_mode"
        private const val NAVIGATION_MODE_UNKNOWN = -1
        private const val NAVIGATION_MODE_THREE_BUTTON = 0
        private const val NAVIGATION_MODE_TWO_BUTTON = 1
        private const val NAVIGATION_MODE_GESTURE = 2
    }
}
