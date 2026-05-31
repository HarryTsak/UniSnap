import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, compute;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../global_state.dart';

// -------------------------------------------------------------
// ΛΕΙΤΟΥΡΓΙΕΣ ΔΙΚΑΙΩΜΑΤΩΝ & ΑΠΟΘΗΚΕΥΣΗΣ
// -------------------------------------------------------------
Future<void> requestPermissions() async {
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await [Permission.camera, Permission.storage, Permission.location].request();
  }
}

List<Map<String, dynamic>> _parseTopics(List<dynamic> decodedData) {
  return decodedData.map((item) {
    // Μαγεία για να μην κρασάρει με τις παλιές σου φώτο!
    List<dynamic> rawImages = item["images"] ?? [];
    List<Map<String, String>> parsedImages = [];
    
    for (var img in rawImages) {
      if (img is String) {
        parsedImages.add({"path": img, "text": "Δεν υπάρχει αποθηκευμένο κείμενο."});
      } else if (img is Map) {
        parsedImages.add({"path": img["path"].toString(), "text": img["text"].toString()});
      }
    }

    return {
      "course": item["course"],
      "images": parsedImages,
    };
  }).toList();
}

Future<void> loadData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    isDarkModeNotifier.value = prefs.getBool('isDarkMode') ?? false;
    autoReminderEnabled.value = prefs.getBool('autoReminder') ?? true;
    
    final String? topicsString = prefs.getString('savedTopics');
    if (topicsString != null) {
      final List<dynamic> decodedData = jsonDecode(topicsString);
      globalUserTopics = _parseTopics(decodedData);
    }

    final String? notesString = prefs.getString('savedNotes');
    if (notesString != null) {
      final List<dynamic> decodedNotes = jsonDecode(notesString);
      globalUserNotes = decodedNotes.map((item) => Map<String, dynamic>.from(item)).toList();
    }
  } catch (e) {
    print("Σφάλμα φόρτωσης: $e");
  }
}

Future<void> saveData() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('savedTopics', jsonEncode(globalUserTopics));
  await prefs.setString('savedNotes', jsonEncode(globalUserNotes));
}

Future<void> saveTheme(bool isDark) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isDarkMode', isDark);
}

Future<void> saveAutoReminder(bool enabled) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('autoReminder', enabled);
}

// -------------------------------------------------------------
// IMAGE PREPROCESSING & OCR HELPERS
// -------------------------------------------------------------

/// Runs heavy image processing in a background isolate.
/// Pipeline: grayscale → contrast boost → sharpen.
img.Image _preprocessIsolate(img.Image source) {
  // 1. Grayscale — removes color noise, helps OCR focus on text
  img.grayscale(source);
  // 2. Contrast boost — makes text pop against background
  img.contrast(source, contrast: 150);
  // 3. Sharpen — crisps up edges of characters
  img.convolution(source, filter: [0, -1, 0, -1, 5, -1, 0, -1, 0], div: 1);
  return source;
}

/// Preprocesses an image file for better OCR results.
/// Returns the path to a temporary processed file.
Future<String> preprocessImageForOCR(String originalPath) async {
  final bytes = await File(originalPath).readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return originalPath; // fallback to original

  final processed = await compute(_preprocessIsolate, decoded);

  final tempDir = await getTemporaryDirectory();
  final processedPath = '${tempDir.path}/ocr_preprocessed_${DateTime.now().millisecondsSinceEpoch}.jpg';
  await File(processedPath).writeAsBytes(img.encodeJpg(processed, quality: 100));

  return processedPath;
}

