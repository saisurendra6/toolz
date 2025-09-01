import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/app_logger.dart';

class SettingsProvider extends ChangeNotifier {
  // Private fields
  bool _autoCleanupEnabled = true;
  int _cleanupDays = AppConstants.defaultCleanupDays;
  bool _notificationsEnabled = true;
  bool _hapticFeedbackEnabled = true;
  bool _isFirstLaunch = true;
  DateTime? _lastCleanup;

  // Notification permission
  bool _hasNotificationPermission = false;
  bool _permissionRequested = false;

  // Getters
  bool get autoCleanupEnabled => _autoCleanupEnabled;
  int get cleanupDays => _cleanupDays;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get hapticFeedbackEnabled => _hapticFeedbackEnabled;
  bool get isFirstLaunch => _isFirstLaunch;
  DateTime? get lastCleanup => _lastCleanup;
  bool get hasNotificationPermission => _hasNotificationPermission;
  bool get permissionRequested => _permissionRequested;

  /// Initialize settings provider with saved preferences
  Future<void> initialize() async {
    try {
      AppLogger.info('⚙️ Initializing settings provider');

      final prefs = await SharedPreferences.getInstance();

      // Load all settings
      _autoCleanupEnabled = prefs.getBool('auto_cleanup_enabled') ?? true;
      _cleanupDays =
          prefs.getInt('cleanup_days') ?? AppConstants.defaultCleanupDays;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _hapticFeedbackEnabled = prefs.getBool('haptic_feedback_enabled') ?? true;
      _isFirstLaunch = prefs.getBool(AppConstants.keyFirstLaunch) ?? true;
      _permissionRequested =
          prefs.getBool(AppConstants.keyNotificationPermissionAsked) ?? false;

      // Load last cleanup date
      final lastCleanupMillis = prefs.getInt(AppConstants.keyLastCleanup);
      if (lastCleanupMillis != null) {
        _lastCleanup = DateTime.fromMillisecondsSinceEpoch(lastCleanupMillis);
      }

      // Validate cleanup days range
      if (_cleanupDays < 1 || _cleanupDays > AppConstants.maxCleanupDays) {
        _cleanupDays = AppConstants.defaultCleanupDays;
        await _saveCleanupDays();
      }

      AppLogger.info(
          '✅ Settings initialized - Auto cleanup: $_autoCleanupEnabled, Days: $_cleanupDays');

      notifyListeners();
    } catch (e) {
      AppLogger.error('❌ Settings initialization failed: $e');

      // Set defaults on error
      _resetToDefaults();
      notifyListeners();
    }
  }

  /// Enable/disable auto cleanup
  Future<void> setAutoCleanup(bool enabled) async {
    try {
      _autoCleanupEnabled = enabled;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auto_cleanup_enabled', enabled);

      AppLogger.info('🧹 Auto cleanup ${enabled ? 'enabled' : 'disabled'}');

      notifyListeners();
    } catch (e) {
      AppLogger.error('❌ Failed to set auto cleanup: $e');
    }
  }

  /// Set cleanup days
  Future<void> setCleanupDays(int days) async {
    try {
      if (days < 1 || days > AppConstants.maxCleanupDays) {
        AppLogger.warning('⚠️ Invalid cleanup days: $days');
        return;
      }

      _cleanupDays = days;
      await _saveCleanupDays();

      AppLogger.info('📅 Cleanup days set to: $days');

      notifyListeners();
    } catch (e) {
      AppLogger.error('❌ Failed to set cleanup days: $e');
    }
  }

  /// Enable/disable notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      _notificationsEnabled = enabled;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', enabled);

      AppLogger.info('🔔 Notifications ${enabled ? 'enabled' : 'disabled'}');

