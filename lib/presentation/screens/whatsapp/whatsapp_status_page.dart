import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:toolz/app/routes.dart';

import '../../../models/whatsapp_status_model.dart';

class WhatsappStatusScreen extends StatefulWidget {
  const WhatsappStatusScreen({super.key});

  @override
  State<WhatsappStatusScreen> createState() => _WhatsappStatusScreenState();
}

class _WhatsappStatusScreenState extends State<WhatsappStatusScreen>
    with AutomaticKeepAliveClientMixin {
  late final Future<List<WhatsappStatusModel>> _statusFilesFuture;

  @override
  void initState() {
    super.initState();
    _statusFilesFuture = _checkPermissionsAndLoadStatus();
  }

  Future<List<WhatsappStatusModel>> _checkPermissionsAndLoadStatus() async {
    // Check permissions first
    final hasPermission = await _hasStoragePermission();
    if (!hasPermission) {
      // Navigate to permission screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(
              context, AppRoutes.whatsappStatusPermission);
        }
      });
      return [];
    }

    // Load status files if permission granted
    return WhatsappStatusModel.getStatusFiles();
  }

  Future<bool> _hasStoragePermission() async {
    if (Platform.isAndroid) {
      final storage = await Permission.storage.status;
      final manageStorage = await Permission.manageExternalStorage.status;
      return storage.isGranted || manageStorage.isGranted;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp Status'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<WhatsappStatusModel>>(
        future: _statusFilesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No statuses available',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            );
          }
          final statuses = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 9 / 16,
            ),
            itemCount: statuses.length,
            itemBuilder: (context, index) {
              final status = statuses[index];
              final file = File(status.path);
              return _StatusGridItem(file: file, isVideo: status.isVideo);
            },
          );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _StatusGridItem extends StatelessWidget {
  final File file;
  final bool isVideo;

  const _StatusGridItem({
    required this.file,
    required this.isVideo,
  });

  void _onTap(BuildContext context) {
    Navigator.pushNamed(
      context,
      isVideo ? AppRoutes.videoPlayer : AppRoutes.imageViewer,
      arguments: file,
    );
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      splashFactory: InkRipple.splashFactory,
      onTap: () => _onTap(context),
      child: Hero(
        tag: file.path,
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: isVideo
              ? _buildVideoThumbnail()
              : Image.file(file, fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildVideoThumbnail() {
    return FutureBuilder<Image>(
      future: _getVideoThumbnail(file.path),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Icon(Icons.error_outline, size: 48));
        }
        return Stack(
          children: [
            Positioned.fill(child: snapshot.data!),
            Container(
              alignment: Alignment.center,
              color: Colors.black26,
              child: const Icon(
                Icons.play_circle_fill,
                size: 56,
                color: Colors.white70,
              ),
            )
          ],
        );
      },
    );
  }

  Future<Image> _getVideoThumbnail(String videoPath) async {
    final bytes = await VideoThumbnail.thumbnailData(
      video: videoPath,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 256,
      quality: 50,
    );

    if (bytes == null) {
      throw Exception('Failed to generate video thumbnail');
    }

    return Image.memory(bytes, fit: BoxFit.cover);
  }
}
