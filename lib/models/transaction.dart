enum TransactionType { youGave, youGot }

class TransactionModel {
  int? id;
  int customerId;
  double amount;
  TransactionType type;
  DateTime date;
  double balance;
  String? description;

  TransactionModel({
    this.id,
    required this.customerId,
    required this.amount,
    required this.type,
    DateTime? date,
    required this.balance,
    this.description,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'amount': amount,
      'type': type == TransactionType.youGave ? 'gave' : 'got',
      'date': date.toIso8601String(),
      'balance': balance,
      'description': description,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int,
      customerId: map['customer_id'] as int,
      amount: map['amount'] as double,
      type: map['type'] == 'gave'
          ? TransactionType.youGave
          : TransactionType.youGot,
      date: DateTime.parse(map['date'] as String),
      balance: map['balance'] as double,
      description: map['description'] as String?,
    );
  }

  TransactionModel copyWith({
    int? id,
    int? customerId,
    double? amount,
    TransactionType? type,
    DateTime? date,
    double? balance,
    String? description,
    bool clearDescription = false,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      balance: balance ?? this.balance,
      description: clearDescription ? null : (description ?? this.description),
    );
  }
}
