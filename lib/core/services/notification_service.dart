import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../../models/notification_model.dart';

class NotificationService {
  // Private constructor for singleton pattern
  NotificationService._();

  // Singleton instance
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  // Method channel for Android communication
  static const _channel = MethodChannel("com.example.toolz/notification_db");

  // Cache for better performance
  static final Map<String, dynamic> _cache = {};
  static DateTime? _lastCacheUpdate;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  // Debug mode
  static const bool _isDebug = kDebugMode;

  /// Initialize the notification service
  static Future<void> initialize() async {
    try {
      if (_isDebug) log("NotificationService: Initializing...");

      // Test connection to native service
      final dbPath = await getDbPath();
      if (_isDebug) log("NotificationService: Connected to DB at $dbPath");

      // Check permissions
      final hasPermission = await checkNotificationPermission();
      if (_isDebug) {
        log("NotificationService: Permission status = $hasPermission");
      }
    } catch (e) {
      if (_isDebug) log("NotificationService: Initialization failed - $e");
      rethrow;
    }
  }

  // MARK: - Core Notification Operations

  /// Get notifications with pagination
  /// [limit] - Maximum number of notifications to fetch (default: 50)
  /// [offset] - Number of notifications to skip (for pagination)
  /// [useCache] - Whether to use cached results for better performance
  static Future<List<NotificationModel>> getNotifications({
    int limit = 50,
    int offset = 0,
    bool useCache = false,
  }) async {
    try {
      if (_isDebug) {
        log("NotificationService: Fetching notifications (limit: $limit, offset: $offset)");
      }

      // Check cache first if enabled
      final cacheKey = 'notifications_${limit}_$offset';
      if (useCache && _isCacheValid() && _cache.containsKey(cacheKey)) {
        if (_isDebug) {
          log("NotificationService: Returning cached notifications");
        }
        return _cache[cacheKey] as List<NotificationModel>;
      }

      final result = await _channel.invokeMethod('getNotifications', {
        'limit': limit,
        'offset': offset,
      });

      if (result == null) {
        if (_isDebug) log("NotificationService: Received null result");
        return [];
      }

      final List<dynamic> rawList = result as List<dynamic>;
      final List<NotificationModel> notifications = rawList
          .map((item) => NotificationModel.fromMap(_safeCastToMap(item)))
          .toList();

      // Cache the results
      if (useCache) {
        _cache[cacheKey] = notifications;
        _lastCacheUpdate = DateTime.now();
      }

      if (_isDebug) {
        log("NotificationService: Successfully fetched ${notifications.length} notifications");
      }

      return notifications;
    } catch (e) {
      if (_isDebug) {
        log("NotificationService: Error fetching notifications - $e");
      }
      throw NotificationServiceException('Failed to fetch notifications', e);
    }
  }

  /// Search notifications by query
  /// [query] - Search term to look for in title, text, and app name
  /// [limit] - Maximum number of results (default: 100)
  static Future<List<NotificationModel>> searchNotifications(
    String query, {
    int limit = 100,
  }) async {
    try {
      if (query.trim().isEmpty) return [];

      if (_isDebug) {
        log("NotificationService: Searching notifications for '$query'");
      }

      final result = await _channel.invokeMethod('searchNotifications', {
        'query': query.trim(),
        'limit': limit,
      });

      if (result == null) return [];

      final List<dynamic> rawList = result as List<dynamic>;
      final List<NotificationModel> notifications = rawList
          .map((item) => NotificationModel.fromMap(_safeCastToMap(item)))
          .toList();

      if (_isDebug) {
        log("NotificationService: Found ${notifications.length} matching notifications");
      }

      return notifications;
    } catch (e) {
      if (_isDebug) log("NotificationService: Search failed - $e");
      throw NotificationServiceException('Search failed', e);
    }
  }

  /// Delete a specific notification
  /// [id] - The notification ID to delete
  /// Returns true if successfully deleted
  static Future<bool> deleteNotification(int id) async {
    try {
      if (_isDebug) log("NotificationService: Deleting notification $id");

      final result = await _channel.invokeMethod('deleteNotification', {
        'id': id,
      });

      if (result is Map<String, dynamic>) {
        final success = result['success'] as bool? ?? false;
        if (success) {
          _invalidateCache(); // Clear cache after deletion
          if (_isDebug) {
            log("NotificationService: Successfully deleted notification $id");
          }
        }
        return success;
      }

      return false;
    } catch (e) {
      if (_isDebug) {
        log("NotificationService: Failed to delete notification $id - $e");
      }
      throw NotificationServiceException('Failed to delete notification', e);
    }
  }

