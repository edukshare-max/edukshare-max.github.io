class VacunaModel {
  final String id;
  final String matricula;
  final String nombreEstudiante;
  final String campana; // Campaña de vacunación
  final String vacuna; // Nombre de la vacuna (COVID-19, Influenza, etc.)
  final int dosis; // Número de dosis (1, 2, 3, refuerzo, etc.)
  final String lote; // Lote y caducidad
  final String aplicadoPor; // Nombre del profesional de salud
  final DateTime fechaAplicacion;
  final String? observaciones;
  final DateTime? timestamp; // Timestamp del registro

  VacunaModel({
    required this.id,
    required this.matricula,
    required this.nombreEstudiante,
    required this.campana,
    required this.vacuna,
    required this.dosis,
    required this.lote,
    required this.aplicadoPor,
    required this.fechaAplicacion,
    this.observaciones,
    this.timestamp,
  });

  // Constructor desde JSON (estructura de Cosmos DB: Tarjeta_vacunacion)
  factory VacunaModel.fromJson(Map<String, dynamic> json) {
    return VacunaModel(
      id: json['id'] ?? '',
      matricula: json['matricula'] ?? '',
      nombreEstudiante: json['nombreEstudiante'] ?? '',
      campana: json['campana'] ?? '',
      vacuna: json['vacuna'] ?? '',
      dosis: json['dosis'] ?? 1,
      lote: json['lote'] ?? '',
      aplicadoPor: json['aplicadoPor'] ?? '',
      fechaAplicacion: json['fechaAplicacion'] != null
          ? DateTime.parse(json['fechaAplicacion'])
          : DateTime.now(),
      observaciones: json['observaciones'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : null,
    );
  }

  // Convertir a JSON (para caché local)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matricula': matricula,
      'nombreEstudiante': nombreEstudiante,
      'campana': campana,
      'vacuna': vacuna,
      'dosis': dosis,
      'lote': lote,
      'aplicadoPor': aplicadoPor,
      'fechaAplicacion': fechaAplicacion.toIso8601String(),
      'observaciones': observaciones,
      'timestamp': timestamp?.toIso8601String(),
    };
  }

  // Getter para formato de fecha legible
  String get fechaFormateada {
    final meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${fechaAplicacion.day} ${meses[fechaAplicacion.month - 1]} ${fechaAplicacion.year}';
  }

  // Getter para extraer año de caducidad del lote
  String? get caducidad {
    final regex = RegExp(r'Cad:(\d{4})');
    final match = regex.firstMatch(lote);
    return match?.group(1);
  }

  // Getter para número de lote limpio
  String get numeroLote {
    final regex = RegExp(r'^([^\s]+)');
    final match = regex.firstMatch(lote);
    return match?.group(1) ?? lote;
  }

  // Getter para tipo de vacuna abreviado
  String get tipoVacunaCorto {
    if (vacuna.contains('COVID')) return 'COVID-19';
    if (vacuna.contains('Influenza')) return 'Influenza';
    if (vacuna.contains('Hepatitis')) return 'Hepatitis';
    return vacuna;
  }

  @override
  String toString() {
    return 'VacunaModel{vacuna: $vacuna, dosis: $dosis, fecha: $fechaFormateada, campaña: $campana}';
  }
}
