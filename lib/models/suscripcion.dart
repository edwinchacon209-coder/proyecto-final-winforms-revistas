/// Modelo de datos para la entidad Suscripción.
/// Vincula a un cliente con una revista en un período determinado.
class Suscripcion {
  final int? id;
  final String numeroSuscripcion;
  final int clienteId;
  final int revistaId;
  final String fechaInicio;  // ISO 8601: YYYY-MM-DD
  final String fechaFin;     // ISO 8601: YYYY-MM-DD

  // Campos de JOIN (opcionales, se rellenan al consultar con datos relacionados)
  final String? clienteNombre;
  final String? revistaNombre;

  const Suscripcion({
    this.id,
    required this.numeroSuscripcion,
    required this.clienteId,
    required this.revistaId,
    required this.fechaInicio,
    required this.fechaFin,
    this.clienteNombre,
    this.revistaNombre,
  });

  factory Suscripcion.fromMap(Map<String, dynamic> map) {
    return Suscripcion(
      id: map['id'] as int?,
      numeroSuscripcion: map['numero_suscripcion'] as String,
      clienteId: map['cliente_id'] as int,
      revistaId: map['revista_id'] as int,
      fechaInicio: map['fecha_inicio'] as String,
      fechaFin: map['fecha_fin'] as String,
      clienteNombre: map['cliente_nombre'] as String?,
      revistaNombre: map['revista_nombre'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'numero_suscripcion': numeroSuscripcion,
      'cliente_id': clienteId,
      'revista_id': revistaId,
      'fecha_inicio': fechaInicio,
      'fecha_fin': fechaFin,
    };
  }

  Suscripcion copyWith({
    int? id,
    String? numeroSuscripcion,
    int? clienteId,
    int? revistaId,
    String? fechaInicio,
    String? fechaFin,
    String? clienteNombre,
    String? revistaNombre,
  }) {
    return Suscripcion(
      id: id ?? this.id,
      numeroSuscripcion: numeroSuscripcion ?? this.numeroSuscripcion,
      clienteId: clienteId ?? this.clienteId,
      revistaId: revistaId ?? this.revistaId,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      revistaNombre: revistaNombre ?? this.revistaNombre,
    );
  }

  @override
  String toString() =>
      'Suscripcion(id: $id, numero: $numeroSuscripcion, clienteId: $clienteId, revistaId: $revistaId)';
}
