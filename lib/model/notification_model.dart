class NotificationModel {
  final String message;
  final bool isAppGroup;
  final String title;
  final String groupKey;
  final String textBig;
  final String textLines;
  final String textSub;
  final String textSummary;
  final String textInfo;
  final int postTime;
  final String sortKey;
  final String tickerText;
  final String text;
  final String packageName;
  final int id;
  final String? tag;
  final bool isGroup;
  final String key;
  final bool isClearable;
  final String? channel;
  final String group;

  // Constructor to initialize all fields
  NotificationModel({
    required this.message,
    required this.isAppGroup,
    required this.title,
    required this.groupKey,
    required this.textLines,
    required this.textBig,
    required this.textSub,
    required this.textSummary,
    required this.textInfo,
    required this.postTime,
    required this.sortKey,
    required this.tickerText,
    required this.text,
    required this.packageName,
    required this.id,
    this.tag,
    required this.isGroup,
    required this.key,
    required this.isClearable,
    this.channel,
    required this.group,
  });

  // Factory method to parse JSON or a similar data format
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      message: json['message'] ?? '',
      isAppGroup: bool.tryParse(json['isAppGroup']) ?? false,
      title: json['title'] ?? '',
      groupKey: json['groupKey'] ?? '',
      textLines: json['textLines'] ?? '',
      textBig: json['textBig'] ?? '',
      textSub: json['textSub'] ?? '',
      textSummary: json['textSummary'] ?? '',
      textInfo: json['textInfo'] ?? '',
      postTime: int.tryParse(json['postTime']) ?? 0,
      sortKey: json['sortKey'] ?? '',
      tickerText: json['tickerText'] ?? '',
      text: json['text'] ?? '',
      packageName: json['packageName'] ?? '',
      id: int.tryParse(json['id']) ?? 0,
      tag: json['tag'],
      isGroup: bool.tryParse(json['isGroup']) ?? false,
      key: json['key'] ?? '',
      isClearable: bool.tryParse(json['isClearable']) ?? false,
      channel: json['channel'],
      group: json['group'] ?? '',
    );
  }

  // Convert the class to a JSON-like map
  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'isAppGroup': isAppGroup,
      'title': title,
      'groupKey': groupKey,
      'textLines': textLines,
      'textBig': textBig,
      'textSub': textSub,
      'textSummary': textSummary,
      'textInfo': textInfo,
      'postTime': postTime,
      'sortKey': sortKey,
      'tickerText': tickerText,
      'text': text,
      'packageName': packageName,
      'id': id,
      'tag': tag,
      'isGroup': isGroup,
      'key': key,
      'isClearable': isClearable,
      'channel': channel,
      'group': group,
    };
  }

  // Helper method for debugging
  @override
  String toString() {
    return '''
NotificationData(
  message: $message,
  isAppGroup: $isAppGroup,
  title: $title,
  groupKey: $groupKey,
  textLines: $textLines,
  textBig: $textBig,
  textSub: $textSub,
  textSummary: $textSummary,
  textInfo: $textInfo,
  postTime: $postTime,
  sortKey: $sortKey,
  tickerText: $tickerText,
  text: $text,
  packageName: $packageName,
  id: $id,
  tag: $tag,
  isGroup: $isGroup,
  key: $key,
  isClearable: $isClearable,
  channel: $channel,
  group: $group,
)
    ''';
  }

  // static Future<void> getNotifications() async {
  //   try {
  //     final dir = await getApplicationSupportDirectory();
  //     var data = dir.listSync().take(20).toList();
  //     print(data);
  //     log("dir: $dir", error: dir);
  //   } catch (e) {
  //     log("error:  ", error: e);
  //   }
  // }
}
