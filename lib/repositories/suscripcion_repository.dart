import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/suscripcion.dart';

/// Repositorio para operaciones CRUD de Suscripciones.
class SuscripcionRepository {
  final DatabaseHelper _dbHelper;

  SuscripcionRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<Database> get _db async => _dbHelper.database;

  Future<int> insertar(Suscripcion suscripcion) async {
    final db = await _db;
    try {
      return await db.insert(
        'suscripciones',
        suscripcion.toMap(),
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw Exception(
          'Ya existe una suscripción con el número "${suscripcion.numeroSuscripcion}".',
        );
      }
      rethrow;
    }
  }

  /// Retorna todas las suscripciones con datos del cliente y la revista (JOIN).
  Future<List<Suscripcion>> obtenerTodas() async {
    final db = await _db;
    final maps = await db.rawQuery('''
      SELECT 
        s.*,
        c.nombre AS cliente_nombre,
        r.nombre AS revista_nombre
      FROM suscripciones s
      INNER JOIN clientes  c ON s.cliente_id = c.id
      INNER JOIN revistas  r ON s.revista_id = r.id
      ORDER BY s.numero_suscripcion ASC
    ''');
    return maps.map(Suscripcion.fromMap).toList();
  }

  /// Retorna las suscripciones de un cliente específico.
  Future<List<Suscripcion>> obtenerPorCliente(int clienteId) async {
    final db = await _db;
    final maps = await db.rawQuery('''
      SELECT 
        s.*,
        c.nombre AS cliente_nombre,
        r.nombre AS revista_nombre
      FROM suscripciones s
      INNER JOIN clientes  c ON s.cliente_id = c.id
      INNER JOIN revistas  r ON s.revista_id = r.id
      WHERE s.cliente_id = ?
      ORDER BY s.numero_suscripcion ASC
    ''', [clienteId]);
    return maps.map(Suscripcion.fromMap).toList();
  }

  Future<Suscripcion?> obtenerPorId(int id) async {
    final db = await _db;
    final maps = await db.rawQuery('''
      SELECT 
        s.*,
        c.nombre AS cliente_nombre,
        r.nombre AS revista_nombre
      FROM suscripciones s
      INNER JOIN clientes  c ON s.cliente_id = c.id
      INNER JOIN revistas  r ON s.revista_id = r.id
      WHERE s.id = ?
      LIMIT 1
    ''', [id]);
    if (maps.isEmpty) return null;
    return Suscripcion.fromMap(maps.first);
  }

  Future<int> actualizar(Suscripcion suscripcion) async {
    final db = await _db;
    try {
      return await db.update(
        'suscripciones',
        suscripcion.toMap(),
        where: 'id = ?',
        whereArgs: [suscripcion.id],
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw Exception('Ya existe otra suscripción con ese número.');
      }
      rethrow;
    }
  }

  Future<int> eliminar(int id) async {
    final db = await _db;
    try {
      return await db.delete('suscripciones', where: 'id = ?', whereArgs: [id]);
    } on DatabaseException catch (e) {
      if (e.toString().contains('FOREIGN KEY constraint failed')) {
        throw Exception(
          'No se puede eliminar la suscripción porque tiene entregas asociadas.',
        );
      }
      rethrow;
    }
  }

  Future<int> contarTotal() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) as total FROM suscripciones');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
