import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/categories.dart';
import '../providers/transactions_provider.dart';

class TransactionsScreen extends StatefulWidget {
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
        _selectedCategory == null) return;

    final category = categories.firstWhere(
          (c) => c.name == _selectedCategory,
      orElse: () => categories.first,
    );

    final digits = _valueController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final cents = digits.isNotEmpty ? int.tryParse(digits) ?? 0 : 0;

    final newTransaction = {
      'emoji': category.emoji,
      'title': _descController.text,
      'subtitle': '${_dateController.text} · ${category.name}',
      'amount': _isExpense
          ? '- ${_formatCurrencyFromCents(cents)}'
          : '+ ${_formatCurrencyFromCents(cents)}',
      'positive': !_isExpense,
    };

    // 🔹 Adiciona globalmente
    Provider.of<TransactionProvider>(context, listen: false)
        .addTransaction(newTransaction);

    // 🔹 Limpa os campos
    setState(() {
      _valueController.clear();
      _dateController.clear();
      _descController.clear();
      _selectedCategory = null;
    });

    // 🔹 Rola para o fim da lista
    Future.delayed(Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatCurrencyFromCents(int cents) {
    final int reais = cents ~/ 100;
    final int centavos = cents % 100;
    String reaisStr = reais.toString();

    final buffer = StringBuffer();
    int count = 0;
    for (int i = reaisStr.length - 1; i >= 0; i--) {
      buffer.write(reaisStr[i]);
      count++;
      if (count == 3 && i != 0) {
        buffer.write('.');
        count = 0;
      }
    }
    final reaisWithDots = buffer.toString().split('').reversed.join();

    return 'R\$ $reaisWithDots,${centavos.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _formCard()),
          SizedBox(width: 16),
          Expanded(child: _historyCard(provider)),
        ],
      ),
    );
  }

  Widget _formCard() {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nova Transação',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Text('Tipo'),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isExpense = true),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: _isExpense ? Colors.red : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                        child: Text('Despesa',
                            style: TextStyle(
                                color:
                                _isExpense ? Colors.white : Colors.black))),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isExpense = false),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: !_isExpense ? Colors.green : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                        child: Text('Receita',
                            style: TextStyle(
                                color:
                                !_isExpense ? Colors.white : Colors.black))),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text('Valor'),
          SizedBox(height: 8),
          TextField(
            controller: _valueController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(15),
              _CurrencyInputFormatter(),
            ],
            decoration: InputDecoration(
              hintText: '0.00',
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          SizedBox(height: 12),
          Text('Data'),
          SizedBox(height: 8),
          TextField(
            controller: _dateController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
              _DateInputFormatter(),
            ],
            decoration: InputDecoration(
              hintText: '04/10/2025',
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          SizedBox(height: 12),
          Text('Descrição'),
          SizedBox(height: 8),
          TextField(
            controller: _descController,
            decoration: InputDecoration(
              hintText: 'Ex: Almoço no restaurante',
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          SizedBox(height: 12),
          Text('Categoria'),
          SizedBox(height: 8),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _addTransaction,
            icon: Icon(Icons.add, color: Colors.white),
            label: Text('Adicionar Transação',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _historyCard(TransactionProvider provider) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Histórico',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 400),
            child: ListView.builder(
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
  }

  Widget _transactionItem(
      String emoji, String title, String subtitle, String amount, bool positive) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 22)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
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

/// formata "04102025" → "04/10/2025"
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue next) {
    var text = next.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i == 1 || i == 3) && i != text.length - 1) buffer.write('/');
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

/// formata em tempo real para “R$ 1.234,56”
class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue next) {
    String digits = next.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return TextEditingValue(text: '');
    if (digits.length > 15) digits = digits.substring(0, 15);

    final int cents = int.tryParse(digits) ?? 0;
    final int reais = cents ~/ 100;
    final int centavos = cents % 100;
    String reaisStr = reais.toString();

    final buffer = StringBuffer();
    int count = 0;
    for (int i = reaisStr.length - 1; i >= 0; i--) {
      buffer.write(reaisStr[i]);
      count++;
      if (count == 3 && i != 0) {
        buffer.write('.');
        count = 0;
      }
    }
    final reaisWithDots = buffer.toString().split('').reversed.join();
    final formatted =
        'R\$ $reaisWithDots,${centavos.toString().padLeft(2, '0')}';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
