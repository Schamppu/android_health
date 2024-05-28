class StepEvent {
  const StepEvent({
    required this.startTime,
    required this.endTime,
    required this.iterationStartTime,
    required this.iterationEndTime,
    required this.steps,
    required this.iteration,
  });
  final DateTime startTime;
  final DateTime endTime;
  final DateTime iterationStartTime;
  final DateTime iterationEndTime;
  final int steps;
  final int iteration;

  @override
  String toString() {
    return 'StepEvent(startTime: $startTime, endTime: $endTime, steps: $steps, iterationStartTime: $iterationStartTime, iterationEndTime: $iterationEndTime)';
  }
}
