import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../models/transaction.dart';
import '../database/database_helper.dart';
import 'edit_transaction_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({Key? key, required this.customer})
    : super(key: key);

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  late Customer _customer;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    _loadCustomerData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomerData() async {
    if (_customer.id != null) {
      final customer = await DatabaseHelper.instance.getCustomer(_customer.id!);
      if (customer != null) {
        setState(() {
          _customer = customer;
        });
      }
    }
  }

  Future<void> _addTransaction(TransactionType type) async {
    final amount = double.tryParse(_amountController.text);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid amount'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    // Calculate new balance
    double currentBalance = _customer.balance;
    double newBalance;

    if (type == TransactionType.youGave) {
      newBalance = currentBalance - amount;
    } else {
      newBalance = currentBalance + amount;
    }

    final transaction = TransactionModel(
      customerId: _customer.id!,
      amount: amount,
      type: type,
      balance: newBalance,
      date: DateTime.now(),
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
    );

    await DatabaseHelper.instance.createTransaction(transaction);
    _amountController.clear();
    _descriptionController.clear();
    await _loadCustomerData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            type == TransactionType.youGave
                ? 'Payment recorded'
                : 'Payment received',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _editTransaction(TransactionModel transaction) async {
    final updatedTransaction = await Navigator.push<TransactionModel>(
      context,
      MaterialPageRoute(
        builder: (context) => EditTransactionScreen(transaction: transaction),
      ),
    );

    if (updatedTransaction != null && transaction.id != null) {
      // Update the transaction in database
      await DatabaseHelper.instance.updateTransaction(updatedTransaction);

      // Recalculate all balances for this customer
      await _recalculateAllBalances();

      // Reload the UI
      await _loadCustomerData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transaction updated successfully'),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _recalculateAllBalances() async {
    // Get fresh customer data from database
    final freshCustomer = await DatabaseHelper.instance.getCustomer(
      _customer.id!,
    );
    if (freshCustomer == null) return;

    // Sort transactions by date
    final sortedTransactions = List<TransactionModel>.from(
      freshCustomer.transactions,
    )..sort((a, b) => a.date.compareTo(b.date));

    // Recalculate running balance
    double runningBalance = 0;
    for (var transaction in sortedTransactions) {
      if (transaction.type == TransactionType.youGave) {
        runningBalance -= transaction.amount;
      } else {
        runningBalance += transaction.amount;
      }

      // Update this transaction's balance
      if (transaction.balance != runningBalance) {
        final updatedTransaction = TransactionModel(
          id: transaction.id,
          customerId: transaction.customerId,
          amount: transaction.amount,
          type: transaction.type,
          date: transaction.date,
          balance: runningBalance,
          description: transaction.description,
        );
        await DatabaseHelper.instance.updateTransaction(updatedTransaction);
      }
    }
  }

  Future<void> _recalculateBalances() async {
    await _recalculateAllBalances();
  }

  Future<void> _deleteTransaction(TransactionModel transaction) async {
    if (transaction.id != null) {
      await DatabaseHelper.instance.deleteTransaction(transaction.id!);
      await _recalculateBalances();
      await _loadCustomerData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transaction deleted'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹ ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM yy · hh:mm a');

    final balance = _customer.balance;
    final isPositive = balance > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_customer.name),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Balance Summary
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      balance >= 0 ? 'You will give' : 'You will get',
                      style: const TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                    Text(
                      currencyFormat.format(balance.abs()),
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: isPositive
                            ? const Color(0xFFE53935)
                            : const Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Quick Amount Input
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        '₹',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Enter amount',
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Description Input
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: 'Add description (optional)',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      prefixIcon: Icon(
                        Icons.notes,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 16),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            _addTransaction(TransactionType.youGave),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'YOU GAVE ₹',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            _addTransaction(TransactionType.youGot),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'YOU GOT ₹',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Entries Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text(
                  'ENTRIES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Text(
                  'YOU GAVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 80),
                Text(
                  'YOU GOT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // Transaction List with Swipe Actions
          Expanded(
            child: _customer.transactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Swipe left to edit or delete',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _customer.transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _customer.transactions[index];
                      return _buildTransactionCard(
                        transaction,
                        currencyFormat,
                        dateFormat,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(
    TransactionModel transaction,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
  ) {
    final isGave = transaction.type == TransactionType.youGave;

    return Dismissible(
      key: Key(transaction.id.toString()),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Swipe left - show action menu
          final action = await showModalBottomSheet<String>(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1976D2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit, color: Color(0xFF1976D2)),
                    ),
                    title: const Text('Edit Transaction'),
                    subtitle: const Text('Modify amount, type or description'),
                    onTap: () => Navigator.pop(context, 'edit'),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete, color: Colors.red),
                    ),
                    title: const Text('Delete Transaction'),
                    subtitle: const Text('Remove this entry permanently'),
                    onTap: () => Navigator.pop(context, 'delete'),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.close, color: Colors.grey),
                    ),
                    title: const Text('Cancel'),
                    onTap: () => Navigator.pop(context, 'cancel'),
                  ),
                ],
              ),
            ),
          );

          if (action == 'edit') {
            _editTransaction(transaction);
          } else if (action == 'delete') {
            _deleteTransaction(transaction);
          }

          return false; // Don't dismiss the card
        }
        return false;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1976D2),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.more_horiz, color: Colors.white, size: 30),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateFormat.format(transaction.date),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bal. ${currencyFormat.format(transaction.balance.abs())}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (isGave)
                  Text(
                    currencyFormat.format(transaction.amount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE53935),
                    ),
                  )
                else
                  const SizedBox(width: 80),
                const SizedBox(width: 24),
                if (!isGave)
                  Text(
                    currencyFormat.format(transaction.amount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  )
                else
                  const SizedBox(width: 80),
              ],
            ),
            if (transaction.description != null &&
                transaction.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notes, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        transaction.description!,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
