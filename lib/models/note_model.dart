class AppNote {
  final int? id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String color;
  final bool isPinned;
  final bool hasReminder;
  final DateTime? reminderDate;

  AppNote({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.color = '#FFFFFF',
    this.isPinned = false,
    this.hasReminder = false,
    this.reminderDate,
  });

  AppNote copyWith({
    int? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? color,
    bool? isPinned,
    bool? hasReminder,
    DateTime? reminderDate,
  }) =>
      AppNote(
        id: id ?? this.id,
        title: title ?? this.title,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        color: color ?? this.color,
        isPinned: isPinned ?? this.isPinned,
        hasReminder: hasReminder ?? this.hasReminder,
        reminderDate: reminderDate ?? this.reminderDate,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'color': color,
        'isPinned': isPinned ? 1 : 0,
        'hasReminder': hasReminder ? 1 : 0,
        'reminderDate': reminderDate?.toIso8601String(),
      };

  factory AppNote.fromMap(Map<String, dynamic> map) => AppNote(
        id: map['id'],
        title: map['title'],
        content: map['content'],
        createdAt: DateTime.parse(map['createdAt']),
        updatedAt:
            map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
        color: map['color'] ?? '#FFFFFF',
        isPinned: map['isPinned'] == 1,
        hasReminder: map['hasReminder'] == 1,
        reminderDate: map['reminderDate'] != null
            ? DateTime.parse(map['reminderDate'])
            : null,
      );
}
