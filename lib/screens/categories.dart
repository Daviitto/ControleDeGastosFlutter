import 'package:flutter/material.dart';
import '../data/categories.dart';
import '../models/category.dart';

class CategoriesScreen extends StatefulWidget {
  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedEmoji;

  final List<String> emojis = ['🏠','🚗','🍔','🎮','💊','📚','✈️','🛒','💳','🎬','⚽','🎵','💰'];

  void _addCategory() {
    if (_nameController.text.isNotEmpty && _selectedEmoji != null) {
      setState(() {
        categories.add(Category(name: _nameController.text, emoji: _selectedEmoji!));
        _nameController.clear();
        _selectedEmoji = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Novo
          Expanded(
            child: Container(
              padding: EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nova Categoria', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  TextField(controller: _nameController, decoration: InputDecoration(hintText: 'Nome da Categoria', border: OutlineInputBorder())),
                  SizedBox(height: 12),
                  Text('Ícone'),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: emojis.map((e) => GestureDetector(
                      onTap: () => setState(() => _selectedEmoji = e),
                      child: Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          color: _selectedEmoji == e ? Colors.black12 : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(child: Text(e, style: TextStyle(fontSize: 24))),
                      ),
                    )).toList(),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _addCategory,
                    icon: Icon(Icons.add, color: Colors.white,),
                    label: Text('Adicionar Categoria', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(width: 16),

          // Existentes
          Expanded(
            child: Container(
              padding: EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Categorias Existentes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  ...categories.map((c) => Container(
                    margin: EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        Text(c.emoji, style: TextStyle(fontSize: 20)),
                        SizedBox(width: 12),
                        Text(c.name),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
