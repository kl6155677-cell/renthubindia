import 'package:intl/intl.dart';

class DateUtilsHelper {
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  static int calculateRentalDays(DateTime start, DateTime end) {
    final difference = end.difference(start).inDays;
    return difference > 0 ? difference : 1; 
  }
}
