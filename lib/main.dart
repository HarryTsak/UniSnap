import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, compute;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

// --- ΠΑΓΚΟΣΜΙΑ ΜΝΗΜΗ ΕΦΑΡΜΟΓΗΣ ---
// Τώρα η λίστα images αποθηκεύει Map (φωτογραφία ΚΑΙ κείμενο)
List<Map<String, dynamic>> globalUserTopics = [];
final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier(false);

// -------------------------------------------------------------
// ΛΕΙΤΟΥΡΓΙΕΣ ΔΙΚΑΙΩΜΑΤΩΝ & ΑΠΟΘΗΚΕΥΣΗΣ
// -------------------------------------------------------------
Future<void> requestPermissions() async {
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await [Permission.camera, Permission.storage, Permission.location].request();
  }
}

Future<void> loadData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    isDarkModeNotifier.value = prefs.getBool('isDarkMode') ?? false;
    
    final String? topicsString = prefs.getString('savedTopics');
    if (topicsString != null) {
      final List<dynamic> decodedData = jsonDecode(topicsString);
      
      globalUserTopics = decodedData.map((item) {
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
  } catch (e) {
    print("Σφάλμα φόρτωσης: $e");
  }
}

Future<void> saveData() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('savedTopics', jsonEncode(globalUserTopics));
}

Future<void> saveTheme(bool isDark) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isDarkMode', isDark);
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

/// Full OCR pipeline: preprocess + ML Kit recognition.
/// Returns the extracted text string.
Future<String> performOCR(String imagePath) async {
  if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
    return "Το OCR λειτουργεί μόνο στην Android/iOS συσκευή σου!";
  }

  // Preprocess image for better accuracy
  final processedPath = await preprocessImageForOCR(imagePath);

  // Run ML Kit text recognition
  final inputImage = InputImage.fromFilePath(processedPath);
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
  final extractedText = recognizedText.text;
  textRecognizer.close();

  // Cleanup temp file
  try {
    if (processedPath != imagePath) {
      await File(processedPath).delete();
    }
  } catch (_) {}

  return extractedText;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestPermissions();
  await loadData(); 
  runApp(const UniSnapApp());
}

class UniSnapApp extends StatelessWidget {
  const UniSnapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, child) {
        return MaterialApp(
          title: 'UniSnap',
          debugShowCheckedModeBanner: false,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            brightness: Brightness.light,
            fontFamily: 'Roboto',
            scaffoldBackgroundColor: const Color(0xFFE5E5E5),
            cardColor: Colors.white,
            appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Colors.black87),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            fontFamily: 'Roboto',
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E1E1E), foregroundColor: Colors.white),
          ),
          home: const CameraScreen(),
        );
      },
    );
  }
}