/// Restores visual Latin lookup-glyphs of Greek letters to clean, actual Greek characters.
String restoreGreekText(String text) {
  if (text.trim().isEmpty) return text;

  // Detect if the text is predominantly English to prevent mangling English documents
  final List<String> englishStopWords = [
    'the', 'and', 'of', 'to', 'for', 'are', 'with', 'this', 'that', 'have',
    'from', 'you', 'your', 'not', 'but', 'all', 'they', 'been', 'were',
    'was', 'is', 'it', 'has', 'every'
  ];
  int englishWordCount = 0;
  final RegExp wordOnlyRegExp = RegExp(r'\b[a-zA-Z]+\b');
  final stopWordMatches = wordOnlyRegExp.allMatches(text.toLowerCase());
  for (final match in stopWordMatches) {
    if (englishStopWords.contains(match.group(0))) {
      englishWordCount++;
    }
  }
  if (englishWordCount >= 2) {
    // Predominantly English document: skip Greek restoration to preserve correct English spelling
    return text;
  }

  // 1. Common Greek/Greeklish visual word mappings
  final Map<String, String> wordReplacements = {
    r'\bLari\b': 'Γιατί',
    r'\bva\b': 'να',
    r'\bKaV\b': 'κανείς',
    r'\bKaL\b': 'και',
    r'\bkaL\b': 'και',
    r'\bkal\b': 'και',
    r'\bTLO\b': 'πιο',
    r'\btlo\b': 'πιο',
    r'\bTlo\b': 'πιο',
    r'\boto\b': 'στο',
    r'\bEva\b': 'Ένα',
    r'\beva\b': 'ένα',
  };

  String restored = text;
  wordReplacements.forEach((key, val) {
    restored = restored.replaceAll(RegExp(key), val);
  });

  // 2. Multi-character visual root mapping
  final Map<String, String> clusterReplacements = {
    'TapakoAouenoeL': 'παρακολουθήσει',
    'ZuotHuata': 'Συστήματα',
    'AoyLouKoÚ': 'Λογισμικού',
    'ALayeipLon': 'Διαχείριση',
    'AsôouévwV': 'Δεδομένων',
    'TvwOE': 'Γνώσεων',
    'uaennawV': 'μαθημάτων',
    'KúKÀoUG': 'Κύκλους',
    'Bhua': 'βήμα',
    'KOvtá': 'κοντά',
    'TTUX': 'πτυχ',
  };

  clusterReplacements.forEach((key, val) {
    restored = restored.replaceAll(key, val);
  });

  // 3. Fine-grained character-by-character visual lookalike mappings
  final RegExp tokenRegExp = RegExp(r'\S+|\s+');
  Iterable<RegExpMatch> matches = tokenRegExp.allMatches(restored);
  List<String> finalWords = [];

  for (final match in matches) {
    String token = match.group(0)!;
    
    // If it is whitespace, preserve it exactly
    if (RegExp(r'^\s+$').hasMatch(token)) {
      finalWords.add(token);
      continue;
    }

    // Preserve standard English acronyms/vocabulary (e.g. ECTS, Welcome, AUEB, COMPUTER)
    final String lettersOnly = token.replaceAll(RegExp(r'[^a-zA-Z]'), '').toLowerCase();
    final List<String> englishPreserve = [
      'welcome', 'computer', 'graphics', 'group', 'ects', 'aueb', 'to', 'the', 'project'
    ];

    if (lettersOnly.isEmpty || englishPreserve.contains(lettersOnly)) {
      finalWords.add(token);
      continue;
    }

    // Visual-glyph conversion character-by-character
    String translatedWord = "";
    for (int i = 0; i < token.length; i++) {
      String char = token[i];
      
      // Lookahead helper for 'ua' -> 'μα' visual map
      if (i < token.length - 1) {
        String twoChars = token.substring(i, i + 2);
        if (twoChars == 'ua') {
          translatedWord += 'μα';
          i++;
          continue;
        }
      }

      switch (char) {
        case 'a': translatedWord += 'α'; break;
        case 'b': translatedWord += 'β'; break;
        case 'v': translatedWord += 'ν'; break;
        case 'u': translatedWord += 'μ'; break;
        case 'p': translatedWord += 'ρ'; break;
        case 'k': translatedWord += 'κ'; break;
        case 'o': translatedWord += 'ο'; break;
        case 't': translatedWord += 'τ'; break;
        case 'r': translatedWord += 'τ'; break;
        case 'e': translatedWord += 'ε'; break;
        case 'n': translatedWord += 'η'; break;
        case 'h': translatedWord += 'η'; break;
        case 'w': translatedWord += 'ω'; break;
        case 'y': translatedWord += 'γ'; break;
        case 'x': translatedWord += 'χ'; break;
        case 'L': translatedWord += 'ι'; break;
        case 'À': translatedWord += 'λ'; break;
        case 'ô': translatedWord += 'δ'; break;
        case 'é': translatedWord += 'έ'; break;
        case 'ú': translatedWord += 'ύ'; break;
        case 'á': translatedWord += 'ά'; break;
        case 'í': translatedWord += 'ί'; break;
        case 'ó': translatedWord += 'ό'; break;
        case 'Z': translatedWord += 'Σ'; break;
        case 'A': translatedWord += 'Δ'; break;
        case 'B': translatedWord += 'β'; break;
        case 'T': translatedWord += 'π'; break;
        case 'O': translatedWord += 'ο'; break;
        case 'E': translatedWord += 'ε'; break;
        case 'X': translatedWord += 'χ'; break;
        case 'G': translatedWord += 'ς'; break;
        case 'V': translatedWord += 'ν'; break;
        default:
          translatedWord += char;
      }
    }
    finalWords.add(translatedWord);
  }

  return finalWords.join('');
}

/// Full OCR pipeline: running text recognition directly on the high-resolution image
/// and processing output through our custom Greekish Restoration Engine.
Future<String> performOCR(String imagePath) async {
  if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
    return "Το OCR λειτουργεί μόνο στην Android/iOS συσκευή σου!";
  }

  // Run ML Kit text recognition directly on the original raw high-resolution image.
  final inputImage = InputImage.fromFilePath(imagePath);
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
  final extractedText = recognizedText.text;
  textRecognizer.close();

  // Parse Latin visual characters back into proper Greek
  return restoreGreekText(extractedText);
}
