import 'package:flutter/material.dart';

class TransactionProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _transactions = [];

  List<Map<String, dynamic>> get transactions => _transactions;

  void addTransaction(Map<String, dynamic> t) {
    _transactions.add(t);
    notifyListeners();
  }

  double get totalReceitas => _sum(true);
  double get totalDespesas => _sum(false);
  double get saldo => totalReceitas - totalDespesas;

  double _sum(bool positive) {
    double total = 0;
    for (var t in _transactions) {
      if (t['positive'] == positive) {
        final digits =
        t['amount'].replaceAll(RegExp(r'[^0-9,]'), '').replaceAll(',', '.');
        total += double.tryParse(digits) ?? 0.0;
      }
    }
    return total;
  }
}
