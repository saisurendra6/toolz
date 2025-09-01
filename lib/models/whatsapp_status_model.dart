import 'dart:developer';
import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;

class WhatsappStatusModel {
  final String path;
  final bool isVideo;

  WhatsappStatusModel({required this.path, required this.isVideo});

  static Future<List<WhatsappStatusModel>> getStatusFiles() async {
    List<WhatsappStatusModel> res = [];
    try {
      const statusPath =
          "/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses";
      Directory dir = Directory(statusPath);
      // log(dir.path, error: dir.listSync());
      // print(dir.listSync());
      dir.listSync().whereType<File>().forEach((file) {
        final ext = p.extension(file.path);
        // log(ext);
        if (ext == ".mp4") {
          res.add(WhatsappStatusModel(path: file.path, isVideo: true));
        } else if (ext == ".jpg") {
          res.add(WhatsappStatusModel(path: file.path, isVideo: false));
        }
      });
    } catch (e) {
      log("whatsApp Status File retival", error: e);
    }

    return res;
  }

  static Future<void> requestStoragePermissions() async {
    if (await Permission.storage.request().isGranted) {
      log("Storage permission granted");
    } else {
      log("Storage permission denied");
    }

    if (await Permission.manageExternalStorage.request().isGranted) {
      log("Manage External Storage permission granted");
    } else {
      log("Manage External Storage permission denied");
    }
  }
}
