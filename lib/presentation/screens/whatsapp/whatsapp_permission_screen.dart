import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:toolz/app/routes.dart';

class WhatsappStatusPermissionScreen extends StatefulWidget {
  const WhatsappStatusPermissionScreen({super.key});

  @override
  State<WhatsappStatusPermissionScreen> createState() =>
      _WhatsappStatusPermissionScreenState();
}

class _WhatsappStatusPermissionScreenState
    extends State<WhatsappStatusPermissionScreen>
    with TickerProviderStateMixin {
  bool _isCheckingPermissions = false;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _checkPermissionsOnInit();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissionsOnInit() async {
    // Check if permissions are already granted
    if (await _hasRequiredPermissions()) {
      // Navigate directly to status screen if permissions are granted
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.whatsappHome);
        }
      });
    }
  }

  Future<bool> _hasRequiredPermissions() async {
    if (Platform.isAndroid) {
      final storagePermission = await Permission.storage.status;
      final manageExternalStorage =
          await Permission.manageExternalStorage.status;

      return storagePermission.isGranted || manageExternalStorage.isGranted;
    }
    return true; // iOS doesn't need explicit storage permissions for app documents
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isCheckingPermissions = true;
    });

    try {
      if (Platform.isAndroid) {
        Map<Permission, PermissionStatus> permissions = {};

        // For Android 11+ (API 30+), request MANAGE_EXTERNAL_STORAGE
        if (await Permission.manageExternalStorage.status.isDenied) {
          permissions[Permission.manageExternalStorage] =
              await Permission.manageExternalStorage.request();
        }

        // Fallback to regular storage permission
        if (!permissions.containsValue(PermissionStatus.granted)) {
          permissions[Permission.storage] = await Permission.storage.request();
        }

        final hasPermission =
            permissions.values.any((status) => status.isGranted);

        if (hasPermission) {
          _navigateToStatusScreen();
        } else {
          _showPermissionDeniedDialog();
        }
      } else {
        // iOS - navigate directly as no explicit permission needed
        _navigateToStatusScreen();
      }
    } catch (e) {
      _showErrorDialog('Failed to request permissions: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingPermissions = false;
        });
      }
    }
  }

  void _navigateToStatusScreen() {
    Navigator.pushReplacementNamed(context, AppRoutes.whatsappStatus);
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Storage permission is required to access WhatsApp status files. '
          'Please grant the permission in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // WhatsApp icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.perm_media,
                    size: 60,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                  'Access WhatsApp Status',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Description
                Text(
                  'To view and save WhatsApp status files, we need permission to access your device storage.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Permission details card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.security,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'We only access WhatsApp status files',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.folder,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No other files or data will be accessed',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // Action buttons
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed:
                            _isCheckingPermissions ? null : _requestPermissions,
                        child: _isCheckingPermissions
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Checking permissions...'),
                                ],
                              )
                            : const Text('Grant Permission'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
