import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/transactions_provider.dart';
import 'screens/dashboard.dart';
import 'screens/transactions.dart';
import 'screens/reports.dart';
import 'screens/categories.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => TransactionProvider(),
      child: ControleApp(),
    ),
  );
}

class ControleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle Financeiro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        textTheme: GoogleFonts.nunitoSansTextTheme(),
      ),
      home: HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  @override
  _HomeShellState createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _pages = [
    DashboardScreen(),
    TransactionsScreen(),
    ReportsScreen(),
    CategoriesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Controle Financeiro',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('Gerencie suas finanças de forma simples e intuitiva',
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
      ),
      body: _pages[_index],
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navButton(0, Icons.dashboard, 'Dashboard'),
            _navButton(1, Icons.attach_money, 'Transações'),
            _navButton(2, Icons.bar_chart, 'Relatórios'),
            _navButton(3, Icons.folder, 'Categorias'),
          ],
        ),
      ),
    );
  }

  Widget _navButton(int i, IconData icon, String label) {
    final selected = _index == i;
    return GestureDetector(
      onTap: () => setState(() => _index = i),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? Colors.grey[200] : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black54),
            SizedBox(width: 8),
            Text(label, style: TextStyle(color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}
