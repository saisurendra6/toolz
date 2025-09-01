class AppConstants {
  // App metadata
  static const String appName = 'toolZ';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Tools that make your life easier and more productive';

  // Database
  static const String notificationsDatabaseName = 'notifications.db';
  static const int notificationsDatabaseVersion = 1;

  // Pagination
  static const int defaultPageSize = 50;
  static const int maxPageSize = 100;

  // Cache
  static const Duration cacheTimeout = Duration(minutes: 5);
  static const int maxCacheSize = 1000;

  // Cleanup
  static const int defaultCleanupDays = 30;
  static const int maxCleanupDays = 365;

  // UI
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration debounceDelay = Duration(milliseconds: 300);

  // Notification channels (if using local notifications)
  static const String defaultChannelId = 'default_channel';
  static const String defaultChannelName = 'Default Notifications';

  // SharedPreferences keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyThemeColor = 'theme_color';
  static const String keyFirstLaunch = 'first_launch';
  static const String keyLastCleanup = 'last_cleanup';
  static const String keyNotificationPermissionAsked =
      'notification_permission_asked';
}
