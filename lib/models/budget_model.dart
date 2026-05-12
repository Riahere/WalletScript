class AppBudget {
  final int? id;
  final String title;
  final String emoji;
  final double targetAmount;
  final double currentAmount;
  final String currency;
  final DateTime? deadline;
  final String color;
  final String? imagePath;
  final String? description;
  final String? category;
  final bool isPriority;
  final bool isArchived;
  final DateTime? archivedAt;
  final int streakMonths;
  final String? lastDepositMonth; // format 'yyyy-MM'
  final List<String> tags;

  // ── AUTO-DEDUCT ──────────────────────────────────────────────────────────
  final bool autoDeductEnabled;
  final double? autoDeductAmount;
  final int? autoDeductDay;
  final String? autoDeductAccountId;

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
    this.isArchived = false,
    this.archivedAt,
    this.streakMonths = 0,
    this.lastDepositMonth,
    this.tags = const [],
    // auto-deduct
    this.autoDeductEnabled = false,
    this.autoDeductAmount,
    this.autoDeductDay,
    this.autoDeductAccountId,
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
        'isArchived': isArchived ? 1 : 0,
        'archivedAt': archivedAt?.toIso8601String(),
        'streakMonths': streakMonths,
        'lastDepositMonth': lastDepositMonth,
        'tags': tags.join(','),
        // auto-deduct
        'autoDeductEnabled': autoDeductEnabled ? 1 : 0,
        'autoDeductAmount': autoDeductAmount,
        'autoDeductDay': autoDeductDay,
        'autoDeductAccountId': autoDeductAccountId,
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
        isArchived: (map['isArchived'] ?? 0) == 1,
        archivedAt: map['archivedAt'] != null
            ? DateTime.tryParse(map['archivedAt'])
            : null,
        streakMonths: (map['streakMonths'] ?? 0) as int,
        lastDepositMonth: map['lastDepositMonth'],
        tags: map['tags'] != null && (map['tags'] as String).isNotEmpty
            ? (map['tags'] as String).split(',')
            : [],
        // auto-deduct
        autoDeductEnabled: (map['autoDeductEnabled'] ?? 0) == 1,
        autoDeductAmount: map['autoDeductAmount'] != null
            ? (map['autoDeductAmount'] as num).toDouble()
            : null,
        autoDeductDay: map['autoDeductDay'],
        autoDeductAccountId: map['autoDeductAccountId'],
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
    bool? isArchived,
    DateTime? archivedAt,
    int? streakMonths,
    String? lastDepositMonth,
    List<String>? tags,
    // auto-deduct
    bool? autoDeductEnabled,
    double? autoDeductAmount,
    int? autoDeductDay,
    String? autoDeductAccountId,
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
        isArchived: isArchived ?? this.isArchived,
        archivedAt: archivedAt ?? this.archivedAt,
        streakMonths: streakMonths ?? this.streakMonths,
        lastDepositMonth: lastDepositMonth ?? this.lastDepositMonth,
        tags: tags ?? this.tags,
        // auto-deduct
        autoDeductEnabled: autoDeductEnabled ?? this.autoDeductEnabled,
        autoDeductAmount: autoDeductAmount ?? this.autoDeductAmount,
        autoDeductDay: autoDeductDay ?? this.autoDeductDay,
        autoDeductAccountId: autoDeductAccountId ?? this.autoDeductAccountId,
      );
}

class GoalDeposit {
  final int? id;
  final int budgetId;
  final double amount;
  final String? sourceAccountId;
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
