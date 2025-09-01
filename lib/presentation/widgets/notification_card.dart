import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toolz/models/notification_model.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;
  final bool showAppIcon;
  final bool isCompact;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onLongPress,
    this.onDelete,
    this.showAppIcon = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        onLongPress: () {
          HapticFeedback.mediumImpact();
          onLongPress?.call();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // App Icon
                  if (showAppIcon) _buildAppIcon(colorScheme),
                  if (showAppIcon) const SizedBox(width: 12),

                  // App Name and Time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.appName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          notification.formattedTime,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Priority Indicator
                  if (notification.priority != 0)
                    _buildPriorityIndicator(colorScheme),

                  // Delete Button
                  if (onDelete != null) _buildDeleteButton(colorScheme),
                ],
              ),

              const SizedBox(height: 12),

              // Notification Content
              _buildContent(theme),

              // Channel and Group Info
              if (!isCompact) _buildMetadata(theme, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppIcon(ColorScheme colorScheme) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _getAppIcon(),
        size: 20,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildPriorityIndicator(ColorScheme colorScheme) {
    Color color;
    IconData icon;

    switch (notification.priorityLevel) {
      case NotificationPriority.max:
        color = Colors.red;
        icon = Icons.priority_high;
        break;
      case NotificationPriority.high:
        color = Colors.orange;
        icon = Icons.keyboard_arrow_up;
        break;
      case NotificationPriority.low:
        color = Colors.blue;
        icon = Icons.keyboard_arrow_down;
        break;
      case NotificationPriority.min:
        color = Colors.grey;
        icon = Icons.remove;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        icon,
        size: 16,
        color: color,
      ),
    );
  }

  Widget _buildDeleteButton(ColorScheme colorScheme) {
    return IconButton(
      icon: const Icon(Icons.delete_outline, size: 20),
      color: colorScheme.error,
      onPressed: () {
        HapticFeedback.lightImpact();
        onDelete?.call();
      },
      tooltip: 'Delete notification',
    );
  }

  Widget _buildContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        if (notification.title.isNotEmpty)
          Text(
            notification.displayTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: isCompact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
          ),

        if (notification.title.isNotEmpty &&
            notification.displayText.isNotEmpty)
          const SizedBox(height: 4),

        // Content Text
        if (notification.displayText.isNotEmpty)
          Text(
            notification.displayText,
            style: theme.textTheme.bodyMedium,
            maxLines: isCompact ? 2 : 4,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildMetadata(ThemeData theme, ColorScheme colorScheme) {
    final metadata = <String>[];

    if (notification.channelId?.isNotEmpty == true) {
      metadata.add('Channel: ${notification.channelId}');
    }

    if (notification.isGroupSummary) {
      metadata.add('Group Summary');
    }

    if (notification.groupName?.isNotEmpty == true) {
      metadata.add('Group: ${notification.groupName}');
    }

    if (!notification.isClearable) {
      metadata.add('Persistent');
    }

    if (metadata.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: metadata
            .map(
              (text) => Chip(
                label: Text(text),
                labelStyle: theme.textTheme.bodySmall,
                backgroundColor:
                    colorScheme.surfaceContainerHighest.withOpacity(0.5),
                side: BorderSide.none,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            )
            .toList(),
      ),
    );
  }

  IconData _getAppIcon() {
    // Map common app package names to icons
    final packageIconMap = {
      'whatsapp': Icons.chat,
      'instagram': Icons.camera_alt,
      'facebook': Icons.people,
      'twitter': Icons.alternate_email,
      'youtube': Icons.play_circle_outline,
      'gmail': Icons.email,
      'messages': Icons.sms,
      'phone': Icons.phone,
      'calendar': Icons.calendar_today,
      'chrome': Icons.web,
      'maps': Icons.map,
      'music': Icons.music_note,
      'camera': Icons.camera,
      'gallery': Icons.photo_library,
      'settings': Icons.settings,
      'clock': Icons.access_time,
      'weather': Icons.wb_sunny,
    };

    final packageLower = notification.packageName.toLowerCase();

    for (final entry in packageIconMap.entries) {
      if (packageLower.contains(entry.key)) {
        return entry.value;
      }
    }

    // Default icons based on app type
    if (packageLower.contains('com.android')) {
      return Icons.android;
    } else if (packageLower.contains('com.google')) {
      return Icons.apps;
    } else if (packageLower.contains('social') ||
        packageLower.contains('chat')) {
      return Icons.chat;
    } else if (packageLower.contains('media') ||
        packageLower.contains('player')) {
      return Icons.play_arrow;
    }

    return Icons.notifications;
  }
}

// Compact version for list views
class CompactNotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const CompactNotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationCard(
      notification: notification,
      onTap: onTap,
      onDelete: onDelete,
      isCompact: true,
      showAppIcon: false,
    );
  }
}

// Notification card with selection support
class SelectableNotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectionChanged;
  final VoidCallback? onTap;

  const SelectableNotificationCard({
    super.key,
    required this.notification,
    required this.isSelected,
    this.onSelectionChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isSelected ? 4 : 2,
      color: isSelected ? colorScheme.primaryContainer.withOpacity(0.3) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Selection Checkbox
            Padding(
              padding: const EdgeInsets.all(16),
              child: Checkbox(
                value: isSelected,
                onChanged: onSelectionChanged,
              ),
            ),

            // Notification Content
            Expanded(
              child: NotificationCard(
                notification: notification,
                onTap: onTap,
                showAppIcon: true,
                isCompact: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
