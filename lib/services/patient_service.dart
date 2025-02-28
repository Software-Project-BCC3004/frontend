import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

class Patient {
  final int? id;
  final String nomePaciente;
  final String cpfPaciente;
  final String diagnostico;
  final String leito;
  final String grauSeveridade;
  final String nomeResponsavel;
  final String cpfResponsavel;

  Patient({
    this.id,
    required this.nomePaciente,
    required this.cpfPaciente,
    required this.diagnostico,
    required this.leito,
    required this.grauSeveridade,
    required this.nomeResponsavel,
    required this.cpfResponsavel,
  });

  Map<String, dynamic> toJson() {
    return {
      'nomePaciente': nomePaciente,
      'cpfPaciente': cpfPaciente,
      'diagnostico': diagnostico,
      'leito': leito,
      'grauSeveridade': grauSeveridade,
      'nomeResponsavel': nomeResponsavel,
      'cpfResponsavel': cpfResponsavel,
    };
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      nomePaciente: json['nomePaciente'] ?? '',
      cpfPaciente: json['cpfPaciente'] ?? '',
      diagnostico: json['diagnostico'] ?? '',
      leito: json['leito'] ?? '',
      grauSeveridade: json['grauSeveridade'] ?? '',
      nomeResponsavel: json['nomeResponsavel'] ?? '',
      cpfResponsavel: json['cpfResponsavel'] ?? '',
    );
  }
}

class PatientService {
  static const String baseUrl = 'http://localhost:8080/pacientes';

  // Adicionar um StreamController para notificar sobre atualizações
  static final StreamController<void> _patientUpdateController =
      StreamController<void>.broadcast();
  static Stream<void> get patientUpdateStream =>
      _patientUpdateController.stream;

  // Método para notificar sobre atualizações
  void notifyPatientUpdate() {
    _patientUpdateController.add(null);
  }

  // Método para converter do modelo UI para o modelo API
  Patient convertToApiPatient(Map<String, dynamic> data) {
    return Patient(
      nomePaciente: data['nomePaciente'] ?? '',
      cpfPaciente: data['cpfPaciente'] ?? '',
      diagnostico: data['diagnostico'] ?? '',
      leito: data['leito'] ?? '',
      grauSeveridade: data['grauSeveridade'] ?? '',
      nomeResponsavel: data['nomeResponsavel'] ?? '',
      cpfResponsavel: data['cpfResponsavel'] ?? '',
    );
  }

  Future<List<Patient>> getAllPatients() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/consultar/todos'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Patient.fromJson(json)).toList();
      } else if (response.statusCode == 404 || response.statusCode == 204) {
        // Lista vazia
        return [];
      } else {
        throw Exception('Falha ao carregar pacientes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  Future<Patient> getPatientById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/consultar/$id'),
      );

      if (response.statusCode == 200) {
        return Patient.fromJson(json.decode(response.body));
      } else {
        throw Exception('Falha ao carregar paciente: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  Future<List<Patient>> getPatientByCpf(String cpf) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/consultar/cpf/$cpf'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Patient.fromJson(json)).toList();
      } else if (response.statusCode == 404 || response.statusCode == 204) {
        return [];
      } else {
        throw Exception(
            'Falha ao buscar paciente por CPF: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  Future<List<Patient>> getPatientByName(String name) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/consultar/nome/$name'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Patient.fromJson(json)).toList();
      } else if (response.statusCode == 404 || response.statusCode == 204) {
        return [];
      } else {
        throw Exception(
            'Falha ao buscar paciente por nome: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  Future<Map<String, dynamic>> createPatient(
      Map<String, dynamic> patientData) async {
    try {
      print('Enviando dados: ${json.encode(patientData)}');

      final response = await http.post(
        Uri.parse('$baseUrl/criar'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(patientData),
      );

      print('Resposta: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Notificar sobre a criação
        notifyPatientUpdate();
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
            'Falha ao criar paciente: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Erro detalhado: $e');
      throw Exception('Erro na requisição: $e');
    }
  }

  Future<Map<String, dynamic>> updatePatient(
      int id, Map<String, dynamic> patientData) async {
    try {
      print('Enviando dados para atualização: ${json.encode(patientData)}');

      final response = await http.put(
        Uri.parse('$baseUrl/atualizar/$id'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(patientData),
      );

      print('Resposta: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        // Notificar sobre a atualização
        notifyPatientUpdate();
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
            'Falha ao atualizar paciente: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Erro detalhado: $e');
      throw Exception('Erro na requisição: $e');
    }
  }

  Future<bool> deletePatient(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/deletar/$id'),
      );

      // Notificar sobre a exclusão
      notifyPatientUpdate();

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }
}
