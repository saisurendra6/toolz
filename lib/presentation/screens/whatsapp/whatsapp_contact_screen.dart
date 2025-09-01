import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class WhatsappContactPage extends StatefulWidget {
  const WhatsappContactPage({super.key});

  @override
  State<WhatsappContactPage> createState() => _WhatsappContactPageState();
}

class _WhatsappContactPageState extends State<WhatsappContactPage> {
  final List<CountryCode> _countryCodes = [
    CountryCode(name: 'India', code: '+91', flag: '🇮🇳'),
    CountryCode(name: 'United States', code: '+1', flag: '🇺🇸'),
    CountryCode(name: 'United Kingdom', code: '+44', flag: '🇬🇧'),
    CountryCode(name: 'Australia', code: '+61', flag: '🇦🇺'),
    CountryCode(name: 'Canada', code: '+1', flag: '🇨🇦'),
    CountryCode(name: 'Germany', code: '+49', flag: '🇩🇪'),
    CountryCode(name: 'France', code: '+33', flag: '🇫🇷'),
    // Add more countries here
  ];

  late final TextEditingController phonenoController, messageController;

  late CountryCode _selectedCountryCode;

  @override
  void initState() {
    super.initState();
    phonenoController = TextEditingController();
    messageController = TextEditingController();
    _selectedCountryCode = _countryCodes[0];
  }

  @override
  void dispose() {
    phonenoController.dispose();
    messageController.dispose();
    super.dispose();
  }

  Future<void> _launchWhatsApp(BuildContext context) async {
    String phone = phonenoController.text.trim();

    if (phone.isNotEmpty && phone.length < 6) {
      _showSnackBar(context, 'Please enter a valid phone number');
      return;
    }

    String message = messageController.text.trim();
    if (phone.isEmpty && message.isEmpty) {
      _showSnackBar(context, 'Please enter phone number and message');
      return;
    }
    String fullPhone = _selectedCountryCode.code + phone;
    fullPhone =
        phone.isEmpty ? "" : fullPhone.replaceAll("+", "").replaceAll(" ", "");
    String encodedMessage = Uri.encodeComponent(message);

    var url = Uri.parse("https://wa.me/$fullPhone?text=$encodedMessage");

    if (await url_launcher.canLaunchUrl(url)) {
      await url_launcher.launchUrl(
        url,
        mode: url_launcher.LaunchMode.externalApplication,
      );
    } else {
      _showSnackBar(context, 'Could not open WhatsApp');
    }
  }

  void _showSnackBar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _openCountryCodeDialog() async {
    String filter = '';
    List<CountryCode> filteredList = List.of(_countryCodes);

    final selected = await showDialog<CountryCode>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            filteredList = _countryCodes
                .where((c) =>
                    c.name.toLowerCase().contains(filter.toLowerCase()) ||
                    c.code.contains(filter))
                .toList();

            return AlertDialog(
              title: const Text('Select Country Code'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Search country',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (val) => setState(() => filter = val),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final country = filteredList[index];
                          return ListTile(
                            leading: Text(country.flag,
                                style: const TextStyle(fontSize: 24)),
                            title: Text(country.name),
                            trailing: Text(country.code),
                            onTap: () => Navigator.of(context).pop(country),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedCountryCode = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Open WhatsApp Contact'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            const Spacer(flex: 2),
            Row(
              children: [
                GestureDetector(
                  onTap: _openCountryCodeDialog,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: theme.colorScheme.primaryContainer,
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedCountryCode.flag,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedCountryCode.code,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: phonenoController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: messageController,
              minLines: 1,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.message),
              ),
            ),
            const Spacer(flex: 1),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _launchWhatsApp(context),
                child: const Text('Open WhatsApp'),
              ),
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}

class CountryCode {
  final String name;
  final String code;
  final String flag;

  CountryCode({
    required this.name,
    required this.code,
    required this.flag,
  });
}