// -------------------------------------------------------------
// ΟΘΟΝΗ 1: ΚΑΜΕΡΑ & ΕΞΥΠΝΟ ΜΕΝΟΥ
// -------------------------------------------------------------
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _topicController = TextEditingController();
  bool _isProcessingOCR = false;

  Future<void> _openCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (photo != null) {
        if (mounted) {
          setState(() => _isProcessingOCR = true);

          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Ανάλυση εικόνας με AI... 🤖'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.cyan,
          ));

          // Use the new preprocessing + OCR pipeline
          String extractedText = await performOCR(photo.path);

          setState(() => _isProcessingOCR = false);
          _showSaveBottomSheet(photo.path, extractedText);
        }
      }
    } catch (e) {
      print("Πρόβλημα με την κάμερα: $e");
      setState(() => _isProcessingOCR = false);
    }
  }

  void _showSaveBottomSheet(String imagePath, String ocrText) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    String previewText = ocrText.trim().isEmpty ? "Δεν εντοπίστηκε κείμενο στην εικόνα." : ocrText.replaceAll('\n', ' ');
    if (previewText.length > 100) previewText = "${previewText.substring(0, 100)}...";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
              child: Column(
                children: [
                  Container(margin: const EdgeInsets.only(top: 12, bottom: 8), width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade500, borderRadius: BorderRadius.circular(10))),
                  Padding(padding: const EdgeInsets.all(16.0), child: Text("Αποθήκευση Snap στο:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87))),
                  
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.cyan.withOpacity(0.5))),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.document_scanner_outlined, color: Colors.cyan), const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Έξυπνη Αναγνώριση Κειμένου:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.cyan)), const SizedBox(height: 4), Text(previewText, style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: isDark ? Colors.white70 : Colors.black87))])),
                      ],
                    ),
                  ),

                  ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.cyan, child: Icon(Icons.add, color: Colors.white)),
                    title: const Text("Δημιουργία Νέου Μαθήματος", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan)),
                    onTap: () { Navigator.pop(context); _showAddTopicDialog(imagePath, ocrText); },
                  ),
                  const Divider(),
                  Expanded(
                    child: globalUserTopics.isEmpty
                        ? const Center(child: Text("Δεν υπάρχουν φάκελοι. Φτιάξε έναν!", style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: globalUserTopics.length,
                            itemBuilder: (context, index) {
                              final topic = globalUserTopics[index];
                              return ListTile(
                                leading: const Icon(Icons.folder, color: Colors.cyan, size: 32),
                                title: Text(topic['course'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text("${topic['images'].length} Snaps"),
                                trailing: const Icon(Icons.save_alt, color: Colors.grey),
                                onTap: () async {
                                  setState(() {
                                    // ΤΩΡΑ ΑΠΟΘΗΚΕΥΕΙ ΚΑΙ ΤΑ ΔΥΟ!
                                    List<Map<String, String>> images = List<Map<String, String>>.from(topic['images']);
                                    images.add({"path": imagePath, "text": ocrText}); 
                                    topic['images'] = images;
                                  });
                                  await saveData(); 
                                  if (mounted) Navigator.pop(context);
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Αποθηκεύτηκε στο: ${topic['course']}!'), backgroundColor: Colors.green));
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _showAddTopicDialog(String imagePath, String ocrText) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Νέο Μάθημα"),
          content: TextField(controller: _topicController, decoration: const InputDecoration(hintText: "π.χ. Δίκτυα", focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyan, width: 2)), border: OutlineInputBorder())),
          actions: [
            TextButton(onPressed: () { _topicController.clear(); Navigator.pop(context); }, child: const Text("Ακύρωση", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
              onPressed: () async {
                if (_topicController.text.isNotEmpty) {
                  setState(() {
                    globalUserTopics.add({
                      "course": _topicController.text, 
                      "images": <Map<String, String>>[ {"path": imagePath, "text": ocrText} ]
                    });
                  });
                  await saveData(); 
                  _topicController.clear(); 
                  if (mounted) Navigator.pop(context);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Το μάθημα δημιουργήθηκε και το Snap αποθηκεύτηκε!'), backgroundColor: Colors.green));
                }
              },
              child: const Text("Δημιουργία & Αποθήκευση", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF222222) : const Color(0xFF9E9797), 
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: InkWell(
                onTap: _isProcessingOCR ? null : _openCamera, 
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.all(40), 
                  child: _isProcessingOCR 
                      ? const CircularProgressIndicator(color: Colors.cyan) 
                      : Icon(Icons.camera_alt_outlined, size: 160, color: isDark ? Colors.white70 : const Color(0xFF2D2D2D))
                ),
              ),
            ),
            Positioned(
              top: 30, left: 0, 
              child: Container(
                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: const BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20)), border: Border.all(color: Colors.cyan, width: 2.0), boxShadow: const [BoxShadow(color: Color.fromARGB(25, 8, 123, 211), blurRadius: 15, offset: Offset(0, 5))]),
                child: PopupMenuButton<String>(
                  icon: Icon(Icons.menu_open, color: isDark ? Colors.white : Colors.black87), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), offset: const Offset(60, 0), 
                  onSelected: (value) {
                    if (value == 'gallery') Navigator.push(context, MaterialPageRoute(builder: (context) => const GalleryScreen()));
                    else if (value == 'settings') Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem(value: 'gallery', child: Row(children: [const Icon(Icons.photo_library_outlined, color: Colors.grey), const SizedBox(width: 12), Text("Η Συλλογή μου", style: TextStyle(color: isDark ? Colors.white : Colors.black87))])),
                    PopupMenuItem(value: 'settings', child: Row(children: [const Icon(Icons.settings_outlined, color: Colors.grey), const SizedBox(width: 12), Text("Ρυθμίσεις", style: TextStyle(color: isDark ? Colors.white : Colors.black87))])),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// ΟΘΟΝΗ 2: ΣΥΛΛΟΓΗ (Gallery Screen)
// -------------------------------------------------------------
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});
  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final TextEditingController _topicController = TextEditingController();

  void _showAddTopicDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Νέο Μάθημα"),
          content: TextField(controller: _topicController, decoration: const InputDecoration(hintText: "π.χ. Βάσεις Δεδομένων", border: OutlineInputBorder(), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyan, width: 2)))),
          actions: [
            TextButton(onPressed: () { _topicController.clear(); Navigator.pop(context); }, child: const Text("Ακύρωση", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: () async {
                if (_topicController.text.isNotEmpty) {
                  setState(() => globalUserTopics.add({"course": _topicController.text, "images": <Map<String, String>>[]}));
                  await saveData(); 
                  _topicController.clear(); 
                  if (mounted) Navigator.pop(context); 
                }
              },
              child: const Text("Δημιουργία", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(elevation: 0, title: const Text('Οι Φάκελοί μου', style: TextStyle(fontWeight: FontWeight.bold))),
      body: globalUserTopics.isEmpty ? _buildEmptyState() : _buildTopicsGrid(isDark),
      floatingActionButton: globalUserTopics.isNotEmpty ? FloatingActionButton(onPressed: _showAddTopicDialog, backgroundColor: Colors.cyan, child: const Icon(Icons.create_new_folder, color: Colors.white)) : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_off_outlined, size: 100, color: Colors.grey), const SizedBox(height: 20),
            const Text("Δεν έχεις προσθέσει κανένα μάθημα.", textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 10),
            const Text("Φτιάξε φακέλους για να οργανώνεις τα snaps σου.", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)), const SizedBox(height: 40),
            SizedBox(width: double.infinity, height: 56, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), onPressed: _showAddTopicDialog, icon: const Icon(Icons.add, color: Colors.white), label: const Text("Δημιουργία Μαθήματος", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)))),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicsGrid(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.0),
        itemCount: globalUserTopics.length,
        itemBuilder: (context, index) {
          final topic = globalUserTopics[index];
          List<dynamic> images = topic['images']; 
          return InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => TopicDetailsScreen(topic: topic))).then((_) => setState(() {})); 
            },
            child: Container(
              decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.cyan.withOpacity(0.3), width: 1), boxShadow: const [BoxShadow(color: Color.fromARGB(15, 0, 0, 0), blurRadius: 10, offset: Offset(0, 4))]),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_shared_outlined, size: 48, color: Colors.cyan), const SizedBox(height: 12),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Text(topic['course'], textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis)), const SizedBox(height: 4),
                  Text("${images.length} Snaps", style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// -------------------------------------------------------------
// ΟΘΟΝΗ 3: ΡΥΘΜΙΣΕΙΣ (Settings Screen)
// -------------------------------------------------------------
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool autoReminder = true; bool autoDelete = false; String selectedLanguage = 'Αυτόματο';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 0, title: const Text('Ρυθμίσεις', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(padding: EdgeInsets.only(left: 8, bottom: 8, top: 8), child: Text("ΕΞΥΠΝΗ ΑΝΑΓΝΩΡΙΣΗ", style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold))),
          Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Column(children: [ListTile(leading: const Icon(Icons.language, color: Colors.blueGrey), title: const Text("Γλώσσα Κειμένου"), subtitle: Text(selectedLanguage), trailing: const Icon(Icons.arrow_forward_ios, size: 16), onTap: () { setState(() { selectedLanguage = selectedLanguage == 'Αυτόματο' ? 'Ελληνικά' : 'Αυτόματο'; }); }), const Divider(height: 1), SwitchListTile(activeColor: Colors.cyan, secondary: const Icon(Icons.event_available, color: Colors.blueGrey), title: const Text("Αυτόματη Υπενθύμιση"), subtitle: const Text("1 ημέρα πριν την προθεσμία"), value: autoReminder, onChanged: (value) => setState(() => autoReminder = value))])),
          const SizedBox(height: 20),
          const Padding(padding: EdgeInsets.only(left: 8, bottom: 8), child: Text("ΣΥΣΤΗΜΑ", style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold))),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
            child: Column(
              children: [
                SwitchListTile(activeColor: Colors.cyan, secondary: const Icon(Icons.dark_mode_outlined, color: Colors.blueGrey), title: const Text("Σκοτεινή Εμφάνιση"), value: isDarkModeNotifier.value, onChanged: (value) { setState(() {}); isDarkModeNotifier.value = value; saveTheme(value); }), 
                const Divider(height: 1), 
                SwitchListTile(activeColor: Colors.redAccent, secondary: const Icon(Icons.delete_sweep, color: Colors.redAccent), title: const Text("Καθαρισμός Χώρου"), subtitle: const Text("Διαγραφή Snaps > 6 μήνες"), value: autoDelete, onChanged: (value) => setState(() => autoDelete = value))
              ]
            )
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// ΟΘΟΝΗ 4: ΠΕΡΙΕΧΟΜΕΝΑ ΦΑΚΕΛΟΥ (Topic Details Screen)
// -------------------------------------------------------------
class TopicDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> topic;
  const TopicDetailsScreen({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    List<dynamic> images = topic['images'];
    return Scaffold(
      appBar: AppBar(elevation: 0, title: Text(topic['course'], style: const TextStyle(fontWeight: FontWeight.bold))),
      body: images.isEmpty
          ? const Center(child: Text("Ο φάκελος είναι άδειος!\nΒγάλε ένα Snap για να το δεις εδώ.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.75),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  // Διαβάζουμε το αντικείμενο που έχει path και text
                  final imageData = images[index]; 
                  final imagePath = imageData['path'];
                  final ocrText = imageData['text'];

                  return InkWell(
                    onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => FullScreenImageScreen(imagePath: imagePath, ocrText: ocrText))); },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Hero(
                        tag: imagePath, 
                        child: Container(
                          color: Colors.grey.shade300,
                          child: kIsWeb ? Image.network(imagePath, fit: BoxFit.cover) : Image.file(File(imagePath), fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// -------------------------------------------------------------
// ΟΘΟΝΗ 5: ΠΛΗΡΗΣ ΟΘΟΝΗ ΚΑΙ ΚΕΙΜΕΝΟ (Full Screen & OCR)
// -------------------------------------------------------------
class FullScreenImageScreen extends StatefulWidget {
  final String imagePath;
  final String ocrText;
  
  const FullScreenImageScreen({super.key, required this.imagePath, required this.ocrText});

  @override
  State<FullScreenImageScreen> createState() => _FullScreenImageScreenState();
}

class _FullScreenImageScreenState extends State<FullScreenImageScreen> {
  late String _currentOcrText;
  bool _isReScanning = false;

  @override
  void initState() {
    super.initState();
    _currentOcrText = widget.ocrText;
  }

  Future<void> _reRunOCR() async {
    setState(() => _isReScanning = true);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Επανάληψη ανάλυσης με AI... 🔄'),
      duration: Duration(seconds: 2),
      backgroundColor: Colors.cyan,
    ));

    try {
      final newText = await performOCR(widget.imagePath);

      // Update in global memory
      for (var topic in globalUserTopics) {
        List<dynamic> images = topic['images'];
        for (var img in images) {
          if (img['path'] == widget.imagePath) {
            img['text'] = newText;
            break;
          }
        }
      }
      await saveData(); // Persist the updated text

      if (mounted) {
        setState(() {
          _currentOcrText = newText;
          _isReScanning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Το κείμενο ενημερώθηκε επιτυχώς! ✅'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      print("Σφάλμα re-OCR: $e");
      if (mounted) {
        setState(() => _isReScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Αποτυχία ανάλυσης. Δοκίμασε ξανά.'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, 
      appBar: AppBar(backgroundColor: Colors.black, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      floatingActionButton: FloatingActionButton(
        onPressed: _isReScanning ? null : _reRunOCR,
        backgroundColor: _isReScanning ? Colors.grey : Colors.cyan,
        child: _isReScanning
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : const Icon(Icons.refresh, color: Colors.white),
      ),
      body: Column(
        children: [
          // Το πάνω μέρος με τη φωτογραφία (πιάνει το 70% της οθόνης)
          Expanded(
            flex: 7,
            child: InteractiveViewer(
              panEnabled: true, minScale: 0.5, maxScale: 4.0,
              child: Hero(
                tag: widget.imagePath, 
                child: kIsWeb ? Image.network(widget.imagePath, fit: BoxFit.contain) : Image.file(File(widget.imagePath), fit: BoxFit.contain),
              ),
            ),
          ),
          // Το κάτω μέρος με το έξυπνο κείμενο (πιάνει το 30%)
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E), // Σκούρο γκρι κουτί
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.copy_all, color: Colors.cyan),
                        const SizedBox(width: 8),
                        const Text("Αναγνωρισμένο Κείμενο", style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold, fontSize: 16)),
                        const Spacer(),
                        Text("Copy", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // ΤΟ ΜΑΓΙΚΟ WIDGET ΠΟΥ ΣΟΥ ΕΠΙΤΡΕΠΕΙ ΝΑ ΚΑΝΕΙΣ ΑΝΤΙΓΡΑΦΗ (COPY)
                    SelectableText(
                      _currentOcrText.trim().isNotEmpty ? _currentOcrText : "Δεν εντοπίστηκε κείμενο στην εικόνα.",
                      style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}