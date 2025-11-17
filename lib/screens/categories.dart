import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';



class Categoria {
  final int id;
  final String nome;
  final String icone;

  Categoria({required this.id, required this.nome, required this.icone});

  // Construtor 'factory' para criar um Categoria a partir de um JSON
  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'],
      nome: json['nome'],
      icone: json['icone'],
    );
  }
}


class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedEmoji;



  List<Categoria> _categories = [];
  bool _isLoading = true; // Para mostrar um loader
  String? _error; // Para mostrar mensagens de erro


  final String _baseUrl = 'http://localhost:8080';

  final List<String> emojis = [
    '🏠', '🚗', '🍔', '🎮', '💊', '📚', '✈️', '🛒',
    '💳', '🎬', '⚽', '🎵', '💰', '🎁', '🏥', '👔','🏍️','🛍️'
  ];

  @override
  void initState() {
    super.initState();
    // 🔹 4. CARREGAR AS CATEGORIAS QUANDO A TELA INICIA
    _fetchCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // 🔹 5. FUNÇÃO PARA BUSCAR CATEGORIAS (GET)
  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(Uri.parse('$_baseUrl/categoria'));

      if (response.statusCode == 200) {
        // Usa utf8.decode para lidar com acentos (ex: 'Moradia')
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _categories = data.map((json) => Categoria.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Falha ao carregar categorias');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Erro ao conectar à API: $e';
      });
    }
  }

  // 🔹 6. FUNÇÃO PARA ADICIONAR CATEGORIA (POST)
  Future<void> _addCategory() async {
    if (_nameController.text.isNotEmpty && _selectedEmoji != null) {
      bool exists = _categories.any((c) => c.nome.toLowerCase() == _nameController.text.toLowerCase());
      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Essa categoria já existe.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Mostra loading no botão (opcional, mas bom UX)
      setState(() { /* Poderia ter um _isAdding = true */ });

      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/categoria'),
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode({
            'nome': _nameController.text,
            'icone': _selectedEmoji!, // O 'icone' do backend armazena o emoji
          }),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Sucesso! Limpa os campos e atualiza a lista
          _nameController.clear();
          _selectedEmoji = null;
          _fetchCategories(); // Recarrega a lista do backend
          FocusScope.of(context).unfocus();
        } else {
          throw Exception('Falha ao salvar categoria');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha o nome e selecione um ícone.')),
      );
    }
  }

  // 🔹 7. FUNÇÃO PARA DELETAR CATEGORIA (DELETE)
  Future<void> _deleteCategory(Categoria category) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/categoria/${category.id}'),
      );

      if (response.statusCode == 200) {
        // Remove da lista local para atualizar a UI imediatamente
        setState(() {
          _categories.removeWhere((c) => c.id == category.id);
        });
      } else {
        throw Exception('Falha ao deletar categoria');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao deletar: $e')),
      );
    }
  }

  // ... (build() e _newCategoryCard() não mudam) ...
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 800;

        if (isWide) {
          // --- LAYOUT PARA TELAS LARGAS ---
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 1, child: _newCategoryCard()),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _existingCategoriesCard(isWide: true)),
              ],
            ),
          );
        } else {
          // --- LAYOUT PARA TELAS PEQUENAS ---
          return ListView(
            padding: const EdgeInsets.all(16),
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
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(25),
                  border: _selectedEmoji == e
                      ? Border.all(color: Colors.black, width: 2.5)
                      : null,
                ),
                child: Center(child: Text(e, style: const TextStyle(fontSize: 24))),
              ),
            )).toList(),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            // 🔹 8. OnPressed agora chama a função async
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

  // 🔹 9. WIDGET DE CATEGORIAS EXISTENTES ATUALIZADO
  Widget _existingCategoriesCard({required bool isWide}) {
    Widget content;

    if (_isLoading) {
      content = const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32.0),
          child: CircularProgressIndicator(),
        ),
      );
    } else if (_error != null) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0),
          child: Text(
            _error!,
            style: TextStyle(color: Colors.red.shade700),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else if (_categories.isEmpty) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0),
          child: Text(
            'Nenhuma categoria cadastrada.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    } else {
      content = ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _categories.length, // 🔹 Usa a lista do estado
        itemBuilder: (context, index) {
          final category = _categories[index]; // 🔹 Usa a lista do estado
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Text(category.icone, style: const TextStyle(fontSize: 20)), // 🔹 Usa .icone
                const SizedBox(width: 12),
                Expanded(child: Text(category.nome)), // 🔹 Usa .nome
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                  onPressed: () => _deleteCategory(category), // 🔹 Chama a função
                  tooltip: 'Deletar Categoria',
                ),
              ],
            ),
          );
        },
      );
    }

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
          content, // 🔹 Mostra o conteúdo (loading, erro, lista ou vazio)
        ],
      ),
    );
  }
}