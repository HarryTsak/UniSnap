import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/helpers.dart';

// -------------------------------------------------------------
// ΟΘΟΝΗ: ΠΡΟΒΟΛΗ ΣΗΜΕΙΩΣΗΣ ΣΑΝ NOTEPAD (Note View Screen)
// -------------------------------------------------------------
class NoteViewScreen extends StatefulWidget {
  final Map<String, String> note;
  final int noteIndex;
  final Map<String, dynamic> folder;

  const NoteViewScreen({
    super.key,
    required this.note,
    required this.noteIndex,
    required this.folder,
  });

  @override
  State<NoteViewScreen> createState() => _NoteViewScreenState();
}

class _NoteViewScreenState extends State<NoteViewScreen> {
  late String _currentContent;
  late TextEditingController _textController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _currentContent = widget.note['content'] ?? "";
    _textController = TextEditingController(text: _currentContent);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _copyToClipboard() async {
    if (_currentContent.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Δεν υπάρχει περιεχόμενο για αντιγραφή! ❌'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    await Clipboard.setData(ClipboardData(text: _currentContent));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Το κείμενο αντιγράφηκε στο clipboard! 📋'),
        backgroundColor: Colors.cyan,
      ));
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Διαγραφή Σημείωσης;"),
          content: const Text("Είστε σίγουροι ότι θέλετε να διαγράψετε αυτή τη σημείωση; Αυτή η ενέργεια δεν αναιρείται."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Ακύρωση", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                List<Map<String, String>> notesList = List<Map<String, String>>.from(widget.folder['notes']);
                notesList.removeAt(widget.noteIndex);
                widget.folder['notes'] = notesList;
                await saveData();
                if (mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Pop NoteViewScreen back to list
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Η σημείωση διαγράφηκε επιτυχώς.'),
                      backgroundColor: Colors.grey,
                    ),
                  );
                }
              },
              child: const Text("Διαγραφή", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveEdits() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Η σημείωση δεν μπορεί να είναι άδεια! ❌'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    setState(() {
      _currentContent = _textController.text;
      _isEditing = false;
      
      List<Map<String, String>> notesList = List<Map<String, String>>.from(widget.folder['notes']);
      notesList[widget.noteIndex] = {
        "content": _currentContent,
        "createdAt": widget.note['createdAt'] ?? DateTime.now().toIso8601String(),
      };
      widget.folder['notes'] = notesList;
    });

    await saveData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Η σημείωση αποθηκεύτηκε! ✅'),
        backgroundColor: Colors.green,
      ));
    }
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return "${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return "";
    }
  }

  Widget _buildNotepadContainer(bool isDark) {
    final double noteTextFontSize = 16.0;
    
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFDF0), // Warm notepad color in light theme
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.cyan.withOpacity(0.2) : Colors.amber.shade200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.amber.shade100.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timestamp Header
            Row(
              children: [
                Icon(
                  Icons.event_note,
                  color: isDark ? Colors.cyan : Colors.amber.shade800,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(widget.note['createdAt'] ?? ""),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.amber.shade900,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1.2),
            // Scrollable Note Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: _isEditing
                    ? TextField(
                        controller: _textController,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        autofocus: true,
                        style: TextStyle(
                          fontSize: noteTextFontSize,
                          height: 1.6,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Γράψτε εδώ...",
                        ),
                      )
                    : SelectableText(
                        _currentContent,
                        style: TextStyle(
                          fontSize: noteTextFontSize,
                          height: 1.6,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          _isEditing ? "Επεξεργασία" : "Προβολή Σημείωσης",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: _isEditing
            ? [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.redAccent),
                  onPressed: () {
                    setState(() {
                      _textController.text = _currentContent;
                      _isEditing = false;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: _saveEdits,
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.copy_rounded),
                  tooltip: "Αντιγραφή",
                  onPressed: _copyToClipboard,
                ),
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded),
                  tooltip: "Επεξεργασία",
                  onPressed: () => setState(() => _isEditing = true),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  tooltip: "Διαγραφή",
                  onPressed: _confirmDelete,
                ),
              ],
      ),
      body: Column(
        children: [
          _buildNotepadContainer(isDark),
        ],
      ),
    );
  }
}
