import 'package:flutter/material.dart';
import 'package:frontend/services/pews_service.dart';
import 'package:frontend/services/patient_service.dart';
import 'package:intl/intl.dart';

class PewsScreen extends StatefulWidget {
  const PewsScreen({super.key});

  @override
  State<PewsScreen> createState() => _PewsScreenState();
}

class _PewsScreenState extends State<PewsScreen> {
  String? selectedPatient;
  String? selectedPatientId;
  String? avaliacaoNeurologica;
  String? avaliacaoCardiovascular;
  String? avaliacaoRespiratoria;
  bool emese = false;
  bool nebulizacao = false;
  int pontuacaoTotal = 0;
  bool isLoading = true;
  String? errorMessage;
  List<Map<String, dynamic>> pacientes = [];

  final PatientService _patientService = PatientService();
  final PewsService _pewsService = PewsService();

  @override
  void initState() {
    super.initState();
    _loadPatients();

    // Adicionar listener para atualizar a lista de pacientes quando a tela receber foco
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final focusNode = FocusNode();
      FocusScope.of(context).requestFocus(focusNode);
      focusNode.addListener(() {
        if (focusNode.hasFocus) {
          _loadPatients();
        }
      });
    });
  }

  Future<void> _loadPatients() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final apiPatients = await _patientService.getAllPatients();

      setState(() {
        pacientes = apiPatients
            .map((patient) => {
                  'id': patient.id.toString(),
                  'nome': patient.nomePaciente,
                })
            .toList();

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Erro ao carregar pacientes: $e';
        isLoading = false;
      });
    }
  }

  final Map<String, Map<String, String>> avaliacoesNeurologicas = {
    'AN0': {
      'titulo': 'Ativo',
      'descricao': 'Ativo',
    },
    'AN1': {
      'titulo': 'Sonolento / Hipoativo',
      'descricao': 'Sonolento / Hipoativo',
    },
    'AN2': {
      'titulo': 'Irritado',
      'descricao': 'Irritado',
    },
    'AN3': {
      'titulo': 'Letárgico / Obnubilado',
      'descricao': 'Letárgico / Obnubilado ou resposta reduzida à dor',
    },
  };

  final Map<String, Map<String, String>> avaliacoesCardiovasculares = {
    'AC0': {
      'titulo': 'Corado',
      'descricao': 'Corado ou TEC 1-2 seg',
    },
    'AC1': {
      'titulo': 'Pálido',
      'descricao':
          'Pálido ou TEC 3 seg ou FC acima do limite superior para a idade',
    },
    'AC2': {
      'titulo': 'Moteado',
      'descricao':
          'Moteado ou TEC 4 seg ou FC ≥ 20 bpm acima do limite superior para a idade',
    },
    'AC3': {
      'titulo': 'Acinzentado / Cianótico',
      'descricao':
          'Acinzentado / cianótico ou TEC ≥ 5 seg ou FC ≥ 30 bpm acima do limite superior para a idade ou bradicardia para a idade',
    },
  };

  final Map<String, Map<String, String>> avaliacoesRespiratorias = {
    'AR0': {
      'titulo': 'Normal',
      'descricao': 'FR normal para a idade, sem retração',
    },
    'AR1': {
      'titulo': 'Alteração Leve',
      'descricao':
          'FR acima do limite superior para a idade, uso de musculatura acessória ou FiO2 ≥ 30% ou 4 litros/min de O2',
    },
    'AR2': {
      'titulo': 'Alteração Moderada',
      'descricao':
          'FR ≥ 20 rpm acima do limite superior para a idade, retrações subcostais, intercostais e de fúrcula ou FiO2 ≥ 40% ou 6 litros/min de O2',
    },
    'AR3': {
      'titulo': 'Alteração Grave',
      'descricao':
          'FR ≥ 5 rpm abaixo do limite inferior para a idade, retrações subcostais, intercostais, de fúrcula, do esterno e gemência ou FiO2 ≥ 50% ou 8 litros/min de O2',
    },
  };

  void calcularPontuacao() {
    int pontos = 0;

    if (avaliacaoNeurologica != null) {
      pontos += int.parse(avaliacaoNeurologica!.substring(2));
    }

    if (avaliacaoCardiovascular != null) {
      pontos += int.parse(avaliacaoCardiovascular!.substring(2));
    }

    if (avaliacaoRespiratoria != null) {
      pontos += int.parse(avaliacaoRespiratoria!.substring(2));
    }

    if (emese) pontos += 2;
    if (nebulizacao) pontos += 2;

    setState(() {
      pontuacaoTotal = pontos;
    });
  }

  Widget buildSelectedItem(String titulo) {
    return Text(
      titulo,
      style: const TextStyle(fontSize: 14),
    );
  }

  Widget buildDropdownItem(Map<String, String> info) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        info['descricao']!,
        style: const TextStyle(fontSize: 14),
        softWrap: true,
      ),
    );
  }

  Future<void> _savePewsEvaluation() async {
    if (selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione um paciente'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (avaliacaoNeurologica == null ||
        avaliacaoCardiovascular == null ||
        avaliacaoRespiratoria == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha todas as avaliações'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final pewsEvaluation = PewsEvaluation(
        avaliacao_neurologica: avaliacaoNeurologica!,
        avaliacao_cardiovascular: avaliacaoCardiovascular!,
        avaliacao_respiratoria: avaliacaoRespiratoria!,
        emese: emese ? 'EmeseSIM' : 'EmeseNAO',
        nebulizacao: nebulizacao ? 'NebulisacaoSIM' : 'NebulisacaoNAO',
        idPaciente: selectedPatientId!,
        pontuacaoTotal: pontuacaoTotal,
        data_pews: DateTime.now(),
      );

      print('Enviando PEWS: ${pewsEvaluation.toJson()}');
      await _pewsService.createPewsEvaluation(pewsEvaluation);

      // A notificação já está sendo feita dentro do método createPewsEvaluation

      setState(() {
        isLoading = false;
        // Resetar os campos após salvar
        selectedPatient = null;
        selectedPatientId = null;
        avaliacaoNeurologica = null;
        avaliacaoCardiovascular = null;
        avaliacaoRespiratoria = null;
        emese = false;
        nebulizacao = false;
        pontuacaoTotal = 0;
      });

      // Recarregar a lista de pacientes após salvar
      _loadPatients();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avaliação PEWS salva com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar avaliação: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avaliação PEWS'),
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
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selecione o Paciente',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: selectedPatientId,
                            isExpanded: true,
                            hint: const Text('Selecione um paciente'),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            items: pacientes.map((paciente) {
                              return DropdownMenuItem<String>(
                                value: paciente['id'],
                                child: Text(paciente['nome']),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedPatientId = newValue;
                                selectedPatient = pacientes.firstWhere(
                                    (p) => p['id'] == newValue)['nome'];
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Avaliação Neurológica',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: avaliacaoNeurologica,
                            isExpanded: true,
                            hint:
                                const Text('Selecione a avaliação neurológica'),
                            menuMaxHeight: 350,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            selectedItemBuilder: (BuildContext context) {
                              return avaliacoesNeurologicas.entries
                                  .map((entry) {
                                return buildSelectedItem(
                                    entry.value['titulo']!);
                              }).toList();
                            },
                            items: avaliacoesNeurologicas.entries.map((entry) {
                              return DropdownMenuItem<String>(
                                value: entry.key,
                                child: buildDropdownItem(entry.value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                avaliacaoNeurologica = newValue;
                                calcularPontuacao();
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Avaliação Cardiovascular',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: avaliacaoCardiovascular,
                            isExpanded: true,
                            hint: const Text(
                                'Selecione a avaliação cardiovascular'),
                            menuMaxHeight: 350,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            selectedItemBuilder: (BuildContext context) {
                              return avaliacoesCardiovasculares.entries
                                  .map((entry) {
                                return buildSelectedItem(
                                    entry.value['titulo']!);
                              }).toList();
                            },
                            items:
                                avaliacoesCardiovasculares.entries.map((entry) {
                              return DropdownMenuItem<String>(
                                value: entry.key,
                                child: buildDropdownItem(entry.value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                avaliacaoCardiovascular = newValue;
                                calcularPontuacao();
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Avaliação Respiratória',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: avaliacaoRespiratoria,
                            isExpanded: true,
                            hint: const Text(
                                'Selecione a avaliação respiratória'),
                            menuMaxHeight: 350,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            selectedItemBuilder: (BuildContext context) {
                              return avaliacoesRespiratorias.entries
                                  .map((entry) {
                                return buildSelectedItem(
                                    entry.value['titulo']!);
                              }).toList();
                            },
                            items: avaliacoesRespiratorias.entries.map((entry) {
                              return DropdownMenuItem<String>(
                                value: entry.key,
                                child: buildDropdownItem(entry.value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                avaliacaoRespiratoria = newValue;
                                calcularPontuacao();
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  SwitchListTile(
                                    title: const Text(
                                      'Emese',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: const Text(
                                        'Adiciona 2 pontos se presente'),
                                    value: emese,
                                    onChanged: (bool value) {
                                      setState(() {
                                        emese = value;
                                        calcularPontuacao();
                                      });
                                    },
                                  ),
                                  const Divider(),
                                  SwitchListTile(
                                    title: const Text(
                                      'Nebulização',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: const Text(
                                        'Adiciona 2 pontos se presente'),
                                    value: nebulizacao,
                                    onChanged: (bool value) {
                                      setState(() {
                                        nebulizacao = value;
                                        calcularPontuacao();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Card(
                            color: Theme.of(context).colorScheme.primary,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Pontuação Total:',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    pontuacaoTotal.toString(),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.secondary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _savePewsEvaluation,
                              child: const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'Salvar Avaliação',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
