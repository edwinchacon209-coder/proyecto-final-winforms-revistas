/// Modelo de datos para la entidad Revista.
class Revista {
  final int? id;
  final String nombre;

  const Revista({
    this.id,
    required this.nombre,
  });

  factory Revista.fromMap(Map<String, dynamic> map) {
    return Revista(
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

  Revista copyWith({int? id, String? nombre}) {
    return Revista(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
    );
  }

  @override
  String toString() => 'Revista(id: $id, nombre: $nombre)';
}
