import 'package:flutter/material.dart';
import 'package:toolz/core/services/notification_service.dart';
import 'dart:async';

import 'package:toolz/models/notification_model.dart';
import 'package:toolz/presentation/widgets/notification_card.dart';

class NotificationsHistoryScreen extends StatefulWidget {
  const NotificationsHistoryScreen({super.key});

  @override
  State<NotificationsHistoryScreen> createState() =>
      _NotificationsHistoryScreenState();
}

class _NotificationsHistoryScreenState extends State<NotificationsHistoryScreen>
    with TickerProviderStateMixin {
  // State management
  List<NotificationModel> _notifications = [];
  List<NotificationModel> _filteredNotifications = [];
  final Set<int> _selectedNotifications = {};

  // Loading and error states
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  String? _errorMessage;

  // Pagination
  int _currentPage = 0;
  final int _pageSize = 50;
  bool _hasMoreData = true;

  // Search and filter
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedApp;
  NotificationPriority? _selectedPriority;
  Timer? _searchDebouncer;

  // UI state
  final ScrollController _scrollController = ScrollController();
  bool _isSelectionMode = false;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupScrollListener();
    _loadNotifications();
  }

  void _initializeAnimations() {
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreNotifications();
      }
    });
  }

  // Data loading methods
  Future<void> _loadNotifications({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 0;
        _hasMoreData = true;
        _notifications.clear();
        _filteredNotifications.clear();
      });
    }

    setState(() {
      _isLoading = refresh || _notifications.isEmpty;
      _hasError = false;
    });

    try {
      final notifications = await NotificationService.getNotifications(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      setState(() {
        if (refresh) {
          _notifications = notifications;
        } else {
          _notifications.addAll(notifications);
        }
        _hasMoreData = notifications.length == _pageSize;
        _currentPage++;
        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load notifications: ${e.toString()}';
      });
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() => _isLoadingMore = true);

    try {
      final newNotifications = await NotificationService.getNotifications(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      setState(() {
        _notifications.addAll(newNotifications);
        _hasMoreData = newNotifications.length == _pageSize;
        _currentPage++;
        _isLoadingMore = false;
      });

      _applyFilters();
    } catch (e) {
      setState(() => _isLoadingMore = false);
      _showErrorSnackBar('Failed to load more notifications');
    }
  }

  // Search and filter methods
  void _onSearchChanged(String query) {
    _searchDebouncer?.cancel();
    _searchDebouncer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query.toLowerCase();
      });
      _performSearch();
    });
  }

  Future<void> _performSearch() async {
    if (_searchQuery.isEmpty) {
      _applyFilters();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final searchResults =
          await NotificationService.searchNotifications(_searchQuery);
      setState(() {
        _notifications = searchResults;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Search failed');
    }
  }

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

    // Search filter (if not already searched)
    if (_searchQuery.isNotEmpty && _notifications.isNotEmpty) {
      filtered = filtered
          .where((n) =>
              n.displayTitle.toLowerCase().contains(_searchQuery) ||
              n.displayText.toLowerCase().contains(_searchQuery) ||
              n.appName.toLowerCase().contains(_searchQuery))
          .toList();
    }

    setState(() {
      _filteredNotifications = filtered;
    });
  }

  // Selection methods
  void _toggleSelection(NotificationModel notification) {
    setState(() {
      if (_selectedNotifications.contains(notification.id)) {
        _selectedNotifications.remove(notification.id);
      } else {
        _selectedNotifications.add(notification.id);
      }

      _isSelectionMode = _selectedNotifications.isNotEmpty;

      if (_isSelectionMode) {
        _fabAnimationController.forward();
      } else {
        _fabAnimationController.reverse();
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedNotifications.addAll(_filteredNotifications.map((n) => n.id));
      _isSelectionMode = true;
      _fabAnimationController.forward();
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedNotifications.clear();
      _isSelectionMode = false;
      _fabAnimationController.reverse();
    });
  }

  // Action methods
  Future<void> _deleteSelected() async {
    if (_selectedNotifications.isEmpty) return;

    final confirmed = await _showConfirmationDialog(
      'Delete Notifications',
      'Delete ${_selectedNotifications.length} selected notifications?',
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      try {
        for (int id in _selectedNotifications) {
          await NotificationService.deleteNotification(id);
        }

        setState(() {
          _notifications
              .removeWhere((n) => _selectedNotifications.contains(n.id));
          _selectedNotifications.clear();
          _isSelectionMode = false;
          _isLoading = false;
        });

        _applyFilters();
        _fabAnimationController.reverse();
        _showSuccessSnackBar(
            '${_selectedNotifications.length} notifications deleted');
      } catch (e) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to delete notifications');
      }
    }
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    try {
      await NotificationService.deleteNotification(notification.id);
      setState(() {
        _notifications.removeWhere((n) => n.id == notification.id);
      });
      _applyFilters();
      _showSuccessSnackBar('Notification deleted');
    } catch (e) {
      _showErrorSnackBar('Failed to delete notification');
    }
  }

  Future<void> _clearAllNotifications() async {
    final confirmed = await _showConfirmationDialog(
      'Clear All Notifications',
      'This will permanently delete all notifications. Continue?',
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      try {
        await NotificationService.clearAllNotifications();
        setState(() {
          _notifications.clear();
          _filteredNotifications.clear();
          _selectedNotifications.clear();
          _isSelectionMode = false;
          _isLoading = false;
        });
        _fabAnimationController.reverse();
        _showSuccessSnackBar('All notifications cleared');
      } catch (e) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to clear notifications');
      }
    }
  }

  Future<void> _performCleanup() async {
    await _showCleanupBottomSheet();
  }

  // UI helper methods
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () => _loadNotifications(refresh: true),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<bool?> _showConfirmationDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: _isSelectionMode
          ? Text('${_selectedNotifications.length} selected')
          : const Text('Notifications'),
      leading: _isSelectionMode
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearSelection,
            )
          : null,
      actions: _buildAppBarActions(),
      bottom: _buildSearchBar(),
    );
  }

  List<Widget> _buildAppBarActions() {
    if (_isSelectionMode) {
      return [
        IconButton(
          icon: const Icon(Icons.select_all),
          onPressed: _selectAll,
          tooltip: 'Select all',
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: _deleteSelected,
          tooltip: 'Delete selected',
        ),
      ];
    }

    return [
      IconButton(
        icon: const Icon(Icons.filter_list),
        onPressed: _showFilterBottomSheet,
        tooltip: 'Filter',
      ),
      IconButton(
        icon: const Icon(Icons.cleaning_services),
        onPressed: _performCleanup,
        tooltip: 'Cleanup',
      ),
      PopupMenuButton<String>(
        onSelected: _handleMenuAction,
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'refresh', child: Text('Refresh')),
          const PopupMenuItem(value: 'clear_all', child: Text('Clear All')),
          const PopupMenuItem(value: 'settings', child: Text('Settings')),
        ],
      ),
    ];
  }

  PreferredSizeWidget _buildSearchBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search notifications...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return _buildErrorWidget();
    }

    if (_filteredNotifications.isEmpty) {
      return _buildEmptyWidget();
    }

    return RefreshIndicator(
      onRefresh: () => _loadNotifications(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _filteredNotifications.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _filteredNotifications.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final notification = _filteredNotifications[index];
          final isSelected = _selectedNotifications.contains(notification.id);

          if (_isSelectionMode) {
            return SelectableNotificationCard(
              notification: notification,
              isSelected: isSelected,
              onSelectionChanged: (selected) => _toggleSelection(notification),
              onTap: () => _navigateToDetail(notification),
            );
          }

          return NotificationCard(
            notification: notification,
            onTap: () => _navigateToDetail(notification),
            onLongPress: () => _toggleSelection(notification),
            onDelete: () => _deleteNotification(notification),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error occurred',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => _loadNotifications(refresh: true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _selectedApp != null
                ? 'No notifications found'
                : 'No notifications yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedApp != null
                ? 'Try adjusting your search or filters'
                : 'Notifications will appear here when received',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty || _selectedApp != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedApp = null;
                  _selectedPriority = null;
                });
                _applyFilters();
              },
              child: const Text('Clear filters'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: _fabAnimation,
      child: FloatingActionButton.extended(
        onPressed: _deleteSelected,
        icon: const Icon(Icons.delete),
        label: Text('Delete (${_selectedNotifications.length})'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  // Navigation and other methods
  void _navigateToDetail(NotificationModel notification) {
    Navigator.pushNamed(
      context,
      '/notification_detail',
      arguments: notification,
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'refresh':
        _loadNotifications(refresh: true);
        break;
      case 'clear_all':
        _clearAllNotifications();
        break;
      case 'settings':
        Navigator.pushNamed(context, '/settings');
        break;
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => FilterBottomSheet(
        selectedApp: _selectedApp,
        selectedPriority: _selectedPriority,
        availableApps: _notifications.map((n) => n.appName).toSet().toList(),
        onApplyFilters: (app, priority) {
          setState(() {
            _selectedApp = app;
            _selectedPriority = priority;
          });
          _applyFilters();
        },
      ),
    );
  }

  Future<void> _showCleanupBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => CleanupBottomSheet(
        onCleanup: (days) async {
          try {
            final result =
                await NotificationService.deleteOldNotifications(days: days);
            _showSuccessSnackBar(
                'Deleted ${result['deleted_count']} old notifications');
            _loadNotifications(refresh: true);
          } catch (e) {
            _showErrorSnackBar('Cleanup failed');
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebouncer?.cancel();
    _fabAnimationController.dispose();
    super.dispose();
  }
}

// Filter Bottom Sheet Widget
class FilterBottomSheet extends StatefulWidget {
  final String? selectedApp;
  final NotificationPriority? selectedPriority;
  final List<String> availableApps;
  final Function(String?, NotificationPriority?) onApplyFilters;

  const FilterBottomSheet({
    super.key,
    required this.selectedApp,
    required this.selectedPriority,
    required this.availableApps,
    required this.onApplyFilters,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String? _tempSelectedApp;
  NotificationPriority? _tempSelectedPriority;

  @override
  void initState() {
    super.initState();
    _tempSelectedApp = widget.selectedApp;
    _tempSelectedPriority = widget.selectedPriority;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Notifications',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),

          // App Filter
          Text('By App', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _tempSelectedApp,
            decoration: const InputDecoration(
              hintText: 'Select app',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String>(
                  value: null, child: Text('All Apps')),
              ...widget.availableApps.map((app) =>
                  DropdownMenuItem<String>(value: app, child: Text(app))),
            ],
            onChanged: (value) => setState(() => _tempSelectedApp = value),
          ),

          const SizedBox(height: 16),

          // Priority Filter
          Text('By Priority', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<NotificationPriority>(
            value: _tempSelectedPriority,
            decoration: const InputDecoration(
              hintText: 'Select priority',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<NotificationPriority>(
                  value: null, child: Text('All Priorities')),
              ...NotificationPriority.values.map((priority) =>
                  DropdownMenuItem<NotificationPriority>(
                      value: priority, child: Text(priority.label))),
            ],
            onChanged: (value) => setState(() => _tempSelectedPriority = value),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _tempSelectedApp = null;
                    _tempSelectedPriority = null;
                  });
                },
                child: const Text('Clear'),
              ),
              FilledButton(
                onPressed: () {
                  widget.onApplyFilters(
                      _tempSelectedApp, _tempSelectedPriority);
                  Navigator.pop(context);
                },
                child: const Text('Apply'),
              ),
            ],
          ),

          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}

// Cleanup Bottom Sheet Widget
class CleanupBottomSheet extends StatefulWidget {
  final Function(int) onCleanup;

  const CleanupBottomSheet({super.key, required this.onCleanup});

  @override
  State<CleanupBottomSheet> createState() => _CleanupBottomSheetState();
}

class _CleanupBottomSheetState extends State<CleanupBottomSheet> {
  int _selectedDays = 30;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Cleanup Old Notifications',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          const Text('Delete notifications older than:'),
          Slider(
            value: _selectedDays.toDouble(),
            min: 7,
            max: 90,
            divisions: 11,
            label: '$_selectedDays days',
            onChanged: (value) => setState(() => _selectedDays = value.round()),
          ),
          Text(
            '$_selectedDays days',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onCleanup(_selectedDays);
                },
                child: const Text('Clean Up'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
