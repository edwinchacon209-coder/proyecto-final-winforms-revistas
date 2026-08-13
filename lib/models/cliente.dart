/// Modelo de datos para la entidad Cliente.
/// Representa a un cliente suscriptor de revistas.
class Cliente {
  final int? id;
  final String nit;
  final String nombre;
  final String? direccion;
  final String? telefono;

  const Cliente({
    this.id,
    required this.nit,
    required this.nombre,
    this.direccion,
    this.telefono,
  });

  /// Crea un Cliente desde un mapa (fila de SQLite).
  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'] as int?,
      nit: map['nit'] as String,
      nombre: map['nombre'] as String,
      direccion: map['direccion'] as String?,
      telefono: map['telefono'] as String?,
    );
  }

  /// Convierte el Cliente a un mapa para insertar/actualizar en SQLite.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nit': nit,
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono,
    };
  }

  /// Crea una copia del cliente con los campos modificados.
  Cliente copyWith({
    int? id,
    String? nit,
    String? nombre,
    String? direccion,
    String? telefono,
  }) {
    return Cliente(
      id: id ?? this.id,
      nit: nit ?? this.nit,
      nombre: nombre ?? this.nombre,
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
    );
  }

  @override
  String toString() => 'Cliente(id: $id, nit: $nit, nombre: $nombre)';
}
