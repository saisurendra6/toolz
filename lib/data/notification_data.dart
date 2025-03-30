import 'dart:developer';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class NotificationData {
  final String name;
  final String path;
  final DateTime dateTime;

  NotificationData(
      {required this.name, required this.path, required this.dateTime});

  static Future<List<NotificationData>> getNotifications() async {
    List<NotificationData> res = [];

    try {
      final supportDir = await getApplicationSupportDirectory();
      final path = p.join(supportDir.path, 'notification_history');
      final dir = Directory(path);

      dir.listSync().whereType<File>().forEach((file) {
        if (p.extension(file.path).contains(".txt")) {
          int val = int.parse(p.basenameWithoutExtension(file.path));
          res.add(NotificationData(
              name: p.basenameWithoutExtension(file.path),
              path: file.path,
              dateTime: DateTime.fromMillisecondsSinceEpoch(val)));
        }
      });
    } catch (e) {
      log("error", error: e);
    }

    res.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return res;
  }

  // static Stream<NotificationData> getNotificationStream(int limit) async* {
  //   final dir = await getApplicationSupportDirectory();
  //   final files = dir.listSync().whereType<File>();
  //   int cnt = 0;
  //   for (var file in files) {
  //     if (!file.path.contains(".txt")) continue;
  //     if (cnt >= limit) break;
  //     String content = await file.readAsString();
  //     final data = NotificationData(
  //         path: file.path,
  //         notification: NotificationModel.fromJson(jsonDecode(content)));
  //     yield data;
  //     cnt++;
  //   }
  // }
}
