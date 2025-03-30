import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toolz/data/notification_data.dart';
import 'package:toolz/model/notification_model.dart';
import 'package:toolz/widgets/notification_card.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen>
    with SingleTickerProviderStateMixin {
  static const EventChannel _eventChannel =
      EventChannel('com.sai.toolz/notifications');

  late AnimationController _bottomSheetAnimationController;
  // late StreamController<List<FileSystemEntity>> _fileStreamController;
  // late Timer _timer;

  @override
  void initState() {
    _listenToNotifications();
    // _getNotifications();
    // NotificationModel.getNotifications();
    _bottomSheetAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));

    // _fileStreamController =
    //     StreamController<List<FileSystemEntity>>.broadcast();
    // _startFileWatcher();
    super.initState();
  }

  @override
  void dispose() {
    _bottomSheetAnimationController.dispose();
    // _timer.cancel();
    // _fileStreamController.close();
    super.dispose();
  }

  // Future<void> _startFileWatcher() async {
  //   Directory? directory = await getApplicationSupportDirectory();
  //   _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
  //     List<FileSystemEntity> files = directory.listSync();
  //     _fileStreamController.add(files);
  //   });
  // }

  // Future<void> _getNotifications() async {
  //   try {
  //     final res = await platform.invokeMethod("startNotificationService");
  //     print("notifications: ");
  //     print(res);
  //   } on PlatformException catch (e) {
  //     print("Failed to get notifications: ${e.message}");
  //   }
  // }

  void _listenToNotifications() {
    _eventChannel.receiveBroadcastStream().listen((event) {
      // setState(() {
      //   _notifications
      //       .add(NotificationModel.fromJson(Map<String, String>.from(event)));
      // });
    }, onError: (error) {
      log("method channel error", error: error);
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Hero(
          tag: "Notification History",
          child: Text("Notification History"),
        ),
      ),

      // body: StreamBuilder<List<FileSystemEntity>>(
      //   stream: _fileStreamController.stream,
      //   builder: (context, snapshot) {
      //     if (!snapshot.hasData) {
      //       return const Center(child: CircularProgressIndicator());
      //     }
      //     List<FileSystemEntity> files = snapshot.data!;
      //     return ListView.builder(
      //       itemCount: files.length,
      //       itemBuilder: (context, index) {
      //         final file = File(files[index].path);
      //         if (!file.path.contains(".txt")) {
      //           return Container();
      //         }
      //         final String source = file.readAsStringSync();
      //         NotificationData data = NotificationData(
      //             path: file.path,
      //             notification: NotificationModel.fromJson(jsonDecode(source)));
      //         return NotificationCard(
      //             notificationData: data.notification,
      //             bottomSheetController: _bottomSheetAnimationController);
      //       },
      //     );
      //   },
      // ),

      body: FutureBuilder(
          future: NotificationData.getNotifications(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasData) {
              if (snapshot.data!.isEmpty) {
                return const Center(child: Text("No Notifications"));
              }
              return Scrollbar(
                interactive: true,
                thickness: 8.0,
                radius: const Radius.circular(4.0),
                child: ListView.builder(
                  itemCount: snapshot.data?.length,
                  itemBuilder: (context, index) {
                    // log("index: $index, filename: ${snapshot.data?[index].name}");
                    final noti = snapshot.data![index];
                    return NotificationCard(
                      notificationModel: NotificationModel.fromJson(
                          jsonDecode(File(noti.path).readAsStringSync())),
                      bottomSheetController: _bottomSheetAnimationController,
                      dateTime: noti.dateTime,
                      size: size,
                    );
                  },
                ),
              );
            }
            return const Center(child: Text("Loading..."));
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // print(_notifications);
          setState(() {});
        },
        child: const Icon(Icons.refresh_rounded),
      ),
    );
  }
}
