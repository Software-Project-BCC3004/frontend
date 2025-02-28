import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = 'http://localhost:8080';

  Future<String?> login(String email, String password, bool isAdmin) async {
    try {
      // Escolher a rota correta com base no tipo de usuário
      final endpoint = isAdmin ? '/auth/adm/login' : '/auth/profissional/login';

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'senha': password,
        }),
      );

      if (response.statusCode == 200) {
        // Retorna o token JWT
        return response.body;
      } else {
        print('Erro no login: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exceção no login: $e');
      return null;
    }
  }
}
