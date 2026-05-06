class AppNote {
  final int? id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? reminderDate;
  final bool hasReminder;
  final bool isPinned;
  final String color;

  AppNote({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.reminderDate,
    this.hasReminder = false,
    this.isPinned = false,
    this.color = '#FFFFFF',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'reminderDate': reminderDate?.toIso8601String(),
    'hasReminder': hasReminder ? 1 : 0,
    'isPinned': isPinned ? 1 : 0,
    'color': color,
  };

  factory AppNote.fromMap(Map<String, dynamic> map) => AppNote(
    id: map['id'],
    title: map['title'] ?? '',
    content: map['content'] ?? '',
    createdAt: DateTime.parse(map['createdAt']),
    updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    reminderDate: map['reminderDate'] != null ? DateTime.parse(map['reminderDate']) : null,
    hasReminder: (map['hasReminder'] ?? 0) == 1,
    isPinned: (map['isPinned'] ?? 0) == 1,
    color: map['color'] ?? '#FFFFFF',
  );

  AppNote copyWith({
    int? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? reminderDate,
    bool? hasReminder,
    bool? isPinned,
    String? color,
  }) => AppNote(
    id: id ?? this.id,
    title: title ?? this.title,
    content: content ?? this.content,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    reminderDate: reminderDate ?? this.reminderDate,
    hasReminder: hasReminder ?? this.hasReminder,
    isPinned: isPinned ?? this.isPinned,
    color: color ?? this.color,
  );
}
