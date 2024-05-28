package com.notacult.android_health

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import androidx.core.app.ActivityCompat
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.fitness.FitnessLocal
import com.google.android.gms.fitness.LocalRecordingClient
import com.google.android.gms.fitness.data.LocalDataSet
import com.google.android.gms.fitness.data.LocalDataType
import com.google.android.gms.fitness.request.LocalDataReadRequest
import io.flutter.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.TimeUnit

class RecordingApiClient() {
    private lateinit var context: Context
    private lateinit var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
    private lateinit var localRecordingClient: LocalRecordingClient
    private lateinit var channel : MethodChannel

    constructor(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding, channel: MethodChannel) : this() {
        this.context = flutterPluginBinding.applicationContext
        this.flutterPluginBinding = flutterPluginBinding
        this.channel = channel
    }

    fun startSubscription(call: MethodCall, result: MethodChannel.Result, activity: Activity) {
        val hasMinPlayServices = GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(context, LocalRecordingClient.LOCAL_RECORDING_CLIENT_MIN_VERSION_CODE)
        if (hasMinPlayServices != ConnectionResult.SUCCESS) {
            result.error("no_play_services", "Google Play Services too low. You need to update Google Play Services.", null)
            return
        }
        this.localRecordingClient = FitnessLocal.getLocalRecordingClient(activity)
        if (ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.ACTIVITY_RECOGNITION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            result.error("no_permission", "No permission to use pedometer.", null)
            return
        }
        localRecordingClient.subscribe(LocalDataType.TYPE_STEP_COUNT_DELTA).addOnSuccessListener {
            result.success(true)
        }.addOnFailureListener { e ->
            result.error("failed_to_subscribe", "Failed to subscribe to the pedometer, error: $e", null)
        }
        return
    }

    fun readPedometerData(call: MethodCall, result: MethodChannel.Result) {
        val bucketTime = call.argument<Int?>("bucketTime")
        val startTime = call.argument<Long>("startTime")!!
        val endTime = call.argument<Long>("endTime")!!
        lateinit var readRequest : LocalDataReadRequest
        if (bucketTime != null) {
            readRequest =
                LocalDataReadRequest.Builder()
                    .aggregate(LocalDataType.TYPE_STEP_COUNT_DELTA)
                    .bucketByTime(bucketTime, TimeUnit.MILLISECONDS)
                    .setTimeRange(startTime, endTime, TimeUnit.MILLISECONDS)
                    .build()
            localRecordingClient.readData(readRequest).addOnSuccessListener { response ->
                var returnList : MutableList<List<HashMap<String, Any>>> = arrayListOf()
                for (dataSet in response.buckets.flatMap { it.dataSets }) {
                    returnList.add(createStepResult(dataSet, result))
                }
                result.success(returnList)
            }
            .addOnFailureListener { e ->
                result.error("read_failure", "Failure to read pedometer data, error: $e.", null)
            }
        } else {
            readRequest =
                LocalDataReadRequest.Builder()
                    .read(LocalDataType.TYPE_STEP_COUNT_DELTA)
                    .setTimeRange(startTime, endTime, TimeUnit.MILLISECONDS)
                    .build()
            localRecordingClient.readData(readRequest).addOnSuccessListener { response ->
                var returnList : MutableList<List<HashMap<String, Any>>> = arrayListOf()
                for (dataSet in response.dataSets) {
                    returnList.add(createStepResult(dataSet, result))
                }
                result.success(returnList)
            }
            .addOnFailureListener { e ->
                result.error("read_failure", "Failure to read pedometer data, error: $e.", null)
            }
        }
        return
    }

    fun endSubscription(result: MethodChannel.Result, activity: Activity) {
        val localRecordingClient = FitnessLocal.getLocalRecordingClient(activity)
        localRecordingClient.unsubscribe(LocalDataType.TYPE_STEP_COUNT_DELTA)
            .addOnSuccessListener {
                result.success(true)
            }
            .addOnFailureListener { e ->
                result.error("failed_to_unsubscribe", "Failed to unsubscribe to the pedometer, error: $e", null)
            }
    }

    private fun createStepResult(dataSet: LocalDataSet, result: MethodChannel.Result): List<HashMap<String, Any>> {
        val stepData =
            dataSet.dataPoints.mapIndexed { _, dp ->
                Log.println(android.util.Log.DEBUG, "bgpedometer", dp.dataType.name)
                return@mapIndexed hashMapOf(
                    "type" to
                            dp.dataType.name,
                    "start" to
                            dp.getStartTime(TimeUnit.MILLISECONDS),
                    "end" to
                            dp.getEndTime(TimeUnit.MILLISECONDS),
                    "fields" to
                            dp.dataType.fields.mapIndexed { _, field -> return@mapIndexed hashMapOf(
                                "name" to
                                    field.name,
                                "value" to
                                    dp.getValue(field).asInt()
                            )},
                )
            }
        return stepData
    }
}