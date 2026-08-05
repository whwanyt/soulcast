import 'chat_memory_fact_category.dart';

/// 可独立增删改的结构化会话记忆事实。
class ChatMemoryFact {
  ChatMemoryFact({
    required this.id,
    required this.category,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatMemoryFact.create({
    required ChatMemoryFactCategory category,
    required String content,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    return ChatMemoryFact(
      id: createChatMemoryFactId(timestamp),
      category: category,
      content: content,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  factory ChatMemoryFact.fromJson(Map<String, dynamic> json) {
    return ChatMemoryFact(
      id: _stringValue(json['id']) ?? createChatMemoryFactId(),
      category: ChatMemoryFactCategory.fromName(_stringValue(json['category'])),
      content: _stringValue(json['content']) ?? '',
      createdAt: _dateValue(json['createdAt']) ?? DateTime.now(),
      updatedAt: _dateValue(json['updatedAt']) ?? DateTime.now(),
    );
  }

  final String id;
  final ChatMemoryFactCategory category;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category.name,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ChatMemoryFact copyWith({
    String? id,
    ChatMemoryFactCategory? category,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatMemoryFact(
      id: id ?? this.id,
      category: category ?? this.category,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 基于时间戳创建记忆事实标识。
String createChatMemoryFactId([DateTime? now]) {
  final timestamp = now ?? DateTime.now();
  return 'memory_fact_${timestamp.microsecondsSinceEpoch}';
}

String? _stringValue(Object? value) {
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  return null;
}

DateTime? _dateValue(Object? value) {
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}
