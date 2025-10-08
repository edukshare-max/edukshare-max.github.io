﻿import 'package:flutter/material.dart';
import '../data/api_service.dart';
import 'cita_form_screen.dart';
// Imports para diseño institucional UAGro
import '../ui/brand.dart';
import '../ui/app_theme.dart';
import '../ui/widgets/brand_sidebar.dart';
import '../ui/widgets/section_card.dart';

class ExpedienteNubeScreen extends StatefulWidget {
  final String? idInicial;
  final String? matriculaInicial;
  const ExpedienteNubeScreen({Key? key, this.idInicial, this.matriculaInicial}) : super(key: key);

  @override
  State<ExpedienteNubeScreen> createState() => _ExpedienteNubeScreenState();
}

class _ExpedienteNubeScreenState extends State<ExpedienteNubeScreen> {
  final _idCtrl = TextEditingController();
  final _matCtrl = TextEditingController();

  Map<String, dynamic>? _carnet;
  List<Map<String, dynamic>> _notas = [];
  List<Map<String, dynamic>> _citas = [];

  bool _loadingCarnet = false;
  bool _loadingNotas = false;
  bool _loadingCitas = false;
  String? _errCarnet;
  String? _errNotas;
  String? _errCitas;

  // Estado aislado para citas del cloud
  List<Map<String, dynamic>> _citasCloud = [];
  bool _cargandoCitas = false;
  String? _errorCitas;

