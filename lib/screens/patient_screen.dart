import 'package:flutter/material.dart';
import 'package:frontend/services/patient_service.dart';

class PatientScreen extends StatefulWidget {
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

class _PatientScreenState extends State<PatientScreen> {
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

  final PatientService _patientService = PatientService();

  @override
  void initState() {
    super.initState();
    _loadPatients();
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

  String _formatCpf(String cpf) {
    // Remover caracteres não numéricos
    cpf = cpf.replaceAll(RegExp(r'[^\d]'), '');

    // Limitar a 11 dígitos
    if (cpf.length > 11) cpf = cpf.substring(0, 11);

    // Formatar o CPF
    if (cpf.length > 9) {
      return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9)}';
    } else if (cpf.length > 6) {
      return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6)}';
    } else if (cpf.length > 3) {
      return '${cpf.substring(0, 3)}.${cpf.substring(3)}';
    }
    return cpf;
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

  void _showAddEditPatientDialog([Patient? patient, int? index]) {
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
      builder: (context) => AlertDialog(
        title: Text(patient != null ? 'Editar Paciente' : 'Novo Paciente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: cpfController,
                decoration: const InputDecoration(
                  labelText: 'CPF',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  final formattedCpf = _formatCpf(value);
                  if (formattedCpf != value) {
                    cpfController.value = TextEditingValue(
                      text: formattedCpf,
                      selection:
                          TextSelection.collapsed(offset: formattedCpf.length),
                    );
                  }
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: diagnosisController,
                decoration: const InputDecoration(
                  labelText: 'Diagnóstico',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bedController,
                decoration: const InputDecoration(
                  labelText: 'Leito (formato: A + 2 números, ex: A01)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: responsibleNameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Responsável',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: responsibleCpfController,
                decoration: const InputDecoration(
                  labelText: 'CPF do Responsável',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  final formattedCpf = _formatCpf(value);
                  if (formattedCpf != value) {
                    responsibleCpfController.value = TextEditingValue(
                      text: formattedCpf,
                      selection:
                          TextSelection.collapsed(offset: formattedCpf.length),
                    );
                  }
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
                  DropdownMenuItem(value: 'Moderado', child: Text('Moderado')),
                  DropdownMenuItem(value: 'Alto', child: Text('Alto')),
                  DropdownMenuItem(value: 'Crítico', child: Text('Crítico')),
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
              // Validar campos vazios
              if (nameController.text.isEmpty ||
                  cpfController.text.isEmpty ||
                  diagnosisController.text.isEmpty ||
                  bedController.text.isEmpty ||
                  responsibleNameController.text.isEmpty ||
                  responsibleCpfController.text.isEmpty) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Campos Obrigatórios'),
                    content: const Text(
                        'Por favor, preencha todos os campos antes de salvar.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
                return;
              }

              // Validar formato do leito
              if (!_validateBedFormat(bedController.text)) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Formato de Leito Inválido'),
                    content: const Text(
                        'O leito deve seguir o formato A + 2 números (ex: A01, A02, A10).'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
                return;
              }

              // Validar CPFs diferentes
              if (!_validateCpfsDifferent(
                  cpfController.text, responsibleCpfController.text)) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('CPFs Iguais ou Inválidos'),
                    content: const Text(
                        'O CPF do paciente não pode ser igual ao CPF do responsável e ambos devem ser válidos.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
                return;
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
                    await _patientService.updatePatient(patient.id!, apiData);
                  }
                  setState(() {
                    patients[index] = newPatient;
                  });
                } else {
                  // Criar novo paciente
                  final Map<String, dynamic> apiData = newPatient.toApiModel();

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
                      'diagnostico':
                          createdPatient['diagnostico'] ?? newPatient.diagnosis,
                      'leito': createdPatient['leito'] ?? newPatient.bed,
                      'grauSeveridade': createdPatient['grauSeveridade'] ??
                          newPatient.severity,
                      'nomeResponsavel': createdPatient['nomeResponsavel'] ??
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pacientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPatients,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditPatientDialog(),
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
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showAddEditPatientDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Adicionar Paciente'),
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
                          child: ListTile(
                            title: Text(patient.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Leito: ${patient.bed}'),
                                Text('Severidade: ${patient.severity}'),
                                Text('Responsável: ${patient.responsibleName}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () =>
                                      _showAddEditPatientDialog(patient, index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _deletePatient(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
