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

    return await openDatabase(
      path,
      version: 2, // ✅ upgraded
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
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
        created_at $textType,
        updated_at $textType
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

  // ✅ Migration for existing users
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE customers ADD COLUMN updated_at TEXT");
    }
  }

  // ================= CUSTOMER CRUD =================

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
    final result = await db.query(
      'customers',
      orderBy: 'updated_at DESC', // ✅ recent first
    );

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
      {...customer.toMap(), 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await instance.database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // ================= TRANSACTION CRUD =================

  Future<int> createTransaction(TransactionModel transaction) async {
    final db = await instance.database;

    final result = await db.insert('transactions', transaction.toMap());

    await _updateCustomerTimestamp(transaction.customerId);

    return result;
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

    final result = await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );

    await _updateCustomerTimestamp(transaction.customerId);

    return result;
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;

    // Get customer_id before delete
    final maps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      final customerId = maps.first['customer_id'] as int;

      await db.delete('transactions', where: 'id = ?', whereArgs: [id]);

      await _updateCustomerTimestamp(customerId);
    }

    return 1;
  }

  // ================= TOTAL CALCULATIONS =================

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

  // ================= PRIVATE HELPER =================

  Future<void> _updateCustomerTimestamp(int customerId) async {
    final db = await instance.database;

    await db.update(
      'customers',
      {'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [customerId],
    );
  }

  // ================= CLOSE =================

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
