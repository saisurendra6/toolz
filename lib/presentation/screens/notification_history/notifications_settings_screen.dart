import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/theme_provider.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _isLoading = false;
  int _notificationCount = 0;
  String _dbSize = 'Calculating...';

  @override
  void initState() {
    super.initState();
    _loadSettingsData();
  }

  Future<void> _loadSettingsData() async {
    try {
      final count = await NotificationService.getNotificationCount();
      final size = await _calculateDatabaseSize();

      if (mounted) {
        setState(() {
          _notificationCount = count;
          _dbSize = size;
        });
      }
    } catch (e) {
      AppLogger.error('Failed to load settings data: $e');
    }
  }

  Future<String> _calculateDatabaseSize() async {
    try {
      final sizeInBytes = _notificationCount * 500; // Rough estimate
      if (sizeInBytes < 1024) {
        return '$sizeInBytes B';
      } else if (sizeInBytes < 1024 * 1024) {
        return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
      } else {
        return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (_) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildUserSection(),
          _buildThemeSection(),
          _buildNotificationSection(),
          _buildDataManagementSection(),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildUserSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                Icons.person,
                size: 32,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'toolZ User',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_notificationCount notifications saved',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSection() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return _buildSection(
          title: 'Appearance',
          icon: Icons.palette,
          children: [
            _buildSwitchTile(
              title: 'Dark Mode',
              subtitle: 'Use dark theme',
              icon: Icons.dark_mode,
              value: themeProvider.isDarkMode,
              onChanged: (value) => themeProvider.toggleTheme(),
            ),
            _buildNavigationTile(
              title: 'Theme Color',
              subtitle: 'Choose your accent color',
              icon: Icons.color_lens,
              trailing: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: themeProvider.currentSeedColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                    width: 1,
                  ),
                ),
              ),
              onTap: () => _showColorPicker(themeProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationSection() {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return _buildSection(
          title: 'Notifications',
          icon: Icons.notifications,
          children: [
            _buildSwitchTile(
              title: 'Auto Cleanup',
              subtitle: 'Automatically delete old notifications',
              icon: Icons.auto_delete,
              value: settingsProvider.autoCleanupEnabled,
              onChanged: (value) => settingsProvider.setAutoCleanup(value),
            ),
            _buildNavigationTile(
              title: 'Cleanup Period',
              subtitle: 'Delete after ${settingsProvider.cleanupDays} days',
              icon: Icons.schedule,
              onTap: () => _showCleanupPeriodDialog(settingsProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDataManagementSection() {
    return _buildSection(
      title: 'Data Management',
      icon: Icons.storage,
      children: [
        _buildInfoTile(
          title: 'Storage Used',
          subtitle: _dbSize,
          icon: Icons.folder_open,
        ),
        _buildInfoTile(
          title: 'Total Notifications',
          subtitle: _notificationCount.toString(),
          icon: Icons.inbox,
        ),
        _buildDangerTile(
          title: 'Clear All Data',
          subtitle: 'Delete all saved notifications',
          icon: Icons.delete_forever,
          onTap: _showClearAllDialog,
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSection(
      title: 'About',
      icon: Icons.info,
      children: [
        _buildInfoTile(
          title: 'Version',
          subtitle: AppConstants.appVersion,
          icon: Icons.info_outline,
        ),
        _buildNavigationTile(
          title: 'Privacy Policy',
          subtitle: 'How we handle your data',
          icon: Icons.privacy_tip,
          onTap: _showPrivacyPolicy,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 8),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
      onTap: () => onChanged(!value),
    );
  }

  Widget _buildNavigationTile({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
      enabled: onTap != null,
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      enabled: false,
    );
  }

  Widget _buildDangerTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.error),
      title: Text(
        title,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  // Essential dialog methods
  void _showColorPicker(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme Color'),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                themeProvider.availableColors.asMap().entries.map((entry) {
              final index = entry.key;
              final colorOption = entry.value;
              final isSelected = index == themeProvider.selectedColorIndex;

              return GestureDetector(
                onTap: () {
                  themeProvider.setThemeColor(index);
                  Navigator.pop(context);
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorOption.color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showCleanupPeriodDialog(SettingsProvider settingsProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cleanup Period'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Delete notifications older than:'),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: settingsProvider.cleanupDays,
              items: [7, 14, 30, 60, 90, 180, 365]
                  .map((days) => DropdownMenuItem(
                        value: days,
                        child: Text('$days days'),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  settingsProvider.setCleanupDays(value);
                }
              },
            ),
          ],
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

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
            'This will permanently delete all saved notifications. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearAllData();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'toolZ stores notifications locally on your device. '
            'No data is transmitted to external servers. '
            'You have full control over your notification history.',
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

  Future<void> _clearAllData() async {
    setState(() => _isLoading = true);

    try {
      await NotificationService.clearAllNotifications();
      _showSuccessSnackBar('All data cleared');
      _loadSettingsData();
    } catch (e) {
      _showErrorSnackBar('Failed to clear data');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
