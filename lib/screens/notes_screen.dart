import 'package:flutter/material.dart';
import '../global_state.dart';
import '../services/helpers.dart';
import 'note_details_screen.dart';

// -------------------------------------------------------------
// ΟΘΟΝΗ: ΚΑΤΗΓΟΡΙΕΣ ΣΗΜΕΙΩΣΕΩΝ (Notes Screen)
// -------------------------------------------------------------
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _categoryController = TextEditingController();

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Νέα Κατηγορία Σημειώσεων"),
          content: TextField(
            controller: _categoryController,
            decoration: const InputDecoration(
              hintText: "π.χ. Σημειώσεις Μαθηματικών",
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyan, width: 2)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _categoryController.clear();
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
                if (_categoryController.text.isNotEmpty) {
                  setState(() {
                    globalUserNotes.add({
                      "category": _categoryController.text,
                      "notes": <Map<String, String>>[]
                    });
                  });
                  await saveData(); 
                  _categoryController.clear(); 
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

  void _confirmDeleteCategory(int index, String categoryName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Διαγραφή Κατηγορίας;"),
          content: Text("Είστε σίγουροι ότι θέλετε να διαγράψετε την κατηγορία '$categoryName' και όλες τις σημειώσεις της; Αυτή η ενέργεια δεν αναιρείται."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Ακύρωση", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                setState(() {
                  globalUserNotes.removeAt(index);
                });
                await saveData();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Η κατηγορία \'$categoryName\' διαγράφηκε! 🗑️'),
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
            const Icon(Icons.note_alt_outlined, size: 100, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              "Δεν έχεις προσθέσει καμία κατηγορία.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Φτιάξε κατηγορίες σημειώσεων για να οργανώνεις τα κείμενα που αντιγράφεις.",
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
                onPressed: _showAddCategoryDialog,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  "Δημιουργία Κατηγορίας",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.0,
        ),
        itemCount: globalUserNotes.length,
        itemBuilder: (context, index) {
          final folder = globalUserNotes[index];
          List<dynamic> notes = folder['notes'] ?? []; 
          return Stack(
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NoteDetailsScreen(folder: folder)),
                  ).then((_) => setState(() {})); 
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.cyan.withOpacity(0.3), width: 1),
                    boxShadow: const [BoxShadow(color: Color.fromARGB(15, 0, 0, 0), blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.folder_copy_outlined, size: 48, color: Colors.cyan),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          folder['category'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${notes.length} Σημειώσεις",
                        style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: InkWell(
                  onTap: () => _confirmDeleteCategory(index, folder['category']),
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
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Οι Σημειώσεις μου', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: globalUserNotes.isEmpty ? _buildEmptyState() : _buildCategoriesGrid(isDark),
      floatingActionButton: globalUserNotes.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showAddCategoryDialog,
              backgroundColor: Colors.cyan,
              child: const Icon(Icons.create_new_folder_rounded, color: Colors.white),
            )
          : null,
    );
  }
}
