import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _chartCard()),
          SizedBox(width: 12),
          Expanded(child: _barCard()),
        ],
      ),
    );
  }

  Widget _chartCard() {
    return Container(
      height: 380,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gastos por Categoria', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(child: Center()),
        ],
      ),
    );
  }

  Widget _barCard() {
    return Container(
      height: 380,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Evolução Mensal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(child: Center()),
        ],
      ),
    );
  }
}
