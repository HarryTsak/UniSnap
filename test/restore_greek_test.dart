import 'package:flutter_test/flutter_test.dart';
import 'package:unisnap/services/helpers.dart';

void main() {
  test('restoreGreekText preserves spaces, restores Greek characters, and keeps ECTS', () {
    const input = 'Lari va TapakoAouenoeL KaV\n'
        'KúKÀoUG uaennawV\n'
        '"ZuotHuata AoyLouKoÚ"\n'
        '• "ALayeipLon AsôouévwV KaL TvwOE\n'
        'Eva Bhua (6 ECTS) TLO KOvtá oto TTUX';

    final result = restoreGreekText(input);

    print('Restored text:\n$result');

    expect(result, contains('Γιατί να παρακολουθήσει κανείς'));
    expect(result, contains('Κύκλους μαθημάτων'));
    expect(result, contains('"Συστήματα Λογισμικού"'));
    expect(result, contains('• "Διαχείριση Δεδομένων και Γνώσεων'));
    expect(result, contains('Ένα βήμα (6 ECTS) πιο κοντά στο πτυχ'));
  });
}
