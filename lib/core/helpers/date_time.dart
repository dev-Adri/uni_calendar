String getDate() {
  DateTime now = DateTime.now();
  List<String> weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  return '${weekdays[now.weekday - 1]} ${now.day} ${now.year}';
}

String getWeekDay() {
  DateTime now = DateTime.now();
  List<String> weekdays = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
  ];
  return weekdays[now.weekday - 1];
}
