import 'transaction.dart';

class Customer {
  int? id;
  String name;
  DateTime createdAt;
  DateTime updatedAt; // ✅ NEW FIELD
  List<TransactionModel> transactions;

  Customer({
    this.id,
    required this.name,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TransactionModel>? transactions,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       transactions = transactions ?? [];

  double get balance {
    double total = 0;
    for (var transaction in transactions) {
      if (transaction.type == TransactionType.youGave) {
        total -= transaction.amount;
      } else {
        total += transaction.amount;
      }
    }
    return total;
  }

  int get entryCount => transactions.length;

  String get balanceStatus {
    if (balance > 0) return 'You will give';
    if (balance < 0) return 'You will get';
    return 'Settled Up';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(), // ✅ added
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.parse(
              map['created_at'] as String,
            ), // fallback for old data
    );
  }

  Customer copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TransactionModel>? transactions,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      transactions: transactions ?? this.transactions,
    );
  }

  @override
  String toString() =>
      'Customer(id: $id, name: $name, balance: $balance, updatedAt: $updatedAt)';
}
