import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://localhost:8080';

  Future<String?> loginAsAdmin(String email, String senha) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/adm/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': '*/*',
        },
        body: jsonEncode({
          'email': email,
          'senha': senha,
        }),
      );

      if (response.statusCode == 200) {
        // O backend retorna o token diretamente, não em formato JSON
        return response.body;
      }
      print('Erro no login ADM: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('Erro no login ADM: $e');
      return null;
    }
  }

  Future<String?> loginAsProfissional(String email, String senha) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/profissional/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': '*/*',
        },
        body: jsonEncode({
          'email': email,
          'senha': senha,
        }),
      );

      if (response.statusCode == 200) {
        // O backend retorna o token diretamente, não em formato JSON
        return response.body;
      }
      print(
          'Erro no login Profissional: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('Erro no login Profissional: $e');
      return null;
    }
  }
}
