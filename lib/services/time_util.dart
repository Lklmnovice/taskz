//todo localization

class DateTimeFormatter {
  static DateTime get today => DateTime.now();

}

extension CustomDateTime on DateTime {
  String toHyphenedYYYYMMDD() {
    return '${this.year}-${this.month}-${this.day}';
  }

  String getWeekDay() {
    return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday-1];
  }
}