class NotificationModel {
  final int id;
  final int postTime;
  final String packageName;
  final String appName;
  final String? notificationKey;
  final int? notificationId;
  final String title;
  final String text;
  final String textBig;
  final String? channelId;
  final String? groupKey;
  final String? groupName;
  final bool isGroupSummary;
  final bool isClearable;
  final int priority;

  NotificationModel({
    required this.id,
    required this.postTime,
    required this.packageName,
    required this.appName,
    this.notificationKey,
    this.notificationId,
    required this.title,
    required this.text,
    required this.textBig,
    this.channelId,
    this.groupKey,
    this.groupName,
    required this.isGroupSummary,
    required this.isClearable,
    required this.priority,
  });

  // Factory constructor from database map
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: _safeInt(map['id']),
      postTime: _safeInt(map['post_time']),
      packageName: _safeString(map['package_name']),
      appName: _safeString(map['app_name']),
      notificationKey: _safeStringNullable(map['notification_key']),
      notificationId: _safeIntNullable(map['notification_id']),
      title: _safeString(map['title']),
      text: _safeString(map['text']),
      textBig: _safeString(map['text_big']),
      channelId: _safeStringNullable(map['channel_id']),
      groupKey: _safeStringNullable(map['group_key']),
      groupName: _safeStringNullable(map['group_name']),
      isGroupSummary: _safeBool(map['is_group_summary']),
      isClearable: _safeBool(map['is_clearable']),
      priority: _safeInt(map['priority']),
    );
  }

  // Convert to map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'post_time': postTime,
      'package_name': packageName,
      'app_name': appName,
      'notification_key': notificationKey,
      'notification_id': notificationId,
      'title': title,
      'text': text,
      'text_big': textBig,
      'channel_id': channelId,
      'group_key': groupKey,
      'group_name': groupName,
      'is_group_summary': isGroupSummary ? 1 : 0,
      'is_clearable': isClearable ? 1 : 0,
      'priority': priority,
    };
  }

  // Utility getters for UI display
  String get displayTitle {
    if (title.isNotEmpty) return title;
    if (appName.isNotEmpty) return appName;
    return 'No Title';
  }

  String get displayText {
    if (textBig.isNotEmpty) return textBig;
    if (text.isNotEmpty) return text;
    return 'No content';
  }

  String get displayContent {
    List<String> parts = [];
    if (title.isNotEmpty) parts.add(title);
    if (textBig.isNotEmpty) {
      parts.add(textBig);
    } else if (text.isNotEmpty) {
      parts.add(text);
    }
    return parts.join('\n');
  }

  DateTime get dateTime {
    return DateTime.fromMillisecondsSinceEpoch(postTime);
  }

  String get formattedTime {
    final dt = dateTime.toLocal();
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  String get detailedTime {
    final dt = dateTime.toLocal();
    return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  NotificationPriority get priorityLevel {
    switch (priority) {
      case -2:
        return NotificationPriority.min;
      case -1:
        return NotificationPriority.low;
      case 0:
        return NotificationPriority.normal;
      case 1:
        return NotificationPriority.high;
      case 2:
        return NotificationPriority.max;
      default:
        return NotificationPriority.normal;
    }
  }

  // Copying with changes
  NotificationModel copyWith({
    int? id,
    int? postTime,
    String? packageName,
    String? appName,
    String? notificationKey,
    int? notificationId,
    String? title,
    String? text,
    String? textBig,
    String? channelId,
    String? groupKey,
    String? groupName,
    bool? isGroupSummary,
    bool? isClearable,
    int? priority,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      postTime: postTime ?? this.postTime,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      notificationKey: notificationKey ?? this.notificationKey,
      notificationId: notificationId ?? this.notificationId,
      title: title ?? this.title,
      text: text ?? this.text,
      textBig: textBig ?? this.textBig,
      channelId: channelId ?? this.channelId,
      groupKey: groupKey ?? this.groupKey,
      groupName: groupName ?? this.groupName,
      isGroupSummary: isGroupSummary ?? this.isGroupSummary,
      isClearable: isClearable ?? this.isClearable,
      priority: priority ?? this.priority,
    );
  }

  // Safe type conversion helpers
  static int _safeInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  static String _safeString(dynamic value) {
    if (value is String) return value;
    if (value != null) return value.toString();
    return '';
  }

  static String? _safeStringNullable(dynamic value) {
    if (value is String && value.isNotEmpty) return value;
    return null;
  }

  static int? _safeIntNullable(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  static bool _safeBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, app: $appName, title: $title)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Enum for notification priority levels
enum NotificationPriority {
  min(-2, 'Min'),
  low(-1, 'Low'),
  normal(0, 'Normal'),
  high(1, 'High'),
  max(2, 'Max');

  const NotificationPriority(this.value, this.label);
  final int value;
  final String label;
}
