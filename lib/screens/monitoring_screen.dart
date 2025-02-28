import 'package:flutter/material.dart';
import 'dart:async';
import 'package:frontend/services/pews_service.dart';
import 'package:frontend/services/patient_service.dart';
import 'package:intl/intl.dart';

class MonitoringScreen extends StatefulWidget {
  // Adicionando um método estático para facilitar a atualização de qualquer instância
  static void refreshInstance(BuildContext context) {
    final state = context.findAncestorStateOfType<_MonitoringScreenState>();
    if (state != null) {
      state._loadData();
    }
  }

  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> pewsList = [];
  bool isLoading = true;
  String? errorMessage;
  Map<String, String> patientNames = {};
  StreamSubscription? _pewsUpdateSubscription;
  Timer? _updateTimer;

  final PewsService _pewsService = PewsService();
  final PatientService _patientService = PatientService();

  // Implementando o mixin AutomaticKeepAliveClientMixin
  @override
  bool get wantKeepAlive => true;

  // Mapeamentos das avaliações
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

  @override
  void initState() {
    super.initState();
    _loadData();

    // Inscrever-se para receber atualizações quando novos PEWS forem criados
    _pewsUpdateSubscription = PewsService.pewsUpdateStream.listen((_) {
      if (mounted) {
        _loadData();
      }
    });

    // Iniciar um timer para atualizar os cronômetros a cada segundo
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // Apenas atualiza o estado para recalcular os tempos restantes
        });
      }
    });
  }

  @override
  void dispose() {
    // Cancelar a inscrição para evitar vazamentos de memória
    _pewsUpdateSubscription?.cancel();
    _updateTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Carregar todas as avaliações PEWS
      final evaluations = await _pewsService.getAllPewsEvaluations();

      // Log para depuração
      print('Avaliações PEWS carregadas: ${evaluations.length}');
      for (var eval in evaluations) {
        print(
            'ID: ${eval.id}, Paciente: ${eval.idPaciente}, Pontuação: ${eval.pontuacaoTotal}, Data: ${eval.data_pews}');
      }

      // Carregar informações dos pacientes
      await _loadPatientNames();

      setState(() {
        pewsList = evaluations.map((pews) {
          // Verificar se emese e nebulização são strings ou booleanos
          bool emeseValue = pews.emese == 'EmeseSIM';
          bool nebulizacaoValue = pews.nebulizacao == 'NebulisacaoSIM';

          // Calcular o intervalo baseado na pontuação
          Duration interval;
          if (pews.pontuacaoTotal >= 7) {
            interval = const Duration(minutes: 0); // Monitorização contínua
          } else if (pews.pontuacaoTotal >= 4) {
            interval = const Duration(minutes: 60); // 1h/1h
          } else if (pews.pontuacaoTotal >= 3) {
            interval = const Duration(minutes: 120); // 2h/2h
          } else if (pews.pontuacaoTotal >= 1) {
            interval = const Duration(minutes: 240); // 4h/4h
          } else {
            interval = const Duration(minutes: 360); // 6h/6h
          }

          // Calcular o tempo restante com base na data de criação e no intervalo
          DateTime dataPews = pews.data_pews;
          DateTime proximaAvaliacao = dataPews.add(interval);
          Duration tempoRestante = proximaAvaliacao.difference(DateTime.now());

          // Se o tempo já passou, definir como zero
          if (tempoRestante.isNegative) {
            tempoRestante = Duration.zero;
          }

          return {
            'id': pews.id ?? 0,
            'paciente': patientNames[pews.idPaciente.toString()] ??
                'Paciente ${pews.idPaciente}',
            'idPaciente': pews.idPaciente,
            'pontuacao': pews.pontuacaoTotal,
            'avaliacaoNeurologica': pews.avaliacao_neurologica,
            'avaliacaoCardiovascular': pews.avaliacao_cardiovascular,
            'avaliacaoRespiratoria': pews.avaliacao_respiratoria,
            'emese': emeseValue,
            'nebulizacao': nebulizacaoValue,
            'dataPews': dataPews,
            'proximaAvaliacao': proximaAvaliacao,
            'tempoRestante': tempoRestante,
            'intervalo': interval,
          };
        }).toList();

        isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar avaliações PEWS: $e');
      setState(() {
        errorMessage = 'Erro ao carregar dados: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadPatientNames() async {
    try {
      final apiPatients = await _patientService.getAllPatients();
      patientNames = {
        for (var patient in apiPatients)
          (patient.id?.toString() ?? ''): patient.nomePaciente,
      };
    } catch (e) {
      print('Erro ao carregar nomes dos pacientes: $e');
      // Não falhar completamente se não conseguir carregar os nomes
    }
  }

  void _showEditDialog(Map<String, dynamic> pews) {
    // Garantir que os valores não sejam nulos
    String avaliacaoNeurologica = pews['avaliacaoNeurologica'] ?? 'AN0';
    String avaliacaoCardiovascular = pews['avaliacaoCardiovascular'] ?? 'AC0';
    String avaliacaoRespiratoria = pews['avaliacaoRespiratoria'] ?? 'AR0';
    bool emese = pews['emese'] ?? false;
    bool nebulizacao = pews['nebulizacao'] ?? false;
    int pontuacaoTotal = pews['pontuacao'] ?? 0;

    void calcularPontuacao() {
      int pontos = 0;

      if (avaliacaoNeurologica.length > 2) {
        try {
          pontos += int.parse(avaliacaoNeurologica.substring(2));
        } catch (e) {
          print('Erro ao converter valor neurológico: $e');
        }
      }

      if (avaliacaoCardiovascular.length > 2) {
        try {
          pontos += int.parse(avaliacaoCardiovascular.substring(2));
        } catch (e) {
          print('Erro ao converter valor cardiovascular: $e');
        }
      }

      if (avaliacaoRespiratoria.length > 2) {
        try {
          pontos += int.parse(avaliacaoRespiratoria.substring(2));
        } catch (e) {
          print('Erro ao converter valor respiratório: $e');
        }
      }

      if (emese) pontos += 2;
      if (nebulizacao) pontos += 2;

      pontuacaoTotal = pontos;
    }

    // Calcular a pontuação inicial
    calcularPontuacao();

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

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Atualizar PEWS - ${pews['paciente']}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Avaliação Neurológica',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: avaliacaoNeurologica,
                      isExpanded: true,
                      hint: const Text('Selecione a avaliação neurológica'),
                      menuMaxHeight: 350,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      selectedItemBuilder: (BuildContext context) {
                        return avaliacoesNeurologicas.entries.map((entry) {
                          return buildSelectedItem(entry.value['titulo']!);
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
                          avaliacaoNeurologica = newValue!;
                          calcularPontuacao();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Avaliação Cardiovascular',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: avaliacaoCardiovascular,
                      isExpanded: true,
                      hint: const Text('Selecione a avaliação cardiovascular'),
                      menuMaxHeight: 350,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      selectedItemBuilder: (BuildContext context) {
                        return avaliacoesCardiovasculares.entries.map((entry) {
                          return buildSelectedItem(entry.value['titulo']!);
                        }).toList();
                      },
                      items: avaliacoesCardiovasculares.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: buildDropdownItem(entry.value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          avaliacaoCardiovascular = newValue!;
                          calcularPontuacao();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Avaliação Respiratória',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: avaliacaoRespiratoria,
                      isExpanded: true,
                      hint: const Text('Selecione a avaliação respiratória'),
                      menuMaxHeight: 350,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      selectedItemBuilder: (BuildContext context) {
                        return avaliacoesRespiratorias.entries.map((entry) {
                          return buildSelectedItem(entry.value['titulo']!);
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
                          avaliacaoRespiratoria = newValue!;
                          calcularPontuacao();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text(
                        'Emese',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('Adiciona 2 pontos se presente'),
                      value: emese,
                      onChanged: (bool value) {
                        setState(() {
                          emese = value;
                          calcularPontuacao();
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text(
                        'Nebulização',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('Adiciona 2 pontos se presente'),
                      value: nebulizacao,
                      onChanged: (bool value) {
                        setState(() {
                          nebulizacao = value;
                          calcularPontuacao();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: Theme.of(context).colorScheme.primary,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    try {
                      // Garantir que o ID não seja nulo
                      final id = pews['id'];
                      if (id == null) {
                        throw Exception('ID da avaliação não encontrado');
                      }

                      // Atualizar os dados do PEWS
                      final updatedPews = PewsEvaluation(
                        id: id,
                        avaliacao_neurologica: avaliacaoNeurologica,
                        avaliacao_cardiovascular: avaliacaoCardiovascular,
                        avaliacao_respiratoria: avaliacaoRespiratoria,
                        emese: emese ? 'EmeseSIM' : 'EmeseNAO',
                        nebulizacao:
                            nebulizacao ? 'NebulisacaoSIM' : 'NebulisacaoNAO',
                        idPaciente: pews['idPaciente'] ?? '',
                        pontuacaoTotal: pontuacaoTotal,
                        data_pews: DateTime.now(),
                      );

                      await _pewsService.updatePewsEvaluation(id, updatedPews);

                      // Recarregar os dados após a atualização
                      _loadData();

                      Navigator.of(context).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Avaliação PEWS atualizada com sucesso!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      Navigator.of(context).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erro ao atualizar avaliação: $e'),
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
        );
      },
    );
  }

  void _showDeleteDialog(Map<String, dynamic> pews) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Alta'),
          content: Text(
              'Tem certeza que deseja dar alta para o paciente ${pews['paciente']}?'),
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
                  final id = pews['id'];
                  if (id != null) {
                    // Chamar o método de exclusão e considerar 204 como sucesso
                    final success = await _pewsService.deletePewsEvaluation(id);

                    // Se chegou aqui, a operação foi bem-sucedida
                    Navigator.of(context).pop();

                    // Atualizar a lista após a exclusão
                    _loadData();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Paciente recebeu alta com sucesso!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    throw Exception('ID da avaliação não encontrado');
                  }
                } catch (e) {
                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao dar alta: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Confirmar Alta'),
            ),
          ],
        );
      },
    );
  }

  String getMonitoringInterval(int score) {
    if (score >= 7) return 'Monitorização contínua';
    if (score >= 4) return 'Sinais vitais 1h/1h';
    if (score >= 3) return 'Sinais vitais 2h/2h';
    if (score >= 1) return 'Sinais vitais 4h/4h';
    return 'Sinais vitais 6h/6h';
  }

  Color getScoreColor(int score) {
    if (score >= 7) return Colors.red;
    if (score >= 4) return Colors.orange;
    if (score >= 3) return Colors.yellow;
    if (score >= 1) return Colors.blue;
    return Colors.green;
  }

  String formatTimer(Duration duration) {
    if (duration.inSeconds == 0) {
      return 'Monitorização contínua';
    }
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}min ${seconds}s';
    }
    if (minutes > 0) {
      return '${minutes}min ${seconds}s';
    }
    return '${seconds}s';
  }

  // Método para calcular o tempo restante para cada avaliação
  Duration calcularTempoRestante(DateTime dataPews, Duration intervalo) {
    if (intervalo.inMinutes == 0) {
      return Duration.zero; // Monitorização contínua
    }

    DateTime proximaAvaliacao = dataPews.add(intervalo);
    Duration tempoRestante = proximaAvaliacao.difference(DateTime.now());

    // Se o tempo já passou, definir como zero
    if (tempoRestante.isNegative) {
      return Duration.zero;
    }

    return tempoRestante;
  }

  @override
  Widget build(BuildContext context) {
    // Necessário chamar super.build quando usar AutomaticKeepAliveClientMixin
    super.build(context);

    // Atualizar os tempos restantes para cada avaliação
    for (var pews in pewsList) {
      if (pews['intervalo'].inMinutes > 0) {
        pews['tempoRestante'] = calcularTempoRestante(
          pews['dataPews'],
          pews['intervalo'],
        );
      }
    }

    // Ordenar a lista por pontuação (maior para menor) e depois por tempo restante (menor para maior)
    final sortedPewsList = List<Map<String, dynamic>>.from(pewsList)
      ..sort((a, b) {
        // Primeiro ordenar por pontuação (maior para menor)
        int scoreComparison = b['pontuacao'].compareTo(a['pontuacao']);
        if (scoreComparison != 0) return scoreComparison;

        // Se a pontuação for igual, ordenar por tempo restante (menor para maior)
        return (a['tempoRestante'] as Duration)
            .compareTo(b['tempoRestante'] as Duration);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoramento PEWS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Atualizar lista',
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
                        onPressed: _loadData,
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                )
              : sortedPewsList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.favorite,
                            color: Colors.green,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'SEM PACIENTES EM OBSERVAÇÃO!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const Text(
                            'VIVA A SAÚDE! :D',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: sortedPewsList.length,
                      itemBuilder: (context, index) {
                        final pews = sortedPewsList[index];
                        final score = pews['pontuacao'] as int;
                        final tempoRestante = pews['tempoRestante'] as Duration;
                        final bool precisaAtualizar =
                            tempoRestante.inSeconds == 0 &&
                                pews['intervalo'].inMinutes > 0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          // Adicionar borda vermelha pulsante se precisar atualizar
                          shape: precisaAtualizar
                              ? RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: Colors.red.withOpacity(
                                        (DateTime.now().millisecondsSinceEpoch %
                                                1000) /
                                            1000),
                                    width: 3,
                                  ),
                                )
                              : null,
                          child: Column(
                            children: [
                              ListTile(
                                title: Text(
                                  pews['paciente'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: getScoreColor(score),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'PEWS: $score',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Intervalo: ${getMonitoringInterval(score)}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                Text(
                                                  'Criado em: ${DateFormat('dd/MM/yyyy HH:mm').format(pews['dataPews'])}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            if (pews['intervalo'].inMinutes ==
                                                0)
                                              Container(
                                                width: constraints.maxWidth,
                                                alignment:
                                                    Alignment.centerRight,
                                                child: const Text(
                                                  'Monitorização contínua',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              )
                                            else if (precisaAtualizar)
                                              Container(
                                                width: constraints.maxWidth,
                                                alignment:
                                                    Alignment.centerRight,
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.warning,
                                                      color: Colors.red,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'ATUALIZAÇÃO NECESSÁRIA!',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            else
                                              Container(
                                                width: constraints.maxWidth,
                                                alignment:
                                                    Alignment.centerRight,
                                                child: Text(
                                                  'Próxima avaliação em: ${formatTimer(tempoRestante)}',
                                                  style: TextStyle(
                                                    color: getScoreColor(score),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Neurológico: ${avaliacoesNeurologicas[pews['avaliacaoNeurologica']]?['titulo'] ?? ''}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      'Cardiovascular: ${avaliacoesCardiovasculares[pews['avaliacaoCardiovascular']]?['titulo'] ?? ''}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      'Respiratório: ${avaliacoesRespiratorias[pews['avaliacaoRespiratoria']]?['titulo'] ?? ''}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    if (pews['emese']) const Text('• Emese'),
                                    if (pews['nebulizacao'])
                                      const Text('• Nebulização'),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            _showEditDialog(pews);
                                          },
                                          child: Text(
                                            'Atualizar',
                                            style: TextStyle(
                                              color: precisaAtualizar
                                                  ? Colors.red
                                                  : null,
                                              fontWeight: precisaAtualizar
                                                  ? FontWeight.bold
                                                  : null,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton(
                                          onPressed: () {
                                            _showDeleteDialog(pews);
                                          },
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: const Text('Dar Alta'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
