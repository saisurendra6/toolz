import 'package:flutter/material.dart';
import 'package:toolz/model/notification_model.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notificationModel;
  final AnimationController bottomSheetController;
  final DateTime dateTime;
  final Size size;
  const NotificationCard({
    super.key,
    required this.notificationModel,
    required this.bottomSheetController,
    required this.dateTime,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    String content =
        "${notificationModel.text}\n${notificationModel.textBig}".trim();
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          // clipBehavior: Clip.antiAliasWithSaveLayer,
          context: context,
          builder: (context) => BottomSheet(
            elevation: 2.0,
            enableDrag: true,
            showDragHandle: true,
            animationController: bottomSheetController,
            onClosing: () {},
            builder: (context) => Container(
              padding: const EdgeInsets.all(8.0),
              color: Theme.of(context).primaryColor.withOpacity(0.4),
              height: 300,
              child: Scrollbar(
                child: SingleChildScrollView(
                    child: Text("data: $notificationModel")),
              ),
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.all(8.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    child: Icon(Icons.flutter_dash),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: size.width - 150,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notificationModel.packageName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          notificationModel.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                          overflow: TextOverflow.clip,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 50,
                    child: Text(
                      "${dateTime.day}-${dateTime.month}\n${dateTime.hour}:${dateTime.minute}",
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              if (notificationModel.textSummary.isNotEmpty)
                Text("summary: ${notificationModel.textSummary}"),
              if (content.isNotEmpty || notificationModel.textLines.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    color: Theme.of(context).primaryColor.withOpacity(0.4),
                  ),
                  child: Text((notificationModel.textLines.isEmpty)
                      ? content
                      : notificationModel.textLines),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
