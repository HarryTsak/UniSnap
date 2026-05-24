import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'gallery_screen.dart';
import 'settings_screen.dart';
import 'notes_screen.dart';

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

  Future<void> _openCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (photo != null) {
        if (mounted) {
          _processCameraImage(photo.path);
        }
      }
    } catch (e) {
      print("Πρόβλημα με την κάμερα: $e");
    }
  }

  void _processCameraImage(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GalleryScreen(
          imagePathToSave: path,
          ocrTextToSave: "",
        ),
      ),
    );
  }

  Widget _buildCameraButton(bool isDark) {
    return Center(
      child: InkWell(
        onTap: _openCamera, 
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.all(40), 
          child: Icon(
            Icons.camera_alt_outlined,
            size: 160,
            color: isDark ? Colors.white70 : const Color(0xFF2D2D2D),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(bool isDark) {
    return Positioned(
      top: 30,
      left: 0, 
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20)),
          border: Border.all(color: Colors.cyan, width: 2.0),
          boxShadow: const [BoxShadow(color: Color.fromARGB(25, 8, 123, 211), blurRadius: 15, offset: Offset(0, 5))],
        ),
        child: PopupMenuButton<String>(
          icon: Icon(Icons.menu_open, color: isDark ? Colors.white : Colors.black87),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          offset: const Offset(60, 0), 
          onSelected: (value) {
            if (value == 'gallery') {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const GalleryScreen()));
            } else if (value == 'notes') {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const NotesScreen()));
            } else if (value == 'settings') {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem(
              value: 'gallery',
              child: Row(
                children: [
                  const Icon(Icons.photo_library_outlined, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text("Η Συλλογή μου", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'notes',
              child: Row(
                children: [
                  const Icon(Icons.note_alt_outlined, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text("Οι Σημειώσεις μου", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  const Icon(Icons.settings_outlined, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text("Ρυθμίσεις", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                ],
              ),
            ),
          ],
        ),
      ),
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
            _buildCameraButton(isDark),
            _buildMenuButton(isDark),
          ],
        ),
      ),
    );
  }
}