  /// Clear all notifications
  /// Returns the number of notifications deleted
  static Future<int> clearAllNotifications() async {
    try {
      if (_isDebug) log("NotificationService: Clearing all notifications");

      final result = await _channel.invokeMethod('clearNotifications');

      if (result is Map<String, dynamic>) {
        final deletedCount = result['deleted_count'] as int? ?? 0;
        _invalidateCache(); // Clear cache after clearing all

        if (_isDebug) {
          log("NotificationService: Successfully cleared $deletedCount notifications");
        }

        return deletedCount;
      }

      return 0;
    } catch (e) {
      if (_isDebug) {
        log("NotificationService: Failed to clear notifications - $e");
      }
      throw NotificationServiceException('Failed to clear notifications', e);
    }
  }

  /// Get total notification count
  static Future<int> getNotificationCount() async {
    try {
      final result = await _channel.invokeMethod('getNotificationCount');
      final count = (result as num?)?.toInt() ?? 0;

      if (_isDebug) log("NotificationService: Total notifications: $count");
      return count;
    } catch (e) {
      if (_isDebug) log("NotificationService: Failed to get count - $e");
      throw NotificationServiceException('Failed to get notification count', e);
    }
  }

  // MARK: - Cleanup Operations

  /// Delete notifications older than specified days
  /// [days] - Number of days to keep (default: 30)
  /// Returns a map with deletion details
  static Future<Map<String, dynamic>> deleteOldNotifications(
      {int days = 30}) async {
    try {
      if (_isDebug) {
        log("NotificationService: Deleting notifications older than $days days");
      }

      final result = await _channel.invokeMethod('deleteOldNotifications', {
        'days': days,
      });

      if (result is Map<String, dynamic>) {
        _invalidateCache(); // Clear cache after cleanup

        if (_isDebug) {
          log("NotificationService: Cleanup completed - ${result['deleted_count']} deleted");
        }

        return Map<String, dynamic>.from(result);
      }

      return {'deleted_count': 0, 'days': days};
    } catch (e) {
      if (_isDebug) log("NotificationService: Cleanup failed - $e");
      throw NotificationServiceException(
          'Failed to delete old notifications', e);
    }
  }

  /// Get count of notifications older than specified days
  /// [days] - Number of days threshold
  static Future<int> getOldNotificationsCount({int days = 30}) async {
    try {
      final result = await _channel.invokeMethod('getOldNotificationsCount', {
        'days': days,
      });

      if (result is Map<String, dynamic>) {
        final count = result['count'] as int? ?? 0;
        if (_isDebug) {
          log("NotificationService: Found $count notifications older than $days days");
        }
        return count;
      }

      return 0;
    } catch (e) {
      if (_isDebug) {
        log("NotificationService: Failed to count old notifications - $e");
      }
      throw NotificationServiceException(
          'Failed to count old notifications', e);
    }
  }

  // MARK: - Permission Management

  /// Check if notification listener permission is granted
  static Future<bool> checkNotificationPermission() async {
    try {
      final result = await _channel.invokeMethod('checkNotificationPermission');
      final hasPermission = result as bool? ?? false;

      if (_isDebug) {
        log("NotificationService: Permission status = $hasPermission");
      }

      return hasPermission;
    } catch (e) {
      if (_isDebug) log("NotificationService: Permission check failed - $e");
      return false;
    }
  }

  /// Request notification listener permission (opens system settings)
  static Future<bool> requestNotificationPermission() async {
    try {
      if (_isDebug) {
        log("NotificationService: Requesting notification permission");
      }

      final result =
          await _channel.invokeMethod('requestNotificationPermission');
      return result as bool? ?? false;
    } catch (e) {
      if (_isDebug) {
        log("NotificationService: Permission request failed - $e");
      }
      throw NotificationServiceException('Failed to request permission', e);
    }
  }

  // MARK: - Database Operations

  /// Get database file path (for debugging)
  static Future<String> getDbPath() async {
    try {
      final result = await _channel.invokeMethod('getDbPath');
      return result as String? ?? '';
    } catch (e) {
      if (_isDebug) log("NotificationService: Failed to get DB path - $e");
      return '';
    }
  }

