import 'package:flutter/material.dart';
import 'screens/customer_list_screen.dart';
import 'database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(const TransactionApp());
}

class TransactionApp extends StatelessWidget {
  const TransactionApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transaction Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,

        // 🔥 Global Font Applied Here
        fontFamily: 'Inter',

        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF1976D2),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 230, 124, 2),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20, // 👈 Change size here
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),

        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(fontWeight: FontWeight.w400),
          titleLarge: TextStyle(fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      home: const CustomerListScreen(),
    );
  }
}
