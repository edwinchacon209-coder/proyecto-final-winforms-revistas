import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/revista.dart';

/// Repositorio para operaciones CRUD de Revistas.
class RevistaRepository {
  final DatabaseHelper _dbHelper;

  RevistaRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<Database> get _db async => _dbHelper.database;

  Future<int> insertar(Revista revista) async {
    final db = await _db;
    try {
      return await db.insert(
        'revistas',
        revista.toMap(),
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw Exception('Ya existe una revista con el nombre "${revista.nombre}".');
      }
      rethrow;
    }
  }

  Future<List<Revista>> obtenerTodas() async {
    final db = await _db;
    final maps = await db.query('revistas', orderBy: 'nombre ASC');
    return maps.map(Revista.fromMap).toList();
  }

  Future<Revista?> obtenerPorId(int id) async {
    final db = await _db;
    final maps = await db.query(
      'revistas',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Revista.fromMap(maps.first);
  }

  Future<int> actualizar(Revista revista) async {
    final db = await _db;
    try {
      return await db.update(
        'revistas',
        revista.toMap(),
        where: 'id = ?',
        whereArgs: [revista.id],
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw Exception('Ya existe otra revista con ese nombre.');
      }
      rethrow;
    }
  }

  Future<int> eliminar(int id) async {
    final db = await _db;
    try {
      return await db.delete('revistas', where: 'id = ?', whereArgs: [id]);
    } on DatabaseException catch (e) {
      if (e.toString().contains('FOREIGN KEY constraint failed')) {
        throw Exception(
          'No se puede eliminar la revista porque tiene suscripciones asociadas.',
        );
      }
      rethrow;
    }
  }

  Future<int> contarTotal() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) as total FROM revistas');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
