import 'android_health.dart';

/// Reads pedometer data from Android Health and returns the data as a list of [StepEvent] objects.
Future<List<StepEvent>> readPedometerData({
  /// The start time of the data to read
  required DateTime startTime,

  /// The end time of the data to read
  required DateTime endTime,

  /// Current time. Defaults to DateTime.now() if not provided.
  DateTime? currentTime,

  /// Interval you want to batch the data to. Not needed if you want to just read all of the data between [startTime] and [endTime]
  Duration? batchInterval,

  /// If you want to normalize the date times. This means that the date times will be rounded to the nearest [batchInterval], so you can get the data in a more organized way.
  bool normalizeDateTime = true,

  /// Callback for each step event added, handy for logging events for instance
  Function(StepEvent)? onStepEvent,

  /// Callback if the subscription fails
  Function()? onSubscriptionFail,
}) async {
  final androidHealth = AndroidHealth();
  final success = await androidHealth.startSubscription();
  if (success) {
    const Duration intervalDuration = Duration(minutes: 30);
    final DateInterval interval = DateInterval.fromDuration(
      duration: const Duration(minutes: 30),
    );
    final List<Object?> stepData = [];
    final currentTime = DateTime.now();
    List<StepEvent> stepEvents = [];
    if (startTime.isBefore(currentTime.subtract(const Duration(seconds: 3)))) {
      DateTime firstIterationTime = startTime;
      if (normalizeDateTime) {
        firstIterationTime = normalizeIntervalTime(
          time: startTime,
          interval: interval,
          returnedInterval: ReturnedInterval.after,
        );
      }
      stepData.addAll(await androidHealth.readStepCount(
        from: startTime,
        to: firstIterationTime.isBefore(currentTime)
            ? firstIterationTime
            : currentTime,
        bucketTime: intervalDuration,
      ));
      if (firstIterationTime.isBefore(currentTime)) {
        stepData.addAll(await androidHealth.readStepCount(
          from: firstIterationTime,
          to: currentTime,
          bucketTime: intervalDuration,
        ));
      }
      int iteration = 0;
      for (final stepObject in stepData) {
        if (stepObject is List) {
          if (stepObject.isNotEmpty) {
            for (final step in stepObject) {
              if (step is Map) {
                final startTime =
                    DateTime.fromMillisecondsSinceEpoch(step['start']);
                final endTime =
                    DateTime.fromMillisecondsSinceEpoch(step['end']);
                final iterationStartTime = iteration == 0
                    ? startTime
                    : firstIterationTime
                        .add(intervalDuration * (iteration - 1));
                final iterationEndTime = iteration == 0
                    ? (firstIterationTime.isBefore(endTime)
                        ? firstIterationTime
                        : endTime)
                    : firstIterationTime.add(intervalDuration * iteration);
                final eventList = step['fields'];
                num steps = 0;
                for (final event in eventList) {
                  if (event is Map) {
                    if (event['name'] == 'steps') {
                      steps += event['value'] ?? 0;
                    }
                  }
                }
                final stepEvent = StepEvent(
                  startTime: startTime,
                  endTime: endTime,
                  iterationStartTime: iterationStartTime,
                  iterationEndTime: iterationEndTime,
                  steps: steps.toInt(),
                  iteration: iteration,
                );
                stepEvents.add(stepEvent);
                onStepEvent?.call(stepEvent);
              }
            }
          }
        }
        iteration++;
      }
    }
    return stepEvents;
  } else {
    onSubscriptionFail?.call();
    return [];
  }
}
