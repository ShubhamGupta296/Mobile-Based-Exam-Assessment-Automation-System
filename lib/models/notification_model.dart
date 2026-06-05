/// Notification document in `notifications` collection.
///
/// Fields:
/// - id
/// - recipientId (User UID)
/// - title
/// - message
/// - type (marks_update, attendance_alert, announcement)
/// - relatedId (studentId or subjectId)
/// - isRead
/// - createdDate
class NotificationModel {
  final String id;
  final String recipientId;
  final String title;
  final String message;
  final String type;
  final String? relatedId;
  final bool isRead;
  final DateTime createdDate;

  NotificationModel({
    this.id = '',
    required this.recipientId,
    required this.title,
    required this.message,
    this.type = 'announcement',
    this.relatedId,
    this.isRead = false,
    DateTime? createdDate,
  }) : createdDate = createdDate ?? DateTime.now();

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: (map['id'] as String?) ?? '',
      recipientId: (map['recipientId'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      message: (map['message'] as String?) ?? '',
      type: (map['type'] as String?) ?? 'announcement',
      relatedId: map['relatedId'] as String?,
      isRead: (map['isRead'] as bool?) ?? false,
      createdDate: map['createdDate'] is DateTime
          ? map['createdDate']
          : DateTime.tryParse(map['createdDate'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'recipientId': recipientId,
      'title': title,
      'message': message,
      'type': type,
      'relatedId': relatedId,
      'isRead': isRead,
      'createdDate': createdDate.toIso8601String(),
    };
  }
}
