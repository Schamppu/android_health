import 'dart:math';

enum ReturnedInterval {
  before,
  after,
}

/// Interval class when executing interval code
class DateInterval {
  DateInterval(
      {this.months = 0,
      this.days = 0,
      this.hours = 0,
      this.minutes = 0,
      this.seconds = 0});
  final int months;
  final int days;
  final int hours;
  final int minutes;
  final int seconds;

  factory DateInterval.fromDuration({required Duration duration}) {
    final durationSeconds = duration.inSeconds;
    final days = durationSeconds ~/ 86400;
    final hours = (durationSeconds - (days * 86400)) ~/ 3600;
    final minutes = (durationSeconds - (days * 86400) - (hours * 3600)) ~/ 60;
    final seconds = max(
        durationSeconds - (days * 86400) - (hours * 3600) - (minutes * 60), 0);
    return DateInterval(
      days: days,
      hours: hours,
      minutes: minutes,
      seconds: seconds,
    );
  }

  @override
  String toString() {
    return 'Months: $months, days: $days, hours: $hours, minutes: $minutes, seconds: $seconds';
  }
}

/// Normalizes time stamp
DateTime normalizeIntervalTime({
  required DateTime time,
  required DateInterval interval,
  ReturnedInterval returnedInterval = ReturnedInterval.before,
  bool atSameMoment = false,
}) {
  DateTime returnTime = time.copyWith(millisecond: 0, microsecond: 0);
  if (interval.months != 0) {
    returnTime =
        returnTime.copyWith(month: 1, day: 1, hour: 0, minute: 0, second: 0);
  } else if (interval.days != 0) {
    returnTime = returnTime.copyWith(day: 1, hour: 0, minute: 0, second: 0);
  } else if (interval.hours != 0) {
    returnTime = returnTime.copyWith(hour: 0, minute: 0, second: 0);
  } else if (interval.minutes != 0) {
    returnTime = returnTime.copyWith(minute: 0, second: 0);
  } else if (interval.seconds != 0) {
    returnTime = returnTime.copyWith(second: 0);
  }
  while (true) {
    final newTime = returnTime.copyWith(
      month: returnTime.month + interval.months,
      day: returnTime.day + interval.days,
      hour: returnTime.hour + interval.hours,
      minute: returnTime.minute + interval.minutes,
      second: returnTime.second + interval.seconds,
    );
    if (((atSameMoment && newTime.isAtSameMomentAs(time)) ||
            (!atSameMoment && !newTime.isAtSameMomentAs(time))) &&
        newTime.isAfter(time)) {
      if (returnedInterval == ReturnedInterval.before) {
        return returnTime;
      } else {
        return newTime;
      }
    }
    returnTime = newTime.copyWith();
  }
}
