import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';



class Categoria {
  final int id;
  final String nome;
  final String icone;
  Categoria({required this.id, required this.nome, required this.icone});
  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(id: json['id'], nome: json['nome'], icone: json['icone']);
  }
}

class Transacao {
  final int id;
  final String descricao;
  final double valor;
  final String data;
  final String tipo;
  final Categoria categoria;
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

// --- FORMATAÇÃO DE MOEDA (Para consistência) ---
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
}

// --- TELA DE DASHBOARD (Agora é Stateful) ---

class DashboardScreen extends StatefulWidget {
  // 🔹 1. PRECISA RECEBER O ID DO USUÁRIO
  final int usuarioId;

  const DashboardScreen({super.key, required this.usuarioId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // 🔹 2. Estado local para armazenar os dados da API
  List<Transacao> _transactions = [];
  double _totalReceitas = 0.0;
  double _totalDespesas = 0.0;
  double _saldo = 0.0;
  bool _isLoading = true;
  String? _error;

  final String _baseUrl = 'http://localhost:8080';

  @override
  void initState() {
    super.initState();
    // 🔹 3. Busca os dados quando a tela é construída
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 🔹 4. USA O NOVO ENDPOINT DE USUÁRIO
      final response = await http.get(
        Uri.parse('$_baseUrl/transacao/usuario/${widget.usuarioId}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        final transactions = data.map((json) => Transacao.fromJson(json)).toList();

        // 🔹 5. Calcula os totais
        _calculateSummary(transactions);
      } else {
        throw Exception('Falha ao carregar transações');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Erro ao conectar à API: $e';
      });
    }
  }

  // 🔹 6. Função para calcular o resumo financeiro
  void _calculateSummary(List<Transacao> transactions) {
    double receitas = 0;
    double despesas = 0;

    for (var t in transactions) {
      if (t.valor > 0) {
        receitas += t.valor;
      } else if (t.valor < 0) {
        despesas += t.valor; // despesas é um valor negativo
      }
    }

    setState(() {
      _transactions = transactions;
      _totalReceitas = receitas;
      _totalDespesas = despesas;
      _saldo = receitas + despesas;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 7. Lida com o estado de Loading e Erro
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Erro ao carregar dados:\n$_error',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // --- O restante do seu build, agora usando o estado local ---

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
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 🔹 8. Usa os valores do estado local
                Expanded(child: _summaryCard('Receitas', CurrencyUtils.formatFromDouble(_totalReceitas), Colors.green.shade50, Colors.green.shade600)),
                const SizedBox(width: 12),
                Expanded(child: _summaryCard('Despesas', CurrencyUtils.formatFromDouble(_totalDespesas), Colors.red.shade50, Colors.red)),
                const SizedBox(width: 12),
                Expanded(child: _summaryCard('Saldo', CurrencyUtils.formatFromDouble(_saldo), Colors.blue.shade50, Colors.blue.shade700)),
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
                if (_transactions.isEmpty)
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
                    // 🔹 9. Usa a lista do estado local
                    itemCount: _transactions.length > 5 ? 5 : _transactions.length,
                    itemBuilder: (context, index) {
                      // 🔹 Pega as transações mais recentes (invertido)
                      final t = _transactions.reversed.toList()[index];
                      // 🔹 10. Constrói o item com dados reais
                      return _transactionItem(
                        t.categoria.icone,
                        t.descricao,
                        '${t.data} · ${t.categoria.nome}',
                        CurrencyUtils.formatFromDouble(t.valor),
                        t.valor >= 0, // 'positive' é baseado no valor
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

  // ❌ Removemos a função _format local, pois usamos CurrencyUtils

  // ... (Seu widget _summaryCard não precisa de mudanças) ...
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

  // ... (Seu widget _transactionItem não precisa de mudanças) ...
  Widget _transactionItem(String emoji, String title, String subtitle, String amount, bool positive) {
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