import 'transaction.dart';

class Customer {
  int? id;
  String name;
  DateTime createdAt;
  List<TransactionModel> transactions;

  Customer({
    this.id,
    required this.name,
    DateTime? createdAt,
    List<TransactionModel>? transactions,
  }) : createdAt = createdAt ?? DateTime.now(),
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
    return {'id': id, 'name': name, 'created_at': createdAt.toIso8601String()};
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Customer copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    List<TransactionModel>? transactions,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      transactions: transactions ?? this.transactions,
    );
  }

  @override
  String toString() => 'Customer(id: $id, name: $name, balance: $balance)';
}
