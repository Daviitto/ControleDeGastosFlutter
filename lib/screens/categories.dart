import 'package:flutter/material.dart';
import '../data/categories.dart';
import '../models/category.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedEmoji;

  final List<String> emojis = [
    '🏠', '🚗', '🍔', '🎮', '💊', '📚', '✈️', '🛒', '💳', '🎬', '⚽', '🎵', '💰', '🎁', '🏥', '👔'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addCategory() {
    if (_nameController.text.isNotEmpty && _selectedEmoji != null) {
      bool exists = categories.any((c) => c.name.toLowerCase() == _nameController.text.toLowerCase());
      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Essa categoria já existe.'), backgroundColor: Colors.red),
        );
        return;
      }
      setState(() {
        categories.add(Category(name: _nameController.text, emoji: _selectedEmoji!));
        _nameController.clear();
        _selectedEmoji = null;
      });
      FocusScope.of(context).unfocus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha o nome e selecione um ícone.')),
      );
    }
  }

  void _deleteCategory(Category category) {
    setState(() {
      categories.remove(category);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 800;

        if (isWide) {
          // --- LAYOUT CORRIGIDO PARA TELAS LARGAS ---
          return Padding(
            padding: const EdgeInsets.all(16.0),
            // IntrinsicHeight força os dois cards a terem a mesma altura do maior
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 1, child: _newCategoryCard()),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: _existingCategoriesCard(isWide: true)),
                ],
              ),
            ),
          );
        } else {
          // --- LAYOUT CORRIGIDO PARA TELAS ESTREITAS ---
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _newCategoryCard(),
              const SizedBox(height: 16),
              _existingCategoriesCard(isWide: false),
            ],
          );
        }
      },
    );
  }

  Widget _newCategoryCard() {
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
          const Text('Nova Categoria', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nome da Categoria',
              hintText: 'Ex: Moradia',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Ícone', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: emojis.map((e) => GestureDetector(
              onTap: () => setState(() => _selectedEmoji = e),
              child: Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(25),
                  border: _selectedEmoji == e ? Border.all(color: Colors.black, width: 2.5) : null,
                ),
                child: Center(child: Text(e, style: const TextStyle(fontSize: 24))),
              ),
            )).toList(),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addCategory,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Adicionar Categoria', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _existingCategoriesCard({required bool isWide}) {
    // O conteúdo da lista de categorias
    Widget categoryList = categories.isEmpty
        ? Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Text('Nenhuma categoria cadastrada.', style: TextStyle(color: Colors.grey.shade600)),
      ),
    )
        : ListView.builder(
      // --- CORREÇÃO PARA TELAS ESTREITAS ---
      // shrinkWrap e physics fazem a lista se comportar como uma coluna,
      // delegando o scroll para o ListView pai.
      shrinkWrap: !isWide,
      physics: !isWide ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              Text(category.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(child: Text(category.name)),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                onPressed: () => _deleteCategory(category),
                tooltip: 'Deletar Categoria',
              ),
            ],
          ),
        );
      },
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Categorias Existentes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          // --- CORREÇÃO PARA TELAS LARGAS ---
          // Se for tela larga, usamos Expanded para dar à lista uma altura definida.
          // Se não, o widget simplesmente é renderizado diretamente.
          if (isWide) Expanded(child: categoryList) else categoryList,
        ],
      ),
    );
  }
}