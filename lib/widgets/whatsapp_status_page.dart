import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:toolz/model/whatsapp_status_model.dart';
import 'package:toolz/screens/image_viewer_screen.dart';
import 'package:toolz/screens/video_player_screen.dart';

class WhatsappStatusPage extends StatefulWidget {
  const WhatsappStatusPage({super.key});

  @override
  State<WhatsappStatusPage> createState() => _WhatsappStatusPageState();
}

class _WhatsappStatusPageState extends State<WhatsappStatusPage> {
  @override
  void initState() {
    WhatsappStatusModel.requestStoragePermissions();
    // WhatsappStatusModel.getStatusFIles();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: WhatsappStatusModel.getStatusFiles(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          // return ListView.builder(
          //     itemCount: snapshot.data!.length,
          //     itemBuilder: (context, index) {
          //       return ListTile(
          //         title: Text(snapshot.data![index].path),
          //       );
          //     });
          return GridView.builder(
            itemCount: snapshot.data!.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, childAspectRatio: 9 / 16),
            itemBuilder: (context, index) {
              final status = snapshot.data![index];
              final file = File(status.path);
              return InkWell(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => (status.isVideo)
                            ? VideoPlayerScreen(file: file)
                            : ImageViewerScreen(file: file, tag: file.path))),
                child: Hero(
                  tag: file.path,
                  child: Card(
                    child: (status.isVideo)
                        ? FutureBuilder(
                            future: getThumbnail(file.path),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              if (snapshot.hasData) {
                                return snapshot.data ?? const Text("data");
                              }
                              return const Text("data");
                            })
                        : Image.file(file, fit: BoxFit.cover),
                  ),
                ),
              );
            },
          );
        }
        return const Text("data");
      },
    );
  }

  Future<Image> getThumbnail(String path) async {
    final bytes = await VideoThumbnail.thumbnailData(
      video: path,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 128,
      quality: 25,
    );

    return Image.memory(bytes);
  }
}
