import 'package:flutter/material.dart';
import 'package:toolz/widgets/whatsapp_contact_page.dart';
import 'package:toolz/widgets/whatsapp_status_page.dart';

class WhatsappScreen extends StatefulWidget {
  const WhatsappScreen({super.key});

  @override
  State<WhatsappScreen> createState() => _WhatsappScreenState();
}

class _WhatsappScreenState extends State<WhatsappScreen> {
  int pageIndex = 0;
  late TextEditingController _phonenoContoller, messageController;
  @override
  void initState() {
    _phonenoContoller = TextEditingController();
    messageController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _phonenoContoller.dispose();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Hero(
          tag: "WhatsApp Utils",
          child: Text("WhatsApp Utils"),
        ),
      ),
      body: (pageIndex == 0)
          ? const WhatsappStatusPage()
          : WhatsappContactPage(
              phonenoController: _phonenoContoller,
              messageController: messageController,
            ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (value) => setState(() => pageIndex = value),
        currentIndex: pageIndex,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.image_rounded), label: "Status"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded), label: "Contact"),
        ],
      ),
    );
  }
}
