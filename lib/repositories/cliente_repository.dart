import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/cliente.dart';

/// Repositorio para operaciones CRUD de Clientes.
class ClienteRepository {
  final DatabaseHelper _dbHelper;

  ClienteRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<Database> get _db async => _dbHelper.database;

  /// Inserta un nuevo cliente. Lanza excepción si el NIT ya existe.
  Future<int> insertar(Cliente cliente) async {
    final db = await _db;
    try {
      return await db.insert(
        'clientes',
        cliente.toMap(),
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw Exception('Ya existe un cliente con el NIT "${cliente.nit}".');
      }
      rethrow;
    }
  }

  /// Retorna todos los clientes ordenados por nombre.
  Future<List<Cliente>> obtenerTodos() async {
    final db = await _db;
    final maps = await db.query('clientes', orderBy: 'nombre ASC');
    return maps.map(Cliente.fromMap).toList();
  }

  /// Busca un cliente por su ID. Retorna null si no existe.
  Future<Cliente?> obtenerPorId(int id) async {
    final db = await _db;
    final maps = await db.query(
      'clientes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Cliente.fromMap(maps.first);
  }

  /// Busca clientes cuyo nombre o NIT contenga el término de búsqueda.
  Future<List<Cliente>> buscar(String termino) async {
    final db = await _db;
    final maps = await db.query(
      'clientes',
      where: 'nombre LIKE ? OR nit LIKE ?',
      whereArgs: ['%$termino%', '%$termino%'],
      orderBy: 'nombre ASC',
    );
    return maps.map(Cliente.fromMap).toList();
  }

  /// Actualiza un cliente existente.
  Future<int> actualizar(Cliente cliente) async {
    final db = await _db;
    try {
      return await db.update(
        'clientes',
        cliente.toMap(),
        where: 'id = ?',
        whereArgs: [cliente.id],
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw Exception('Ya existe otro cliente con el NIT "${cliente.nit}".');
      }
      rethrow;
    }
  }

  /// Elimina un cliente. Lanza excepción si tiene suscripciones asociadas.
  Future<int> eliminar(int id) async {
    final db = await _db;
    try {
      return await db.delete(
        'clientes',
        where: 'id = ?',
        whereArgs: [id],
      );
    } on DatabaseException catch (e) {
      if (e.toString().contains('FOREIGN KEY constraint failed')) {
        throw Exception(
          'No se puede eliminar el cliente porque tiene suscripciones asociadas.',
        );
      }
      rethrow;
    }
  }

  /// Retorna el total de clientes registrados.
  Future<int> contarTotal() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) as total FROM clientes');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
