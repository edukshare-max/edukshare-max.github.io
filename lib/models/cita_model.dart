// 🏥 MODELO DE CITAS MÉDICAS
// Para citas estudiantiles UAGro

class CitaModel {
  final String id;
  final String matricula;
  final DateTime fecha;
  final String hora;
  final String tipo;
  final String servicio; // Agregar servicio
  final String doctor;
  final String estado;
  final String motivo; // Agregar motivo
  final String lugar; // Agregar lugar
  final String? notas;

  CitaModel({
    required this.id,
    required this.matricula,
    required this.fecha,
    required this.hora,
    required this.tipo,
    required this.servicio,
    required this.doctor,
    required this.estado,
    required this.motivo,
    required this.lugar,
    this.notas,
  });

  factory CitaModel.fromJson(Map<String, dynamic> json) {
    return CitaModel(
      id: json['_id'] ?? json['id'] ?? '',
      matricula: json['matricula'] ?? '',
      fecha: DateTime.tryParse(json['fecha'] ?? '') ?? DateTime.now(),
      hora: json['hora'] ?? '',
      tipo: json['tipo'] ?? json['tipo_cita'] ?? '',
      servicio: json['servicio'] ?? json['tipo'] ?? '',
      doctor: json['doctor'] ?? json['medico'] ?? '',
      estado: json['estado'] ?? 'programada',
      motivo: json['motivo'] ?? json['descripcion'] ?? '',
      lugar: json['lugar'] ?? json['consultorio'] ?? 'Consultorio Médico',
      notas: json['notas'] ?? json['observaciones'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matricula': matricula,
      'fecha': fecha.toIso8601String(),
      'hora': hora,
      'tipo': tipo,
      'servicio': servicio,
      'doctor': doctor,
      'estado': estado,
      'motivo': motivo,
      'lugar': lugar,
      'notas': notas,
    };
  }
}