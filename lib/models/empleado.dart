/// Modelo de datos para la entidad Empleado.
class Empleado {
  final int? id;
  final String nombre;

  const Empleado({
    this.id,
    required this.nombre,
  });

  factory Empleado.fromMap(Map<String, dynamic> map) {
    return Empleado(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
    };
  }

  Empleado copyWith({int? id, String? nombre}) {
    return Empleado(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
    );
  }

  @override
  String toString() => 'Empleado(id: $id, nombre: $nombre)';
}