      notifyListeners();
    } catch (e) {
      AppLogger.error('❌ Failed to set notifications: $e');
    }
  }

  /// Enable/disable haptic feedback
  Future<void> setHapticFeedbackEnabled(bool enabled) async {
    try {
      _hapticFeedbackEnabled = enabled;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('haptic_feedback_enabled', enabled);

      AppLogger.info('📳 Haptic feedback ${enabled ? 'enabled' : 'disabled'}');

      notifyListeners();
    } catch (e) {
      AppLogger.error('❌ Failed to set haptic feedback: $e');
    }
  }

  /// Mark first launch as completed
  Future<void> completeFirstLaunch() async {
    try {
      _isFirstLaunch = false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyFirstLaunch, false);

      AppLogger.info('✅ First launch completed');

      notifyListeners();
    } catch (e) {
      AppLogger.error('❌ Failed to complete first launch: $e');
    }
  }

  /// Update notification permission status
  void updateNotificationPermission(bool hasPermission) {
    if (_hasNotificationPermission != hasPermission) {
      _hasNotificationPermission = hasPermission;
      AppLogger.info('🔐 Notification permission updated: $hasPermission');
      notifyListeners();
    }
  }

  /// Mark permission as requested
  Future<void> markPermissionRequested() async {
    try {
      _permissionRequested = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyNotificationPermissionAsked, true);

      AppLogger.info('❓ Permission request marked');

      notifyListeners();
    } catch (e) {
      AppLogger.error('❌ Failed to mark permission requested: $e');
    }
  }

  /// Update last cleanup timestamp
  Future<void> updateLastCleanup() async {
    try {
      _lastCleanup = DateTime.now();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          AppConstants.keyLastCleanup, _lastCleanup!.millisecondsSinceEpoch);

      AppLogger.info('🧹 Last cleanup timestamp updated');

      notifyListeners();
    } catch (e) {
      AppLogger.error('❌ Failed to update last cleanup: $e');
    }
  }

  /// Check if auto cleanup should run
  bool shouldRunAutoCleanup() {
    if (!_autoCleanupEnabled) return false;
    if (_lastCleanup == null) return true;

    final daysSinceLastCleanup =
        DateTime.now().difference(_lastCleanup!).inDays;
    return daysSinceLastCleanup >= _cleanupDays;
  }

  /// Get days since last cleanup
  int get daysSinceLastCleanup {
    if (_lastCleanup == null) return -1;
    return DateTime.now().difference(_lastCleanup!).inDays;
  }

  /// Get formatted last cleanup date
  String get lastCleanupFormatted {
    if (_lastCleanup == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(_lastCleanup!);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    }
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    try {
      AppLogger.info('🔄 Resetting settings to defaults');

      _resetToDefaults();

      // Clear all saved preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auto_cleanup_enabled');
      await prefs.remove('cleanup_days');
      await prefs.remove('notifications_enabled');
      await prefs.remove('haptic_feedback_enabled');
      await prefs.remove(AppConstants.keyLastCleanup);

      notifyListeners();

      AppLogger.info('✅ Settings reset completed');
    } catch (e) {
      AppLogger.error('❌ Failed to reset settings: $e');
    }
  }

  /// Export settings as Map
  Map<String, dynamic> exportSettings() {
    return {
      'auto_cleanup_enabled': _autoCleanupEnabled,
      'cleanup_days': _cleanupDays,
      'notifications_enabled': _notificationsEnabled,
      'haptic_feedback_enabled': _hapticFeedbackEnabled,
      'last_cleanup': _lastCleanup?.millisecondsSinceEpoch,
      'permission_requested': _permissionRequested,
      'export_timestamp': DateTime.now().millisecondsSinceEpoch,
      'app_version': AppConstants.appVersion,
    };
  }

  /// Import settings from Map
  Future<void> importSettings(Map<String, dynamic> settings) async {
    try {
      AppLogger.info('📥 Importing settings');

      _autoCleanupEnabled = settings['auto_cleanup_enabled'] ?? true;
      _cleanupDays =
          settings['cleanup_days'] ?? AppConstants.defaultCleanupDays;
      _notificationsEnabled = settings['notifications_enabled'] ?? true;
      _hapticFeedbackEnabled = settings['haptic_feedback_enabled'] ?? true;
      _permissionRequested = settings['permission_requested'] ?? false;

      final lastCleanupMillis = settings['last_cleanup'] as int?;
      if (lastCleanupMillis != null) {
        _lastCleanup = DateTime.fromMillisecondsSinceEpoch(lastCleanupMillis);
      }

      // Save imported settings
      await _saveAllSettings();

      notifyListeners();

      AppLogger.info('✅ Settings imported successfully');
    } catch (e) {
      AppLogger.error('❌ Failed to import settings: $e');
      rethrow;
    }
  }

  /// Private helper methods
  void _resetToDefaults() {
    _autoCleanupEnabled = true;
    _cleanupDays = AppConstants.defaultCleanupDays;
    _notificationsEnabled = true;
    _hapticFeedbackEnabled = true;
    _lastCleanup = null;
  }

  Future<void> _saveCleanupDays() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('cleanup_days', _cleanupDays);
  }

  Future<void> _saveAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_cleanup_enabled', _autoCleanupEnabled);
    await prefs.setInt('cleanup_days', _cleanupDays);
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('haptic_feedback_enabled', _hapticFeedbackEnabled);
    await prefs.setBool(
        AppConstants.keyNotificationPermissionAsked, _permissionRequested);

    if (_lastCleanup != null) {
      await prefs.setInt(
          AppConstants.keyLastCleanup, _lastCleanup!.millisecondsSinceEpoch);
    }
  }

  /// Settings validation
  bool get isValid {
    return _cleanupDays >= 1 && _cleanupDays <= AppConstants.maxCleanupDays;
  }

  /// Get settings summary for display
  String get settingsSummary {
    final buffer = StringBuffer();
    buffer.writeln(
        'Auto Cleanup: ${_autoCleanupEnabled ? 'Enabled' : 'Disabled'}');
    buffer.writeln('Cleanup Days: $_cleanupDays');
    buffer.writeln(
        'Notifications: ${_notificationsEnabled ? 'Enabled' : 'Disabled'}');
    buffer.writeln(
        'Haptic Feedback: ${_hapticFeedbackEnabled ? 'Enabled' : 'Disabled'}');
    buffer.writeln('Last Cleanup: $lastCleanupFormatted');
    return buffer.toString();
  }

  @override
  void dispose() {
    AppLogger.info('🧹 Disposing settings provider');
    super.dispose();
  }
}
