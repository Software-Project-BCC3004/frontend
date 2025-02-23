import 'package:flutter/material.dart';

class PatientScreen extends StatefulWidget {
  const PatientScreen({super.key});

  @override
  State<PatientScreen> createState() => _PatientScreenState();
}

class Patient {
  final String name;
  final String cpf;
  final String diagnosis;
  final String bed;
  final String severity;
  final String responsibleName;
  final String responsibleCpf;

  Patient({
    required this.name,
    required this.cpf,
    required this.diagnosis,
    required this.bed,
    required this.severity,
    required this.responsibleName,
    required this.responsibleCpf,
  });
}

class _PatientScreenState extends State<PatientScreen> {
  final List<Patient> patients = [];
  final nameController = TextEditingController();
  final cpfController = TextEditingController();
  final diagnosisController = TextEditingController();
  final bedController = TextEditingController();
  final responsibleNameController = TextEditingController();
  final responsibleCpfController = TextEditingController();
  String selectedSeverity = 'BAIXO';

  String _formatCpf(String cpf) {
    cpf = cpf.replaceAll(RegExp(r'[^\d]'), '');
    if (cpf.length > 11) cpf = cpf.substring(0, 11);
    if (cpf.length > 9) {
      return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9)}';
    } else if (cpf.length > 6) {
      return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6)}';
    } else if (cpf.length > 3) {
      return '${cpf.substring(0, 3)}.${cpf.substring(3)}';
    }
    return cpf;
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
      selectedSeverity = 'BAIXO';
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
                  labelText: 'Leito',
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
                  DropdownMenuItem(value: 'BAIXO', child: Text('Baixo')),
                  DropdownMenuItem(value: 'MEDIO', child: Text('Médio')),
                  DropdownMenuItem(value: 'ALTO', child: Text('Alto')),
                  DropdownMenuItem(value: 'CRITICO', child: Text('Crítico')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedSeverity = value!;
                  });
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
            onPressed: () {
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

              final newPatient = Patient(
                name: nameController.text,
                cpf: cpfController.text,
                diagnosis: diagnosisController.text,
                bed: bedController.text,
                severity: selectedSeverity,
                responsibleName: responsibleNameController.text,
                responsibleCpf: responsibleCpfController.text,
              );

              setState(() {
                if (patient != null && index != null) {
                  patients[index] = newPatient;
                } else {
                  patients.add(newPatient);
                }
              });

              Navigator.pop(context);
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
            onPressed: () {
              setState(() {
                patients.removeAt(index);
              });
              Navigator.pop(context);
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
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditPatientDialog(),
          ),
        ],
      ),
      body: patients.isEmpty
          ? const Center(
              child: Text(
                'Nenhum paciente cadastrado',
                style: TextStyle(fontSize: 18),
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
                          icon: const Icon(Icons.delete, color: Colors.red),
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
