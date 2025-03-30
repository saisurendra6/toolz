import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsappContactPage extends StatelessWidget {
  final TextEditingController phonenoController, messageController;
  const WhatsappContactPage(
      {super.key,
      required this.phonenoController,
      required this.messageController});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          const Spacer(flex: 2),
          TextField(
            controller: phonenoController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.person_rounded),
              labelText: "Phone Number",
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          TextField(
            minLines: 1,
            maxLines: 5,
            controller: messageController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.message_rounded),
              labelText: "Message",
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
            ),
            keyboardType: TextInputType.multiline,
          ),
          // const SizedBox(height: 40),
          const Spacer(flex: 1),
          OutlinedButton(
              onPressed: () async {
                String phno = phonenoController.text.trim();
                String urlencodedtext =
                    Uri.encodeFull(messageController.text.trim());
                Uri url =
                    Uri.parse("https://wa.me/$phno/?text=$urlencodedtext");
                await launchUrl(url);
              },
              child: const Text("Open WhataApp")),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
