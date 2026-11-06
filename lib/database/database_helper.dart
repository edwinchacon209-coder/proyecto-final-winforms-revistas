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
    // ── 1. Clientes y Empresas (15 clientes variados) ──
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
    final c9 = await db.insert('clientes', {
      'nit': '443322-5',
      'nombre': 'Clínica Dental Sonrisas Sanas',
      'direccion': '2da Calle 18-40, Zona 15, Vista Hermosa II',
      'telefono': '2369-1234',
    });
    final c10 = await db.insert('clientes', {
      'nit': '887766-9',
      'nombre': 'Bufete Jurídico Méndez & Asociados',
      'direccion': '6ta Avenida 6-63, Zona 10, Edificio Sixtino I Of. 502',
      'telefono': '2269-8080',
    });
    final c11 = await db.insert('clientes', {
      'nit': '332211-4',
      'nombre': 'Inmobiliaria y Constructora Los Volcanes',
      'direccion': 'Carretera a El Salvador Km 18.5, Fraijanes',
      'telefono': '6644-2200',
    });
    final c12 = await db.insert('clientes', {
      'nit': '778899-1',
      'nombre': 'Imprenta y Litografía Moderna',
      'direccion': 'Avenida Petapa 34-21, Zona 12',
      'telefono': '2476-5544',
    });
    final c13 = await db.insert('clientes', {
      'nit': '224466-8',
      'nombre': 'Universidad Panamericana de Guatemala',
      'direccion': 'Paseo Cayalá, Zona 16, Edificio de Posgrados',
      'telefono': '2490-3000',
    });
    final c14 = await db.insert('clientes', {
      'nit': '667788-3',
      'nombre': 'Distribuidora de Alimentos La Canasta',
      'direccion': 'Boulevard San Cristóbal 8-90, Zona 8 de Mixco',
      'telefono': '2484-9911',
    });
    final c15 = await db.insert('clientes', {
      'nit': '991122-0',
      'nombre': 'Café Gourmet Las Cumbres',
      'direccion': 'Calle Principal #4-20, Cobán, Alta Verapaz',
      'telefono': '7951-3322',
    });

    // ── 2. Revistas (10 revistas temáticas) ──
    final r1 = await db.insert('revistas', {'nombre': 'Negocios & Finanzas'});
    final r2 = await db.insert('revistas', {'nombre': 'Tecnología Hoy'});
    final r3 = await db.insert('revistas', {'nombre': 'Salud y Vida'});
    final r4 = await db.insert('revistas', {'nombre': 'Cocina & Sabor'});
    final r5 = await db.insert('revistas', {'nombre': 'Ciencia al Día'});
    final r6 = await db.insert('revistas', {'nombre': 'Viajes & Aventura'});
    final r7 = await db.insert('revistas', {'nombre': 'Deportes Total'});
    final r8 = await db.insert('revistas', {'nombre': 'Arquitectura & Diseño'});
    final r9 = await db.insert('revistas', {'nombre': 'Educación y Cultura'});
    final r10 = await db.insert('revistas', {'nombre': 'Automovilismo Moderno'});

    // ── 3. Empleados de Entrega (8 repartidores) ──
    final emp1 = await db.insert('empleados', {'nombre': 'Carlos Mendoza'});
    final emp2 = await db.insert('empleados', {'nombre': 'María López'});
    final emp3 = await db.insert('empleados', {'nombre': 'Juan Pérez'});
    final emp4 = await db.insert('empleados', {'nombre': 'Andrea Gómez'});
    final emp5 = await db.insert('empleados', {'nombre': 'Roberto Juárez'});
    final emp6 = await db.insert('empleados', {'nombre': 'Lucía Castillo'});
    final emp7 = await db.insert('empleados', {'nombre': 'Fernando Morales'});
    final emp8 = await db.insert('empleados', {'nombre': 'Sofía Estrada'});

    // ── 4. Suscripciones (25 suscripciones únicas) ──
    final s1 = await db.insert('suscripciones', {'numero_suscripcion': 'S-0001', 'cliente_id': c1, 'revista_id': r1, 'fecha_inicio': '2025-01-01', 'fecha_fin': '2025-12-31'});
    final s2 = await db.insert('suscripciones', {'numero_suscripcion': 'S-0002', 'cliente_id': c1, 'revista_id': r2, 'fecha_inicio': '2025-01-01', 'fecha_fin': '2025-12-31'});
    final s3 = await db.insert('suscripciones', {'numero_suscripcion': 'S-0003', 'cliente_id': c2, 'revista_id': r1, 'fecha_inicio': '2025-02-01', 'fecha_fin': '2026-01-31'});
    final s4 = await db.insert('suscripciones', {'numero_suscripcion': 'S-0004', 'cliente_id': c2, 'revista_id': r4, 'fecha_inicio': '2025-03-01', 'fecha_fin': '2026-02-28'});
    final s5 = await db.insert('suscripciones', {'numero_suscripcion': 'S-0005', 'cliente_id': c3, 'revista_id': r3, 'fecha_inicio': '2025-01-15', 'fecha_fin': '2026-01-14'});
    final s6 = await db.insert('suscripciones', {'numero_suscripcion': 'S-0006', 'cliente_id': c3, 'revista_id': r6, 'fecha_inicio': '2025-05-01', 'fecha_fin': '2026-04-30'});
    final s7 = await db.insert('suscripciones', {'numero_suscripcion': 'S-0007', 'cliente_id': c4, 'revista_id': r1, 'fecha_inicio': '2025-01-01', 'fecha_fin': '2026-12-31'});
    final s8 = await db.insert('suscripciones', {'numero_suscripcion': 'S-0008', 'cliente_id': c4, 'revista_id': r2, 'fecha_inicio': '2025-04-01', 'fecha_fin': '2026-03-31'});
    final s9 = await db.insert('suscripciones', {'numero_suscripcion': 'S-0009', 'cliente_id': c5, 'revista_id': r3, 'fecha_inicio': '2025-02-01', 'fecha_fin': '2026-01-31'});
    final s10 = await db.insert('suscripciones', {'numero_suscripcion': 'S-0010', 'cliente_id': c5, 'revista_id': r5, 'fecha_inicio': '2025-06-01', 'fecha_fin': '2026-05-31'});
    final s11 = await db.insert('suscripciones', {'numero_suscripcion': 'S-0011', 'cliente_id': c6, 'revista_id': r5, 'fecha_inicio': '2025-01-15', 'fecha_fin': '2025-12-15'});
    final s12 = await db.insert('suscripciones', {'numero_suscripcion': 'S-0012', 'cliente_id': c7, 'revista_id': r4, 'fecha_inicio': '2025-03-10', 'fecha_fin': '2026-03-09'});
    final s13 = await db.insert('suscripciones', {'numero_suscripcion': 'S-0013', 'cliente_id': c7, 'revista_id': r7, 'fecha_inicio': '2025-07-01', 'fecha_fin': '2026-06-30'});
    final s14 = await db.insert('suscripciones', {'numero_suscripcion': 'S-0014', 'cliente_id': c8, 'revista_id': r7, 'fecha_inicio': '2025-04-01', 'fecha_fin': '2026-03-31'});
    final s15 = await db.insert('suscripciones', {'numero_suscripcion': 'S-0015', 'cliente_id': c8, 'revista_id': r10, 'fecha_inicio': '2025-04-01', 'fecha_fin': '2026-03-31'});
    final s16 = await db.insert('suscripciones', {'numero_suscripcion': 'S-0016', 'cliente_id': c9, 'revista_id': r3, 'fecha_inicio': '2025-05-01', 'fecha_fin': '2026-04-30'});
    final s17 = await db.insert('suscripciones', {'numero_suscripcion': 'S-0017', 'cliente_id': c10, 'revista_id': r1, 'fecha_inicio': '2025-01-01', 'fecha_fin': '2026-12-31'});
    final s18 = await db.insert('suscripciones', {'numero_suscripcion': 'S-0018', 'cliente_id': c11, 'revista_id': r8, 'fecha_inicio': '2025-02-15', 'fecha_fin': '2026-02-14'});
    final s19 = await db.insert('suscripciones', {'numero_suscripcion': 'S-0019', 'cliente_id': c11, 'revista_id': r1, 'fecha_inicio': '2025-02-15', 'fecha_fin': '2026-02-14'});
    final s20 = await db.insert('suscripciones', {'numero_suscripcion': 'S-0020', 'cliente_id': c12, 'revista_id': r8, 'fecha_inicio': '2025-03-01', 'fecha_fin': '2026-02-28'});
    final s21 = await db.insert('suscripciones', {'numero_suscripcion': 'S-0021', 'cliente_id': c13, 'revista_id': r9, 'fecha_inicio': '2025-01-10', 'fecha_fin': '2026-01-09'});
    final s22 = await db.insert('suscripciones', {'numero_suscripcion': 'S-0022', 'cliente_id': c13, 'revista_id': r5, 'fecha_inicio': '2025-01-10', 'fecha_fin': '2026-01-09'});
    final s23 = await db.insert('suscripciones', {'numero_suscripcion': 'S-0023', 'cliente_id': c14, 'revista_id': r4, 'fecha_inicio': '2025-06-01', 'fecha_fin': '2026-05-31'});
    final s24 = await db.insert('suscripciones', {'numero_suscripcion': 'S-0024', 'cliente_id': c15, 'revista_id': r6, 'fecha_inicio': '2025-04-15', 'fecha_fin': '2026-04-14'});
    final s25 = await db.insert('suscripciones', {'numero_suscripcion': 'S-0025', 'cliente_id': c15, 'revista_id': r4, 'fecha_inicio': '2025-04-15', 'fecha_fin': '2026-04-14'});

    // ── 5. Entregas (35 envíos: Realizadas, Atrasadas y Pendientes) ──
    final hoy = DateTime.now();

    String formatoFecha(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    // A. Entregas Realizadas (15 entregas)
    await db.insert('entregas', {
      'numero_envio': 'E-0001',
      'suscripcion_id': s1,
      'empleado_id': emp1,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 40))),
      'fecha_entrega': formatoFecha(hoy.subtract(const Duration(days: 40))),
      'observaciones': 'Recibido en recepción principal por Lic. Fuentes.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0002',
      'suscripcion_id': s2,
      'empleado_id': emp2,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 35))),
      'fecha_entrega': formatoFecha(hoy.subtract(const Duration(days: 35))),
      'observaciones': 'Entregado a encargado de bodega sin novedades.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0003',
      'suscripcion_id': s3,
      'empleado_id': emp3,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 30))),
      'fecha_entrega': formatoFecha(hoy.subtract(const Duration(days: 29))),
      'observaciones': 'Entrega adelantada un día a solicitud del cliente.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0004',
      'suscripcion_id': s5,
      'empleado_id': emp1,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 25))),
      'fecha_entrega': formatoFecha(hoy.subtract(const Duration(days: 25))),
      'observaciones': 'Recibido en conserjería del hotel con sello conforme.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0005',
      'suscripcion_id': s7,
      'empleado_id': emp4,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 22))),
      'fecha_entrega': formatoFecha(hoy.subtract(const Duration(days: 22))),
      'observaciones': 'Firma y sello en garita de seguridad nivel 8.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0006',
      'suscripcion_id': s9,
      'empleado_id': emp5,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 20))),
      'fecha_entrega': formatoFecha(hoy.subtract(const Duration(days: 20))),
      'observaciones': 'Entregado en sucursal Roosevelt conforme.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0007',
      'suscripcion_id': s11,
      'empleado_id': emp6,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 18))),
      'fecha_entrega': formatoFecha(hoy.subtract(const Duration(days: 18))),
      'observaciones': 'Entregado en secretaría del colegio.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0008',
      'suscripcion_id': s12,
      'empleado_id': emp2,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 15))),
      'fecha_entrega': formatoFecha(hoy.subtract(const Duration(days: 15))),
      'observaciones': 'Entregado al chef ejecutivo de turno.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0009',
      'suscripcion_id': s15,
      'empleado_id': emp7,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 14))),
      'fecha_entrega': formatoFecha(hoy.subtract(const Duration(days: 14))),
      'observaciones': 'Recibido en taller de servicio automotriz.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0010',
      'suscripcion_id': s16,
      'empleado_id': emp8,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 12))),
      'fecha_entrega': formatoFecha(hoy.subtract(const Duration(days: 12))),
      'observaciones': 'Entregado en recepción médica dental.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0011',
      'suscripcion_id': s17,
      'empleado_id': emp1,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 10))),
      'fecha_entrega': formatoFecha(hoy.subtract(const Duration(days: 10))),
      'observaciones': 'Entregado en oficina jurídica Sixtino.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0012',
      'suscripcion_id': s18,
      'empleado_id': emp3,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 8))),
      'fecha_entrega': formatoFecha(hoy.subtract(const Duration(days: 8))),
      'observaciones': 'Firma de recibido por Ing. de Proyectos.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0013',
      'suscripcion_id': s20,
      'empleado_id': emp4,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 6))),
      'fecha_entrega': formatoFecha(hoy.subtract(const Duration(days: 6))),
      'observaciones': 'Recibido en control de calidad de imprenta.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0014',
      'suscripcion_id': s21,
      'empleado_id': emp5,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 4))),
      'fecha_entrega': formatoFecha(hoy.subtract(const Duration(days: 4))),
      'observaciones': 'Entregado en biblioteca universitaria Cayalá.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0015',
      'suscripcion_id': s23,
      'empleado_id': emp6,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 3))),
      'fecha_entrega': formatoFecha(hoy.subtract(const Duration(days: 3))),
      'observaciones': 'Recibido en centro de distribución San Cristóbal.',
    });

    // B. Entregas Atrasadas (10 entregas)
    await db.insert('entregas', {
      'numero_envio': 'E-0016',
      'suscripcion_id': s4,
      'empleado_id': emp2,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 10))),
      'fecha_entrega': null,
      'observaciones': 'Intento 1: Local cerrado por inventario de almacén.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0017',
      'suscripcion_id': s6,
      'empleado_id': emp1,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 8))),
      'fecha_entrega': null,
      'observaciones': 'Dirección temporalmente inaccesible por obras viales.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0018',
      'suscripcion_id': s8,
      'empleado_id': emp4,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 7))),
      'fecha_entrega': null,
      'observaciones': 'Pendiente de confirmación de horario de oficina.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0019',
      'suscripcion_id': s10,
      'empleado_id': emp5,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 5))),
      'fecha_entrega': null,
      'observaciones': 'Cliente solicitó reprogramación para próximo lunes.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0020',
      'suscripcion_id': s13,
      'empleado_id': emp3,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 4))),
      'fecha_entrega': null,
      'observaciones': 'Reprogramado por lluvia intensa y derrumbe en ruta.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0021',
      'suscripcion_id': s14,
      'empleado_id': emp7,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 3))),
      'fecha_entrega': null,
      'observaciones': 'Repartidor con desperfecto mecánico en motocicleta.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0022',
      'suscripcion_id': s19,
      'empleado_id': emp8,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 3))),
      'fecha_entrega': null,
      'observaciones': 'Garita no autorizó ingreso sin carnet de identificación.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0023',
      'suscripcion_id': s22,
      'empleado_id': emp1,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 2))),
      'fecha_entrega': null,
      'observaciones': 'Facultad en período de evaluaciones sin atención al público.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0024',
      'suscripcion_id': s24,
      'empleado_id': emp2,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 1))),
      'fecha_entrega': null,
      'observaciones': 'Envío foráneo en tránsito hacia Alta Verapaz.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0025',
      'suscripcion_id': s25,
      'empleado_id': emp3,
      'fecha_programada': formatoFecha(hoy.subtract(const Duration(days: 1))),
      'fecha_entrega': null,
      'observaciones': null,
    });

    // C. Entregas Pendientes a tiempo (10 entregas)
    await db.insert('entregas', {
      'numero_envio': 'E-0026',
      'suscripcion_id': s1,
      'empleado_id': emp1,
      'fecha_programada': formatoFecha(hoy),
      'fecha_entrega': null,
      'observaciones': 'Programada para entrega hoy en turno de la tarde.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0027',
      'suscripcion_id': s2,
      'empleado_id': emp2,
      'fecha_programada': formatoFecha(hoy.add(const Duration(days: 1))),
      'fecha_entrega': null,
      'observaciones': 'Paquete empacado y listo para despacho matutino.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0028',
      'suscripcion_id': s3,
      'empleado_id': emp3,
      'fecha_programada': formatoFecha(hoy.add(const Duration(days: 2))),
      'fecha_entrega': null,
      'observaciones': null,
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0029',
      'suscripcion_id': s5,
      'empleado_id': emp4,
      'fecha_programada': formatoFecha(hoy.add(const Duration(days: 3))),
      'fecha_entrega': null,
      'observaciones': 'Edición especial de fin de mes.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0030',
      'suscripcion_id': s7,
      'empleado_id': emp5,
      'fecha_programada': formatoFecha(hoy.add(const Duration(days: 4))),
      'fecha_entrega': null,
      'observaciones': null,
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0031',
      'suscripcion_id': s9,
      'empleado_id': emp6,
      'fecha_programada': formatoFecha(hoy.add(const Duration(days: 5))),
      'fecha_entrega': null,
      'observaciones': 'Programado según ciclo quincenal.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0032',
      'suscripcion_id': s12,
      'empleado_id': emp7,
      'fecha_programada': formatoFecha(hoy.add(const Duration(days: 6))),
      'fecha_entrega': null,
      'observaciones': 'Ruta Carretera a El Salvador.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0033',
      'suscripcion_id': s15,
      'empleado_id': emp8,
      'fecha_programada': formatoFecha(hoy.add(const Duration(days: 7))),
      'fecha_entrega': null,
      'observaciones': null,
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0034',
      'suscripcion_id': s18,
      'empleado_id': emp1,
      'fecha_programada': formatoFecha(hoy.add(const Duration(days: 8))),
      'fecha_entrega': null,
      'observaciones': 'Volumen doble de revistas de arquitectura.',
    });
    await db.insert('entregas', {
      'numero_envio': 'E-0035',
      'suscripcion_id': s21,
      'empleado_id': emp2,
      'fecha_programada': formatoFecha(hoy.add(const Duration(days: 10))),
      'fecha_entrega': null,
      'observaciones': 'Entrega en rectoría universitaria.',
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
