import 'package:intl/intl.dart';

String capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

String formatFullDate(DateTime date) =>
    capitalize(DateFormat("EEEE d 'de' MMMM", 'es').format(date));

String formatShortDate(DateTime date) =>
    DateFormat('EEE d MMM', 'es').format(date);

String formatMonthDay(DateTime date) =>
    DateFormat("d 'de' MMMM", 'es').format(date);

String formatClock(DateTime date) => DateFormat('HH:mm').format(date);

String formatMinutesOfDay(int minutes) {
  final hours = (minutes ~/ 60).toString().padLeft(2, '0');
  final mins = (minutes % 60).toString().padLeft(2, '0');
  return '$hours:$mins';
}

int minutesFromTimeOfDay(int hour, int minute) => hour * 60 + minute;

String countdownLabel(Duration duration) {
  if (duration.inMinutes <= 0) return 'ahora';
  if (duration.inMinutes < 60) return 'en ${duration.inMinutes} min';
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  if (minutes == 0) return 'en $hours h';
  return 'en $hours h $minutes min';
}

String dayLabel(DateTime date, DateTime now) {
  final target = DateTime(date.year, date.month, date.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = target.difference(today).inDays;
  if (diff == 0) return 'Hoy';
  if (diff == 1) return 'Mañana';
  if (diff == -1) return 'Ayer';
  if (diff < 0) return 'Vencida';
  if (diff < 7) return 'En $diff días';
  return formatShortDate(date);
}

String formatGrade(double? grade) {
  if (grade == null) return '';
  if (grade == grade.roundToDouble()) return grade.toStringAsFixed(0);
  return grade.toStringAsFixed(1);
}
