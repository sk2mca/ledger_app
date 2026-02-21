import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../database/database_helper.dart';
import '../models/customer.dart';
import '../models/transaction.dart';
import '../widgets/app_logo.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;
  bool _isImporting = false;

  Future<void> _exportData() async {
    setState(() => _isExporting = true);

    try {
      // Get all customers with transactions
      final customers = await DatabaseHelper.instance.getAllCustomers();

      // Prepare data for export
      final exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'version': '1.0',
        'customers': customers.map((customer) {
          return {
            'name': customer.name,
            'created_at': customer.createdAt.toIso8601String(),
            'transactions': customer.transactions.map((transaction) {
              return {
                'amount': transaction.amount,
                'type': transaction.type == TransactionType.youGave
                    ? 'gave'
                    : 'got',
                'date': transaction.date.toIso8601String(),
                'balance': transaction.balance,
                'description': transaction.description,
              };
            }).toList(),
          };
        }).toList(),
      };

      // Convert to JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Get the Downloads directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      // Create filename with timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = 'transaction_backup_$timestamp.json';
      final file = File('${directory!.path}/$filename');

      // Write to file
      await file.writeAsString(jsonString);

      setState(() => _isExporting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported successfully!\n$filename'),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isExporting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _importData() async {
    try {
      // Use file_picker to select a JSON file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Select backup file',
      );

      // User canceled the picker
      if (result == null) {
        return;
      }

      // Get the file path
      String? filePath = result.files.single.path;

      if (filePath == null) {
        throw Exception('Could not access file path');
      }

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Data'),
          content: Text(
            'Import data from:\n\n${result.files.single.name}\n\n'
            'This will REPLACE all existing data.\n\n'
            'Continue?',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Replace All'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      setState(() => _isImporting = true);

      // Read the file
      final file = File(filePath);

      if (!await file.exists()) {
        throw Exception('File not found');
      }

      // Read and parse JSON
      final jsonString = await file.readAsString();
      final Map<String, dynamic> importData = json.decode(jsonString);

      // Validate JSON structure
      if (!importData.containsKey('customers')) {
        throw Exception('Invalid backup file format');
      }

      // Clear existing data
      final existingCustomers = await DatabaseHelper.instance.getAllCustomers();
      for (var customer in existingCustomers) {
        if (customer.id != null) {
          await DatabaseHelper.instance.deleteCustomer(customer.id!);
        }
      }

      // Import customers and transactions
      final customersList = importData['customers'] as List;
      for (var customerData in customersList) {
        final customer = Customer(
          name: customerData['name'],
          createdAt: DateTime.parse(customerData['created_at']),
        );

        final customerId = await DatabaseHelper.instance.createCustomer(
          customer,
        );

        // Import transactions
        final transactionsList = customerData['transactions'] as List;
        for (var transactionData in transactionsList) {
          final transaction = TransactionModel(
            customerId: customerId,
            amount: (transactionData['amount'] as num).toDouble(),
            type: transactionData['type'] == 'gave'
                ? TransactionType.youGave
                : TransactionType.youGot,
            date: DateTime.parse(transactionData['date']),
            balance: (transactionData['balance'] as num).toDouble(),
            description: transactionData['description'] as String?,
          );

          await DatabaseHelper.instance.createTransaction(transaction);
        }
      }

      setState(() => _isImporting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully imported ${customersList.length} customers!',
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );

        // Go back to refresh the list
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isImporting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Data Management Section
          Container(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // Export Data
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.upload_file,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  title: const Text(
                    'Export Data',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text(
                    'Backup all customers and transactions',
                    style: TextStyle(fontSize: 13),
                  ),
                  trailing: _isExporting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _isExporting ? null : _exportData,
                ),

                const Divider(height: 32),

                // Import Data
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.download, color: Color(0xFF1976D2)),
                  ),
                  title: const Text(
                    'Import Data',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text(
                    'Restore from backup file',
                    style: TextStyle(fontSize: 13),
                  ),
                  trailing: _isImporting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _isImporting ? null : _importData,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Instructions Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'How to use',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '📤 Export: Creates a backup file in Downloads folder\n\n'
                  '📥 Import: Opens file browser to select backup file',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue[900],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // App Info
          Container(
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
                //const AnimatedAppLogo(size: 60),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/icon/logo.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Transaction Manager',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Developed by Suresh Palanisamy',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
