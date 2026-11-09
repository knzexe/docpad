import 'package:intl/intl.dart';

String formatDate(DateTime date, {String languageCode = 'en'}) {
  final locale = languageCode == 'bn' ? 'bn' : 'en';
  try {
    return DateFormat('d MMM yyyy', locale).format(date.toLocal());
  } catch (_) {
    return DateFormat('d MMM yyyy').format(date.toLocal());
  }
}

String formatDateTime(DateTime date) {
  return DateFormat('d MMM yyyy, HH:mm').format(date.toLocal());
}

String describeAge(DateTime retrievedAt, {DateTime? now}) {
  final clock = now ?? DateTime.now();
  final diff = clock.difference(retrievedAt);
  if (diff.isNegative || diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 48) return '${diff.inHours} hr ago';
  return formatDateTime(retrievedAt);
}
