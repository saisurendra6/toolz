import 'dart:async';
import 'package:toolz/core/services/notification_service.dart';
import 'package:toolz/core/utils/app_logger.dart';

/// Initialize core application services
Future<void> initializeServices() async {
  try {
    AppLogger.info('🔧 Initializing core services');

    // Initialize notification service
    await NotificationService.initialize();
    AppLogger.info('✅ Notification service initialized');

    // Check notification permissions
    final hasPermission =
        await NotificationService.checkNotificationPermission();
    if (hasPermission) {
      AppLogger.info('✅ Notification permissions granted');
    } else {
      AppLogger.warning('⚠️ Notification permissions not granted');
    }

    // Get initial notification count for logging
    try {
      final count = await NotificationService.getNotificationCount();
      AppLogger.info('📊 Found $count notifications in database');
    } catch (e) {
      AppLogger.warning('⚠️ Could not get notification count: $e');
    }

    AppLogger.info('✅ All services initialized successfully');
  } catch (e) {
    AppLogger.error('❌ Failed to initialize services: $e');
    rethrow;
  }
}
