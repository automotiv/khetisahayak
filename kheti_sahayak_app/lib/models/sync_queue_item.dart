import 'dart:convert';

class SyncQueueItem {
  final int? id;
  final String entityType; // e.g. 'farm', 'activity'
  final String action; // 'create', 'update', 'delete'
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;

  SyncQueueItem({
    this.id,
    required this.entityType,
    required this.action,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entity_type': entityType,
      'action': action,
      'payload': jsonEncode(payload),
      'created_at': createdAt.toIso8601String(),
      'retry_count': retryCount,
    };
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'],
      entityType: map['entity_type'],
      action: map['action'],
      payload: jsonDecode(map['payload']),
      createdAt: DateTime.parse(map['created_at']),
      retryCount: map['retry_count'] ?? 0,
    );
  }
}
