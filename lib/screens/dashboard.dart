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
      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- ALTERAÇÃO PRINCIPAL AQUI ---
          // O IntrinsicHeight força a Row e seus filhos a terem a mesma altura.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _summaryCard('Receitas', _format(provider.totalReceitas), Colors.green.shade50, Colors.green.shade600)),
                const SizedBox(width: 12),
                Expanded(child: _summaryCard('Despesas', _format(provider.totalDespesas), Colors.red.shade50, Colors.red)),
                const SizedBox(width: 12),
                Expanded(child: _summaryCard('Saldo', _format(provider.saldo), Colors.blue.shade50, Colors.blue.shade700)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: cardStyle,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Transações Recentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (provider.transactions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Text(
                        'Nenhuma transação encontrada.',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.transactions.length > 5 ? 5 : provider.transactions.length,
                    itemBuilder: (context, index) {
                      final t = provider.transactions.reversed.toList()[index];
                      return _transactionItem(
                        t['emoji'],
                        t['title'],
                        t['subtitle'],
                        t['amount'],
                        t['positive'],
                      );
                    },
                    separatorBuilder: (context, index) => const Divider(height: 16),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _format(double value) {
    final prefix = value < 0 ? '- R\$ ' : 'R\$ ';
    return prefix + value.abs().toStringAsFixed(2).replaceAll('.', ',');
  }

  Widget _summaryCard(String title, String value, Color bg, Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[800], fontSize: 14, fontWeight: FontWeight.w600)),
          // O Spacer é crucial aqui, pois ele vai expandir para preencher o espaço extra
          // que o IntrinsicHeight e o stretch do CrossAxisAlignment vão fornecer.
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: accent),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title == 'Saldo' ? 'Saldo atual' : (title == 'Receitas' ? 'Total de entradas' : 'Total de saídas'),
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _transactionItem(String emoji, String title, String subtitle, String amount, bool positive) {
    // Nenhuma alteração necessária aqui
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          amount,
          style: TextStyle(
            color: positive ? Colors.green.shade600 : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}