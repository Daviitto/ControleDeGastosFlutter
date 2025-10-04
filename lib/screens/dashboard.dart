import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transactions_provider.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);

    final cardStyle = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _summaryCard('Receitas', _format(provider.totalReceitas), Colors.green.shade50, Colors.green)),
              SizedBox(width: 12),
              Expanded(child: _summaryCard('Despesas', _format(provider.totalDespesas), Colors.red.shade50, Colors.red)),
              SizedBox(width: 12),
              Expanded(child: _summaryCard('Saldo', _format(provider.saldo), Colors.grey.shade100, Colors.green)),
            ],
          ),
          SizedBox(height: 20),
          Container(
            decoration: cardStyle,
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Transações Recentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                for (var t in provider.transactions.reversed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _transactionItem(
                      t['emoji'],
                      t['title'],
                      t['subtitle'],
                      t['amount'],
                      t['positive'],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _format(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Widget _summaryCard(String title, String value, Color bg, Color accent) {
    return Container(
      height: 120,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[700])),
          Spacer(),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: accent)),
          SizedBox(height: 6),
          Text(title == 'Saldo' ? 'Saldo atual' : (title == 'Receitas' ? 'Total de entradas' : 'Total de saídas'),
              style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _transactionItem(String emoji, String title, String subtitle, String amount, bool positive) {
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
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Text(amount, style: TextStyle(color: positive ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
