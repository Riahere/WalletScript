class AppBudget {
  final int? id;
  final String title;
  final String emoji;
  final double targetAmount;
  final double currentAmount;
  final String currency;
  final DateTime? deadline;
  final String color;
  final String? imagePath; // vision board photo
  final String? description; // motivasi / catatan
  final String?
      category; // 'vehicle', 'property', 'education', 'travel', 'gadget', 'other'
  final bool isPriority;

  AppBudget({
    this.id,
    required this.title,
    required this.emoji,
    required this.targetAmount,
    required this.currentAmount,
    required this.currency,
    this.deadline,
    required this.color,
    this.imagePath,
    this.description,
    this.category,
    this.isPriority = false,
  });

  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  double get remaining => targetAmount - currentAmount;
  int? get daysLeft =>
      deadline != null ? deadline!.difference(DateTime.now()).inDays : null;
  bool get isCompleted => currentAmount >= targetAmount;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'emoji': emoji,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'currency': currency,
        'deadline': deadline?.toIso8601String(),
        'color': color,
        'imagePath': imagePath,
        'description': description,
        'category': category ?? 'other',
        'isPriority': isPriority ? 1 : 0,
      };

  factory AppBudget.fromMap(Map<String, dynamic> map) => AppBudget(
        id: map['id'],
        title: map['title'],
        emoji: map['emoji'],
        targetAmount: (map['targetAmount'] as num).toDouble(),
        currentAmount: (map['currentAmount'] as num).toDouble(),
        currency: map['currency'] ?? 'IDR',
        deadline:
            map['deadline'] != null ? DateTime.tryParse(map['deadline']) : null,
        color: map['color'] ?? '0xFF10B981',
        imagePath: map['imagePath'],
        description: map['description'],
        category: map['category'] ?? 'other',
        isPriority: (map['isPriority'] ?? 0) == 1,
      );

  AppBudget copyWith({
    int? id,
    String? title,
    String? emoji,
    double? targetAmount,
    double? currentAmount,
    String? currency,
    DateTime? deadline,
    String? color,
    String? imagePath,
    String? description,
    String? category,
    bool? isPriority,
  }) =>
      AppBudget(
        id: id ?? this.id,
        title: title ?? this.title,
        emoji: emoji ?? this.emoji,
        targetAmount: targetAmount ?? this.targetAmount,
        currentAmount: currentAmount ?? this.currentAmount,
        currency: currency ?? this.currency,
        deadline: deadline ?? this.deadline,
        color: color ?? this.color,
        imagePath: imagePath ?? this.imagePath,
        description: description ?? this.description,
        category: category ?? this.category,
        isPriority: isPriority ?? this.isPriority,
      );
}

class GoalDeposit {
  final int? id;
  final int budgetId;
  final double amount;
  final String? sourceAccountId; // wallet source
  final String? sourceAccountName;
  final String? note;
  final String? attachmentPath;
  final DateTime date;

  GoalDeposit({
    this.id,
    required this.budgetId,
    required this.amount,
    this.sourceAccountId,
    this.sourceAccountName,
    this.note,
    this.attachmentPath,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'budgetId': budgetId,
        'amount': amount,
        'sourceAccountId': sourceAccountId,
        'sourceAccountName': sourceAccountName,
        'note': note,
        'attachmentPath': attachmentPath,
        'date': date.toIso8601String(),
      };

  factory GoalDeposit.fromMap(Map<String, dynamic> map) => GoalDeposit(
        id: map['id'],
        budgetId: map['budgetId'],
        amount: (map['amount'] as num).toDouble(),
        sourceAccountId: map['sourceAccountId'],
        sourceAccountName: map['sourceAccountName'],
        note: map['note'],
        attachmentPath: map['attachmentPath'],
        date: DateTime.parse(map['date']),
      );
}
