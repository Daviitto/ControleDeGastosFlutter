import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/categories.dart';
import '../providers/transactions_provider.dart';

// --- MELHORIA: Lógica de formatação centralizada para evitar repetição ---
class CurrencyUtils {
  static String formatFromCents(int cents) {
    final double value = cents / 100.0;
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
}

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  _TransactionsScreenState createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String? _selectedCategory;
  bool _isExpense = true;

  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _valueController.dispose();
    _dateController.dispose();
    _descController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addTransaction() {
    if (_valueController.text.isEmpty ||
        _dateController.text.isEmpty ||
        _descController.text.isEmpty ||
        _selectedCategory == null) {
      // Opcional: Mostrar um snackbar de erro
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos.')),
      );
      return;
    }

    final category = categories.firstWhere(
          (c) => c.name == _selectedCategory,
      orElse: () => categories.first,
    );

    final digits = _valueController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final cents = digits.isNotEmpty ? int.tryParse(digits) ?? 0 : 0;

    if (cents == 0) return; // Não adiciona transação com valor zero

    final newTransaction = {
      'emoji': category.emoji,
      'title': _descController.text,
      'subtitle': '${_dateController.text} · ${category.name}',
      'amount': _isExpense
          ? '- ${CurrencyUtils.formatFromCents(cents)}'
          : '+ ${CurrencyUtils.formatFromCents(cents)}',
      'positive': !_isExpense,
    };

    Provider.of<TransactionProvider>(context, listen: false)
        .addTransaction(newTransaction);

    setState(() {
      _valueController.clear();
      _dateController.clear();
      _descController.clear();
      _selectedCategory = null;
      _isExpense = true; // Reseta para o padrão
    });

    // Rola para o fim da lista de forma mais robusta
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- ALTERAÇÃO PRINCIPAL: LayoutBuilder para criar uma UI Responsiva ---
    return LayoutBuilder(
      builder: (context, constraints) {
        // Se a tela for larga (web/tablet), usa Row. Se for estreita (celular), usa Column.
        bool isWide = constraints.maxWidth > 800;

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
          // Em telas estreitas, tudo fica em uma única coluna rolável (ListView)
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
        crossAxisAlignment: CrossAxisAlignment.stretch, // Estica o botão
        mainAxisSize: MainAxisSize.min, // Ocupa o mínimo de espaço vertical
        children: [
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
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            items: categories
                .map((c) => DropdownMenuItem(
              value: c.name,
              child: Text('${c.emoji} ${c.name}'),
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
            onPressed: _addTransaction,
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
    // Usamos um Consumer para reconstruir apenas a lista quando os dados mudarem
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        return Container(
          height: 570, // Altura fixa para o layout lado a lado
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
              // --- CORREÇÃO DO SCROLL ---
              // Expanded garante que a lista ocupe todo o espaço vertical disponível no Card
              Expanded(
                child: provider.transactions.isEmpty
                    ? Center(
                  child: Text(
                    'Nenhuma transação registrada.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
                    : ListView.builder(
                  controller: _scrollController,
                  itemCount: provider.transactions.length,
                  itemBuilder: (context, index) {
                    final t = provider.transactions[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _transactionItem(t['emoji'], t['title'],
                          t['subtitle'], t['amount'], t['positive']),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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

// --- FORMATTERS MANTIDOS, MAS COM MELHORIAS NO CÓDIGO PRINCIPAL ---
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