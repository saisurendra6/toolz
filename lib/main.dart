import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:toolz/app/routes.dart';
import 'package:toolz/core/utils/notification_initialize_services.dart';
import 'dart:async';

// Providers
import 'providers/theme_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/settings_provider.dart';

// Utils
import 'core/utils/app_logger.dart';
import 'core/constants/app_constants.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize app logger
  AppLogger.initialize(isDebug: true);
  AppLogger.info('🚀 Starting Notification Saver App');

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    AppLogger.error('💥 Flutter error: ${details.exception}');
    AppLogger.error('Stack trace: ${details.stack}');
  };

  // Configure system UI
  await _configureSystemUI();

  // Initialize core services
  await initializeServices();

  // Run app with error handling
  runZonedGuarded<Future<void>>(() async {
    runApp(const MyApp());
  }, _handleGlobalError);
}

/// Configure system UI appearance
Future<void> _configureSystemUI() async {
  try {
    AppLogger.info('🎨 Configuring system UI');

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    AppLogger.info('✅ System UI configured successfully');
  } catch (e) {
    AppLogger.error('❌ Failed to configure system UI: $e');
  }
}

/// Handle uncaught errors globally
void _handleGlobalError(Object error, StackTrace stack) {
  AppLogger.error('💥 Uncaught error: $error');
  AppLogger.error('Stack trace: $stack');

  // In production, you might want to send this to a crash reporting service
  // like Firebase Crashlytics or Sentry
}

/// Main application widget with provider setup
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    AppLogger.info('🏗️ Building main application widget');

    return MultiProvider(
      providers: _createProviders(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            // App metadata
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,

            // Theme configuration
            theme: themeProvider.currentTheme,
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

            // Navigation
            initialRoute: AppRoutes.splash,
            onGenerateRoute: RouteGenerator.generateRoute,

            // Global app configuration
            builder: (context, child) => _AppBuilder(child: child),

            // Error handling
            onUnknownRoute: (settings) => _createErrorRoute(settings),
          );
        },
      ),
    );
  }

  /// Create and configure all providers
  List<ChangeNotifierProvider> _createProviders() {
    AppLogger.info('🔗 Setting up providers');

    return [
      // Theme provider
      ChangeNotifierProvider<ThemeProvider>(
        create: (context) {
          final provider = ThemeProvider();
          provider.initialize();
          return provider;
        },
      ),

      // Notification provider
      ChangeNotifierProvider<NotificationProvider>(
        create: (context) => NotificationProvider(),
      ),

      // Settings provider
      ChangeNotifierProvider<SettingsProvider>(
        create: (context) {
          final provider = SettingsProvider();
          provider.initialize();
          return provider;
        },
      ),
    ];
  }

  /// Create error route for unknown routes
  Route<dynamic> _createErrorRoute(RouteSettings settings) {
    AppLogger.error('🚫 Unknown route: ${settings.name}');

    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
        body: Center(
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
                'Page Not Found',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'The requested page "${settings.name}" could not be found.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed(AppRoutes.home),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// App builder widget for global configuration
class _AppBuilder extends StatelessWidget {
  final Widget? child;

  const _AppBuilder({required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Dismiss keyboard when tapping outside
      onTap: () {
        final currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus &&
            currentFocus.focusedChild != null) {
          currentFocus.focusedChild!.unfocus();
        }
      },
      child: MediaQuery(
        // Ensure text scaling is within reasonable bounds
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.3)),
        ),
        child: child!,
      ),
    );
  }
}
