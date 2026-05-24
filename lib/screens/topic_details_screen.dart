import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'full_screen_image_screen.dart';

// -------------------------------------------------------------
// ΟΘΟΝΗ 4: ΠΕΡΙΕΧΟΜΕΝΑ ΦΑΚΕΛΟΥ (Topic Details Screen)
// -------------------------------------------------------------
class TopicDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> topic;
  const TopicDetailsScreen({super.key, required this.topic});

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        "Ο φάκελος είναι άδειος!\nΒγάλε ένα Snap για να το δεις εδώ.",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey, fontSize: 16),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, dynamic imageData) {
    final imagePath = imageData['path'];
    final ocrText = imageData['text'];

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenImageScreen(imagePath: imagePath, ocrText: ocrText),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Hero(
          tag: imagePath,
          child: Container(
            color: Colors.grey.shade300,
            child: kIsWeb
                ? Image.network(imagePath, fit: BoxFit.cover)
                : Image.file(File(imagePath), fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }

  Widget _buildImagesGrid(BuildContext context, List<dynamic> images) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return _buildGridItem(context, images[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> images = topic['images'];
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(topic['course'], style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: images.isEmpty ? _buildEmptyState() : _buildImagesGrid(context, images),
    );
  }
}
