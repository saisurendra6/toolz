import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../core/services/notification_service.dart';
import '../core/utils/app_logger.dart';
import 'dart:math' as math;

class NotificationProvider extends ChangeNotifier {
  // Private fields
  List<NotificationModel> _notifications = [];
  List<NotificationModel> _filteredNotifications = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  // Pagination
  int _currentPage = 0;
  final int _pageSize = 50;
  bool _hasMoreData = true;

  // Filter state
  String _searchQuery = '';
  String? _selectedApp;
  NotificationPriority? _selectedPriority;

  // Statistics
  int _totalCount = 0;
  Map<String, int> _appStats = {};

  // Getters
  List<NotificationModel> get notifications => _filteredNotifications;
  List<NotificationModel> get allNotifications => _notifications;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  bool get hasMoreData => _hasMoreData;
  String get searchQuery => _searchQuery;
  String? get selectedApp => _selectedApp;
  NotificationPriority? get selectedPriority => _selectedPriority;
  int get totalCount => _totalCount;
  Map<String, int> get appStats => _appStats;
  bool get isEmpty => _filteredNotifications.isEmpty;
  bool get hasData => _filteredNotifications.isNotEmpty;

  /// Initialize provider and load initial data
  Future<void> initialize() async {
    AppLogger.info('📱 Initializing notification provider');
    await loadNotifications();
  }