  /// Optimize database for better performance
  static Future<bool> optimizeDatabase() async {
    try {
      if (_isDebug) log("NotificationService: Optimizing database");

      final result = await _channel.invokeMethod('optimizeDatabase');
      final success = result as bool? ?? false;

      if (success) {
        _invalidateCache(); // Clear cache after optimization
        if (_isDebug) {
          log("NotificationService: Database optimization completed");
        }
      }

      return success;
    } catch (e) {
      if (_isDebug) {
        log("NotificationService: Database optimization failed - $e");
      }
      throw NotificationServiceException('Database optimization failed', e);
    }
  }

  // MARK: - Statistics and Analytics

  /// Get notification statistics grouped by app
  static Future<Map<String, int>> getNotificationStatsByApp() async {
    try {
      // This would require additional method in MainActivity
      // For now, we'll analyze the current notifications
      final notifications = await getNotifications(limit: 1000);
      final Map<String, int> stats = {};

      for (final notification in notifications) {
        stats[notification.appName] = (stats[notification.appName] ?? 0) + 1;
      }

      // Sort by count descending
      final sortedStats = Map<String, int>.fromEntries(
        stats.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
      );

      if (_isDebug) {
        log("NotificationService: Generated stats for ${sortedStats.length} apps");
      }

      return sortedStats;
    } catch (e) {
      if (_isDebug) log("NotificationService: Failed to get stats - $e");
      return {};
    }
  }

  /// Get notifications from the last N days
  static Future<List<NotificationModel>> getRecentNotifications({
    int days = 7,
    int limit = 100,
  }) async {
    try {
      final cutoffTime =
          DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;

      final allNotifications = await getNotifications(limit: limit * 2);
      final recentNotifications = allNotifications
          .where((n) => n.postTime >= cutoffTime)
          .take(limit)
          .toList();

      if (_isDebug) {
        log("NotificationService: Found ${recentNotifications.length} notifications from last $days days");
      }

      return recentNotifications;
    } catch (e) {
      if (_isDebug) {
        log("NotificationService: Failed to get recent notifications - $e");
      }
      throw NotificationServiceException(
          'Failed to get recent notifications', e);
    }
  }

  // MARK: - Cache Management

  /// Clear internal cache
  static void clearCache() {
    _cache.clear();
    _lastCacheUpdate = null;
    if (_isDebug) log("NotificationService: Cache cleared");
  }

  /// Check if cache is still valid
  static bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheTimeout;
  }

  /// Invalidate cache (mark as expired)
  static void _invalidateCache() {
    _lastCacheUpdate = null;
  }

  // MARK: - Helper Methods

  /// Safely cast dynamic to Map<String, dynamic>
  static Map<String, dynamic> _safeCastToMap(dynamic item) {
    if (item is Map<String, dynamic>) {
      return item;
    } else if (item is Map) {
      return Map<String, dynamic>.from(item);
    } else {
      if (_isDebug) {
        log("NotificationService: Warning - Unable to cast to Map: $item");
      }
      return {};
    }
  }
}

// MARK: - Custom Exception Class

/// Custom exception for NotificationService errors
class NotificationServiceException implements Exception {
  final String message;
  final dynamic originalError;

  const NotificationServiceException(this.message, [this.originalError]);

  @override
  String toString() {
    if (originalError != null) {
      return 'NotificationServiceException: $message\nCaused by: $originalError';
    }
    return 'NotificationServiceException: $message';
  }
}

// MARK: - Service Configuration

/// Configuration class for NotificationService
class NotificationServiceConfig {
  final Duration cacheTimeout;
  final bool enableDebugLogs;
  final int defaultPageSize;
  final int maxCacheSize;

  const NotificationServiceConfig({
    this.cacheTimeout = const Duration(minutes: 5),
    this.enableDebugLogs = kDebugMode,
    this.defaultPageSize = 50,
    this.maxCacheSize = 1000,
  });
}

// MARK: - Notification Filter

/// Filter class for advanced notification querying
class NotificationFilter {
  final String? appName;
  final NotificationPriority? priority;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? isClearable;
  final String? channelId;

  const NotificationFilter({
    this.appName,
    this.priority,
    this.startDate,
    this.endDate,
    this.isClearable,
    this.channelId,
  });

  Map<String, dynamic> toMap() {
    return {
      if (appName != null) 'app_name': appName,
      if (priority != null) 'priority': priority!.value,
      if (startDate != null) 'start_date': startDate!.millisecondsSinceEpoch,
      if (endDate != null) 'end_date': endDate!.millisecondsSinceEpoch,
      if (isClearable != null) 'is_clearable': isClearable,
      if (channelId != null) 'channel_id': channelId,
    };
  }
}
