import 'package:flutter/material.dart';
import 'note_view_screen.dart';

// -------------------------------------------------------------
// ΟΘΟΝΗ: ΠΕΡΙΕΧΟΜΕΝΑ ΚΑΤΗΓΟΡΙΑΣ ΣΗΜΕΙΩΣΕΩΝ (Note Details Screen)
// -------------------------------------------------------------
class NoteDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> folder;
  const NoteDetailsScreen({super.key, required this.folder});

  @override
  State<NoteDetailsScreen> createState() => _NoteDetailsScreenState();
}

class _NoteDetailsScreenState extends State<NoteDetailsScreen> {

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notes_rounded, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Η κατηγορία είναι άδεια!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "Αντιγράψτε κείμενο από οποιοδήποτε Snap και αποθηκεύστε το εδώ.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return "${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> rawNotes = widget.folder['notes'] ?? [];
    List<Map<String, String>> notes = List<Map<String, String>>.from(
      rawNotes.map((item) => Map<String, String>.from(item))
    );

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(widget.folder['category'], style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: notes.isEmpty
          ? _buildEmptyState()
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  final content = note['content'] ?? "";
                  final dateStr = _formatDate(note['createdAt'] ?? "");

                  String previewContent = content.replaceAll('\n', ' ');
                  if (previewContent.length > 120) {
                    previewContent = "${previewContent.substring(0, 120)}...";
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.cyan.withOpacity(0.2), width: 1),
                      boxShadow: const [BoxShadow(color: Color.fromARGB(10, 0, 0, 0), blurRadius: 10, offset: Offset(0, 2))],
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NoteViewScreen(
                              note: note,
                              noteIndex: index,
                              folder: widget.folder,
                            ),
                          ),
                        ).then((_) => setState(() {}));
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.description_outlined, color: Colors.cyan, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                const Spacer(),
                                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              previewContent,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
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
