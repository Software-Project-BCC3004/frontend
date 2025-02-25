import 'package:flutter/material.dart';

class ProfessionalScreen extends StatefulWidget {
  const ProfessionalScreen({super.key});

  @override
  State<ProfessionalScreen> createState() => _ProfessionalScreenState();
}

class _ProfessionalScreenState extends State<ProfessionalScreen> {
  final _professionals = ValueNotifier<List<Map<String, dynamic>>>([]);
  final List<String> _funcoes = [
    'Doutor',
    'Enfermeiro',
    'Técnico de Enfermagem'
  ];

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidCRM(String crm) {
    // Formato: CRM/UF 000000
    return RegExp(r'^CRM\/[A-Z]{2}\s\d{6}$').hasMatch(crm);
  }

  void _addProfessional() {
    String nome = '';
    String funcao = _funcoes[0];
    String email = '';
    String crm = '';
    String? emailError;
    String? crmError;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Adicionar Profissional'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        hintText: 'Digite o nome completo',
                      ),
                      onChanged: (value) => nome = value,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: funcao,
                      decoration: const InputDecoration(
                        labelText: 'Função',
                      ),
                      items: _funcoes.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          funcao = newValue!;
                          if (funcao != 'Doutor') {
                            crm = '';
                            crmError = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    if (funcao == 'Doutor')
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'CRM',
                          hintText: 'CRM/UF 000000',
                          errorText: crmError,
                        ),
                        onChanged: (value) {
                          crm = value;
                          setState(() {
                            if (!_isValidCRM(value)) {
                              crmError =
                                  'CRM inválido. Use o formato: CRM/UF 000000';
                            } else {
                              crmError = null;
                            }
                          });
                        },
                      ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'exemplo@dominio.com',
                        errorText: emailError,
                      ),
                      onChanged: (value) {
                        email = value;
                        setState(() {
                          if (!_isValidEmail(value)) {
                            emailError = 'Email inválido';
                          } else {
                            emailError = null;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    if (nome.isEmpty ||
                        email.isEmpty ||
                        (funcao == 'Doutor' && crm.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Preencha todos os campos obrigatórios'),
                        ),
                      );
                      return;
                    }

                    if (!_isValidEmail(email)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Email inválido'),
                        ),
                      );
                      return;
                    }

                    if (funcao == 'Doutor' && !_isValidCRM(crm)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('CRM inválido'),
                        ),
                      );
                      return;
                    }

                    final newProfessional = {
                      'id': DateTime.now().millisecondsSinceEpoch,
                      'nome': nome,
                      'funcao': funcao,
                      'email': email,
                      if (funcao == 'Doutor') 'crm': crm,
                    };
                    Navigator.pop(context);
                    _professionals.value = [
                      newProfessional,
                      ..._professionals.value
                    ];
                  },
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editProfessional(Map<String, dynamic> professional) {
    String nome = professional['nome'];
    String funcao = professional['funcao'];
    String email = professional['email'];
    String crm = professional['crm'] ?? '';
    String? emailError;
    String? crmError;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Editar Profissional'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        hintText: 'Digite o nome completo',
                      ),
                      controller: TextEditingController(text: nome),
                      onChanged: (value) => nome = value,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: funcao,
                      decoration: const InputDecoration(
                        labelText: 'Função',
                      ),
                      items: _funcoes.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          funcao = newValue!;
                          if (funcao != 'Doutor') {
                            crm = '';
                            crmError = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    if (funcao == 'Doutor')
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'CRM',
                          hintText: 'CRM/UF 000000',
                          errorText: crmError,
                        ),
                        controller: TextEditingController(text: crm),
                        onChanged: (value) {
                          crm = value;
                          setState(() {
                            if (!_isValidCRM(value)) {
                              crmError =
                                  'CRM inválido. Use o formato: CRM/UF 000000';
                            } else {
                              crmError = null;
                            }
                          });
                        },
                      ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'exemplo@dominio.com',
                        errorText: emailError,
                      ),
                      controller: TextEditingController(text: email),
                      onChanged: (value) {
                        email = value;
                        setState(() {
                          if (!_isValidEmail(value)) {
                            emailError = 'Email inválido';
                          } else {
                            emailError = null;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    if (nome.isEmpty ||
                        email.isEmpty ||
                        (funcao == 'Doutor' && crm.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Preencha todos os campos obrigatórios'),
                        ),
                      );
                      return;
                    }

                    if (!_isValidEmail(email)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Email inválido'),
                        ),
                      );
                      return;
                    }

                    if (funcao == 'Doutor' && !_isValidCRM(crm)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('CRM inválido'),
                        ),
                      );
                      return;
                    }

                    final updatedProfessional = {
                      'id': professional['id'],
                      'nome': nome,
                      'funcao': funcao,
                      'email': email,
                      if (funcao == 'Doutor') 'crm': crm,
                    };
                    Navigator.pop(context);
                    final index = _professionals.value
                        .indexWhere((p) => p['id'] == professional['id']);
                    if (index != -1) {
                      final newList =
                          List<Map<String, dynamic>>.from(_professionals.value);
                      newList[index] =
                          Map<String, dynamic>.from(updatedProfessional);
                      _professionals.value = newList;
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteProfessional(Map<String, dynamic> professional) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir ${professional['nome']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _professionals.value = _professionals.value
                  .where((p) => p['id'] != professional['id'])
                  .toList();
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _viewProfessionalDetails(Map<String, dynamic> professional) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(professional['nome']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Função: ${professional['funcao']}'),
            const SizedBox(height: 8),
            if (professional['funcao'] == 'Doutor') ...[
              Text('CRM: ${professional['crm']}'),
              const SizedBox(height: 8),
            ],
            Text('Email: ${professional['email']}'),
          ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipe Médica'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addProfessional,
          ),
        ],
      ),
      body: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: _professionals,
        builder: (context, professionals, _) {
          if (professionals.isEmpty) {
            return const Center(
              child: Text(
                'Ainda não há membros na equipe.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: professionals.length,
            itemBuilder: (context, index) {
              final professional = professionals[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(professional['nome']),
                  subtitle: Text(
                      '${professional['funcao']} - ${professional['email']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editProfessional(professional),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteProfessional(professional),
                      ),
                    ],
                  ),
                  onTap: () => _viewProfessionalDetails(professional),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
