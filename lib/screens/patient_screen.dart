import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/services/patient_service.dart';
import 'dart:async';

class PatientScreen extends StatefulWidget {
  static void refreshInstance(BuildContext context) {
    final state = context.findAncestorStateOfType<_PatientScreenState>();
    if (state != null) {
      state._loadPatients();
    }
  }

  const PatientScreen({super.key});

  @override
  State<PatientScreen> createState() => _PatientScreenState();
}

class Patient {
  final int? id;
  final String name;
  final String cpf;
  final String diagnosis;
  final String bed;
  final String severity;
  final String responsibleName;
  final String responsibleCpf;

  Patient({
    this.id,
    required this.name,
    required this.cpf,
    required this.diagnosis,
    required this.bed,
    required this.severity,
    required this.responsibleName,
    required this.responsibleCpf,
  });

  // Converter para o modelo da API
  Map<String, dynamic> toApiModel() {
    return {
      'nomePaciente': name,
      'cpfPaciente': cpf,
      'diagnostico': diagnosis,
      'leito': bed,
      'grauSeveridade': severity,
      'nomeResponsavel': responsibleName,
      'cpfResponsavel': responsibleCpf,
    };
  }

  // Criar a partir do modelo da API
  static Patient fromApiModel(Map<String, dynamic> apiModel) {
    return Patient(
      id: apiModel['id'],
      name: apiModel['nomePaciente'] ?? '',
      cpf: apiModel['cpfPaciente'] ?? '',
      diagnosis: apiModel['diagnostico'] ?? '',
      bed: apiModel['leito'] ?? '',
      severity: apiModel['grauSeveridade'] ?? 'Baixo',
      responsibleName: apiModel['nomeResponsavel'] ?? '',
      responsibleCpf: apiModel['cpfResponsavel'] ?? '',
    );
  }
}

