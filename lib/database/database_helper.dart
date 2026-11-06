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

  /// Inserta datos de demostración completos para pruebas y reportes.
  ///
  /// Recibe un [DatabaseExecutor] para poder usarse tanto en [_onCreate]
  /// como dentro de una transacción en [reiniciarConDatosDemostracion].
  Future<void> _insertarDatosDemostracion(DatabaseExecutor db) async {
    // 1. Clientes (8 clientes realistas en Guatemala)
    final c1 = await db.insert('clientes', {
      'nit': '123456-7',
      'nombre': 'Librería Central',
      'direccion': '5ta Avenida 10-20, Zona 1, Ciudad de Guatemala',
      'telefono': '2222-3333',
    });
    final c2 = await db.insert('clientes', {
      'nit': '987654-3',
      'nombre': 'Supermercados del Norte',
      'direccion': 'Boulevard Los Próceres 15-60, Zona 10',
      'telefono': '3333-4444',
    });
    final c3 = await db.insert('clientes', {
      'nit': '555555-1',
      'nombre': 'Hotel Las Flores',
      'direccion': '7ma Calle 2-30, Zona 9',
      'telefono': '4444-5555',
    });
    final c4 = await db.insert('clientes', {
      'nit': '789123-4',
      'nombre': 'Corporación Financiera de Occidente',
      'direccion': '12 Calle 4-55, Zona 14, Edificio Reforma Nivel 8',
      'telefono': '2333-9900',
    });
    final c5 = await db.insert('clientes', {
      'nit': '345678-9',
      'nombre': 'Farmacias La Salud',
      'direccion': 'Calzada Roosevelt 22-01, Zona 11',
      'telefono': '2470-1122',
    });
    final c6 = await db.insert('clientes', {
      'nit': '654321-0',
      'nombre': 'Colegio Mayor San Jerónimo',
      'direccion': '4ta Avenida Norte #12, Antigua Guatemala',
      'telefono': '7832-4500',
    });
    final c7 = await db.insert('clientes', {
      'nit': '112233-8',
      'nombre': 'Restaurante y Café Mirador',
      'direccion': 'Carretera a El Salvador Km 14.5, Santa Catarina Pinula',
      'telefono': '6634-8899',
    });
    final c8 = await db.insert('clientes', {
      'nit': '998877-2',
      'nombre': 'Distribuidora Automotriz del Valle',
      'direccion': 'Calzada San Juan 14-88, Zona 7',
      'telefono': '2433-7711',
    });

    // 2. Revistas (7 revistas variadas)
    final r1 = await db.insert('revistas', {'nombre': 'Negocios & Finanzas'});
    final r2 = await db.insert('revistas', {'nombre': 'Tecnología Hoy'});
    final r3 = await db.insert('revistas', {'nombre': 'Salud y Vida'});
    final r4 = await db.insert('revistas', {'nombre': 'Cocina & Sabor'});
    final r5 = await db.insert('revistas', {'nombre': 'Ciencia al Día'});
    final r6 = await db.insert('revistas', {'nombre': 'Viajes & Aventura'});
    final r7 = await db.insert('revistas', {'nombre': 'Deportes Total'});

    // 3. Empleados de entrega (5 repartidores)
    final emp1 = await db.insert('empleados', {'nombre': 'Carlos Mendoza'});
    final emp2 = await db.insert('empleados', {'nombre': 'María López'});
    final emp3 = await db.insert('empleados', {'nombre': 'Juan Pérez'});
    final emp4 = await db.insert('empleados', {'nombre': 'Andrea Gómez'});
    final emp5 = await db.insert('empleados', {'nombre': 'Roberto Juárez'});

    // 4. Suscripciones (14 suscripciones únicas)
    final s1 = await db.insert('suscripciones', {
      'numero_suscripcion': 'S-0001',
      'cliente_id': c1,
      'revista_id': r1,
      'fecha_inicio': '2025-01-01',
      'fecha_fin': '2025-12-31',
    });
    final s2 = await db.insert('suscripciones', {
      'numero_suscripcion': 'S-0002',
      'cliente_id': c1,
      'revista_id': r2,
      'fecha_inicio': '2025-01-01',
      'fecha_fin': '2025-12-31',
    });
    final s3 = await db.insert('suscripciones', {
      'numero_suscripcion': 'S-0003',
      'cliente_id': c2,
      'revista_id': r1,
      'fecha_inicio': '2025-02-01',
      'fecha_fin': '2026-01-31',
    });
    final s4 = await db.insert('suscripciones', {
      'numero_suscripcion': 'S-0004',
      'cliente_id': c2,
      'revista_id': r4,
      'fecha_inicio': '2025-03-01',
      'fecha_fin': '2026-02-28',
    });
    final s5 = await db.insert('suscripciones', {
      'numero_suscripcion': 'S-0005',
      'cliente_id': c3,
      'revista_id': r3,
      'fecha_inicio': '2025-01-15',
      'fecha_fin': '2026-01-14',
    });
    final s6 = await db.insert('suscripciones', {
      'numero_suscripcion': 'S-0006',
      'cliente_id': c3,
      'revista_id': r6,
      'fecha_inicio': '2025-05-01',
      'fecha_fin': '2026-04-30',
    });
    final s7 = await db.insert('suscripciones', {
      'numero_suscripcion': 'S-0007',
      'cliente_id': c4,
      'revista_id': r1,
      'fecha_inicio': '2025-01-01',
      'fecha_fin': '2026-12-31',
    });
    final s8 = await db.insert('suscripciones', {
      'numero_suscripcion': 'S-0008',
      'cliente_id': c4,
      'revista_id': r2,
      'fecha_inicio': '2025-04-01',
      'fecha_fin': '2026-03-31',
    });
    final s9 = await db.insert('suscripciones', {
      'numero_suscripcion': 'S-0009',
      'cliente_id': c5,
      'revista_id': r3,
      'fecha_inicio': '2025-02-01',
      'fecha_fin': '2026-01-31',
    });
    final s10 = await db.insert('suscripciones', {
      'numero_suscripcion': 'S-0010',
      'cliente_id': c5,
      'revista_id': r5,
      'fecha_inicio': '2025-06-01',
      'fecha_fin': '2026-05-31',
    });
    final s11 = await db.insert('suscripciones', {
      'numero_suscripcion': 'S-0011',
      'cliente_id': c6,
      'revista_id': r5,
      'fecha_inicio': '2025-01-15',
      'fecha_fin': '2025-12-15',
    });
    final s12 = await db.insert('suscripciones', {
      'numero_suscripcion': 'S-0012',
      'cliente_id': c7,
      'revista_id': r4,
      'fecha_inicio': '2025-03-10',
      'fecha_fin': '2026-03-09',
    });
    final s13 = await db.insert('suscripciones', {
      'numero_suscripcion': 'S-0013',
      'cliente_id': c7,
      'revista_id': r7,
      'fecha_inicio': '2025-07-01',
      'fecha_fin': '2026-06-30',
    });
    final s14 = await db.insert('suscripciones', {
      'numero_suscripcion': 'S-0014',
      'cliente_id': c8,
      'revista_id': r7,
      'fecha_inicio': '2025-04-01',
      'fecha_fin': '2026-03-31',
    });

    // 5. Entregas (20 envíos con estados variados: Realizadas, Pendientes y Atrasadas)
    final hoy = DateTime.now();

    String formatoFecha(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    // A. Entregas Realizadas (8 entregas)
    await db.insert('entregas', {
      'numero_envio': 'E-0001',
      'suscripcion_id': s1,
      'empleado_id': emp1,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 30))),
      'fecha_entrega': formatoFecha(hoy.subtract(const Duration(days: 30))),
      'observaciones': 'Recibido en recepción principal por Lic. Fuentes.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0002',
      'suscripcion_id': s2,
      'empleado_id': emp2,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 25))),
      'fecha_entrega': formatoFecha(hoy.subtract(const Duration(days: 25))),
      'observaciones': 'Entregado a encargado de bodega sin novedades.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0003',
      'suscripcion_id': s3,
      'empleado_id': emp3,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 20))),
      'fecha_entrega': formatoFecha(hoy.subtract(const Duration(days: 19))),
      'observaciones': 'Entrega adelantada un día a solicitud del cliente.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0004',
      'suscripcion_id': s5,
      'empleado_id': emp1,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 15))),
      'fecha_entrega': formatoFecha(hoy.subtract(const Duration(days: 15))),
      'observaciones': 'Recibido en conserjería del hotel con sello conforme.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0005',
      'suscripcion_id': s7,
      'empleado_id': emp4,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 12))),
      'fecha_entrega': formatoFecha(hoy.subtract(const Duration(days: 12))),
      'observaciones': 'Firma y sello en garita de seguridad nivel 8.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0006',
      'suscripcion_id': s9,
      'empleado_id': emp5,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 10))),
      'fecha_entrega': formatoFecha(hoy.subtract(const Duration(days: 10))),
      'observaciones': 'Entregado en sucursal Roosevelt conforme.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0007',
      'suscripcion_id': s11,
      'empleado_id': emp3,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 7))),
      'fecha_entrega': formatoFecha(hoy.subtract(const Duration(days: 7))),
      'observaciones': 'Entregado en secretaría del colegio.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0008',
      'suscripcion_id': s12,
      'empleado_id': emp2,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 4))),
      'fecha_entrega': formatoFecha(hoy.subtract(const Duration(days: 4))),
      'observaciones': 'Entregado al chef ejecutivo de turno.',
    });

    // B. Entregas Atrasadas (fecha programada ya pasó, aún no entregadas) (6 entregas)
    await db.insert('entregas', {
      'numero_envio': 'E-0009',
      'suscripcion_id': s4,
      'empleado_id': emp2,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 8))),
      'fecha_entrega': null,
      'observaciones': 'Intento 1: Local cerrado por inventario anual.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0010',
      'suscripcion_id': s6,
      'empleado_id': emp1,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 6))),
      'fecha_entrega': null,
      'observaciones': 'Dirección temporalmente inaccesible por obras viales.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0011',
      'suscripcion_id': s8,
      'empleado_id': emp4,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 5))),
      'fecha_entrega': null,
      'observaciones': 'Pendiente de confirmación de horario de entrega.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0012',
      'suscripcion_id': s10,
      'empleado_id': emp5,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 3))),
      'fecha_entrega': null,
      'observaciones': null,
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0013',
      'suscripcion_id': s13,
      'empleado_id': emp3,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 2))),
      'fecha_entrega': null,
      'observaciones': 'Reprogramado por lluvia intensa en la ruta.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0014',
      'suscripcion_id': s14,
      'empleado_id': emp1,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 1))),
      'fecha_entrega': null,
      'observaciones': null,
    });

    // C. Entregas Pendientes a tiempo (fecha programada hoy o futura) (6 entregas)
    await db.insert('entregas', {
      'numero_envio': 'E-0015',
      'suscripcion_id': s1,
      'empleado_id': emp1,
      'fecha_programada': formatoFecha(hoy),
      'fecha_entrega': null,
      'observaciones': 'Programada para entrega hoy en turno de la tarde.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0016',
      'suscripcion_id': s2,
      'empleado_id': emp2,
      'fecha_programada': formatoFecha(hoy.add(const Duration(days: 2))),
      'fecha_entrega': null,
      'observaciones': 'Paquete empacado y listo para despacho.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0017',
      'suscripcion_id': s3,
      'empleado_id': emp3,
      'fecha_programada': formatoFecha(hoy.add(const Duration(days: 4))),
      'fecha_entrega': null,
      'observaciones': null,
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0018',
      'suscripcion_id': s5,
      'empleado_id': emp4,
      'fecha_programada': formatoFecha(hoy.add(const Duration(days: 5))),
      'fecha_entrega': null,
      'observaciones': 'Edición especial de fin de mes.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0019',
      'suscripcion_id': s7,
      'empleado_id': emp5,
      'fecha_programada': formatoFecha(hoy.add(const Duration(days: 7))),
      'fecha_entrega': null,
      'observaciones': null,
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0020',
      'suscripcion_id': s9,
      'empleado_id': emp2,
      'fecha_programada': formatoFecha(hoy.add(const Duration(days: 10))),
      'fecha_entrega': null,
      'observaciones': 'Programado según ciclo quincenal.',
    });
  }

  /// Limpia y recarga la base de datos con los datos de prueba completos.
  /// Muy útil para pruebas, presentaciones académicas y demostraciones de reportes.
  Future<void> reiniciarConDatosDemostracion() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('entregas');
      await txn.delete('suscripciones');
      await txn.delete('empleados');
      await txn.delete('revistas');
      await txn.delete('clientes');
      await _insertarDatosDemostracion(txn);
    });
  }

  /// Cierra la conexión a la base de datos.
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
