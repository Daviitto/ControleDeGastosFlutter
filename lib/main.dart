import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- IMPORTAÇÕES DE MÓDULOS DE OUTROS ARQUIVOS ---
import 'utills/app_constants.dart';
import 'screens/login_screen.dart';

import 'screens/dashboard.dart';
import 'screens/transactions.dart';
import 'screens/categories.dart';

void main() {
  // 🔹 REMOVEMOS O CHANGENOTIFIERPROVIDER
  runApp(ControleApp());
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
          // 🔹 Usa a função createMaterialColor
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
          contentPadding:
          EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
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

// 🔹 2. ADIÇÃO DA FUNÇÃO createMaterialColor
// Esta função é necessária para o 'primarySwatch'
MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  final swatch = <int, Color>{};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.value, swatch);
}

// -------------------------------------------------------------------
// SHELL PRINCIPAL (HomeShell)
// -------------------------------------------------------------------

class HomeShell extends StatefulWidget {
  // A HOMESHELL AGORA RECEBE O ID DO USUÁRIO
  final int usuarioId;

  // ATUALIZA O CONSTRUTOR
  const HomeShell({super.key, required this.usuarioId});

  @override
  _HomeShellState createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  // DECLARA A LISTA DE PÁGINAS (sem 'final')
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // INICIA A LISTA AQUI, USANDO O ID DO WIDGET
    _pages = [
      // Passa o ID do usuário para as telas que precisam dele
      DashboardScreen(usuarioId: widget.usuarioId),
      TransactionsScreen(usuarioId: widget.usuarioId),
      const CategoriesScreen(), // Categories não precisa do ID, então está OK
    ];
  }

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
      // O BODY AGORA USA A LISTA _pages INICIADA NO initState
      body: _pages[_index],
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        color: Colors.white,
        child: Row(
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? primaryColor : Colors.black54),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? primaryColor : Colors.black87,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}