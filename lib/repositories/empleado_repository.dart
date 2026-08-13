import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/empleado.dart';

/// Repositorio para operaciones CRUD de Empleados.
class EmpleadoRepository {
  final DatabaseHelper _dbHelper;

  EmpleadoRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<Database> get _db async => _dbHelper.database;

  Future<int> insertar(Empleado empleado) async {
    final db = await _db;
    return db.insert('empleados', empleado.toMap());
  }

  Future<List<Empleado>> obtenerTodos() async {
    final db = await _db;
    final maps = await db.query('empleados', orderBy: 'nombre ASC');
    return maps.map(Empleado.fromMap).toList();
  }

  Future<Empleado?> obtenerPorId(int id) async {
    final db = await _db;
    final maps = await db.query(
      'empleados',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Empleado.fromMap(maps.first);
  }

  Future<int> actualizar(Empleado empleado) async {
    final db = await _db;
    return db.update(
      'empleados',
      empleado.toMap(),
      where: 'id = ?',
      whereArgs: [empleado.id],
    );
  }

  Future<int> eliminar(int id) async {
    final db = await _db;
    try {
      return await db.delete('empleados', where: 'id = ?', whereArgs: [id]);
    } on DatabaseException catch (e) {
      if (e.toString().contains('FOREIGN KEY constraint failed')) {
        throw Exception(
          'No se puede eliminar el empleado porque tiene entregas asociadas.',
        );
      }
      rethrow;
    }
  }
}
