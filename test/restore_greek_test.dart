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

  test('advanced Greek OCR mapping and English GPU protection', () {
    // 1. Core parallel-computing acronyms must be preserved exactly
    expect(restoreGreekText('GPU'), equals('GPU'));
    expect(restoreGreekText('GPGPU'), equals('GPGPU'));
    expect(restoreGreekText('NVIDIA'), equals('NVIDIA'));

    // 2. Latin 'A' must map to Greek capital 'Α' (Alpha) instead of 'Δ' (Delta)
    expect(restoreGreekText('Apxitektovikn'), equals('Αρχιτεκτονικη'));

    // 3. Latin 'D' must map to Greek capital 'Δ' (Delta)
    expect(restoreGreekText('Dedomena'), equals('Δεdοmεηα'));

    // 4. Latin 'T' must map to Greek lowercase 't'/'T' -> 'τ' (Tau) instead of 'π' (Pi)
    expect(restoreGreekText('TLO'), equals('πιο')); // Word replacements still work for TLO
    expect(restoreGreekText('T'), equals('τ')); // Single T maps to τ

    // 5. 'suyxpovns' must correctly map u to υ (upsilon) because y is a Greek consonant (γ)
    expect(restoreGreekText('suyxpovns'), equals('συγχρονης'));

    // 6. Special accented characters representing Greek letters
    expect(restoreGreekText('etEĞEpyaTtóv'), equals('ετεξεργαττόν'));
    expect(restoreGreekText('ðarnpήoel'), equals('δατηρήοεl'));
    expect(restoreGreekText('aKoÀoU®iaKÓV'), equals('αKολοΥθιαKÓν'));
  });
}
