import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


// --- MODELOS DE DADOS DO BACKEND ---

class Categoria {
  final int id;
  final String nome;
  final String icone;

  Categoria({required this.id, required this.nome, required this.icone});

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'],
      nome: json['nome'],
      icone: json['icone'],
    );
  }
}

class Transacao {
  final int id;
  final String descricao;
  final double valor; // O backend provavelmente usa double/BigDecimal
  final String data;
  final String tipo; // Ex: "DESPESA" ou "RECEITA"
  final Categoria categoria;
  // Não precisamos do 'usuario' aqui, mas o backend sim

  Transacao({
    required this.id,
    required this.descricao,
    required this.valor,
    required this.data,
    required this.tipo,
    required this.categoria,
  });

  factory Transacao.fromJson(Map<String, dynamic> json) {
    return Transacao(
      id: json['id'],
      descricao: json['descricao'],
      valor: (json['valor'] as num).toDouble(),
      data: json['data'],
      tipo: json['tipo'],
      categoria: Categoria.fromJson(json['categoria']),
    );
  }
}

// --- FORMATAÇÃO DE MOEDA (Mantido) ---
class CurrencyUtils {
  static String formatFromDouble(double value) {
    final bool isNegative = value < 0;
    String valueStr = value.abs().toStringAsFixed(2).replaceAll('.', ',');

    final parts = valueStr.split(',');
    String reaisStr = parts[0];
    final centavosStr = parts[1];

    final buffer = StringBuffer();
    int count = 0;
    for (int i = reaisStr.length - 1; i >= 0; i--) {
      buffer.write(reaisStr[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    final reaisWithDots = buffer.toString().split('').reversed.join();

    return '${isNegative ? '- ' : ''}R\$ $reaisWithDots,$centavosStr';
  }

  static String formatFromCents(int cents) {
    return formatFromDouble(cents / 100.0);
  }
}

// --- TELA DE TRANSAÇÕES ---

class TransactionsScreen extends StatefulWidget {
  // 🔹 1. PRECISAMOS RECEBER O ID DO USUÁRIO LOGADO
  final int usuarioId;

  const TransactionsScreen({super.key, required this.usuarioId});

  @override
  _TransactionsScreenState createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  // --- Controladores (Mantidos) ---
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // --- Estado da UI ---
  bool _isExpense = true;
  bool _isLoading = true;
  String? _error;

  // --- Listas de Dados da API ---
  List<Transacao> _transactions = [];
  List<Categoria> _categories = [];
  Categoria? _selectedCategory; // 🔹 Agora é um objeto Categoria

  // 🔹 2. URL da API
  final String _baseUrl = 'http://localhost:8080';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _valueController.dispose();
    _dateController.dispose();
    _descController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 🔹 3. BUSCA OS DADOS INICIAIS (CATEGORIAS E TRANSAÇÕES)
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Busca ambas em paralelo
      final futureCategories = _fetchCategories();
      final futureTransactions = _fetchTransactions();

      // Espera ambas terminarem
      await Future.wait([futureCategories, futureTransactions]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Erro ao carregar dados: $e';
      });
    }
  }

