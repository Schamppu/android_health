import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
export 'step_event.dart';
export 'read_data.dart';
export 'date_interval.dart';

class AndroidHealth {
  static const MethodChannel _androidMethodChannel =
      MethodChannel('android_health_channel');

  /// Starts the subscription to the pedometer data.
  Future<bool> startSubscription() async {
    if (!Platform.isAndroid) {
      throw UnsupportedError(
          'getStepCount() is not supported on Android. Use stepCountStream instead.');
    }
    print('testi');
    final bool data = await _androidMethodChannel.invokeMethod(
      'startSubscription',
    );
    return data;
  }

  /// Ends the subscription to the pedometer data.
  Future<bool> endSubscription() async {
    if (!Platform.isAndroid) {
      throw UnsupportedError(
          'getStepCount() is not supported on Android. Use stepCountStream instead.');
    }
    final bool data = await _androidMethodChannel.invokeMethod(
      'endSubscription',
    );
    return data;
  }

  /// Reads the step data from Android platform.
  Future<dynamic> readStepCount({
    required DateTime from,
    required DateTime to,
    Duration? bucketTime,
  }) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError(
          'getStepCount() is not supported on Android. Use stepCountStream instead.');
    }

    final args = <String, dynamic>{
      'bucketTime': bucketTime?.inMilliseconds,
      'startTime': from.millisecondsSinceEpoch,
      'endTime': to.millisecondsSinceEpoch
    };
    final dynamic data = await _androidMethodChannel.invokeMethod(
      'readPedometerData',
      args,
    );
    return data;
  }
}
