class AppTransaction {
  final int? id;
  final String title;
  final double amount;
  final String type;
  final String category;
  final String currency;
  final String accountId;
  final String? toAccountId;
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
    'id': id,
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
    title: map['title'],
    amount: map['amount'],
    type: map['type'],
    category: map['category'],
    currency: map['currency'],
    accountId: map['accountId'],
    toAccountId: map['toAccountId'],
    date: DateTime.parse(map['date']),
    note: map['note'],
    attachmentPath: map['attachmentPath'],
  );
}