  Future<void> _fetchCategories() async {
    final response = await http.get(Uri.parse('$_baseUrl/categoria'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      setState(() {
        _categories = data.map((json) => Categoria.fromJson(json)).toList();
      });
    } else {
      throw Exception('Falha ao carregar categorias');
    }
  }

  Future<void> _fetchTransactions() async {
    // ❗ AVISO: Isto busca TODAS as transações.
    // O ideal seria seu backend ter: /transacao/usuario/{id}
    final response = await http.get(Uri.parse('$_baseUrl/transacao'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      setState(() {
        _transactions = data.map((json) => Transacao.fromJson(json)).toList();
      });
    } else {
      throw Exception('Falha ao carregar transações');
    }
  }

  // 🔹 4. ADICIONA UMA TRANSAÇÃO (POST)
  Future<void> _addTransaction() async {
    if (_valueController.text.isEmpty ||
        _dateController.text.isEmpty ||
        _descController.text.isEmpty ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos.')),
      );
      return;
    }

    final digits = _valueController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final cents = digits.isNotEmpty ? int.tryParse(digits) ?? 0 : 0;
    if (cents == 0) return;

    final double valor = cents / 100.0 * (_isExpense ? -1 : 1);

    // ❗ O 'tipo' DEVE ser igual ao que seu backend espera (Enum, String, etc.)
    // Vou assumir que é "DESPESA" ou "RECEITA"
    final String tipo = _isExpense ? "DESPESA" : "RECEITA";

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/transacao'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'descricao': _descController.text,
          'valor': valor, // Envia como double
          'data': _dateController.text, // Ex: "17/11/2025"
          'tipo': tipo,
          // 🔹 Envia os objetos aninhados com seus IDs, como o backend espera
          'categoria': {
            'id': _selectedCategory!.id
          },
          'usuario': {
            'id': widget.usuarioId // 🔹 Usa o ID recebido pelo widget
          }
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Sucesso! Limpa tudo e recarrega a lista
        setState(() {
          _valueController.clear();
          _dateController.clear();
          _descController.clear();
          _selectedCategory = null;
          _isExpense = true;
        });
        _fetchTransactions(); // Recarrega o histórico
      } else {
        throw Exception('Falha ao salvar: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao adicionar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 800;

        // 🔹 Mostra loading ou erro se aplicável
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_error != null) {
          return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
        }

        if (isWide) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 1, child: _formCard()),
                const SizedBox(width: 16),
                Expanded(flex: 1, child: _historyCard()),
              ],
            ),
          );
        } else {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _formCard(),
              const SizedBox(height: 16),
              _historyCard(),
            ],
          );
        }
      },
    );
  }

  Widget _formCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ... (Tipo, Valor, Data, Descrição - Sem mudanças) ...
          const Text('Nova Transação',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Tipo'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isExpense = true),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: _isExpense ? Colors.red : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                        child: Text('Despesa',
                            style: TextStyle(
                                color:
                                _isExpense ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold))),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isExpense = false),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: !_isExpense ? Colors.green : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                        child: Text('Receita',
                            style: TextStyle(
                                color:
                                !_isExpense ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold))),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Valor'),
          const SizedBox(height: 8),
          TextField(
            controller: _valueController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _CurrencyInputFormatter(),
            ],
            decoration: InputDecoration(
              prefixText: 'R\$ ',
              hintText: '0,00',
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Data'),
          const SizedBox(height: 8),
          TextField(
            controller: _dateController,
            keyboardType: TextInputType.datetime,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
              _DateInputFormatter(),
            ],
            decoration: InputDecoration(
              hintText: 'DD/MM/AAAA',
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Descrição'),
          const SizedBox(height: 8),
          TextField(
            controller: _descController,
            decoration: InputDecoration(
              hintText: 'Ex: Almoço no restaurante',
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Categoria'),
          const SizedBox(height: 8),

          // 🔹 5. DROPDOWN ATUALIZADO (usando a lista _categories da API)
          DropdownButtonFormField<Categoria>(
            value: _selectedCategory,
            items: _categories // 🔹 Usa a lista da API
                .map((c) => DropdownMenuItem(
              value: c, // 🔹 O valor agora é o objeto Categoria
              child: Text('${c.icone} ${c.nome}'), // 🔹 Usa .icone e .nome
            ))
                .toList(),
            onChanged: (value) => setState(() => _selectedCategory = value),
            decoration: InputDecoration(
              hintText: 'Selecione uma categoria',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addTransaction, // 🔹 Chama a nova função
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Adicionar Transação',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyCard() {
    // 🔹 6. HISTÓRICO ATUALIZADO (não usa mais Consumer)
    return Container(
      height: 570,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Histórico',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: _transactions.isEmpty
                ? Center(
              child: Text(
                'Nenhuma transação registrada.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              itemCount: _transactions.length, // 🔹 Usa a lista da API
              itemBuilder: (context, index) {
                final t = _transactions[index]; // 🔹 Objeto Transacao
                final bool isPositive = t.valor >= 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _transactionItem(
                    t.categoria.icone,
                    t.descricao,
                    '${t.data} · ${t.categoria.nome}',
                    CurrencyUtils.formatFromDouble(t.valor),
                    isPositive,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ... (_transactionItem, _DateInputFormatter, _CurrencyInputFormatter - Sem mudanças) ...
  Widget _transactionItem(String emoji, String title, String subtitle,
      String amount, bool positive) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle,
                    style:
                    TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Text(amount,
              style: TextStyle(
                  color: positive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i == 1 || i == 3) && i != text.length - 1) buffer.write('/');
    }
    var newText = buffer.toString();
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');

    final cents = int.tryParse(digits) ?? 0;
    final formatted = CurrencyUtils.formatFromCents(cents).replaceFirst('R\$ ', '');

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}