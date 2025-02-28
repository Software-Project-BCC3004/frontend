import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class PewsEvaluation {
  final int? id;
  final String avaliacao_neurologica;
  final String avaliacao_cardiovascular;
  final String avaliacao_respiratoria;
  final String emese;
  final String nebulizacao;
  final String idPaciente;
  final int pontuacaoTotal;
  final DateTime data_pews;

  PewsEvaluation({
    this.id,
    required this.avaliacao_neurologica,
    required this.avaliacao_cardiovascular,
    required this.avaliacao_respiratoria,
    required this.emese,
    required this.nebulizacao,
    required this.idPaciente,
    required this.pontuacaoTotal,
    required this.data_pews,
  });

  Map<String, dynamic> toJson() {
    return {
      'avaliacao_neurologica': avaliacao_neurologica,
      'avaliacao_cardiovascular': avaliacao_cardiovascular,
      'avaliacao_respiratoria': avaliacao_respiratoria,
      'emese': emese,
      'nebulizacao': nebulizacao,
      'idPaciente': idPaciente,
      'pontuacaoTotal': pontuacaoTotal,
      'data_pews': DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(data_pews),
    };
  }

  factory PewsEvaluation.fromJson(Map<String, dynamic> json) {
    return PewsEvaluation(
      id: json['id'] is String ? int.tryParse(json['id']) : json['id'],
      avaliacao_neurologica: json['avaliacao_neurologica'] ?? 'AN0',
      avaliacao_cardiovascular: json['avaliacao_cardiovascular'] ?? 'AC0',
      avaliacao_respiratoria: json['avaliacao_respiratoria'] ?? 'AR0',
      emese: json['emese'] ?? 'EmeseNAO',
      nebulizacao: json['nebulizacao'] ?? 'NebulisacaoNAO',
      idPaciente: json['idPaciente']?.toString() ?? '',
      pontuacaoTotal: json['pontuacaoTotal'] is String
          ? int.tryParse(json['pontuacaoTotal']) ?? 0
          : json['pontuacaoTotal'] ?? 0,
      data_pews: json['data_pews'] != null
          ? DateTime.parse(json['data_pews'])
          : DateTime.now(),
    );
  }
}

class PewsService {
  final String baseUrl = 'http://localhost:8080';

  // Adicione este StreamController como uma variável estática
  static final StreamController<bool> _pewsUpdateController =
      StreamController<bool>.broadcast();

  // Stream que outros widgets podem ouvir para saber quando os dados PEWS mudaram
  static Stream<bool> get pewsUpdateStream => _pewsUpdateController.stream;

  // Método para notificar que houve uma mudança nos dados PEWS
  void notifyPewsUpdate() {
    _pewsUpdateController.add(true);
  }

  Future<List<PewsEvaluation>> getAllPewsEvaluations() async {
    final response = await http.get(
      Uri.parse('$baseUrl/avaliacao/pews/listar'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => PewsEvaluation.fromJson(json)).toList();
    } else if (response.statusCode == 404 || response.statusCode == 204) {
      // Retornar lista vazia se não houver avaliações
      return [];
    } else {
      throw Exception(
          'Falha ao buscar avaliações PEWS: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> createPewsEvaluation(PewsEvaluation pews) async {
    final response = await http.post(
      Uri.parse('$baseUrl/avaliacao/pews/criar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(pews.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      notifyPewsUpdate();
      return jsonDecode(response.body);
    } else {
      print('Erro na resposta: ${response.statusCode} - ${response.body}');
      throw Exception(
          'Falha ao criar avaliação PEWS: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> updatePewsEvaluation(
      dynamic id, PewsEvaluation pews) async {
    final response = await http.put(
      Uri.parse('$baseUrl/avaliacao/pews/atualizar/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(pews.toJson()),
    );

    if (response.statusCode == 200) {
      notifyPewsUpdate();
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Falha ao atualizar avaliação PEWS: ${response.statusCode} - ${response.body}');
    }
  }

  Future<bool> deletePewsEvaluation(int id) async {
    try {
      // Usar a URL correta para deletar
      final response = await http.delete(
        Uri.parse('$baseUrl/avaliacao/pews/deletar/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      // Considerar 204 (No Content) como sucesso
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Notificar sobre a exclusão
        notifyPewsUpdate();
        return true;
      } else {
        throw Exception(
            'Falha ao excluir avaliação PEWS: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao excluir avaliação PEWS: $e');
    }
  }
}
