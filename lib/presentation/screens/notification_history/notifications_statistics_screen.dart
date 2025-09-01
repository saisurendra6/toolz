import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../core/services/notification_service.dart';
import '../../../models/notification_model.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with TickerProviderStateMixin {
  // State management
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  // Statistics data
  int _totalNotifications = 0;
  int _totalApps = 0;
  Map<String, int> _appStats = {};
  List<DailyStats> _dailyStats = [];
  List<PriorityStats> _priorityStats = [];

  // Time period selection
  StatsPeriod _selectedPeriod = StatsPeriod.week;

  // Animation controllers
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadStatistics();
  }

  void _setupAnimations() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Load data in parallel for better performance
      final futures = await Future.wait([
        NotificationService.getNotificationCount(),
        NotificationService.getNotificationStatsByApp(),
        _getDailyStatistics(),
        _getPriorityStatistics(),
      ]);

      if (mounted) {
        setState(() {
          _totalNotifications = futures[0] as int;
          _appStats = futures[1] as Map<String, int>;
          _dailyStats = futures[2] as List<DailyStats>;
          _priorityStats = futures[3] as List<PriorityStats>;
          _totalApps = _appStats.length;
          _isLoading = false;
        });

        // Start animations
        _fadeAnimationController.forward();
        _slideAnimationController.forward();
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

  Future<List<DailyStats>> _getDailyStatistics() async {
    try {
      final List<DailyStats> stats = [];
      final now = DateTime.now();

      // Get data for the selected period
      int days = _selectedPeriod == StatsPeriod.week
          ? 7
          : _selectedPeriod == StatsPeriod.month
              ? 30
              : 90;

      for (int i = days - 1; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        // In a real implementation, you'd query the database for this specific day
        // For now, we'll simulate data
        final count = math.Random().nextInt(30) + 5;

        stats.add(DailyStats(
          date: startOfDay,
          count: count,
        ));
      }

      return stats;
    } catch (e) {
      return [];
    }
  }

  Future<List<PriorityStats>> _getPriorityStatistics() async {
    try {
      // Simulate priority distribution
      return [
        PriorityStats(NotificationPriority.max, 15, Colors.red),
        PriorityStats(NotificationPriority.high, 45, Colors.orange),
        PriorityStats(NotificationPriority.normal, 120, Colors.blue),
        PriorityStats(NotificationPriority.low, 35, Colors.green),
        PriorityStats(NotificationPriority.min, 8, Colors.grey),
      ];
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
            tooltip: 'Refresh statistics',
          ),
          PopupMenuButton<StatsPeriod>(
            icon: const Icon(Icons.calendar_month),
            onSelected: (period) {
              setState(() {
                _selectedPeriod = period;
              });
              _loadStatistics();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: StatsPeriod.week, child: Text('Last Week')),
              const PopupMenuItem(
                  value: StatsPeriod.month, child: Text('Last Month')),
              const PopupMenuItem(
                  value: StatsPeriod.quarter, child: Text('Last Quarter')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStatistics,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_hasError) {
      return _buildErrorWidget();
    }

    if (_totalNotifications == 0) {
      return _buildEmptyWidget();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSummaryCards(),
              const SizedBox(height: 24),
              _buildAppDistributionChart(),
              const SizedBox(height: 24),
              _buildTimelineChart(),
              const SizedBox(height: 24),
              _buildPriorityDistributionChart(),
              const SizedBox(height: 24),
              _buildInsightsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading statistics...'),
        ],
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
            'Failed to load statistics',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error occurred',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loadStatistics,
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
            Icons.bar_chart,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No statistics available',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Statistics will appear here when you have notifications',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Total',
            value: _totalNotifications.toString(),
            icon: Icons.notifications,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Apps',
            value: _totalApps.toString(),
            icon: Icons.apps,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Today',
            value: _dailyStats.isNotEmpty
                ? _dailyStats.last.count.toString()
                : '0',
            icon: Icons.today,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
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
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppDistributionChart() {
    if (_appStats.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Distribution',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(flex: 1, child: _buildPieChart()),
                  const SizedBox(width: 16),
                  Expanded(flex: 1, child: _buildAppLegend()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    final total = _appStats.values.fold(0, (sum, count) => sum + count);
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
    ];

    return CustomPaint(
      size: Size.infinite,
      painter: PieChartPainter(
        data: _appStats,
        colors: colors,
        total: total,
      ),
    );
  }

  Widget _buildAppLegend() {
    final sortedApps = _appStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedApps.take(7).toList().asMap().entries.map((entry) {
        final index = entry.key;
        final appEntry = entry.value;
        final percentage =
            (appEntry.value / _totalNotifications * 100).toStringAsFixed(1);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: colors[index % colors.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appEntry.key,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${appEntry.value} ($percentage%)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimelineChart() {
    if (_dailyStats.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Timeline',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: CustomPaint(
                size: Size.infinite,
                painter: LineChartPainter(
                  data: _dailyStats,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityDistributionChart() {
    if (_priorityStats.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Priority Distribution',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: CustomPaint(
                size: Size.infinite,
                painter: BarChartPainter(
                  data: _priorityStats,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsSection() {
    final insights = _generateInsights();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Insights',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...insights.map((insight) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.arrow_right,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(insight)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  List<String> _generateInsights() {
    final insights = <String>[];

    if (_appStats.isNotEmpty) {
      final topApp =
          _appStats.entries.reduce((a, b) => a.value > b.value ? a : b);
      insights
          .add('${topApp.key} sends the most notifications (${topApp.value})');

      final percentage =
          (topApp.value / _totalNotifications * 100).toStringAsFixed(0);
      insights.add('This represents $percentage% of all your notifications');
    }

    if (_dailyStats.length >= 2) {
      final recent = _dailyStats.sublist(_dailyStats.length - 2);
      final trend = recent[1].count - recent[0].count;
      if (trend > 0) {
        insights.add('Your notifications increased by $trend today');
      } else if (trend < 0) {
        insights.add('Your notifications decreased by ${trend.abs()} today');
      } else {
        insights.add('Your notification count remained stable today');
      }
    }

    final avgDaily = _totalNotifications / math.max(_dailyStats.length, 1);
    insights.add(
        'You receive an average of ${avgDaily.toStringAsFixed(0)} notifications per day');

    return insights;
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }
}

// Data models
class DailyStats {
  final DateTime date;
  final int count;

  DailyStats({required this.date, required this.count});
}

class PriorityStats {
  final NotificationPriority priority;
  final int count;
  final Color color;

  PriorityStats(this.priority, this.count, this.color);
}

enum StatsPeriod { week, month, quarter }

// Custom painters
class PieChartPainter extends CustomPainter {
  final Map<String, int> data;
  final List<Color> colors;
  final int total;

  PieChartPainter({
    required this.data,
    required this.colors,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;

    double startAngle = -math.pi / 2;

    final sortedData = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (int i = 0; i < sortedData.length && i < colors.length; i++) {
      final entry = sortedData[i];
      final sweepAngle = (entry.value / total) * 2 * math.pi;

      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class LineChartPainter extends CustomPainter {
  final List<DailyStats> data;
  final Color color;

  LineChartPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final maxCount = data.map((e) => e.count).reduce(math.max).toDouble();
    final path = Path();

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - (data[i].count / maxCount) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw points
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - (data[i].count / maxCount) * size.height;
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class BarChartPainter extends CustomPainter {
  final List<PriorityStats> data;

  BarChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxCount = data.map((e) => e.count).reduce(math.max).toDouble();
    final barWidth = size.width / data.length * 0.6;
    final barSpacing = size.width / data.length;

    for (int i = 0; i < data.length; i++) {
      final stat = data[i];
      final barHeight = (stat.count / maxCount) * size.height;

      final paint = Paint()
        ..color = stat.color
        ..style = PaintingStyle.fill;

      final rect = Rect.fromLTWH(
        i * barSpacing + (barSpacing - barWidth) / 2,
        size.height - barHeight,
        barWidth,
        barHeight,
      );

      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