// Classe para formatar CPF automaticamente
class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;

    if (text.isEmpty) {
      return newValue;
    }

    // Remove caracteres não numéricos
    text = text.replaceAll(RegExp(r'[^\d]'), '');

    // Limita a 11 dígitos
    if (text.length > 11) {
      text = text.substring(0, 11);
    }

    var formattedText = '';
    for (var i = 0; i < text.length; i++) {
      // Adiciona ponto após o 3º e 6º dígito
      if (i == 3 || i == 6) {
        formattedText += '.';
      }
      // Adiciona hífen após o 9º dígito
      else if (i == 9) {
        formattedText += '-';
      }
      formattedText += text[i];
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class _PatientScreenState extends State<PatientScreen>
    with AutomaticKeepAliveClientMixin {
  final List<Patient> patients = [];
  final nameController = TextEditingController();
  final cpfController = TextEditingController();
  final diagnosisController = TextEditingController();
  final bedController = TextEditingController();
  final responsibleNameController = TextEditingController();
  final responsibleCpfController = TextEditingController();
  String selectedSeverity = 'Baixo';
  bool isLoading = true;
  String? errorMessage;
  StreamSubscription? _patientUpdateSubscription;

  // Mensagens de erro para validação
  String? nameError;
  String? cpfError;
  String? diagnosisError;
  String? bedError;
  String? responsibleNameError;
  String? responsibleCpfError;

  final PatientService _patientService = PatientService();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadPatients();

    _patientUpdateSubscription = PatientService.patientUpdateStream.listen((_) {
      if (mounted) {
        _loadPatients();
      }
    });
  }

  @override
  void dispose() {
    // Liberar os controllers quando a tela for descartada
    nameController.dispose();
    cpfController.dispose();
    diagnosisController.dispose();
    bedController.dispose();
    responsibleNameController.dispose();
    responsibleCpfController.dispose();
    _patientUpdateSubscription?.cancel();
    super.dispose();
  }

  // Adicionar este método para mapear valores de severidade do backend para o frontend
  String _mapSeverityFromBackend(String backendSeverity) {
    // Mapeamento dos valores do backend para os valores do frontend
    switch (backendSeverity.toLowerCase()) {
      case 'baixo':
        return 'Baixo';
      case 'moderado':
        return 'Moderado';
      case 'alto':
        return 'Alto';
      case 'crítico':
      case 'critico':
        return 'Crítico';
      default:
        return 'Baixo'; // Valor padrão
    }
  }

  // Adicionar este método para mapear valores de severidade do frontend para o backend
  String _mapSeverityToBackend(String frontendSeverity) {
    // O backend espera exatamente "Baixo", "Moderado", "Alto", "Crítico"
    // Não precisamos alterar o valor, pois já está no formato correto
    return frontendSeverity;
  }

  Future<void> _loadPatients() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final apiPatients = await _patientService.getAllPatients();

      setState(() {
        patients.clear();
        for (var apiPatient in apiPatients) {
          try {
            // Converter para Map<String, dynamic> para usar com fromApiModel
            final patientMap = {
              'id': apiPatient.id,
              'nomePaciente': apiPatient.nomePaciente,
              'cpfPaciente': apiPatient.cpfPaciente,
              'diagnostico': apiPatient.diagnostico,
              'leito': apiPatient.leito,
              'grauSeveridade': apiPatient.grauSeveridade,
              'nomeResponsavel': apiPatient.nomeResponsavel,
              'cpfResponsavel': apiPatient.cpfResponsavel,
            };

            patients.add(Patient.fromApiModel(patientMap));
          } catch (e) {
            print('Erro ao converter paciente: $e');
          }
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Erro ao carregar pacientes: $e';
        isLoading = false;
      });
    }
  }

  // Validar todos os campos do formulário
  bool _validateForm() {
    bool isValid = true;

    // Validar nome
    if (nameController.text.isEmpty) {
      nameError = 'Nome é obrigatório';
      isValid = false;
    } else {
      nameError = null;
    }

    // Validar CPF
    final cpfText = cpfController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cpfText.isEmpty) {
      cpfError = 'CPF é obrigatório';
      isValid = false;
    } else if (cpfText.length != 11) {
      cpfError = 'CPF deve ter 11 dígitos';
      isValid = false;
    } else {
      cpfError = null;
    }

    // Validar diagnóstico
    if (diagnosisController.text.isEmpty) {
      diagnosisError = 'Diagnóstico é obrigatório';
      isValid = false;
    } else {
      diagnosisError = null;
    }

    // Validar leito
    if (bedController.text.isEmpty) {
      bedError = 'Leito é obrigatório';
      isValid = false;
    } else if (!_validateBedFormat(bedController.text)) {
      bedError = 'Formato inválido (use A + 2 números, ex: A01)';
      isValid = false;
    } else {
      bedError = null;
    }

    // Validar nome do responsável
    if (responsibleNameController.text.isEmpty) {
      responsibleNameError = 'Nome do responsável é obrigatório';
      isValid = false;
    } else {
      responsibleNameError = null;
    }

    // Validar CPF do responsável
    final responsibleCpfText =
        responsibleCpfController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (responsibleCpfText.isEmpty) {
      responsibleCpfError = 'CPF do responsável é obrigatório';
      isValid = false;
    } else if (responsibleCpfText.length != 11) {
      responsibleCpfError = 'CPF deve ter 11 dígitos';
      isValid = false;
    } else if (cpfText == responsibleCpfText) {
      responsibleCpfError =
          'CPF do responsável não pode ser igual ao do paciente';
      isValid = false;
    } else {
      responsibleCpfError = null;
    }

    return isValid;
  }

  bool _validateBedFormat(String bed) {
    // Validar formato A + 2 números
    return RegExp(r'^A\d{2}$').hasMatch(bed);
  }

  bool _validateCpfsDifferent(String patientCpf, String responsibleCpf) {
    // Remover formatação para comparar
    final cleanPatientCpf = patientCpf.replaceAll(RegExp(r'[^\d]'), '');
    final cleanResponsibleCpf = responsibleCpf.replaceAll(RegExp(r'[^\d]'), '');

    // Se um dos CPFs estiver vazio, consideramos como diferentes
    if (cleanPatientCpf.isEmpty || cleanResponsibleCpf.isEmpty) {
      return true;
    }

    return cleanPatientCpf != cleanResponsibleCpf;
  }

  // Método para mostrar detalhes do paciente
  void _showPatientDetails(Patient patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(patient.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('CPF', patient.cpf),
              _detailRow('Diagnóstico', patient.diagnosis),
              _detailRow('Leito', patient.bed),
              _detailRow('Severidade', patient.severity),
              const Divider(),
              _detailRow('Responsável', patient.responsibleName),
              _detailRow('CPF do Responsável', patient.responsibleCpf),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  // Widget para exibir uma linha de detalhes
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.blue,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  void _showAddEditPatientDialog([Patient? patient, int? index]) {
    // Limpar mensagens de erro
    nameError = null;
    cpfError = null;
    diagnosisError = null;
    bedError = null;
    responsibleNameError = null;
    responsibleCpfError = null;

    if (patient != null) {
      nameController.text = patient.name;
      cpfController.text = patient.cpf;
      diagnosisController.text = patient.diagnosis;
      bedController.text = patient.bed;
      responsibleNameController.text = patient.responsibleName;
      responsibleCpfController.text = patient.responsibleCpf;
      selectedSeverity = patient.severity;
    } else {
      nameController.clear();
      cpfController.clear();
      diagnosisController.clear();
      bedController.clear();
      responsibleNameController.clear();
      responsibleCpfController.clear();
      selectedSeverity = 'Baixo';
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(patient != null ? 'Editar Paciente' : 'Novo Paciente'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nome',
                      border: const OutlineInputBorder(),
                      errorText: nameError,
                    ),
                    onChanged: (value) {
                      setState(() {
                        if (value.isEmpty) {
                          nameError = 'Nome é obrigatório';
                        } else {
                          nameError = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: cpfController,
                    decoration: InputDecoration(
                      labelText: 'CPF',
                      border: const OutlineInputBorder(),
                      errorText: cpfError,
                      helperText: 'Formato: 000.000.000-00',
                    ),
                    inputFormatters: [
                      CpfInputFormatter(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        final cpfText = value.replaceAll(RegExp(r'[^\d]'), '');
                        if (cpfText.isEmpty) {
                          cpfError = 'CPF é obrigatório';
                        } else if (cpfText.length != 11) {
                          cpfError = 'CPF deve ter 11 dígitos';
                        } else {
                          cpfError = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: diagnosisController,
                    decoration: InputDecoration(
                      labelText: 'Diagnóstico',
                      border: const OutlineInputBorder(),
                      errorText: diagnosisError,
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      setState(() {
                        if (value.isEmpty) {
                          diagnosisError = 'Diagnóstico é obrigatório';
                        } else {
                          diagnosisError = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: bedController,
                    decoration: InputDecoration(
                      labelText: 'Leito',
                      border: const OutlineInputBorder(),
                      helperText: 'Formato: A + 2 números (ex: A01)',
                      errorText: bedError,
                    ),
                    onChanged: (value) {
                      setState(() {
                        if (value.isEmpty) {
                          bedError = 'Leito é obrigatório';
                        } else if (!_validateBedFormat(value)) {
                          bedError =
                              'Formato inválido (use A + 2 números, ex: A01)';
                        } else {
                          bedError = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: responsibleNameController,
                    decoration: InputDecoration(
                      labelText: 'Nome do Responsável',
                      border: const OutlineInputBorder(),
                      errorText: responsibleNameError,
                    ),
                    onChanged: (value) {
                      setState(() {
                        if (value.isEmpty) {
                          responsibleNameError =
                              'Nome do responsável é obrigatório';
                        } else {
                          responsibleNameError = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: responsibleCpfController,
                    decoration: InputDecoration(
                      labelText: 'CPF do Responsável',
                      border: const OutlineInputBorder(),
                      errorText: responsibleCpfError,
                      helperText: 'Formato: 000.000.000-00',
                    ),
                    inputFormatters: [
                      CpfInputFormatter(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        final responsibleCpfText =
                            value.replaceAll(RegExp(r'[^\d]'), '');
                        final patientCpfText =
                            cpfController.text.replaceAll(RegExp(r'[^\d]'), '');

                        if (responsibleCpfText.isEmpty) {
                          responsibleCpfError =
                              'CPF do responsável é obrigatório';
                        } else if (responsibleCpfText.length != 11) {
                          responsibleCpfError = 'CPF deve ter 11 dígitos';
                        } else if (patientCpfText == responsibleCpfText) {
                          responsibleCpfError =
                              'CPF do responsável não pode ser igual ao do paciente';
                        } else {
                          responsibleCpfError = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Grau de Severidade',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedSeverity,
                    items: const [
                      DropdownMenuItem(value: 'Baixo', child: Text('Baixo')),
                      DropdownMenuItem(
                          value: 'Moderado', child: Text('Moderado')),
                      DropdownMenuItem(value: 'Alto', child: Text('Alto')),
                      DropdownMenuItem(
                          value: 'Crítico', child: Text('Crítico')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedSeverity = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Validar todos os campos
                  setState(() {
                    _validateForm();
                  });

                  // Verificar se há erros
                  if (nameError != null ||
                      cpfError != null ||
                      diagnosisError != null ||
                      bedError != null ||
                      responsibleNameError != null ||
                      responsibleCpfError != null) {
                    return; // Não prosseguir se houver erros
                  }

                  final newPatient = Patient(
                    id: patient?.id,
                    name: nameController.text,
                    cpf: cpfController.text,
                    diagnosis: diagnosisController.text,
                    bed: bedController.text,
                    severity: selectedSeverity,
                    responsibleName: responsibleNameController.text,
                    responsibleCpf: responsibleCpfController.text,
                  );

                  try {
                    if (patient != null && index != null) {
                      // Atualizar paciente existente
                      if (patient.id != null) {
                        // Criar o JSON diretamente
                        final Map<String, dynamic> apiData =
                            newPatient.toApiModel();

                        print('Enviando para atualização: $apiData');
                        await _patientService.updatePatient(
                            patient.id!, apiData);
                      }
                      setState(() {
                        patients[index] = newPatient;
                      });
                    } else {
                      // Criar novo paciente
                      final Map<String, dynamic> apiData =
                          newPatient.toApiModel();

                      print('Enviando para criação: $apiData');

                      try {
                        final createdPatient =
                            await _patientService.createPatient(apiData);

                        // Converter a resposta para Map<String, dynamic>
                        final Map<String, dynamic> patientMap = {
                          'id': createdPatient['id'],
                          'nomePaciente':
                              createdPatient['nomePaciente'] ?? newPatient.name,
                          'cpfPaciente':
                              createdPatient['cpfPaciente'] ?? newPatient.cpf,
                          'diagnostico': createdPatient['diagnostico'] ??
                              newPatient.diagnosis,
                          'leito': createdPatient['leito'] ?? newPatient.bed,
                          'grauSeveridade': createdPatient['grauSeveridade'] ??
                              newPatient.severity,
                          'nomeResponsavel':
                              createdPatient['nomeResponsavel'] ??
                                  newPatient.responsibleName,
                          'cpfResponsavel': createdPatient['cpfResponsavel'] ??
                              newPatient.responsibleCpf,
                        };

                        setState(() {
                          patients.add(Patient.fromApiModel(patientMap));
                        });
                      } catch (e) {
                        print('Erro ao criar paciente: $e');
                        throw Exception('Falha ao criar paciente: $e');
                      }
                    }

                    Navigator.pop(context);

                    // Notificar que houve uma atualização
                    _patientService.notifyPatientUpdate();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(patient != null
                            ? 'Paciente atualizado com sucesso!'
                            : 'Paciente cadastrado com sucesso!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deletePatient(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir este paciente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final patient = patients[index];
              Navigator.pop(context);

              if (patient.id != null) {
                try {
                  final success =
                      await _patientService.deletePatient(patient.id!);
                  if (success) {
                    setState(() {
                      patients.removeAt(index);
                    });

                    // Notificar que houve uma atualização
                    _patientService.notifyPatientUpdate();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Paciente excluído com sucesso!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Erro ao excluir paciente'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                setState(() {
                  patients.removeAt(index);
                });
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pacientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPatients,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPatients,
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                )
              : patients.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Nenhum paciente cadastrado',
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: patients.length,
                      itemBuilder: (context, index) {
                        final patient = patients[index];
                        return Card(
                          margin: const EdgeInsets.all(8.0),
                          child: InkWell(
                            onTap: () => _showPatientDetails(patient),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              patient.name,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'CPF: ${patient.cpf}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getSeverityColor(
                                              patient.severity),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          patient.severity,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text('Leito: ${patient.bed}'),
                                            Text(
                                              'Responsável: ${patient.responsibleName}',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () =>
                                                _showAddEditPatientDialog(
                                                    patient, index),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () =>
                                                _deletePatient(index),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditPatientDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Método para obter a cor com base na severidade
  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'Baixo':
        return Colors.green;
      case 'Moderado':
        return Colors.orange;
      case 'Alto':
        return Colors.deepOrange;
      case 'Crítico':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
