//todo localization
const MONTH_DAY = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
const MONTH_STR = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December'
];

class DateTimeFormatter {
  static bool isLeapYear(int year) =>
      (year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0));
  static DateTime get today => DateTime.now();
  static DateTime get tomorrow => today.add(Duration(days: 1));
}

extension CustomDateTime on DateTime {
  String toHyphenedYYYYMMDD() {
    final str =
        '${this.year}-${this.month.toPaddedString()}-${this.day.toPaddedString()}';
    assert(RegExp(r'\d{4}-[01]\d-[0-3]\d').hasMatch(str));
    return str;
  }

  String getWeekDay() {
    return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1];
  }

  String getMonthStrShort() {
    return day.toString().padLeft(2, '0') +
        ' ' +
        [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dic'
        ][month - 1];
  }

  String getMonthStr() {
    return MONTH_STR[month - 1];
  }

  DateTime toMonthEnd() {
    final isLeapYear = DateTimeFormatter.isLeapYear(this.year);
    final str = this.toHyphenedYYYYMMDD().substring(0, 8);
    final day = this.month != 2
        ? MONTH_DAY[this.month - 1]
        : isLeapYear ? MONTH_DAY[1] + 1 : MONTH_DAY[1];
    return DateTime.parse(str + day.toPaddedString());
  }

  DateTime toMonthStart() {
    final str = this.toHyphenedYYYYMMDD().substring(0, 8);
    final day = 1;
    return DateTime.parse(str + day.toPaddedString());
  }

  bool operator <(Object other) =>
      other is DateTime &&
      (microsecondsSinceEpoch < other.microsecondsSinceEpoch);

  bool operator <=(Object other) =>
      other is DateTime && (this < other || this == other);

  bool operator >(Object other) => !(this <= other);
}

extension CustomInt on int {
  String toPaddedString() {
    return toString().padLeft(2, '0');
  }
}