  /// Load notifications with pagination
  Future<void> loadNotifications({bool refresh = false}) async {
    try {
      if (refresh) {
        _resetPagination();
      }

      _setLoading(true);
      _clearError();

      final notifications = await NotificationService.getNotifications(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
        useCache: !refresh,
      );

      if (refresh) {
        _notifications = notifications;
      } else {
        _notifications.addAll(notifications);
      }

      _hasMoreData = notifications.length == _pageSize;
      _currentPage++;

      await _loadStatistics();
      _applyFilters();

      AppLogger.info(
          '✅ Loaded ${notifications.length} notifications (total: ${_notifications.length})');
    } catch (e) {
      _setError('Failed to load notifications: $e');
      AppLogger.error('❌ Failed to load notifications: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load more notifications for infinite scroll
  Future<void> loadMoreNotifications() async {
    if (_isLoading || !_hasMoreData) return;

    try {
      _setLoading(true);

      final newNotifications = await NotificationService.getNotifications(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      _notifications.addAll(newNotifications);
      _hasMoreData = newNotifications.length == _pageSize;
      _currentPage++;

      _applyFilters();

      AppLogger.info('✅ Loaded ${newNotifications.length} more notifications');
    } catch (e) {
      _setError('Failed to load more notifications: $e');
      AppLogger.error('❌ Failed to load more notifications: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Search notifications
  Future<void> searchNotifications(String query) async {
    try {
      _searchQuery = query.trim();

      if (_searchQuery.isEmpty) {
        _applyFilters();
        return;
      }

      _setLoading(true);
      _clearError();

      final searchResults =
          await NotificationService.searchNotifications(_searchQuery);
      _notifications = searchResults;
      _resetPagination();

      _applyFilters();

      AppLogger.info(
          '🔍 Search completed: ${searchResults.length} results for "$_searchQuery"');
    } catch (e) {
      _setError('Search failed: $e');
      AppLogger.error('❌ Search failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Apply filters to notifications
  void _applyFilters() {
    List<NotificationModel> filtered = List.from(_notifications);

    // App filter
    if (_selectedApp != null) {
      filtered = filtered.where((n) => n.appName == _selectedApp).toList();
    }

    // Priority filter
    if (_selectedPriority != null) {
      filtered =
          filtered.where((n) => n.priorityLevel == _selectedPriority).toList();
    }

    // Search filter (for local search when not using search API)
    if (_searchQuery.isNotEmpty && _notifications.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((n) =>
              n.displayTitle.toLowerCase().contains(query) ||
              n.displayText.toLowerCase().contains(query) ||
              n.appName.toLowerCase().contains(query))
          .toList();
    }

    _filteredNotifications = filtered;
    notifyListeners();

    AppLogger.debug(
        '🔽 Filters applied: ${filtered.length}/${_notifications.length} notifications');
  }

  /// Set app filter
  void setAppFilter(String? appName) {
    _selectedApp = appName;
    _applyFilters();
    AppLogger.info('🎯 App filter set: $appName');
  }

  /// Set priority filter
  void setPriorityFilter(NotificationPriority? priority) {
    _selectedPriority = priority;
    _applyFilters();
    AppLogger.info('🎯 Priority filter set: ${priority?.label}');
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _selectedApp = null;
    _selectedPriority = null;
    _applyFilters();
    AppLogger.info('🧹 All filters cleared');
  }

  /// Delete a notification
  Future<bool> deleteNotification(int id) async {
    try {
      final success = await NotificationService.deleteNotification(id);

      if (success) {
        _notifications.removeWhere((n) => n.id == id);
        _totalCount = math.max(0, _totalCount - 1);

        notifyListeners();
        AppLogger.info('🗑️ Notification deleted: $id');
      }

      return success;
    } catch (e) {
      _setError('Failed to delete notification: $e');
      AppLogger.error('❌ Failed to delete notification: $e');
      return false;
    }
  }

  /// Delete multiple notifications
  Future<int> deleteMultipleNotifications(List<int> ids) async {
    int deletedCount = 0;

    try {
      for (int id in ids) {
        final success = await NotificationService.deleteNotification(id);
        if (success) {
          deletedCount++;
          _notifications.removeWhere((n) => n.id == id);
          _filteredNotifications.removeWhere((n) => n.id == id);
        }
      }
      _totalCount = math.max(0, _totalCount - deletedCount);

      if (deletedCount > 0) {
        notifyListeners();
        AppLogger.info('🗑️ Deleted $deletedCount notifications');
      }
    } catch (e) {
      _setError('Failed to delete notifications: $e');
      AppLogger.error('❌ Failed to delete multiple notifications: $e');
    }

    return deletedCount;
  }

  /// Clear all notifications
  Future<bool> clearAllNotifications() async {
    try {
      _setLoading(true);

      final deletedCount = await NotificationService.clearAllNotifications();

      _notifications.clear();
      _filteredNotifications.clear();
      _totalCount = 0;
      _appStats.clear();
      _resetPagination();

      notifyListeners();

      AppLogger.info('🧹 Cleared all notifications: $deletedCount deleted');
      return true;
    } catch (e) {
      _setError('Failed to clear notifications: $e');
      AppLogger.error('❌ Failed to clear all notifications: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Load statistics
  Future<void> _loadStatistics() async {
    try {
      final futures = await Future.wait([
        NotificationService.getNotificationCount(),
        NotificationService.getNotificationStatsByApp(),
      ]);

      _totalCount = futures[0] as int;
      _appStats = futures[1] as Map<String, int>;

      AppLogger.debug(
          '📊 Statistics loaded: $_totalCount total, ${_appStats.length} apps');
    } catch (e) {
      AppLogger.error('❌ Failed to load statistics: $e');
    }
  }

  /// Get recent notifications (last 7 days)
  Future<List<NotificationModel>> getRecentNotifications({int days = 7}) async {
    try {
      return await NotificationService.getRecentNotifications(days: days);
    } catch (e) {
      AppLogger.error('❌ Failed to get recent notifications: $e');
      return [];
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    AppLogger.info('🔄 Refreshing notification data');
    await loadNotifications(refresh: true);
  }

  /// Get notification by ID
  NotificationModel? getNotificationById(int id) {
    try {
      return _notifications.firstWhere((n) => n.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get notifications for specific app
  List<NotificationModel> getNotificationsByApp(String appName) {
    return _notifications.where((n) => n.appName == appName).toList();
  }

  /// Get available apps for filtering
  List<String> get availableApps {
    return _appStats.keys.toList()..sort();
  }

  /// Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _hasError = true;
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _hasError = false;
    _errorMessage = null;
  }

  void _resetPagination() {
    _currentPage = 0;
    _hasMoreData = true;
  }

  /// Cleanup method
  @override
  void dispose() {
    AppLogger.info('🧹 Disposing notification provider');
    super.dispose();
  }
}
