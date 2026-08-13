import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/entrega.dart';

/// Repositorio para operaciones CRUD de Entregas.
/// Módulo principal del sistema según el caso académico.
class EntregaRepository {
  final DatabaseHelper _dbHelper;

  EntregaRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<Database> get _db async => _dbHelper.database;

  Future<int> insertar(Entrega entrega) async {
    final db = await _db;
    try {
      return await db.insert(
        'entregas',
        entrega.toMap(),
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw Exception(
          'Ya existe una entrega con el número "${entrega.numeroEnvio}".',
        );
      }
      rethrow;
    }
  }

  /// Query con JOIN completo para obtener todos los datos relacionados.
  static const String _joinQuery = '''
    SELECT 
      e.*,
      s.numero_suscripcion  AS suscripcion_numero,
      c.nombre              AS cliente_nombre,
      r.nombre              AS revista_nombre,
      emp.nombre            AS empleado_nombre
    FROM entregas e
    INNER JOIN suscripciones s   ON e.suscripcion_id = s.id
    INNER JOIN clientes      c   ON s.cliente_id     = c.id
    INNER JOIN revistas      r   ON s.revista_id     = r.id
    INNER JOIN empleados     emp ON e.empleado_id    = emp.id
  ''';

  /// Retorna todas las entregas con datos completos.
  Future<List<Entrega>> obtenerTodas() async {
    final db = await _db;
    final maps = await db.rawQuery(
      '$_joinQuery ORDER BY e.fecha_programada DESC',
    );
    return maps.map(Entrega.fromMap).toList();
  }

  /// Retorna solo las entregas pendientes (fecha_entrega IS NULL).
  Future<List<Entrega>> obtenerPendientes() async {
    final db = await _db;
    final maps = await db.rawQuery(
      '$_joinQuery WHERE e.fecha_entrega IS NULL ORDER BY e.fecha_programada ASC',
    );
    return maps.map(Entrega.fromMap).toList();
  }

  /// Retorna solo las entregas realizadas (fecha_entrega IS NOT NULL).
  Future<List<Entrega>> obtenerRealizadas() async {
    final db = await _db;
    final maps = await db.rawQuery(
      '$_joinQuery WHERE e.fecha_entrega IS NOT NULL ORDER BY e.fecha_entrega DESC',
    );
    return maps.map(Entrega.fromMap).toList();
  }

  Future<Entrega?> obtenerPorId(int id) async {
    final db = await _db;
    final maps = await db.rawQuery('$_joinQuery WHERE e.id = ? LIMIT 1', [id]);
    if (maps.isEmpty) return null;
    return Entrega.fromMap(maps.first);
  }

  Future<int> actualizar(Entrega entrega) async {
    final db = await _db;
    return db.update(
      'entregas',
      entrega.toMap(),
      where: 'id = ?',
      whereArgs: [entrega.id],
    );
  }

  /// Marca una entrega como realizada, registrando la fecha exacta de entrega.
  Future<int> marcarComoEntregada({
    required int id,
    required String fechaEntrega,
    String? observaciones,
  }) async {
    final db = await _db;
    return db.update(
      'entregas',
      {
        'fecha_entrega': fechaEntrega,
        'observaciones': observaciones,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> eliminar(int id) async {
    final db = await _db;
    return db.delete('entregas', where: 'id = ?', whereArgs: [id]);
  }

  /// Estadísticas para el Dashboard.
  Future<Map<String, int>> obtenerEstadisticas() async {
    final db = await _db;

    final total = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM entregas'),
        ) ??
        0;

    final realizadas = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM entregas WHERE fecha_entrega IS NOT NULL',
          ),
        ) ??
        0;

    // Pendientes y atrasadas: fecha_entrega IS NULL y fecha_programada < hoy
    final hoy = DateTime.now();
    final hoyStr =
        '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';

    final atrasadas = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM entregas WHERE fecha_entrega IS NULL AND fecha_programada < ?',
            [hoyStr],
          ),
        ) ??
        0;

    final pendientes = total - realizadas;

    return {
      'total': total,
      'realizadas': realizadas,
      'pendientes': pendientes,
      'atrasadas': atrasadas,
    };
  }
}
