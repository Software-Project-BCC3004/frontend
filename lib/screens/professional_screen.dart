import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/professional.dart';
import '../services/professional_service.dart';

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

class ProfessionalScreen extends StatefulWidget {
  const ProfessionalScreen({super.key});

  @override
  State<ProfessionalScreen> createState() => _ProfessionalScreenState();
}

class _ProfessionalScreenState extends State<ProfessionalScreen> {
  final ProfessionalService _professionalService = ProfessionalService();
  List<Professional> _professionals = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Lista de estados brasileiros para validação
  final List<String> _estadosBrasileiros = [
    'AC',
    'AL',
    'AP',
    'AM',
    'BA',
    'CE',
    'DF',
    'ES',
    'GO',
    'MA',
    'MT',
    'MS',
    'MG',
    'PA',
    'PB',
    'PR',
    'PE',
    'PI',
    'RJ',
    'RN',
    'RS',
    'RO',
    'RR',
    'SC',
    'SP',
    'SE',
    'TO'
  ];

  // Regex para validação de email
  final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+(\.[a-zA-Z]+)?$',
    caseSensitive: false,
  );

  @override
  void initState() {
    super.initState();
    _loadProfessionals();
  }

  Future<void> _loadProfessionals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final professionals = await _professionalService.getAllProfessionals();
      setState(() {
        _professionals = professionals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar profissionais: $e';
        _isLoading = false;
      });
    }
  }

  void _showAddEditDialog({Professional? professional}) {
    final bool isEditing = professional != null;
    final TextEditingController nameController = TextEditingController(
        text: isEditing ? professional.nomeProfissional : '');
    final TextEditingController emailController =
        TextEditingController(text: isEditing ? professional.email : '');
    final TextEditingController documentNumberController =
        TextEditingController(
            text: isEditing ? professional.numeroDocumento : '');
    final TextEditingController stateController = TextEditingController(
        text: isEditing ? professional.estadoDocumento : '');
    final TextEditingController passwordController = TextEditingController();

    // Normalizar a função selecionada
    String selectedRole =
        isEditing ? _normalizeFuncao(professional.funcao) : 'Médico';
    if (selectedRole != 'Médico' &&
        selectedRole != 'Enfermeiro' &&
        selectedRole != 'Técnico') {
      selectedRole = 'Médico'; // Valor padrão seguro
    }

    String documentType = isEditing ? professional.tipoDocumento : 'CRM';
    if (documentType != 'CRM' && documentType != 'CPF') {
      documentType = selectedRole == 'Médico' ? 'CRM' : 'CPF';
    }

    // Mensagens de erro para validação
    String? documentNumberError;
    String? stateError;
    String? emailError;

    // Atualizar tipo de documento com base na função
    void updateDocumentType(String role) {
      if (role == 'Médico') {
        documentType = 'CRM';
        // Limpar o campo se mudar de CPF para CRM
        documentNumberController.clear();
        documentNumberError = null;
      } else {
        documentType = 'CPF';
        // Limpar o campo se mudar de CRM para CPF
        documentNumberController.clear();
        documentNumberError = null;
      }
    }

    // Validar número do documento
    void validateDocumentNumber(String value) {
      if (value.isEmpty) {
        documentNumberError = 'Campo obrigatório';
        return;
      }

      if (documentType == 'CRM') {
        if (value.length != 5 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
          documentNumberError = 'CRM deve conter 5 dígitos numéricos';
        } else {
          documentNumberError = null;
        }
      } else {
        // CPF
        // Remove caracteres não numéricos para validação
        final numericValue = value.replaceAll(RegExp(r'[^\d]'), '');
        if (numericValue.length != 11) {
          documentNumberError = 'CPF deve conter 11 dígitos numéricos';
        } else {
          documentNumberError = null;
        }
      }
    }

    // Validar estado
    void validateState(String value) {
      if (value.isEmpty) {
        stateError = 'Campo obrigatório';
        return;
      }

      if (!_estadosBrasileiros.contains(value.toUpperCase())) {
        stateError = 'Use a sigla do estado (ex: RJ, SP)';
      } else {
        stateError = null;
      }
    }

    // Validar email
    void validateEmail(String value) {
      if (value.isEmpty) {
        emailError = 'Campo obrigatório';
        return;
      }

      if (!_emailRegex.hasMatch(value)) {
        emailError = 'Digite um email válido';
      } else {
        emailError = null;
      }
    }

    // Validação inicial
    if (documentNumberController.text.isNotEmpty) {
      validateDocumentNumber(documentNumberController.text);
    }
    if (stateController.text.isNotEmpty) {
      validateState(stateController.text);
    }
    if (emailController.text.isNotEmpty) {
      validateEmail(emailController.text);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing
                  ? 'Editar Profissional'
                  : 'Adicionar Novo Profissional'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome Completo',
                        border: OutlineInputBorder(),
                        helperText: 'Digite o nome completo do profissional',
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Função',
                        border: OutlineInputBorder(),
                        helperText: 'Selecione a função do profissional',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Médico',
                          child: Text('Médico'),
                        ),
                        DropdownMenuItem(
                          value: 'Enfermeiro',
                          child: Text('Enfermeiro'),
                        ),
                        DropdownMenuItem(
                          value: 'Técnico',
                          child: Text('Técnico'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedRole = value;
                            updateDocumentType(value);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: const OutlineInputBorder(),
                        helperText: 'Digite um email válido',
                        errorText: emailError,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) {
                        setState(() {
                          validateEmail(value);
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (!isEditing) ...[
                      TextField(
                        controller: passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Senha',
                          border: OutlineInputBorder(),
                          helperText: 'Mínimo de 6 caracteres',
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      controller: documentNumberController,
                      decoration: InputDecoration(
                        labelText: documentType == 'CRM'
                            ? 'Número do CRM'
                            : 'Número do CPF',
                        border: const OutlineInputBorder(),
                        helperText: documentType == 'CRM'
                            ? 'Digite 5 dígitos numéricos'
                            : 'Digite o CPF (formato: 000.000.000-00)',
                        errorText: documentNumberError,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: documentType == 'CRM'
                          ? [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(5),
                            ]
                          : [
                              CpfInputFormatter(),
                              LengthLimitingTextInputFormatter(
                                  14), // 000.000.000-00
                            ],
                      onChanged: (value) {
                        setState(() {
                          validateDocumentNumber(value);
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: stateController,
                      decoration: InputDecoration(
                        labelText:
                            documentType == 'CRM' ? 'Estado do CRM' : 'Estado',
                        border: const OutlineInputBorder(),
                        helperText: 'Digite a sigla do estado (ex: RJ, SP)',
                        errorText: stateError,
                      ),
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                        LengthLimitingTextInputFormatter(2),
                      ],
                      onChanged: (value) {
                        setState(() {
                          validateState(value);
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Validar todos os campos antes de salvar
                    validateDocumentNumber(documentNumberController.text);
                    validateState(stateController.text);
                    validateEmail(emailController.text);

                    if (nameController.text.isEmpty ||
                        emailController.text.isEmpty ||
                        documentNumberController.text.isEmpty ||
                        stateController.text.isEmpty ||
                        (!isEditing && passwordController.text.isEmpty) ||
                        documentNumberError != null ||
                        stateError != null ||
                        emailError != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Por favor, corrija os campos destacados'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    try {
                      // Para CPF, extrair apenas os números antes de salvar
                      String documentNumber = documentNumberController.text;
                      if (documentType == 'CPF') {
                        documentNumber =
                            documentNumber.replaceAll(RegExp(r'[^\d]'), '');
                      }

                      final newProfessional = Professional(
                        id: isEditing ? professional!.id : null,
                        nomeProfissional: nameController.text,
                        funcao: selectedRole,
                        email: emailController.text,
                        senha: isEditing ? null : passwordController.text,
                        numeroDocumento: documentNumber,
                        tipoDocumento: documentType,
                        estadoDocumento: stateController.text.toUpperCase(),
                      );

                      if (isEditing) {
                        await _professionalService.updateProfessional(
                            professional!.id!, newProfessional);
                      } else {
                        await _professionalService
                            .createProfessional(newProfessional);
                      }

                      Navigator.of(context).pop();
                      _loadProfessionals();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEditing
                              ? 'Profissional atualizado com sucesso!'
                              : 'Profissional adicionado com sucesso!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erro: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Text(isEditing ? 'Atualizar' : 'Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(Professional professional) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text(
              'Tem certeza que deseja excluir o profissional ${professional.nomeProfissional}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await _professionalService
                      .deleteProfessional(professional.id!);
                  Navigator.of(context).pop();
                  _loadProfessionals();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profissional excluído com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao excluir profissional: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Equipe Médica'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfessionals,
            tooltip: 'Atualizar lista',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProfessionals,
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                )
              : _professionals.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.people_outline,
                            color: Colors.blue,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Nenhum profissional cadastrado',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _professionals.length,
                      itemBuilder: (context, index) {
                        final professional = _professionals[index];

                        // Formatar CPF para exibição se for CPF
                        String documentoFormatado =
                            professional.numeroDocumento;
                        if (professional.tipoDocumento == 'CPF' &&
                            professional.numeroDocumento.length == 11) {
                          final cpf = professional.numeroDocumento;
                          documentoFormatado =
                              '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9)}';
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Icon(
                                professional.funcao == 'Médico'
                                    ? Icons.medical_services
                                    : professional.funcao == 'Enfermeiro'
                                        ? Icons.healing
                                        : Icons.health_and_safety,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              professional.nomeProfissional,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Função: ${_normalizeFuncao(professional.funcao)}'),
                                Text('Email: ${professional.email}'),
                                Text(
                                    '${professional.tipoDocumento}: $documentoFormatado - ${professional.estadoDocumento}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _showAddEditDialog(
                                      professional: professional),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _showDeleteDialog(professional),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Método auxiliar para normalizar a exibição da função
  String _normalizeFuncao(String funcao) {
    switch (funcao) {
      case 'MÃ©dico':
      case 'Médico':
        return 'Médico';
      case 'Enfermeiro':
        return 'Enfermeiro';
      case 'Tecnico':
      case 'Técnico':
        return 'Técnico';
      default:
        return funcao;
    }
  }
}
