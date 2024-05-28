package com.notacult.android_health

import android.app.Activity
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** Not a Cult's Android Health integration */
class AndroidHealthPlugin : FlutterPlugin, ActivityAware, MethodCallHandler {
    private lateinit var androidHealthChannel: MethodChannel
    private lateinit var androidHealth : RecordingApiClient
    private lateinit var activity: Activity

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        /// Create channels
        androidHealthChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "android_health_channel")
        androidHealthChannel.setMethodCallHandler(this)
        androidHealth = RecordingApiClient(flutterPluginBinding, androidHealthChannel)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        //
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        TODO("Not yet implemented")
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        TODO("Not yet implemented")
    }

    override fun onDetachedFromActivity() {
        TODO("Not yet implemented")
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "startSubscription" -> {
                androidHealth.startSubscription(call, result, activity)
            }
            "readPedometerData" -> {
                androidHealth.readPedometerData(call, result)
            }
            "endSubscription" -> {
                androidHealth.endSubscription(result, activity)
            }
            else -> {
                result.notImplemented();
            }
        }
    }
}
