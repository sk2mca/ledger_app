import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/customer.dart';
import '../models/transaction.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('transactions.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
      CREATE TABLE customers (
        id $idType,
        name $textType,
        created_at $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id $idType,
        customer_id $integerType,
        amount $realType,
        type $textType,
        date $textType,
        balance $realType,
        description TEXT,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');
  }

  // Customer CRUD operations
  Future<int> createCustomer(Customer customer) async {
    final db = await instance.database;
    return await db.insert('customers', customer.toMap());
  }

  Future<Customer?> getCustomer(int id) async {
    final db = await instance.database;
    final maps = await db.query('customers', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      final customer = Customer.fromMap(maps.first);
      customer.transactions = await getTransactionsByCustomer(id);
      return customer;
    }
    return null;
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await instance.database;
    final result = await db.query('customers', orderBy: 'name ASC');

    List<Customer> customers = [];
    for (var map in result) {
      final customer = Customer.fromMap(map);
      customer.transactions = await getTransactionsByCustomer(customer.id!);
      customers.add(customer);
    }
    return customers;
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await instance.database;
    return db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await instance.database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // Transaction CRUD operations
  Future<int> createTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<TransactionModel>> getTransactionsByCustomer(
    int customerId,
  ) async {
    final db = await instance.database;
    final result = await db.query(
      'transactions',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'date DESC',
    );

    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalYouWillGive() async {
    final customers = await getAllCustomers();
    double total = 0;
    for (var customer in customers) {
      if (customer.balance < 0) {
        total += customer.balance.abs();
      }
    }
    return total;
  }

  Future<double> getTotalYouWillGet() async {
    final customers = await getAllCustomers();
    double total = 0;
    for (var customer in customers) {
      if (customer.balance > 0) {
        total += customer.balance;
      }
    }
    return total;
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
