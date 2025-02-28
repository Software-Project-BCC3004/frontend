import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/professional.dart';

class ProfessionalService {
  final String baseUrl = 'http://localhost:8080';

  Future<List<Professional>> getAllProfessionals() async {
    final response = await http.get(
      Uri.parse('$baseUrl/profissional/consultar/todos'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Professional.fromJson(json)).toList();
    } else if (response.statusCode == 404 || response.statusCode == 204) {
      return [];
    } else {
      throw Exception(
          'Falha ao buscar profissionais: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Professional> createProfessional(Professional professional) async {
    final response = await http.post(
      Uri.parse('$baseUrl/profissional/criar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(professional.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Professional.fromJson(jsonDecode(response.body));
    } else {
      print('Erro na resposta: ${response.statusCode} - ${response.body}');
      throw Exception(
          'Falha ao criar profissional: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Professional> updateProfessional(
      String id, Professional professional) async {
    final response = await http.put(
      Uri.parse('$baseUrl/profissional/atualizar/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(professional.toJson()),
    );

    if (response.statusCode == 200) {
      return Professional.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
          'Falha ao atualizar profissional: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> deleteProfessional(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/profissional/deletar/$id'),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Falha ao deletar profissional: ${response.statusCode} - ${response.body}');
    }
  }
}
