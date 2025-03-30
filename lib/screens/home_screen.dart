import 'package:flutter/material.dart';
import 'package:toolz/screens/notification_history_page.dart';
import 'package:toolz/screens/whatsapp_screen.dart';
import 'package:toolz/widgets/homescreen_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("toolZ"), centerTitle: true),
      body: const Column(
        children: [
          HomescreenCard(
            title: "WhatsApp Utils",
            screen: WhatsappScreen(),
          ),
          HomescreenCard(
            title: "Notification History",
            screen: NotificationHistoryScreen(),
          ),
        ],
      ),
    );
  }
}
