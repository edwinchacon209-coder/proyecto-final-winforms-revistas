/// Modelo de datos para la entidad Entrega.
/// Representa un envío de revista a un cliente suscriptor.
///
/// Estado de la entrega:
///   - [fechaEntrega] == null  → Pendiente
///   - [fechaEntrega] != null  → Realizada
class Entrega {
  final int? id;
  final String numeroEnvio;
  final int suscripcionId;
  final int empleadoId;
  final String fechaProgramada; // ISO 8601: YYYY-MM-DD
  final String? fechaEntrega;  // null = pendiente
  final String? observaciones;

  // Campos de JOIN (opcionales)
  final String? suscripcionNumero;
  final String? clienteNombre;
  final String? revistaNombre;
  final String? empleadoNombre;

  const Entrega({
    this.id,
    required this.numeroEnvio,
    required this.suscripcionId,
    required this.empleadoId,
    required this.fechaProgramada,
    this.fechaEntrega,
    this.observaciones,
    this.suscripcionNumero,
    this.clienteNombre,
    this.revistaNombre,
    this.empleadoNombre,
  });

  /// Retorna true si la entrega ya fue completada.
  bool get esRealizada => fechaEntrega != null;

  /// Retorna true si la entrega está atrasada (pendiente y pasó la fecha programada).
  bool get esAtrasada {
    if (esRealizada) return false;
    final programada = DateTime.tryParse(fechaProgramada);
    if (programada == null) return false;
    final hoy = DateTime.now();
    return DateTime(hoy.year, hoy.month, hoy.day)
        .isAfter(DateTime(programada.year, programada.month, programada.day));
  }

  factory Entrega.fromMap(Map<String, dynamic> map) {
    return Entrega(
      id: map['id'] as int?,
      numeroEnvio: map['numero_envio'] as String,
      suscripcionId: map['suscripcion_id'] as int,
      empleadoId: map['empleado_id'] as int,
      fechaProgramada: map['fecha_programada'] as String,
      fechaEntrega: map['fecha_entrega'] as String?,
      observaciones: map['observaciones'] as String?,
      suscripcionNumero: map['suscripcion_numero'] as String?,
      clienteNombre: map['cliente_nombre'] as String?,
      revistaNombre: map['revista_nombre'] as String?,
      empleadoNombre: map['empleado_nombre'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'numero_envio': numeroEnvio,
      'suscripcion_id': suscripcionId,
      'empleado_id': empleadoId,
      'fecha_programada': fechaProgramada,
      'fecha_entrega': fechaEntrega,
      'observaciones': observaciones,
    };
  }

  Entrega copyWith({
    int? id,
    String? numeroEnvio,
    int? suscripcionId,
    int? empleadoId,
    String? fechaProgramada,
    String? fechaEntrega,
    String? observaciones,
    String? suscripcionNumero,
    String? clienteNombre,
    String? revistaNombre,
    String? empleadoNombre,
  }) {
    return Entrega(
      id: id ?? this.id,
      numeroEnvio: numeroEnvio ?? this.numeroEnvio,
      suscripcionId: suscripcionId ?? this.suscripcionId,
      empleadoId: empleadoId ?? this.empleadoId,
      fechaProgramada: fechaProgramada ?? this.fechaProgramada,
      fechaEntrega: fechaEntrega ?? this.fechaEntrega,
      observaciones: observaciones ?? this.observaciones,
      suscripcionNumero: suscripcionNumero ?? this.suscripcionNumero,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      revistaNombre: revistaNombre ?? this.revistaNombre,
      empleadoNombre: empleadoNombre ?? this.empleadoNombre,
    );
  }

  @override
  String toString() =>
      'Entrega(id: $id, numero: $numeroEnvio, realizada: $esRealizada, atrasada: $esAtrasada)';
}
