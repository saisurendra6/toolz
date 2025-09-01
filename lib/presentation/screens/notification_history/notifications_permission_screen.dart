import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/routes.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/app_logger.dart';
import 'dart:async';

class NotificationsPermissionScreen extends StatefulWidget {
  const NotificationsPermissionScreen({super.key});

  @override
  State<NotificationsPermissionScreen> createState() =>
      _NotificationsPermissionScreenState();
}

class _NotificationsPermissionScreenState
    extends State<NotificationsPermissionScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isLoading = false;
  bool _hasPermission = false;
  Timer? _permissionCheckTimer;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkInitialPermission();
    _startPermissionChecking();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
  }

  void _checkInitialPermission() async {
    try {
      final hasPermission =
          await NotificationService.checkNotificationPermission();

      if (mounted) {
        setState(() {
          _hasPermission = hasPermission;
        });

        if (hasPermission) {
          _navigateToNotificationHome();
        }
      }
    } catch (e) {
      AppLogger.error('Failed to check initial permission: $e');
    }
  }

  void _startPermissionChecking() {
    _permissionCheckTimer = Timer.periodic(
      const Duration(seconds: 2),
      (timer) async {
        try {
          final hasPermission =
              await NotificationService.checkNotificationPermission();

          if (mounted && hasPermission && !_hasPermission) {
            setState(() {
              _hasPermission = hasPermission;
            });

            await Future.delayed(const Duration(seconds: 1));
            _navigateToNotificationHome();
          }
        } catch (e) {
          AppLogger.error('Permission check failed: $e');
        }
      },
    );
  }

  void _navigateToNotificationHome() {
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.notificationsHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.primary.withOpacity(0.1),
                colorScheme.surface,
                colorScheme.primaryContainer.withOpacity(0.05),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Animated Icon
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: _hasPermission
                              ? Colors.green
                              : colorScheme.primary,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: (_hasPermission
                                      ? Colors.green
                                      : colorScheme.primary)
                                  .withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          _hasPermission
                              ? Icons.check
                              : Icons.notifications_off,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Title
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    _hasPermission
                        ? 'Permission Granted!'
                        : 'Notification Access Required',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color:
                          _hasPermission ? Colors.green : colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 16),

                // Description
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    _hasPermission
                        ? 'Great! Now you can save and manage all your notifications.'
                        : 'To save your notifications, we need permission to access notification history.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 48),

                // Permission steps or success message
                if (!_hasPermission) _buildPermissionSteps(theme),
                if (_hasPermission) _buildSuccessMessage(theme),

                const Spacer(),

                // Action buttons
                if (!_hasPermission) _buildActionButtons(theme),

                const SizedBox(height: 16),

                // Skip button
                if (!_hasPermission)
                  TextButton(
                    onPressed: _navigateToNotificationHome,
                    child: Text(
                      'Skip for now',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionSteps(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How to enable:',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStep(
              number: '1',
              title: 'Open Settings',
              description: 'Tap the button below to open system settings',
              theme: theme,
            ),
            _buildStep(
              number: '2',
              title: 'Find Notification Saver',
              description: 'Look for "Notification Saver" in the list',
              theme: theme,
            ),
            _buildStep(
              number: '3',
              title: 'Enable Permission',
              description: 'Toggle the switch to grant notification access',
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required String number,
    required String title,
    required String description,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage(ThemeData theme) {
    return Card(
      color: Colors.green.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All set!',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your notifications will now be automatically saved.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isLoading ? null : _openPermissionSettings,
            icon: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation(theme.colorScheme.onPrimary),
                    ),
                  )
                : const Icon(Icons.settings),
            label: Text(_isLoading ? 'Opening Settings...' : 'Open Settings'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _checkPermission,
            icon: const Icon(Icons.refresh),
            label: const Text('Check Permission'),
          ),
        ),
      ],
    );
  }

  Future<void> _openPermissionSettings() async {
    setState(() => _isLoading = true);

    try {
      await NotificationService.requestNotificationPermission();

      // Add haptic feedback
      HapticFeedback.lightImpact();

      // Show instruction snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enable Notification Saver in the settings'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      AppLogger.error('Failed to open permission settings: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to open settings'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkPermission() async {
    try {
      final hasPermission =
          await NotificationService.checkNotificationPermission();

      if (mounted) {
        setState(() {
          _hasPermission = hasPermission;
        });

        if (hasPermission) {
          // HapticFeedback.successImpact();
          await Future.delayed(const Duration(milliseconds: 1500));
          _navigateToNotificationHome();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission not granted yet'),
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Permission check failed: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _permissionCheckTimer?.cancel();
    super.dispose();
  }
}
