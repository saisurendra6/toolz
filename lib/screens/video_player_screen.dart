import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final File file;
  const VideoPlayerScreen({super.key, required this.file});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;

  @override
  void initState() {
    _videoPlayerController = VideoPlayerController.file(widget.file);
    _videoPlayerController.initialize();
    _videoPlayerController.play();
    super.initState();
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              onPressed: () async {
                await Share.shareXFiles([XFile(widget.file.path)]);
              },
              icon: const Icon(Icons.share_rounded))
        ],
      ),
      body: Stack(
        children: [
          VideoPlayer(_videoPlayerController),
          // Center(
          //   child: IconButton(
          //     onPressed: () {
          //       setState(() {
          //         if (_videoPlayerController.value.isPlaying) {
          //           _videoPlayerController.pause();
          //         } else {
          //           _videoPlayerController.play();
          //         }
          //       });
          //     },
          //     icon: Icon(
          //       _videoPlayerController.value.isPlaying
          //           ? Icons.pause
          //           : Icons.play_arrow_rounded,
          //       size: 42,
          //       color: Colors.white,
          //     ),
          //   ),
          // ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            if (_videoPlayerController.value.isPlaying) {
              _videoPlayerController.pause();
            } else {
              _videoPlayerController.play();
            }
          });
        },
        child: _videoPlayerController.value.isPlaying
            ? const Icon(Icons.pause)
            : const Icon(Icons.play_arrow_rounded),
      ),
    );
  }
}
