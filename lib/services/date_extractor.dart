// Extracts future dates from OCR text using multiple date format patterns.
// Returns a list of DateTime objects found in the text.
//
// Supported formats:
//   - DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY
//   - DD/MM/YY, DD-MM-YY, DD.MM.YY
//   - DD/MM, DD-MM (assumes current year, or next year if date has passed)
//   - Greek month names: "15 Ιουνίου 2026", "15 Ιουνίου"
//   - English month names: "15 June 2026", "June 15, 2026"

List<DateTime> extractDatesFromText(String text) {
  final List<DateTime> dates = [];
  final now = DateTime.now();

  // Greek month name map
  const greekMonths = {
    'ιανουαρίου': 1, 'ιανουάριος': 1, 'ιαν': 1,
    'φεβρουαρίου': 2, 'φεβρουάριος': 2, 'φεβ': 2,
    'μαρτίου': 3, 'μάρτιος': 3, 'μαρ': 3,
    'απριλίου': 4, 'απρίλιος': 4, 'απρ': 4,
    'μαΐου': 5, 'μάιος': 5, 'μαϊου': 5, 'μάι': 5,
    'ιουνίου': 6, 'ιούνιος': 6, 'ιουν': 6,
    'ιουλίου': 7, 'ιούλιος': 7, 'ιουλ': 7,
    'αυγούστου': 8, 'αύγουστος': 8, 'αυγ': 8,
    'σεπτεμβρίου': 9, 'σεπτέμβριος': 9, 'σεπ': 9,
    'οκτωβρίου': 10, 'οκτώβριος': 10, 'οκτ': 10,
    'νοεμβρίου': 11, 'νοέμβριος': 11, 'νοε': 11,
    'δεκεμβρίου': 12, 'δεκέμβριος': 12, 'δεκ': 12,
  };

  // English month name map
  const englishMonths = {
    'january': 1, 'jan': 1,
    'february': 2, 'feb': 2,
    'march': 3, 'mar': 3,
    'april': 4, 'apr': 4,
    'may': 5,
    'june': 6, 'jun': 6,
    'july': 7, 'jul': 7,
    'august': 8, 'aug': 8,
    'september': 9, 'sep': 9, 'sept': 9,
    'october': 10, 'oct': 10,
    'november': 11, 'nov': 11,
    'december': 12, 'dec': 12,
  };

  // Pattern 1: DD/MM/YYYY or DD-MM-YYYY or DD.MM.YYYY
  final fullDateRegex = RegExp(r'\b(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4})\b');
  for (final match in fullDateRegex.allMatches(text)) {
    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final year = int.tryParse(match.group(3)!);
    if (day != null && month != null && year != null) {
      final date = _tryDate(year, month, day);
      if (date != null && date.isAfter(now)) dates.add(date);
    }
  }

  // Pattern 2: DD/MM/YY or DD-MM-YY or DD.MM.YY (2-digit year)
  final shortYearRegex = RegExp(r'\b(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2})\b');
  for (final match in shortYearRegex.allMatches(text)) {
    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final shortYear = int.tryParse(match.group(3)!);
    if (day != null && month != null && shortYear != null) {
      final year = 2000 + shortYear;
      final date = _tryDate(year, month, day);
      if (date != null && date.isAfter(now)) dates.add(date);
    }
  }

  // Pattern 3: DD/MM or DD-MM (no year — assume current or next year)
  final noYearRegex = RegExp(r'\b(\d{1,2})[/\-](\d{1,2})\b');
  for (final match in noYearRegex.allMatches(text)) {
    // Skip if this is part of a longer date already matched (e.g., DD/MM/YYYY)
    final fullStr = text.substring(match.end);
    if (fullStr.isNotEmpty && (fullStr[0] == '/' || fullStr[0] == '-' || fullStr[0] == '.')) continue;

    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    if (day != null && month != null) {
      var date = _tryDate(now.year, month, day);
      if (date != null) {
        if (date.isBefore(now)) {
          date = _tryDate(now.year + 1, month, day);
        }
        if (date != null && date.isAfter(now)) dates.add(date);
      }
    }
  }

  // Pattern 4: Greek month names — "15 Ιουνίου 2026" or "15 Ιουνίου"
  final lowerText = text.toLowerCase();
  for (final entry in greekMonths.entries) {
    final monthName = entry.key;
    final monthNum = entry.value;

    // With year: "15 Ιουνίου 2026"
    final withYearRegex = RegExp('(\\d{1,2})\\s+$monthName\\s+(\\d{4})', caseSensitive: false);
    for (final match in withYearRegex.allMatches(lowerText)) {
      final day = int.tryParse(match.group(1)!);
      final year = int.tryParse(match.group(2)!);
      if (day != null && year != null) {
        final date = _tryDate(year, monthNum, day);
        if (date != null && date.isAfter(now)) dates.add(date);
      }
    }

    // Without year: "15 Ιουνίου"
    final noYearMonthRegex = RegExp('(\\d{1,2})\\s+$monthName(?!\\s+\\d)', caseSensitive: false);
    for (final match in noYearMonthRegex.allMatches(lowerText)) {
      final day = int.tryParse(match.group(1)!);
      if (day != null) {
        var date = _tryDate(now.year, monthNum, day);
        if (date != null && date.isBefore(now)) {
          date = _tryDate(now.year + 1, monthNum, day);
        }
        if (date != null && date.isAfter(now)) dates.add(date);
      }
    }
  }

  // Pattern 5: English month names — "15 June 2026" or "June 15, 2026" or "15 June"
  for (final entry in englishMonths.entries) {
    final monthName = entry.key;
    final monthNum = entry.value;

    // "15 June 2026"
    final engWithYear1 = RegExp('(\\d{1,2})\\s+$monthName\\s+(\\d{4})', caseSensitive: false);
    for (final match in engWithYear1.allMatches(lowerText)) {
      final day = int.tryParse(match.group(1)!);
      final year = int.tryParse(match.group(2)!);
      if (day != null && year != null) {
        final date = _tryDate(year, monthNum, day);
        if (date != null && date.isAfter(now)) dates.add(date);
      }
    }

    // "June 15, 2026"
    final engWithYear2 = RegExp('$monthName\\s+(\\d{1,2}),?\\s+(\\d{4})', caseSensitive: false);
    for (final match in engWithYear2.allMatches(lowerText)) {
      final day = int.tryParse(match.group(1)!);
      final year = int.tryParse(match.group(2)!);
      if (day != null && year != null) {
        final date = _tryDate(year, monthNum, day);
        if (date != null && date.isAfter(now)) dates.add(date);
      }
    }

    // "15 June" (no year)
    final engNoYear = RegExp('(\\d{1,2})\\s+$monthName(?!\\s+\\d)', caseSensitive: false);
    for (final match in engNoYear.allMatches(lowerText)) {
      final day = int.tryParse(match.group(1)!);
      if (day != null) {
        var date = _tryDate(now.year, monthNum, day);
        if (date != null && date.isBefore(now)) {
          date = _tryDate(now.year + 1, monthNum, day);
        }
        if (date != null && date.isAfter(now)) dates.add(date);
      }
    }
  }

  // Remove duplicates and sort
  final uniqueDates = <DateTime>{};
  for (final d in dates) {
    // Normalize to date-only for dedup
    uniqueDates.add(DateTime(d.year, d.month, d.day));
  }

  final result = uniqueDates.toList()..sort();
  return result;
}

/// Safely creates a DateTime, returning null for invalid dates.
DateTime? _tryDate(int year, int month, int day) {
  if (month < 1 || month > 12) return null;
  if (day < 1 || day > 31) return null;
  try {
    final date = DateTime(year, month, day);
    // Verify the date is valid (e.g., not Feb 30)
    if (date.month != month || date.day != day) return null;
    return date;
  } catch (_) {
    return null;
  }
}
