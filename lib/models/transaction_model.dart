class AppTransaction {
  final int? id;
  final String title;
  final double amount;
  final String type; // 'income', 'expense', 'transfer'
  final String category;
  final String currency;
  final String accountId;
  final String? toAccountId; // untuk transfer
  final DateTime date;
  final String? note;
  final String? attachmentPath;

  AppTransaction({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.currency,
    required this.accountId,
    this.toAccountId,
    required this.date,
    this.note,
    this.attachmentPath,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'amount': amount,
        'type': type,
        'category': category,
        'currency': currency,
        'accountId': accountId,
        'toAccountId': toAccountId,
        'date': date.toIso8601String(),
        'note': note,
        'attachmentPath': attachmentPath,
      };

  factory AppTransaction.fromMap(Map<String, dynamic> map) => AppTransaction(
        id: map['id'],
        title: map['title'] ?? '',
        amount: (map['amount'] as num).toDouble(),
        type: map['type'] ?? 'expense',
        category: map['category'] ?? 'Lainnya',
        currency: map['currency'] ?? 'IDR',
        accountId: map['accountId'] ?? '',
        toAccountId: map['toAccountId'],
        date: DateTime.parse(map['date']),
        note: map['note'],
        attachmentPath: map['attachmentPath'],
      );

  AppTransaction copyWith({
    int? id,
    String? title,
    double? amount,
    String? type,
    String? category,
    String? currency,
    String? accountId,
    String? toAccountId,
    DateTime? date,
    String? note,
    String? attachmentPath,
  }) =>
      AppTransaction(
        id: id ?? this.id,
        title: title ?? this.title,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        category: category ?? this.category,
        currency: currency ?? this.currency,
        accountId: accountId ?? this.accountId,
        toAccountId: toAccountId ?? this.toAccountId,
        date: date ?? this.date,
        note: note ?? this.note,
        attachmentPath: attachmentPath ?? this.attachmentPath,
      );
}
