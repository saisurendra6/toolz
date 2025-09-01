import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/routes.dart';
import '../../../core/services/notification_service.dart';
import '../../../models/notification_model.dart';
import '../../widgets/notification_card.dart';
import 'dart:async';

class NotificationsHomeScreen extends StatefulWidget {
  const NotificationsHomeScreen({super.key});

  @override
  State<NotificationsHomeScreen> createState() =>
      _NotificationsHomeScreenState();
}

class _NotificationsHomeScreenState extends State<NotificationsHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _statsAnimationController;
  late Animation<double> _statsAnimation;

  // Data
  int _totalNotifications = 0;
  List<NotificationModel> _recentNotifications = [];
  Map<String, int> _appStats = {};

  // State
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  // Refresh
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadHomeData();
    _startPeriodicRefresh();
  }

  void _setupAnimations() {
    _statsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _statsAnimation = CurvedAnimation(
      parent: _statsAnimationController,
      curve: Curves.easeOutBack,
    );
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        _loadHomeData(silent: true);
      }
    });
  }

  Future<void> _loadHomeData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      // Load data in parallel
      final futures = await Future.wait([
        NotificationService.getNotificationCount(),
        NotificationService.getRecentNotifications(days: 7, limit: 10),
        NotificationService.getNotificationStatsByApp(),
      ]);

      if (mounted) {
        setState(() {
          _totalNotifications = futures[0] as int;
          _recentNotifications = futures[1] as List<NotificationModel>;
          _appStats = futures[2] as Map<String, int>;
          _isLoading = false;
        });

        // Start stats animation
        _statsAnimationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          if (_isLoading) _buildLoadingSliver(),
          if (_hasError) _buildErrorSliver(),
          if (!_isLoading && !_hasError) ...[
            _buildStatsSection(),
            _buildRecentNotificationsSection(),
            _buildTopAppsSection(),
            _buildQuickActionsSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Notification Saver',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primaryContainer,
              ],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.notifications_active,
              size: 80,
              color: Colors.white70,
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.notifications),
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.notificationsSettings),
        ),
      ],
    );
  }

  Widget _buildLoadingSliver() {
    return const SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildErrorSliver() {
    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load data',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Unknown error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _loadHomeData(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AnimatedBuilder(
          animation: _statsAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _statsAnimation.value,
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.notifications,
                      title: 'Total',
                      value: _totalNotifications.toString(),
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.today,
                      title: 'This Week',
                      value: _recentNotifications.length.toString(),
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.apps,
                      title: 'Apps',
                      value: _appStats.length.toString(),
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentNotificationsSection() {
    if (_recentNotifications.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Notifications',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.notifications),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...(_recentNotifications.take(5).map(
                  (notification) => CompactNotificationCard(
                    notification: notification,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.notificationDetail,
                      arguments: notification,
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppsSection() {
    final topApps = _appStats.entries.take(5).toList();

    if (topApps.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Apps',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...topApps
                .map((entry) => _buildAppStatItem(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppStatItem(String appName, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.apps,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              appName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.list,
                    title: 'View All',
                    subtitle: 'Browse notifications',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.notifications),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.analytics,
                    title: 'Statistics',
                    subtitle: 'View analytics',
                    onTap: () => Navigator.pushNamed(
                        context, AppRoutes.notificationsStatistics),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon,
                  size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _statsAnimationController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }
}