  @override
  void initState() {
    super.initState();
    if (widget.idInicial != null) _idCtrl.text = widget.idInicial!;
    if (widget.matriculaInicial != null) _matCtrl.text = widget.matriculaInicial!;
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _matCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscarCarnet() async {
    final id = _idCtrl.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe el ID (QR) para buscar el carnet.')),
      );
      return;
    }
    setState(() { _loadingCarnet = true; _errCarnet = null; _carnet = null; });
    try {
      final doc = await ApiService.getExpedienteById(id);
      if (doc == null) {
        setState(() => _errCarnet = 'No se encontró carnet con ese ID.');
      } else {
        setState(() => _carnet = doc);
      }
    } catch (e) {
      setState(() => _errCarnet = 'Error: $e');
    } finally {
      setState(() => _loadingCarnet = false);
    }
  }

  Future<void> _buscarNotas() async {
    final m = _matCtrl.text.trim();
    if (m.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe la matrícula para buscar notas.')),
      );
      return;
    }
    setState(() { _loadingNotas = true; _errNotas = null; _notas = []; });
    try {
      final res = await ApiService.getNotasForMatricula(m);
      if (res.isEmpty) {
        setState(() => _errNotas = 'No hay notas para la matrícula $m.');
      } else {
        setState(() => _notas = res);
      }
    } catch (e) {
      setState(() => _errNotas = 'Error: $e');
    } finally {
      setState(() => _loadingNotas = false);
    }
  }

  Future<void> _buscarCitas() async {
    final m = _matCtrl.text.trim();
    if (m.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe la matrícula para buscar citas.')),
      );
      return;
    }
    setState(() { _loadingCitas = true; _errCitas = null; _citas = []; });
    try {
      final res = await ApiService.getCitasByMatricula(m);
      if (res.isEmpty) {
        setState(() => _errCitas = 'No hay citas para la matrícula $m.');
      } else {
        setState(() => _citas = res);
      }
    } catch (e) {
      setState(() => _errCitas = 'Error: $e');
    } finally {
      setState(() => _loadingCitas = false);
    }
  }

  /// Navegar a formulario de crear cita y refrescar al volver
  Future<void> _agendarCita() async {
    final m = _matCtrl.text.trim();
    if (m.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe la matrícula para agendar una cita.')),
      );
      return;
    }

    // Navegar al formulario de citas
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CitaFormScreen(matricula: m),
      ),
    );

    // Si se creó una cita, refrescar la lista automáticamente
    if (result == true && mounted) {
      try {
        setState(() { _loadingCitas = true; _errCitas = null; });
        final newCitas = await ApiService.getCitasByMatricula(m);
        setState(() {
          _citas = newCitas;
          _loadingCitas = false;
        });
        // También refrescar citas del cloud
        final matricula = _currentMatricula();
        if (matricula.isNotEmpty) {
          await _mostrarCitasImpl(matricula);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cita creada y lista actualizada'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        setState(() {
          _errCitas = 'Error al refrescar: $e';
          _loadingCitas = false;
        });
      }
    }
  }

  /// Obtener matrícula desde controlador o carnet cargado
  String _currentMatricula() {
    // 1. Controlador del campo de búsqueda por matrícula
    final matField = _matCtrl.text.trim();
    if (matField.isNotEmpty) return matField;
    
    // 2. Matrícula del carnet cargado (si hay)
    if (_carnet != null) {
      final carnetMat = (_carnet!['matricula'] ?? '').toString().trim();
      if (carnetMat.isNotEmpty) return carnetMat;
    }
    
    return '';
  }

  /// Mostrar citas del cloud para la matrícula actual
  Future<void> _mostrarCitas() async {
    final m = _currentMatricula();
    if (m.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa matrícula para buscar citas')),
      );
      return;
    }

    await _mostrarCitasImpl(m);
  }

  /// Implementación de mostrar citas con matrícula específica
  Future<void> _mostrarCitasImpl(String m) async {
    setState(() { 
      _cargandoCitas = true; 
      _errorCitas = null; 
    });
    
    try {
      final list = await ApiService.getCitasByMatricula(m);
      print('[CITAS_FETCH] m=$m len=${list.length}');
      
      setState(() {
        _citasCloud = list;
        _cargandoCitas = false;
      });
    } catch (e) {
      setState(() {
        _errorCitas = 'Error: $e';
        _cargandoCitas = false;
      });
    }
  }

  Widget _buildCarnet() {
    if (_loadingCarnet) {
      return SectionCard(
        icon: Icons.card_membership,
        title: 'Carnet Universitario',
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_errCarnet != null) {
      return SectionCard(
        icon: Icons.card_membership,
        title: 'Carnet Universitario',
        child: Text(
          _errCarnet!, 
          style: TextStyle(color: UAGroColors.error),
        ),
      );
    }
    if (_carnet == null) return const SizedBox.shrink();

    final id = (_carnet!['_id'] ?? _carnet!['id'] ?? '').toString();
    final matricula = (_carnet!['matricula'] ?? '').toString();
    final nombre = (_carnet!['nombre'] ?? _carnet!['nombreCompleto'] ?? '').toString();

    return SectionCard(
      icon: Icons.card_membership,
      title: 'Carnet Universitario',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          _infoRow('ID', id),
          const SizedBox(height: 8),
          _infoRow('Matrícula', matricula),
          const SizedBox(height: 8),
          _infoRow('Nombre', nombre),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(value.isEmpty ? '-' : value),
        ),
      ],
    );
  }

  Widget _buildNotas() {
    if (_loadingNotas) {
      return SectionCard(
        icon: Icons.notes,
        title: 'Notas Médicas',
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_errNotas != null) {
      return SectionCard(
        icon: Icons.notes,
        title: 'Notas Médicas',
        child: Text(
          _errNotas!, 
          style: TextStyle(color: UAGroColors.error),
        ),
      );
    }
    if (_notas.isEmpty) return const SizedBox.shrink();

    return SectionCard(
      icon: Icons.notes,
      title: 'Notas Médicas (${_notas.length})',
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _notas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final n = _notas[index];
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n['cuerpo'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                _infoRow('Departamento', n['departamento'] ?? ''),
                const SizedBox(height: 4),
                _infoRow('Tratante', n['tratante'] ?? ''),
                const SizedBox(height: 4),
                _infoRow('Fecha', n['createdAt'] ?? ''),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCitas() {
    if (_loadingCitas) {
      return SectionCard(
        icon: Icons.event,
        title: 'Citas Programadas',
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_errCitas != null) {
      return SectionCard(
        icon: Icons.event,
        title: 'Citas Programadas',
        child: Text(
          _errCitas!, 
          style: TextStyle(color: UAGroColors.error),
        ),
      );
    }
    if (_citas.isEmpty) return const SizedBox.shrink();

    return SectionCard(
      icon: Icons.event,
      title: 'Citas Programadas (${_citas.length})',
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _citas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final c = _citas[index];
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c['motivo'] ?? 'Sin motivo especificado',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _infoRow('Departamento', c['departamento'] ?? 'N/A'),
                const SizedBox(height: 4),
                _infoRow('Inicio', c['inicio'] ?? ''),
                const SizedBox(height: 4),
                _infoRow('Fin', c['fin'] ?? ''),
                const SizedBox(height: 4),
                _infoRow('Estado', c['estado'] ?? 'programada'),
                if (c['googleEventId'] != null && c['googleEventId'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.sync, size: 16, color: UAGroColors.success),
                      const SizedBox(width: 4),
                      Text(
                        'Sincronizada con Google Calendar',
                        style: TextStyle(
                          fontSize: 12, 
                          color: UAGroColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expediente en la Nube'),
        actions: [
          IconButton(
            tooltip: 'Citas',
            icon: const Icon(Icons.event_rounded),
            onPressed: () async {
              // Obtener matrícula del carnet encontrado o del campo
              String? m;
              if (_carnet != null) {
                m = (_carnet!['matricula'] ?? '').toString().trim();
              }
              if (m == null || m.isEmpty) {
                m = _matCtrl.text.trim();
              }
              if (m.isEmpty) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Busca un carnet primero')),
                );
                return;
              }
              try {
                final citas = await ApiService.getCitasForMatricula(m);
                if (!context.mounted) return;
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) {
                    return SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.event_rounded),
                                    const SizedBox(width: 8),
                                    Text('Citas • $m',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                                  ],
                                ),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    Navigator.pop(_); // Cerrar modal actual
                                    // Navegar a formulario de cita
                                    final result = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CitaFormScreen(matricula: m!),
                                      ),
                                    );
                                    // Si se creó una cita, refrescar la lista
                                    if (result == true) {
                                      // Refrescar citas automáticamente
                                      try {
                                        final newCitas = await ApiService.getCitasForMatricula(m!);
                                        setState(() {
                                          _citas = newCitas;
                                        });
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Cita creada y lista actualizada'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        print('Error al refrescar citas: $e');
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Nueva'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (citas.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text('Sin citas', style: Theme.of(context).textTheme.bodyMedium),
                              )
                            else
                              Flexible(
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: citas.length,
                                  itemBuilder: (ctx, i) {
                                    final c = citas[i];
                                    final motivo = (c['motivo'] ?? '').toString();
                                    final inicio = (c['inicio'] ?? '').toString();
                                    final fin    = (c['fin'] ?? '').toString();
                                    final estado = (c['estado'] ?? '').toString();
                                    return Card(
                                      child: ListTile(
                                        leading: const Icon(Icons.event_available_rounded),
                                        title: Text(motivo.isEmpty ? 'Cita' : motivo,
                                            maxLines: 1, overflow: TextOverflow.ellipsis),
                                        subtitle: Text(
                                          '$inicio → $fin${estado.isEmpty ? '' : '  •  $estado'}',
                                          maxLines: 2, overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No se pudieron cargar las citas')),
                );
              }
            },
          ),
          IconButton(
            tooltip: 'Mostrar citas del cloud',
            icon: const Icon(Icons.list),
            onPressed: _mostrarCitas,
          ),
        ],
      ),
      body: Row(
        children: [
          // Barra lateral institucional UAGro
          const BrandSidebar(),
          // Contenido principal (sin cambios de lógica)
          Expanded(
            child: SingleChildScrollView(
              padding: AppTheme.contentPadding,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NO CAMBIAR LÓGICA: mantener callbacks/estados intactos
                    SectionCard(
                      icon: Icons.qr_code_scanner,
                      title: 'Buscar por ID (QR)',
                      child: Column(
                        children: [
                          TextField(
                            controller: _idCtrl,
                            decoration: const InputDecoration(
                              labelText: 'ID (QR)', 
                              border: OutlineInputBorder()
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _buscarCarnet,
                              child: const Text('Buscar Carnet por ID'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing),
                    _buildCarnet(),
                    const SizedBox(height: AppTheme.spacing),
                    SectionCard(
                      icon: Icons.search,
                      title: 'Buscar por Matrícula',
                      child: Column(
                        children: [
                          TextField(
                            controller: _matCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Matrícula', 
                              border: OutlineInputBorder()
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _buscarNotas,
                                  child: const Text('Buscar Notas'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _buscarCitas,
                                  child: const Text('Buscar Citas'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Botones para citas con diseño responsivo
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _agendarCita,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Nueva Cita'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: UAGroColors.gold,
                                    foregroundColor: UAGroColors.blue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _mostrarCitas,
                                  icon: const Icon(Icons.list),
                                  label: const Text('Mostrar citas'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: UAGroColors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing),
                    _buildNotas(),
                    const SizedBox(height: AppTheme.spacing),
                    _buildCitas(),
                    const SizedBox(height: AppTheme.spacing),
                    _buildCitasCloud(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget para mostrar las citas del cloud
  Widget _buildCitasCloud() {
    if (_cargandoCitas) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.event, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  const Text(
                    'Citas del Cloud',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const CircularProgressIndicator(),
              const SizedBox(height: 8),
              const Text('Cargando citas del cloud...'),
            ],
          ),
        ),
      );
    }

    if (_errorCitas != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.event, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  const Text(
                    'Citas del Cloud',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'No fue posible cargar las citas.',
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_citasCloud.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.event, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  const Text(
                    'Citas del Cloud (0)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'No hay citas para esta matrícula.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Debug temporal para confirmar claves
    if (_citasCloud.isNotEmpty) {
      print('[CITAS_KEYS] ${_citasCloud.first.keys.toList()}');
    }

    // Ordenar por inicio descendente
    final list = [..._citasCloud];
    list.sort((a, b) {
      final da = _parseIso(_str(a, 'inicio'));
      final db = _parseIso(_str(b, 'inicio'));
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  'Citas del Cloud (${list.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = list[index];
                final motivo = _str(item, 'motivo');
                final dtIni = _parseIso(_str(item, 'inicio'));
                final (fecha, hora) = _fmtFechaHora(dtIni);
                final dep = _str(item, 'departamento');
                final est = _str(item, 'estado');

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Icono izquierdo
                      Icon(
                        Icons.event,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 12),
                      // Contenido principal
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              motivo.isEmpty ? 'Sin asunto' : motivo,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Fecha: $fecha',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              'Hora: $hora',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            if (dep.isNotEmpty)
                              Text(
                                'Departamento: $dep',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Chip de estado a la derecha
                      if (est.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _estadoColor(est),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            est,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _estadoTextColor(est),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helpers locales para citas
  String _str(Map m, String k) {
    final v = m[k];
    return (v == null) ? '' : v.toString().trim();
  }

  DateTime? _parseIso(String s) {
    if (s.isEmpty) return null;
    try {
      return DateTime.parse(s).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _two(int n) => n < 10 ? '0$n' : '$n';

  (String, String) _fmtFechaHora(DateTime? dt) {
    if (dt == null) return ('No especificada', 'No especificada');
    final f = '${dt.year}-${_two(dt.month)}-${_two(dt.day)}';
    final h = '${_two(dt.hour)}:${_two(dt.minute)}';
    return (f, h);
  }

  Color _estadoColor(String estado) {
    final est = estado.toLowerCase();
    if (est.contains('programada')) return Colors.blue.shade100;
    if (est.contains('cancelada')) return Colors.red.shade100;
    if (est.contains('realizada') || est.contains('completada')) return Colors.green.shade100;
    return Colors.grey.shade100;
  }

  Color _estadoTextColor(String estado) {
    final est = estado.toLowerCase();
    if (est.contains('programada')) return Colors.blue.shade700;
    if (est.contains('cancelada')) return Colors.red.shade700;
    if (est.contains('realizada') || est.contains('completada')) return Colors.green.shade700;
    return Colors.grey.shade700;
  }
}