class AppBudget {
  final int? id;
  final String title;
  final String emoji;
  final double targetAmount;
  final double currentAmount;
  final String currency;
  final DateTime? deadline;
  final String color;

  AppBudget({
    this.id,
    required this.title,
    required this.emoji,
    required this.targetAmount,
    required this.currentAmount,
    required this.currency,
    this.deadline,
    required this.color,
  });

  double get progress => currentAmount / targetAmount;
  double get remaining => targetAmount - currentAmount;

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'emoji': emoji,
    'targetAmount': targetAmount,
    'currentAmount': currentAmount,
    'currency': currency,
    'deadline': deadline?.toIso8601String(),
    'color': color,
  };

  factory AppBudget.fromMap(Map<String, dynamic> map) => AppBudget(
    id: map['id'],
    title: map['title'],
    emoji: map['emoji'],
    targetAmount: map['targetAmount'],
    currentAmount: map['currentAmount'],
    currency: map['currency'],
    deadline: map['deadline'] != null ? DateTime.parse(map['deadline']) : null,
    color: map['color'],
  );
}
