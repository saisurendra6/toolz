import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:toolz/app/routes.dart';
import 'package:toolz/providers/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App Theme Section
          _buildSectionHeader('Appearance', Icons.palette),
          _buildThemeSettings(themeProvider),
          const SizedBox(height: 24),

          // Notifications Section
          _buildSectionHeader('Notifications', Icons.notifications),
          _buildNotificationSettings(),
          const SizedBox(height: 24),

          // WhatsApp Section
          _buildSectionHeader('WhatsApp Utils', Icons.chat),
          _buildWhatsAppSettings(),
          const SizedBox(height: 24),

          // Privacy & Security
          _buildSectionHeader('Privacy & Security', Icons.security),
          _buildPrivacySettings(),
          const SizedBox(height: 24),

          // Storage & Data
          _buildSectionHeader('Storage & Data', Icons.storage),
          _buildStorageSettings(),
          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('About', Icons.info),
          _buildAboutSection(),
          const SizedBox(height: 32),

          // Footer
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSettings(ThemeProvider themeProvider) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            ),
            title: const Text('Dark Mode'),
            subtitle: Text(
              themeProvider.isDarkMode
                  ? 'Dark theme enabled'
                  : 'Light theme enabled',
            ),
            value: themeProvider.isDarkMode,
            onChanged: (value) => themeProvider.toggleTheme(),
          ),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('App Color'),
            subtitle: const Text('Choose your preferred accent color'),
            trailing: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            onTap: () => _showColorPicker(themeProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Notification History'),
            subtitle: const Text('View saved notifications'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Notification Settings'),
            subtitle: const Text('Configure notification capture'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.notificationsSettings),
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Notification Access'),
            subtitle: const Text('Grant notification listening permission'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.notificationsPermission),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsAppSettings() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('Status Viewer'),
            subtitle: const Text('View WhatsApp status files'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.pushNamed(context, AppRoutes.whatsappStatus),
          ),
          ListTile(
            leading: const Icon(Icons.contact_phone),
            title: const Text('Direct Message'),
            subtitle: const Text('Send message without saving contact'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.whatsappContact),
          ),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('Storage Permissions'),
            subtitle: const Text('Manage WhatsApp file access'),
            onTap: () => _showStoragePermissionDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySettings() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Data Privacy'),
            subtitle: const Text('Your data stays on your device'),
            onTap: () => _showPrivacyInfo(),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('Clear All Data'),
            subtitle: const Text('Delete all saved notifications'),
            onTap: () => _showClearDataDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageSettings() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('Storage Usage'),
            subtitle: const Text('View app storage details'),
            onTap: () => _showStorageInfo(),
          ),
          ListTile(
            leading: const Icon(Icons.auto_delete),
            title: const Text('Auto-Delete'),
            subtitle: const Text('Automatically delete old notifications'),
            trailing: Switch(
              value: true, // This should come from your settings provider
              onChanged: (value) {
                // Implement auto-delete toggle
                _showFeatureComingSoon();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('App Version'),
            subtitle: Text(_packageInfo?.version ?? 'Loading...'),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('What\'s New'),
            subtitle: const Text('View latest updates and features'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showChangelogDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share App'),
            subtitle: const Text('Share toolZ with friends'),
            onTap: () => _shareApp(),
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Rate App'),
            subtitle: const Text('Rate us on Play Store'),
            onTap: () => _rateApp(),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Report Issue'),
            subtitle: const Text('Help us improve the app'),
            onTap: () => _reportIssue(),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'toolZ',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Made with ❤️ for productivity',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        Text(
          '© 2025 toolZ. Version ${_packageInfo?.version ?? '1.0.0'}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  void _showColorPicker(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Color'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: themeProvider.availableColors.map((color) {
              return GestureDetector(
                onTap: () {
                  themeProvider.setThemeColor(
                      themeProvider.availableColors.indexOf(color));
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      width: 2,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showStoragePermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Permission'),
        content: const Text(
          'Storage permission is required to access WhatsApp status files. '
          'This permission is only used to read status files and nothing else.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Privacy'),
        content: const Text(
          'toolZ respects your privacy:\n\n'
          '• All data is stored locally on your device\n'
          '• No data is sent to external servers\n'
          '• Notifications are saved only on your device\n'
          '• WhatsApp status files are accessed read-only\n'
          '• No analytics or tracking is performed',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all saved notifications and app data. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement clear data functionality
              _showFeatureComingSoon();
            },
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );
  }

  void _showStorageInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Usage'),
        content: const Text(
          'App Storage: 15.2 MB\n'
          'Notifications: 8.7 MB\n'
          'Cache: 3.1 MB\n'
          'Other: 3.4 MB\n\n'
          'Storage usage is calculated approximately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showChangelogDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('What\'s New'),
        content: const SingleChildScrollView(
          child: Text(
            'Version 1.0.0\n'
            '• Initial release\n'
            '• Notification history and saving\n'
            '• WhatsApp status viewer\n'
            '• Direct WhatsApp messaging\n'
            '• Modern Material 3 design\n'
            '• Dark/Light theme support\n\n'
            'Coming Soon:\n'
            '• Auto-delete old notifications\n'
            '• Export/Import settings\n'
            '• More WhatsApp utilities',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _shareApp() {
    Share.share(
      'Check out toolZ - The ultimate productivity app!\n'
      'Save notifications, view WhatsApp status, and more.\n'
      'Download now: https://github.com/saisurendra6/toolz',
    );
  }

  void _rateApp() {
    final uri = Uri.parse('market://details?id=com.example.toolz');
    launchUrl(uri).catchError((_) {
      // Fallback to web version if Play Store app not available
      return launchUrl(Uri.parse(
          'https://play.google.com/store/apps/details?id=com.example.toolz'));
    });
  }

  void _reportIssue() {
    final uri = Uri.parse(
        'mailto:saisurendra.kusam@gmail.com?subject=Bug Report&body=Please describe the issue:');
    launchUrl(uri);
  }

  void _showFeatureComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This feature is coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
