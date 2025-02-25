import 'package:flutter/material.dart';
import 'dart:async';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  // Dados mockados para visualização
  final List<Map<String, dynamic>> pewsList = [
    {
      'paciente': 'João Silva',
      'pontuacao': 8,
      'avaliacaoNeurologica': 'AN3',
      'avaliacaoCardiovascular': 'AC1',
      'avaliacaoRespiratoria': 'AR3',
      'emese': true,
      'nebulizacao': true,
      'timer': const Duration(seconds: 0), // Monitorização contínua
    },
    {
      'paciente': 'Maria Santos',
      'pontuacao': 4,
      'avaliacaoNeurologica': 'AN1',
      'avaliacaoCardiovascular': 'AC0',
      'avaliacaoRespiratoria': 'AR2',
      'emese': true,
      'nebulizacao': false,
      'timer': const Duration(minutes: 60), // 1h/1h
    },
    {
      'paciente': 'Pedro Oliveira',
      'pontuacao': 2,
      'avaliacaoNeurologica': 'AN0',
      'avaliacaoCardiovascular': 'AC0',
      'avaliacaoRespiratoria': 'AR1',
      'emese': false,
      'nebulizacao': false,
      'timer': const Duration(minutes: 240), // 4h/4h
    },
  ];

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

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Iniciar os timers
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          for (var pews in pewsList) {
            var duration = pews['timer'] as Duration;
            if (duration.inSeconds > 0) {
              pews['timer'] = duration - const Duration(seconds: 1);
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showEditDialog(Map<String, dynamic> pews) {
    String? avaliacaoNeurologica = pews['avaliacaoNeurologica'];
    String? avaliacaoCardiovascular = pews['avaliacaoCardiovascular'];
    String? avaliacaoRespiratoria = pews['avaliacaoRespiratoria'];
    bool emese = pews['emese'];
    bool nebulizacao = pews['nebulizacao'];
    int pontuacaoTotal = 0;

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

      pontuacaoTotal = pontos;
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
                          avaliacaoNeurologica = newValue;
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
                          avaliacaoCardiovascular = newValue;
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
                          avaliacaoRespiratoria = newValue;
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
                  onPressed: () {
                    // Atualizar os dados do PEWS
                    this.setState(() {
                      pews['avaliacaoNeurologica'] = avaliacaoNeurologica;
                      pews['avaliacaoCardiovascular'] = avaliacaoCardiovascular;
                      pews['avaliacaoRespiratoria'] = avaliacaoRespiratoria;
                      pews['emese'] = emese;
                      pews['nebulizacao'] = nebulizacao;
                      pews['pontuacao'] = pontuacaoTotal;

                      // Resetar o timer baseado na nova pontuação
                      if (pontuacaoTotal >= 7) {
                        pews['timer'] = const Duration(seconds: 0);
                      } else if (pontuacaoTotal >= 4) {
                        pews['timer'] = const Duration(minutes: 60);
                      } else if (pontuacaoTotal >= 3) {
                        pews['timer'] = const Duration(minutes: 120);
                      } else if (pontuacaoTotal >= 1) {
                        pews['timer'] = const Duration(minutes: 240);
                      } else {
                        pews['timer'] = const Duration(minutes: 360);
                      }
                    });
                    Navigator.of(context).pop();
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
              onPressed: () {
                setState(() {
                  pewsList.remove(pews);
                });
                Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    // Ordenar a lista por pontuação (maior para menor)
    final sortedPewsList = List<Map<String, dynamic>>.from(pewsList)
      ..sort((a, b) => b['pontuacao'].compareTo(a['pontuacao']));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoramento PEWS'),
      ),
      body: sortedPewsList.isEmpty
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
                final timer = pews['timer'] as Duration;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Intervalo: ${getMonitoringInterval(score)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (timer.inSeconds == 0)
                                      Container(
                                        width: constraints.maxWidth,
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          formatTimer(timer),
                                          style: TextStyle(
                                            color: getScoreColor(score),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        width: constraints.maxWidth,
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          'Próxima avaliação em: ${formatTimer(timer)}',
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
                                  child: const Text('Atualizar'),
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
