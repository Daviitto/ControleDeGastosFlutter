import 'dart:convert'; // 🔹 Importar
import 'package:http/http.dart' as http; // 🔹 Importar
import 'package:controle_financeiro_flutter/main.dart';
import 'package:flutter/material.dart';
import 'register_screen.dart';
import '../utills/app_constants.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 🔹 Controladores para pegar os valores
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false; // 🔹 Para loading

  // 🔹 Base URL (use 'http://localhost:8080' se estiver no Chrome web)
  final String _baseUrl = 'http://localhost:8080';
  // final String _baseUrl = 'http://10.0.2.2:8080'; // Se for emulador Android

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    if (_emailController.text.isEmpty || _senhaController.text.isEmpty) {
      _showErrorSnackbar('E-mail e senha são obrigatórios.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/usuario/login'), // 🔹 Endpoint de login
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': _emailController.text,
          'senha': _senhaController.text,
        }),
      );

      if (response.statusCode == 200) {
        // 🔹 Sucesso! Login feito
        if (mounted) {
          // 🔹 🔹 🔹 INÍCIO DA MUDANÇA 🔹 🔹 🔹

          // 1. Decodifica a resposta para pegar os dados do usuário
          // Usamos utf8.decode para garantir que nomes com acentos sejam lidos
          final Map<String, dynamic> usuarioData = jsonDecode(utf8.decode(response.bodyBytes));

          // 2. Extrai o ID do usuário
          // Certifique-se que seu JSON de Usuario (Java) retorna um campo 'id'
          final int usuarioId = usuarioData['id'];

          // 3. Navega para a HomeShell, AGORA PASSANDO O ID DO USUÁRIO
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeShell(usuarioId: usuarioId), // 🔹 Passa o ID
            ),
          );
          // 🔹 🔹 🔹 FIM DA MUDANÇA 🔹 🔹 🔹
        }
      } else if (response.statusCode == 401) {
        // 🔹 Não autorizado
        _showErrorSnackbar('E-mail ou senha incorretos.');
      } else {
        // 🔹 Outros erros
        _showErrorSnackbar('Erro ao fazer login: ${response.body}');
      }
    } catch (e) {
      _showErrorSnackbar('Erro de conexão: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBgColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // ... (Logo e Títulos - sem mudanças) ...
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.trending_up, color: primaryColor, size: 30),
                  SizedBox(width: 8),
                  Text(
                    'FinControl',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),

              // Título
              const Text(
                'Bem-vindo de volta',
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Acesse sua conta para gerenciar suas finanças',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 30),

              // Campo E-mail
              const Text(
                'E-mail',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController, // 🔹 Vincula controlador
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'seu@email.com',
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 2),
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Campo Senha
              const Text(
                'Senha',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _senhaController, // 🔹 Vincula controlador
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  hintText: '.......',
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 2),
                  ),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),

              // ... (Esqueceu a Senha? - sem mudanças) ...
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Lógica para Esqueceu a senha
                  },
                  child: const Text(
                    'Esqueceu a senha?',
                    style: TextStyle(color: primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Botão Entrar
              ElevatedButton(
                onPressed: _isLoading ? null : _loginUser, // 🔹 Chama a função
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text('Entrar'),
              ),

              const SizedBox(height: 30),

              // ... (Não tem uma conta? - sem mudanças) ...
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Não tem uma conta? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterPage()),
                      );
                    },
                    child: const Text(
                      "Criar conta",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}