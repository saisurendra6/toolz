import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ImageViewerScreen extends StatelessWidget {
  final File file;
  final String tag;
  const ImageViewerScreen({super.key, required this.file, required this.tag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text("Image Viewer"),
        actions: [
          IconButton(
              onPressed: () async {
                await Share.shareXFiles([XFile(file.path)]);
              },
              icon: const Icon(Icons.share_rounded))
        ],
      ),
      body: Hero(tag: tag, child: Center(child: Image.file(file))),
    );
  }
}
