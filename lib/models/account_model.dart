class AppAccount {
  final int? id;
  final String name;
  final String type;
  final double balance;
  final String currency;
  final String icon;
  final String color;

  AppAccount({
    this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.currency,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type,
    'balance': balance,
    'currency': currency,
    'icon': icon,
    'color': color,
  };

  factory AppAccount.fromMap(Map<String, dynamic> map) => AppAccount(
    id: map['id'],
    name: map['name'],
    type: map['type'],
    balance: map['balance'],
    currency: map['currency'],
    icon: map['icon'],
    color: map['color'],
  );
}
