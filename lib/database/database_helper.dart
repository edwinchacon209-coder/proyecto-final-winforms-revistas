import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Helper singleton para manejar la base de datos SQLite.
///
/// Gestiona la apertura, creación de tablas, migraciones y
/// activación de foreign keys. Todos los repositorios usan
/// esta clase para obtener la instancia de la base de datos.
class DatabaseHelper {
  static const String _dbName = 'revistas_sa.db';
  static const int _dbVersion = 1;

  // Singleton: solo existe una instancia durante el ciclo de vida de la app.
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  /// Retorna la instancia abierta de la base de datos.
  /// Si no existe, la crea e inicializa.
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  /// Activa el soporte de claves foráneas en SQLite.
  /// DEBE ejecutarse antes de cualquier operación.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Crea todas las tablas al inicializar la base de datos por primera vez.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS clientes (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        nit       TEXT    NOT NULL,
        nombre    TEXT    NOT NULL,
        direccion TEXT,
        telefono  TEXT,
        UNIQUE(nit)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS revistas (
        id     INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT    NOT NULL,
        UNIQUE(nombre)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS empleados (
        id     INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS suscripciones (
        id                  INTEGER PRIMARY KEY AUTOINCREMENT,
        numero_suscripcion  TEXT    NOT NULL,
        cliente_id          INTEGER NOT NULL,
        revista_id          INTEGER NOT NULL,
        fecha_inicio        TEXT    NOT NULL,
        fecha_fin           TEXT    NOT NULL,
        UNIQUE(numero_suscripcion),
        FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE RESTRICT,
        FOREIGN KEY (revista_id) REFERENCES revistas(id) ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS entregas (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        numero_envio     TEXT    NOT NULL,
        suscripcion_id   INTEGER NOT NULL,
        empleado_id      INTEGER NOT NULL,
        fecha_programada TEXT    NOT NULL,
        fecha_entrega    TEXT,
        observaciones    TEXT,
        UNIQUE(numero_envio),
        FOREIGN KEY (suscripcion_id) REFERENCES suscripciones(id) ON DELETE RESTRICT,
        FOREIGN KEY (empleado_id)    REFERENCES empleados(id)      ON DELETE RESTRICT
      )
    ''');

    // Insertar datos de demostración
    await _insertarDatosDemostracion(db);
  }

  /// Inserta datos de demostración para poder usar la app inmediatamente.
  ///
  /// IMPORTANTE: Estos son datos de ejemplo, NO reglas del negocio.
  /// La aplicación funciona igualmente con datos completamente nuevos.
  Future<void> _insertarDatosDemostracion(Database db) async {
    // Clientes de ejemplo
    final clienteId1 = await db.insert('clientes', {
      'nit': '123456-7',
      'nombre': 'Librería Central',
      'direccion': '5ta Avenida 10-20, Zona 1',
      'telefono': '2222-3333',
    });
    final clienteId2 = await db.insert('clientes', {
      'nit': '987654-3',
      'nombre': 'Supermercados del Norte',
      'direccion': 'Boulevard Los Próceres 15-60, Zona 10',
      'telefono': '3333-4444',
    });
    final clienteId3 = await db.insert('clientes', {
      'nit': '555555-1',
      'nombre': 'Hotel Las Flores',
      'direccion': '7ma Calle 2-30, Zona 9',
      'telefono': '4444-5555',
    });

    // Revistas de ejemplo
    final revistaId1 = await db.insert('revistas', {'nombre': 'Negocios & Finanzas'});
    final revistaId2 = await db.insert('revistas', {'nombre': 'Tecnología Hoy'});
    final revistaId3 = await db.insert('revistas', {'nombre': 'Salud y Vida'});

    // Empleados de ejemplo
    final empleadoId1 = await db.insert('empleados', {'nombre': 'Carlos Mendoza'});
    final empleadoId2 = await db.insert('empleados', {'nombre': 'María López'});

    // Suscripciones de ejemplo
    final suscId1 = await db.insert('suscripciones', {
      'numero_suscripcion': 'S-0001',
      'cliente_id': clienteId1,
      'revista_id': revistaId1,
      'fecha_inicio': '2025-01-01',
      'fecha_fin': '2025-12-31',
    });
    final suscId2 = await db.insert('suscripciones', {
      'numero_suscripcion': 'S-0002',
      'cliente_id': clienteId1,
      'revista_id': revistaId2,
      'fecha_inicio': '2025-01-01',
      'fecha_fin': '2025-12-31',
    });
    final suscId3 = await db.insert('suscripciones', {
      'numero_suscripcion': 'S-0003',
      'cliente_id': clienteId2,
      'revista_id': revistaId1,
      'fecha_inicio': '2025-03-01',
      'fecha_fin': '2025-12-31',
    });
    final suscId4 = await db.insert('suscripciones', {
      'numero_suscripcion': 'S-0004',
      'cliente_id': clienteId3,
      'revista_id': revistaId3,
      'fecha_inicio': '2025-06-01',
      'fecha_fin': '2025-12-31',
    });

    // Entregas de ejemplo
    // Entrega completada
    await db.insert('entregas', {
      'numero_envio': 'E-0001',
      'suscripcion_id': suscId1,
      'empleado_id': empleadoId1,
      'fecha_programada': '2025-08-01',
      'fecha_entrega': '2025-08-01',
      'observaciones': 'Entrega realizada sin inconvenientes.',
    });
    // Entrega pendiente (a tiempo)
    final hoy = DateTime.now();
    final manana = hoy.add(const Duration(days: 3));
    final fechaManana =
        '${manana.year}-${manana.month.toString().padLeft(2, '0')}-${manana.day.toString().padLeft(2, '0')}';
    await db.insert('entregas', {
      'numero_envio': 'E-0002',
      'suscripcion_id': suscId2,
      'empleado_id': empleadoId2,
      'fecha_programada': fechaManana,
      'fecha_entrega': null,
      'observaciones': null,
    });
    // Entrega atrasada (fecha pasada, sin completar)
    final ayer = hoy.subtract(const Duration(days: 5));
    final fechaAyer =
        '${ayer.year}-${ayer.month.toString().padLeft(2, '0')}-${ayer.day.toString().padLeft(2, '0')}';
    await db.insert('entregas', {
      'numero_envio': 'E-0003',
      'suscripcion_id': suscId3,
      'empleado_id': empleadoId1,
      'fecha_programada': fechaAyer,
      'fecha_entrega': null,
      'observaciones': null,
    });
    // Otra entrega pendiente
    await db.insert('entregas', {
      'numero_envio': 'E-0004',
      'suscripcion_id': suscId4,
      'empleado_id': empleadoId2,
      'fecha_programada': fechaManana,
      'fecha_entrega': null,
      'observaciones': null,
    });
  }

  /// Cierra la conexión a la base de datos.
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
