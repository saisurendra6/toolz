import 'package:flutter/material.dart';
import 'package:toolz/presentation/screens/whatsapp/whatsapp_contact_screen.dart';
import 'package:toolz/presentation/screens/whatsapp/whatsapp_status_page.dart';

class WhatsappHomeScreen extends StatefulWidget {
  final int? initialIndex;
  const WhatsappHomeScreen({super.key, this.initialIndex});

  @override
  State<WhatsappHomeScreen> createState() => _WhatsappHomeScreenState();
}

class _WhatsappHomeScreenState extends State<WhatsappHomeScreen>
    with TickerProviderStateMixin {
  int _pageIndex = 0;

  // Animation controllers to enhance UI transitions (optional)
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _fadeController.forward();

    if (widget.initialIndex != null) {
      _onPageChanged(widget.initialIndex!);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (_pageIndex != index) {
      setState(() {
        _pageIndex = index;
      });
      _fadeController.reset();
      _fadeController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _pageIndex == 0
            ? const WhatsappStatusScreen()
            : const WhatsappContactPage(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pageIndex,
        onDestinationSelected: _onPageChanged,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.image_outlined),
            selectedIcon: Icon(Icons.image),
            label: 'Status',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Contact',
          ),
        ],
      ),
    );
  }
}
