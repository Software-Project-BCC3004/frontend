class Professional {
  final String? id;
  final String nomeProfissional;
  final String funcao;
  final String email;
  final String? senha;
  final String numeroDocumento;
  final String tipoDocumento;
  final String estadoDocumento;

  Professional({
    this.id,
    required this.nomeProfissional,
    required this.funcao,
    required this.email,
    this.senha,
    required this.numeroDocumento,
    required this.tipoDocumento,
    required this.estadoDocumento,
  });

  factory Professional.fromJson(Map<String, dynamic> json) {
    return Professional(
      id: json['id']?.toString(),
      nomeProfissional: _decodeUtf8(json['nomeProfissional'] ?? ''),
      funcao: _decodeUtf8(json['funcao'] ?? ''),
      email: json['email'] ?? '',
      numeroDocumento: json['numeroDocumento'] ?? '',
      tipoDocumento: json['tipoDocumento'] ?? '',
      estadoDocumento: json['estadoDocumento'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nomeProfissional': nomeProfissional,
      'funcao': funcao,
      'email': email,
      'senha': senha,
      'numeroDocumento': numeroDocumento,
      'tipoDocumento': tipoDocumento,
      'estadoDocumento': estadoDocumento,
    };
  }

  // Método auxiliar para decodificar strings UTF-8 se necessário
  static String _decodeUtf8(String text) {
    try {
      // Se a string já estiver correta, retorna ela mesma
      if (text.contains('ã') || text.contains('é') || text.contains('ç')) {
        return text;
      }

      // Tenta normalizar a string se ela contiver caracteres codificados incorretamente
      if (text.contains('Ã') || text.contains('Ã©') || text.contains('Ã§')) {
        // Substitui manualmente os caracteres mais comuns
        return text
            .replaceAll('Ã£', 'ã')
            .replaceAll('Ã©', 'é')
            .replaceAll('Ã§', 'ç')
            .replaceAll('Ã', 'Á')
            .replaceAll('Ã"', 'Ó')
            .replaceAll('Ãª', 'ê')
            .replaceAll('Ã­', 'í')
            .replaceAll('Ã³', 'ó')
            .replaceAll('Ãº', 'ú')
            .replaceAll('Ã¡', 'á')
            .replaceAll('Ã¢', 'â')
            .replaceAll('Ãµ', 'õ');
      }
      return text;
    } catch (e) {
      print('Erro ao decodificar texto: $e');
      return text;
    }
  }
}
