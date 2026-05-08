class AppAccount {
  final int? id;
  final String name;
  final String group;
  final String type;
  final double balance;
  final String currency;
  final String icon;
  final String color;

  AppAccount({
    this.id,
    required this.name,
    required this.group,
    required this.type,
    required this.balance,
    required this.currency,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'grp': group,
        'type': type,
        'balance': balance,
        'currency': currency,
        'icon': icon,
        'color': color,
      };

  factory AppAccount.fromMap(Map<String, dynamic> map) => AppAccount(
        id: map['id'],
        name: map['name'],
        group: map['grp'] ?? 'Others',
        type: map['type'] ?? 'others',
        balance: (map['balance'] as num).toDouble(),
        currency: map['currency'] ?? 'IDR',
        icon: map['icon'] ?? 'wallet',
        color: map['color'] ?? '0xFF10B981',
      );

  AppAccount copyWith({
    int? id,
    String? name,
    String? group,
    String? type,
    double? balance,
    String? currency,
    String? icon,
    String? color,
  }) =>
      AppAccount(
        id: id ?? this.id,
        name: name ?? this.name,
        group: group ?? this.group,
        type: type ?? this.type,
        balance: balance ?? this.balance,
        currency: currency ?? this.currency,
        icon: icon ?? this.icon,
        color: color ?? this.color,
      );
}
