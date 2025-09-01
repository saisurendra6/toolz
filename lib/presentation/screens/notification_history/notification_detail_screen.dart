import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/notification_service.dart';
import '../../../models/notification_model.dart';

class NotificationDetailScreen extends StatefulWidget {
  final NotificationModel notification;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
  });

  @override
  State<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.notification.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyToClipboard,
            tooltip: 'Copy content',
          ),
          IconButton(
            icon: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete),
            onPressed: _isDeleting ? null : _deleteNotification,
            tooltip: 'Delete notification',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 24),
            _buildContent(theme),
            const SizedBox(height: 24),
            _buildMetadata(theme),
            const SizedBox(height: 24),
            _buildTechnicalDetails(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // App Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.notifications,
                size: 28,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),

            // App info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.notification.appName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.notification.detailedTime,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (widget.notification.priorityLevel !=
                      NotificationPriority.normal)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Chip(
                        label: Text(widget.notification.priorityLevel.label),
                        backgroundColor: _getPriorityColor().withOpacity(0.1),
                        side: BorderSide.none,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Content',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            if (widget.notification.title.isNotEmpty) ...[
              Text(
                'Title',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                widget.notification.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Text content
            if (widget.notification.text.isNotEmpty) ...[
              Text(
                'Text',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                widget.notification.text,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],

            // Big text (expanded content)
            if (widget.notification.textBig.isNotEmpty &&
                widget.notification.textBig != widget.notification.text) ...[
              Text(
                'Expanded Content',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: SelectableText(
                  widget.notification.textBig,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],

            // Empty state
            if (widget.notification.title.isEmpty &&
                widget.notification.text.isEmpty &&
                widget.notification.textBig.isEmpty) ...[
              Center(
                child: Text(
                  'No content available',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetadata(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
                'Channel', widget.notification.channelId ?? 'Default', theme),
            _buildDetailRow('Package', widget.notification.packageName, theme),
            _buildDetailRow(
                'Priority', widget.notification.priorityLevel.label, theme),
            _buildDetailRow('Clearable',
                widget.notification.isClearable ? 'Yes' : 'No', theme),
            if (widget.notification.groupKey?.isNotEmpty == true)
              _buildDetailRow(
                  'Group',
                  widget.notification.groupName ??
                      widget.notification.groupKey!,
                  theme),
            if (widget.notification.isGroupSummary)
              _buildDetailRow('Type', 'Group Summary', theme),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalDetails(ThemeData theme) {
    return Card(
      child: ExpansionTile(
        title: Text(
          'Technical Details',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow('ID', widget.notification.id.toString(), theme),
                _buildDetailRow(
                    'Notification ID',
                    widget.notification.notificationId?.toString() ?? 'None',
                    theme),
                _buildDetailRow('Post Time',
                    widget.notification.postTime.toString(), theme),
                _buildDetailRow('Notification Key',
                    widget.notification.notificationKey ?? 'None', theme),
                if (widget.notification.groupKey?.isNotEmpty == true)
                  _buildDetailRow(
                      'Group Key', widget.notification.groupKey!, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor() {
    switch (widget.notification.priorityLevel) {
      case NotificationPriority.max:
        return Colors.red;
      case NotificationPriority.high:
        return Colors.orange;
      case NotificationPriority.low:
        return Colors.blue;
      case NotificationPriority.min:
        return Colors.grey;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  void _copyToClipboard() {
    final content = [
      'App: ${widget.notification.appName}',
      'Time: ${widget.notification.detailedTime}',
      if (widget.notification.title.isNotEmpty)
        'Title: ${widget.notification.title}',
      if (widget.notification.displayText.isNotEmpty)
        'Content: ${widget.notification.displayText}',
    ].join('\n');

    Clipboard.setData(ClipboardData(text: content));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _deleteNotification() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content:
            const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isDeleting = true);

      try {
        await NotificationService.deleteNotification(widget.notification.id);

        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate deletion

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isDeleting = false);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}
