import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../global_state.dart';
import '../services/helpers.dart';
import '../services/date_extractor.dart';
import '../services/notification_service.dart';
import 'topic_details_screen.dart';

// -------------------------------------------------------------
// ΟΘΟΝΗ 2: ΣΥΛΛΟΓΗ (Gallery Screen / Collection Screen)
// -------------------------------------------------------------
class GalleryScreen extends StatefulWidget {
  final String? imagePathToSave;
  final String? ocrTextToSave;

  const GalleryScreen({
    super.key,
    this.imagePathToSave,
    this.ocrTextToSave,
  });

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final TextEditingController _topicController = TextEditingController();

  void _scheduleRemindersIfNeeded(String ocrText, String courseName) {
    if (!autoReminderEnabled.value) return;

    final dates = extractDatesFromText(ocrText);
    if (dates.isEmpty) return;

    for (final date in dates) {
      final dateStr = '${date.day}/${date.month}/${date.year}';
      final notifId = NotificationService.generateId(courseName, date);
      NotificationService.instance.scheduleReminder(
        id: notifId,
        courseName: courseName,
        deadlineDate: date,
        dateString: dateStr,
      );
    }

    // Show a feedback snackbar if dates were found
    if (mounted && dates.isNotEmpty) {
      final dateCount = dates.length;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('📅 $dateCount ${dateCount == 1 ? 'προθεσμία εντοπίστηκε' : 'προθεσμίες εντοπίστηκαν'}! Θα λάβεις υπενθύμιση.'),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.orange.shade700,
      ));
    }
  }

  void _showAddTopicDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Νέο Μάθημα"),
          content: TextField(
            controller: _topicController,
            decoration: const InputDecoration(
              hintText: "π.χ. Βάσεις Δεδομένων",
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyan, width: 2)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _topicController.clear();
                Navigator.pop(context);
              },
              child: const Text("Ακύρωση", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                if (_topicController.text.isNotEmpty) {
                  final courseName = _topicController.text;

                  if (widget.imagePathToSave != null) {
                    // Save Mode: create new folder AND store the snap immediately
                    setState(() {
                      globalUserTopics.add({
                        "course": courseName,
                        "images": <Map<String, String>>[
                          {"path": widget.imagePathToSave!, "text": widget.ocrTextToSave ?? ""}
                        ]
                      });
                    });
                    await saveData();
                    _scheduleRemindersIfNeeded(widget.ocrTextToSave ?? "", courseName);
                    _topicController.clear();

                    if (mounted) {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Close GalleryScreen (returns to CameraScreen)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Το μάθημα δημιουργήθηκε και το Snap αποθηκεύτηκε! ✅'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    // Normal Mode: just create the empty collection
                    setState(() => globalUserTopics.add({"course": courseName, "images": <Map<String, String>>[]}));
                    await saveData();
                    _topicController.clear();
                    if (mounted) Navigator.pop(context);
                  }
                }
              },
              child: const Text("Δημιουργία", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteTopic(int index, String courseName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Διαγραφή Μαθήματος;"),
          content: Text("Είστε σίγουροι ότι θέλετε να διαγράψετε το μάθημα '$courseName' και όλα τα Snaps του; Αυτή η ενέργεια δεν αναιρείται."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Ακύρωση", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                setState(() {
                  globalUserTopics.removeAt(index);
                });
                await saveData();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Το μάθημα \'$courseName\' διαγράφηκε! 🗑️'),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_off_outlined, size: 100, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              "Δεν έχεις προσθέσει κανένα μάθημα.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Φτιάξε φακέλους για να οργανώνεις τα snaps σου.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _showAddTopicDialog,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  "Δημιουργία Μαθήματος",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavePreviewCard(bool isDark) {
    if (widget.imagePathToSave == null) return const SizedBox.shrink();

    String previewText = (widget.ocrTextToSave ?? "").trim().isEmpty
        ? "Μπορείτε να σαρώσετε κείμενο με AI αφού αποθηκευτεί."
        : (widget.ocrTextToSave ?? "").replaceAll('\n', ' ');
    if (previewText.length > 80) previewText = "${previewText.substring(0, 80)}...";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.cyan.shade900.withOpacity(0.5), Colors.blueGrey.shade900.withOpacity(0.5)]
              : [Colors.cyan.shade50, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyan.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Thumbnail of the image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 60,
              height: 60,
              child: kIsWeb
                  ? Image.network(widget.imagePathToSave!, fit: BoxFit.cover)
                  : Image.file(File(widget.imagePathToSave!), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Αποθήκευση νέου Snap",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  previewText,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicsGrid(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.0,
        ),
        itemCount: globalUserTopics.length,
        itemBuilder: (context, index) {
          final topic = globalUserTopics[index];
          List<dynamic> images = topic['images'];
          final bool isSaveMode = widget.imagePathToSave != null;

          return Stack(
            children: [
              InkWell(
                onTap: isSaveMode
                    ? () async {
                        // Save Mode: Tap to save the snap immediately
                        setState(() {
                          List<Map<String, String>> updatedImages = List<Map<String, String>>.from(topic['images']);
                          updatedImages.add({
                            "path": widget.imagePathToSave!,
                            "text": widget.ocrTextToSave ?? "",
                          });
                          topic['images'] = updatedImages;
                        });
                        await saveData();
                        _scheduleRemindersIfNeeded(widget.ocrTextToSave ?? "", topic['course']);

                        if (mounted) {
                          Navigator.pop(context); // Close GalleryScreen (returns to CameraScreen)
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Αποθηκεύτηκε στο: ${topic['course']}! ✅'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    : () {
                        // Normal Mode: Navigate to TopicDetailsScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => TopicDetailsScreen(topic: topic)),
                        ).then((_) => setState(() {}));
                      },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSaveMode ? Colors.cyan.withOpacity(0.5) : Colors.cyan.withOpacity(0.3),
                      width: isSaveMode ? 1.5 : 1.0,
                    ),
                    boxShadow: const [BoxShadow(color: Color.fromARGB(15, 0, 0, 0), blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSaveMode ? Icons.save_alt_rounded : Icons.folder_shared_outlined,
                        size: 48,
                        color: Colors.cyan,
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          topic['course'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (isSaveMode)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.cyan.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "Αποθήκευση εδώ",
                            style: TextStyle(
                              color: Colors.cyan,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Text(
                          "${images.length} Snaps",
                          style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
                ),
              ),
              if (!isSaveMode) // Only show delete button if not in save selection mode
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: () => _confirmDeleteTopic(index, topic['course']),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade900.withOpacity(0.8) : Colors.grey.shade200.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isSaveMode = widget.imagePathToSave != null;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          isSaveMode ? 'Αποθήκευση Snap' : 'Οι Φάκελοί μου',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _buildSavePreviewCard(isDark),
          Expanded(
            child: globalUserTopics.isEmpty ? _buildEmptyState() : _buildTopicsGrid(isDark),
          ),
        ],
      ),
      floatingActionButton: globalUserTopics.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showAddTopicDialog,
              backgroundColor: Colors.cyan,
              child: Icon(
                isSaveMode ? Icons.create_new_folder_rounded : Icons.create_new_folder,
                color: Colors.white,
              ),
            )
          : null,
    );
  }
}
