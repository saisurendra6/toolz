import 'dart:io';

import 'package:flutter/material.dart';
import 'package:toolz/presentation/screens/home_screen.dart';
import 'package:toolz/presentation/screens/whatsapp/whatsapp_permission_screen.dart';

import '../core/constants/app_constants.dart';
import '../models/notification_model.dart';
import '../presentation/screens/image_view_screen.dart';
import '../presentation/screens/notification_history/notifications_home_screen.dart';
import '../presentation/screens/not_found_screen.dart';
import '../presentation/screens/notification_history/notification_detail_screen.dart';
import '../presentation/screens/notification_history/notifications_history_screen.dart';
import '../presentation/screens/notification_history/notifications_permission_screen.dart';
import '../presentation/screens/notification_history/notifications_settings_screen.dart';
import '../presentation/screens/settings_screen.dart';
import '../presentation/screens/splash_screen.dart';
import '../presentation/screens/notification_history/notifications_statistics_screen.dart';
import '../presentation/screens/video_player_screen.dart';
import '../presentation/screens/whatsapp/whatsapp_screen.dart';

class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String home = '/home';
  static const String whatsappHome = '/whatsapp_home';
  static const String notificationsHome = '/notifications_home';
  static const appSettings = '/appSettings';

  static const String notifications = '/notifications';
  static const String notificationDetail = '/notification_detail';
  static const String notificationsPermission = '/notification_permission';
  static const String notificationsStatistics = '/notification_statistics';
  static const String notificationsSettings = '/notification_settings';
  static const String whatsappStatus = '/whatsapp_status';
  static const String whatsappContact = '/whatsapp_contact';
  static const String whatsappStatusPermission = '/whatsapp_status_permissions';

  static const String imageViewer = '/image_viewer';
  static const String videoPlayer = '/video_player';
}

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return _createRoute(const HomeScreen());
      case AppRoutes.splash:
        return _createRoute(const SplashScreen());
      case AppRoutes.notificationsHome:
        return _createRoute(const NotificationsHomeScreen());
      case AppRoutes.notifications:
        return _createRoute(const NotificationsHistoryScreen());
      case AppRoutes.notificationDetail:
        final notification = settings.arguments as NotificationModel?;
        return _createRoute(
            NotificationDetailScreen(notification: notification!));
      case AppRoutes.notificationsSettings:
        return _createRoute(const NotificationSettingsScreen());
      case AppRoutes.notificationsPermission:
        return _createRoute(const NotificationsPermissionScreen());
      case AppRoutes.notificationsStatistics:
        return _createRoute(const StatisticsScreen());
      case AppRoutes.whatsappHome || AppRoutes.whatsappStatus:
        return _createRoute(const WhatsappHomeScreen());
      case AppRoutes.whatsappStatusPermission:
        return _createRoute(const WhatsappStatusPermissionScreen());
      case AppRoutes.whatsappContact:
        return _createRoute(const WhatsappHomeScreen(initialIndex: 1));

      case AppRoutes.appSettings:
        return _createRoute(const AppSettingsScreen());

      case AppRoutes.imageViewer:
        final file = settings.arguments as File;
        return _createRoute(ImageViewerScreen(file: file));
      case AppRoutes.videoPlayer:
        final file = settings.arguments as File;
        return _createRoute(VideoPlayerScreen(file: file));

      default:
        return _createRoute(const NotFoundScreen());
    }
  }

  static Route<dynamic> _createRoute(Widget screen) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: AppConstants.animationDuration,
    );
  }
}
