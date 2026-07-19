class Expense {
  const Expense({
    this.id,
    required this.amount,
    required this.category,
    this.note = '',
    required this.date,
    this.createdAt,
  });

  final String? id;
  final double amount;
  final String category;
  final String note;
  final DateTime date;
  final DateTime? createdAt;
}

class Income {
  const Income({
    this.id,
    required this.amount,
    required this.source,
    this.isPassive = false,
    this.note = '',
    required this.date,
    this.createdAt,
  });

  final String? id;
  final double amount;
  final String source;
  final bool isPassive;
  final String note;
  final DateTime date;
  final DateTime? createdAt;
}

class Device {
  const Device({
    this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.purchaseDate,
    this.status = 'active',
    this.soldPrice,
    this.soldDate,
    this.note = '',
    this.createdAt,
  });

  final String? id;
  final String name;
  final String category;
  final double price;
  final DateTime purchaseDate;
  final String status;
  final double? soldPrice;
  final DateTime? soldDate;
  final String note;
  final DateTime? createdAt;
}

class PassiveSource {
  const PassiveSource({
    this.id,
    required this.name,
    required this.monthlyAmount,
    this.createdAt,
  });

  final String? id;
  final String name;
  final double monthlyAmount;
  final DateTime? createdAt;
}

class UserAssets {
  const UserAssets({
    this.total = 0,
    this.lockedAssets = 0,
    this.cash = 0,
    this.updatedAt,
    this.firstRecordDate,
  });

  final double total;
  final double lockedAssets;
  final double cash;
  final DateTime? updatedAt;
  final DateTime? firstRecordDate;

  double get netWorth => lockedAssets + cash;
}
