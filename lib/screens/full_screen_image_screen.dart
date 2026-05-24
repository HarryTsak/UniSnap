import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../global_state.dart';
import '../services/helpers.dart';

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

  Future<void> _copyToClipboard() async {
    final cleanText = _currentOcrText.trim();
    if (cleanText.isEmpty || 
        cleanText == "Δεν εντοπίστηκε κείμενο στην εικόνα." || 
        cleanText == "Μπορείτε να σαρώσετε κείμενο με AI αφού αποθηκευτεί." ||
        cleanText == "Το OCR λειτουργεί μόνο στην Android/iOS συσκευή σου!") {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Δεν υπάρχει κείμενο για αντιγραφή! ❌'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    await Clipboard.setData(ClipboardData(text: _currentOcrText));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Το κείμενο αντιγράφηκε στο clipboard! 📋'),
        backgroundColor: Colors.cyan,
        duration: Duration(seconds: 2),
      ));
      
      // Prompt the user to save the copied text as a Note Category
      _showSaveNotePrompt();
    }
  }

  void _showSaveNotePrompt() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            bool isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Drag Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade500,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "Αποθήκευση ως Σημείωση στο:",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  // Create New Category Tile
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.cyan,
                      child: Icon(Icons.add, color: Colors.white),
                    ),
                    title: const Text(
                      "Δημιουργία Νέας Κατηγορίας",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showAddNoteCategoryDialog();
                    },
                  ),
                  const Divider(),
                  // Categories list
                  Expanded(
                    child: globalUserNotes.isEmpty
                        ? const Center(
                            child: Text(
                              "Δεν υπάρχουν κατηγορίες σημειώσεων. Φτιάξε μία!",
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: globalUserNotes.length,
                            itemBuilder: (context, index) {
                              final folder = globalUserNotes[index];
                              List<dynamic> notesList = folder['notes'] ?? [];
                              return ListTile(
                                leading: const Icon(Icons.note_add_rounded, color: Colors.cyan, size: 32),
                                title: Text(folder['category'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text("${notesList.length} Σημειώσεις"),
                                trailing: const Icon(Icons.save_alt_rounded, color: Colors.grey),
                                onTap: () async {
                                  setSheetState(() {
                                    List<Map<String, String>> updatedNotes = List<Map<String, String>>.from(
                                      notesList.map((item) => Map<String, String>.from(item))
                                    );
                                    updatedNotes.add({
                                      "content": _currentOcrText,
                                      "createdAt": DateTime.now().toIso8601String(),
                                    });
                                    folder['notes'] = updatedNotes;
                                  });
                                  await saveData();
                                  if (mounted) {
                                    Navigator.pop(context); // Close bottom sheet
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Αποθηκεύτηκε στην κατηγορία: ${folder['category']}! 📝'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddNoteCategoryDialog() {
    final TextEditingController noteCategoryController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Νέα Κατηγορία Σημειώσεων"),
          content: TextField(
            controller: noteCategoryController,
            decoration: const InputDecoration(
              hintText: "π.χ. Σημειώσεις Φυσικής",
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyan, width: 2)),
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                noteCategoryController.clear();
                Navigator.pop(context);
              },
              child: const Text("Ακύρωση", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
              onPressed: () async {
                if (noteCategoryController.text.isNotEmpty) {
                  final catName = noteCategoryController.text;
                  setState(() {
                    globalUserNotes.add({
                      "category": catName,
                      "notes": <Map<String, String>>[
                        {
                          "content": _currentOcrText,
                          "createdAt": DateTime.now().toIso8601String(),
                        }
                      ]
                    });
                  });
                  await saveData();
                  noteCategoryController.clear();
                  if (mounted) {
                    Navigator.pop(context); // Close dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Η κατηγορία δημιουργήθηκε και η σημείωση αποθηκεύτηκε! 📝'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              child: const Text("Δημιουργία & Αποθήκευση", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImageContainer() {
    return InteractiveViewer(
      panEnabled: true,
      minScale: 0.5,
      maxScale: 4.0,
      child: Hero(
        tag: widget.imagePath,
        child: kIsWeb
            ? Image.network(widget.imagePath, fit: BoxFit.contain)
            : Image.file(File(widget.imagePath), fit: BoxFit.contain),
      ),
    );
  }

  Widget _buildOcrTextPanel() {
    return Container(
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
            InkWell(
              onTap: _copyToClipboard,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.copy_all, color: Colors.cyan),
                    const SizedBox(width: 8),
                    const Text(
                      "Αναγνωρισμένο Κείμενο",
                      style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "Copy",
                        style: TextStyle(color: Colors.cyan, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              _currentOcrText.trim().isNotEmpty ? _currentOcrText : "Δεν εντοπίστηκε κείμενο στην εικόνα.",
              style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, 
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
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
            child: _buildImageContainer(),
          ),
          // Το κάτω μέρος με το έξυπνο κείμενο (πιάνει το 30%)
          Expanded(
            flex: 3,
            child: _buildOcrTextPanel(),
          ),
        ],
      ),
    );
  }
}
