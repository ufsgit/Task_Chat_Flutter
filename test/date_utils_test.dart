import 'package:flutter_test/flutter_test.dart';
import 'package:task_chat/core/date_utils.dart';

void main() {
  group('formatDateToDayMonthYear Tests', () {
    test('formats null and empty strings', () {
      expect(formatDateToDayMonthYear(null), '');
      expect(formatDateToDayMonthYear(''), '');
      expect(formatDateToDayMonthYear('   '), '');
    });

    test('formats ISO8601 strings to day/month/year', () {
      expect(formatDateToDayMonthYear('2024-10-24'), '24/10/2024');
      expect(formatDateToDayMonthYear('2024-05-09T10:00:00.000'), '09/05/2024');
    });

    test('formats slash MM/DD/YYYY to DD/MM/YYYY', () {
      expect(formatDateToDayMonthYear('10/24/2024'), '24/10/2024');
      expect(formatDateToDayMonthYear('24/10/2024'), '24/10/2024');
      expect(formatDateToDayMonthYear('2024/10/24'), '24/10/2024');
    });

    test('formats hyphen MM-DD-YYYY or YYYY-MM-DD to DD/MM/YYYY', () {
      expect(formatDateToDayMonthYear('2024-10-24'), '24/10/2024');
      expect(formatDateToDayMonthYear('24-10-2024'), '24/10/2024');
      expect(formatDateToDayMonthYear('10-24-2024'), '24/10/2024');
    });

    test('formats dates containing time components and AM/PM without showing time', () {
      expect(formatDateToDayMonthYear('2024-10-24 10:30:00'), '24/10/2024');
      expect(formatDateToDayMonthYear('24/10/2024 10:30:00'), '24/10/2024');
      expect(formatDateToDayMonthYear('10/24/2024 02:30 PM'), '24/10/2024');
      expect(formatDateToDayMonthYear('24-10-2024 15:00:00'), '24/10/2024');
      expect(formatDateToDayMonthYear('24/10/2024, 10:30 AM'), '24/10/2024');
      expect(formatDateToDayMonthYear('2024-10-24T18:30:00.000Z'), isNotEmpty);
    });
  });
}
