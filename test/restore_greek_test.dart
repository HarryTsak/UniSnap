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

  test('smart upsilon-vs-mu heuristic correctly restores common words', () {
    // 1. 'touG' should be restored to 'τους' (u -> υ because followed by G/ς which is consonant)
    expect(restoreGreekText('touG'), equals('τους'));

    // 2. 'uou' should be restored to 'μου' (first u -> μ because followed by vowel o, second u -> υ)
    expect(restoreGreekText('uou'), equals('μου'));

    // 3. 'Kupiakn' should be restored to 'Kυριακη' (u -> υ because followed by p/ρ consonant)
    expect(restoreGreekText('Kupiakn'), equals('Kυριακη'));

    // 4. 'Maiou' should be restored to 'Mαιου' (u -> υ because it is at the end of the word, i -> ι)
    expect(restoreGreekText('Maiou'), equals('Mαιου'));

    // 5. 'auto' should be restored to 'αυτο' (u -> υ because followed by t/τ consonant)
    expect(restoreGreekText('auto'), equals('αυτο'));
  });
}
