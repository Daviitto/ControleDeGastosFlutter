
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// --- IMPORTAÇÕES DE MÓDULOS DE OUTROS ARQUIVOS ---
import 'utills/app_constants.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard.dart';
import 'screens/transactions.dart';
import 'screens/categories.dart';
import 'providers/transactions_provider.dart';

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
        primaryColor: primaryColor,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: createMaterialColor(primaryColor),
        ).copyWith(
          secondary: primaryColor,
          primary: primaryColor,
        ),
        scaffoldBackgroundColor: scaffoldBgColor,
        textTheme: GoogleFonts.nunitoSansTextTheme(),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            borderSide: BorderSide(color: primaryColor, width: 2.0),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

// -------------------------------------------------------------------
// SHELL PRINCIPAL (HomeShell)
// -------------------------------------------------------------------

class HomeShell extends StatefulWidget {
  @override
  _HomeShellState createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final _pages = [
    DashboardScreen(),
    TransactionsScreen(),
    CategoriesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.trending_up, color: primaryColor, size: 30),
            SizedBox(width: 8),
            Text(
              'FinControl',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.black54,
              size: 28,
            ),
            tooltip: 'Sair',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                    (Route<dynamic> route) => false,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _pages[_index],
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        color: Colors.white,
        // --- ALTERAÇÃO AQUI ---
        child: Row(
          // mainAxisAlignment foi removido, pois Expanded cuida da distribuição
          children: [
            Expanded(child: _navButton(0, Icons.dashboard, 'Dashboard')),
            Expanded(child: _navButton(1, Icons.attach_money, 'Transações')),
            Expanded(child: _navButton(2, Icons.folder, 'Categorias')),
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          // Centraliza o conteúdo dentro do botão expandido
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? primaryColor : Colors.black54),
            const SizedBox(width: 8),
            // Usamos Flexible para que o texto quebre a linha se for muito grande
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? primaryColor : Colors.black87,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
                // Evita que o texto quebre no meio de uma palavra
                softWrap: false,
                // Adiciona '...' se o texto ainda for muito grande
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}