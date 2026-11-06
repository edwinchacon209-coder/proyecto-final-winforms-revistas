import 'package:flutter/material.dart';
import '../../repositories/cliente_repository.dart';
import '../../repositories/revista_repository.dart';
import '../../repositories/suscripcion_repository.dart';
import '../../repositories/entrega_repository.dart';
import '../clientes/clientes_screen.dart';
import '../revistas/revistas_screen.dart';
import '../empleados/empleados_screen.dart';
import '../suscripciones/suscripciones_screen.dart';
import '../entregas/entregas_screen.dart';
import '../reportes/reportes_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _clienteRepo = ClienteRepository();
  final _revistaRepo = RevistaRepository();
  final _suscripcionRepo = SuscripcionRepository();
  final _entregaRepo = EntregaRepository();

  int _totalClientes = 0;
  int _totalRevistas = 0;
  int _totalSuscripciones = 0;
  int _entregasPendientes = 0;
  int _entregasRealizadas = 0;
  int _entregasAtrasadas = 0;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarEstadisticas();
  }

  Future<void> _cargarEstadisticas() async {
    setState(() => _cargando = true);
    try {
      final clientes = await _clienteRepo.contarTotal();
      final revistas = await _revistaRepo.contarTotal();
      final suscripciones = await _suscripcionRepo.contarTotal();
      final stats = await _entregaRepo.obtenerEstadisticas();

      if (mounted) {
        setState(() {
          _totalClientes = clientes;
          _totalRevistas = revistas;
          _totalSuscripciones = suscripciones;
          _entregasPendientes = stats['pendientes'] ?? 0;
          _entregasRealizadas = stats['realizadas'] ?? 0;
          _entregasAtrasadas = stats['atrasadas'] ?? 0;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar estadísticas: $e')),
        );
      }
    }
  }

  void _navegar(Widget destino) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => destino),
    ).then((_) => _cargarEstadisticas()); // Recargar al volver
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revistas S.A.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Sistema de Gestión de Entregas',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment),
            tooltip: 'Centro de Reportes',
            onPressed: () => _navegar(const ReportesScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _cargarEstadisticas,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarEstadisticas,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Sección Entregas ---
                    _SectionTitle(
                      icon: Icons.local_shipping,
                      titulo: 'Entregas',
                      color: cs.primary,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            titulo: 'Pendientes',
                            valor: _entregasPendientes,
                            icono: Icons.schedule,
                            color: Colors.orange.shade700,
                            onTap: () => _navegar(
                              const EntregasScreen(filtroInicial: 'pendientes'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            titulo: 'Realizadas',
                            valor: _entregasRealizadas,
                            icono: Icons.check_circle,
                            color: Colors.green.shade700,
                            onTap: () => _navegar(
                              const EntregasScreen(filtroInicial: 'realizadas'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _StatCard(
                      titulo: 'Atrasadas',
                      valor: _entregasAtrasadas,
                      icono: Icons.warning_amber_rounded,
                      color: Colors.red.shade700,
                      ancho: double.infinity,
                      onTap: () => _navegar(
                        const EntregasScreen(filtroInicial: 'atrasadas'),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Sección Catálogos ---
                    _SectionTitle(
                      icon: Icons.folder_open,
                      titulo: 'Catálogos',
                      color: cs.primary,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            titulo: 'Clientes',
                            valor: _totalClientes,
                            icono: Icons.people,
                            color: cs.primary,
                            onTap: () => _navegar(const ClientesScreen()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            titulo: 'Revistas',
                            valor: _totalRevistas,
                            icono: Icons.menu_book,
                            color: Colors.teal.shade700,
                            onTap: () => _navegar(const RevistasScreen()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _StatCard(
                      titulo: 'Suscripciones',
                      valor: _totalSuscripciones,
                      icono: Icons.subscriptions,
                      color: Colors.purple.shade700,
                      ancho: double.infinity,
                      onTap: () => _navegar(const SuscripcionesScreen()),
                    ),
                    const SizedBox(height: 24),

                    // --- Accesos rápidos ---
                    _SectionTitle(
                      icon: Icons.flash_on,
                      titulo: 'Accesos rápidos',
                      color: cs.primary,
                    ),
                    const SizedBox(height: 12),
                    _AccesoRapido(
                      icono: Icons.add_box,
                      titulo: 'Nueva Entrega',
                      subtitulo: 'Registrar un nuevo envío',
                      color: cs.primary,
                      onTap: () => _navegar(
                        const EntregasScreen(abrirFormulario: true),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _AccesoRapido(
                      icono: Icons.person_add,
                      titulo: 'Nuevo Cliente',
                      subtitulo: 'Registrar un nuevo cliente',
                      color: Colors.teal.shade700,
                      onTap: () => _navegar(const ClientesScreen(abrirFormulario: true)),
                    ),
                    const SizedBox(height: 8),
                    _AccesoRapido(
                      icono: Icons.badge,
                      titulo: 'Empleados',
                      subtitulo: 'Gestionar empleados',
                      color: Colors.brown.shade600,
                      onTap: () => _navegar(const EmpleadosScreen()),
                    ),
                    const SizedBox(height: 24),

                    // --- Sección Reportes (Hasta abajo) ---
                    _SectionTitle(
                      icon: Icons.analytics,
                      titulo: 'Centro de Reportes',
                      color: Colors.indigo.shade700,
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _navegar(const ReportesScreen()),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.indigo.shade800,
                                const Color(0xFF1565C0),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Generación de Reportes',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'PDF y Excel (.xlsx) General o Específico',
                                      style: TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}

// ─── Widgets auxiliares del Dashboard ────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final Color color;

  const _SectionTitle({
    required this.icon,
    required this.titulo,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: color.withValues(alpha: 0.3))),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String titulo;
  final int valor;
  final IconData icono;
  final Color color;
  final VoidCallback? onTap;
  final double? ancho;

  const _StatCard({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
    this.onTap,
    this.ancho,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ancho,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icono, color: color, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$valor',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccesoRapido extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final Color color;
  final VoidCallback? onTap;

  const _AccesoRapido({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icono, color: color),
        ),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitulo),
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
      ),
    );
  }
}
