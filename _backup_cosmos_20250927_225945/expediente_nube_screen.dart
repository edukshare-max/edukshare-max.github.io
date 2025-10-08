// lib/screens/expediente_nube_screen.dart
import 'package:flutter/material.dart';
import '../data/cloudant_query.dart';

// UI institucional UAGro
import 'package:cres_carnets_ibmcloud/ui/uagro_widgets.dart';


class ExpedienteNubeScreen extends StatefulWidget {
  final String? matriculaInicial;
  const ExpedienteNubeScreen({super.key, this.matriculaInicial});

  @override
  State<ExpedienteNubeScreen> createState() => _ExpedienteNubeScreenState();
}

class _ExpedienteNubeScreenState extends State<ExpedienteNubeScreen> {
  final _mat = TextEditingController();
  final _api = CloudantQueries();

  Map<String, dynamic>? _patient;
  List<Map<String, dynamic>> _notes = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.matriculaInicial != null &&
        widget.matriculaInicial!.trim().isNotEmpty) {
      _mat.text = widget.matriculaInicial!.trim();
      _buscar();
    }
  }

  @override
  void dispose() {
    _mat.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    final m = _mat.text.trim();
    if (m.isEmpty) {
      setState(() {
        _patient = null;
        _notes = [];
        _error = 'Escribe una matrícula para buscar.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final p = await _api.fetchLatestPatient(m);
      final n = await _api.fetchNotes(m);
      if (!mounted) return;
      setState(() {
        _patient = p;
        _notes = n;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // Helper visual para pares llave:valor
  Widget _kv(String k, dynamic v) {
    final String val = (v == null || (v is String && v.trim().isEmpty)) ? '—' : '$v';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 200,
            child: Text(k, style: TextStyle(color: Colors.black.withOpacity(.6))),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(val)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: uagroAppBar('CRES Carnets', 'Expediente desde la nube'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BrandHeader(
              title: 'CRES Carnets',
              subtitle: 'Expediente de salud universitario',
            ),
            const SizedBox(height: 16),

            // ===== Búsqueda =====
            SectionCard(
              icon: Icons.search,
              title: 'Buscar por matrícula',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _mat,
                          decoration: const InputDecoration(
                            labelText: 'Matrícula',
                            // sin OutlineInputBorder para usar el tema UAGro
                          ),
                          onSubmitted: (_) => _buscar(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _loading ? null : _buscar,
                        icon: const Icon(Icons.search),
                        label: const Text('Buscar'),
                      ),
                    ],
                  ),
                  if (_loading) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: TextStyle(color: cs.error)),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ===== Paciente (NUBE) =====
            SectionCard(
              icon: Icons.cloud_outlined,
              title: 'Carnet (último) — NUBE',
              child: (_patient == null)
                  ? Text(
                      'No se encontró carnet para esta matrícula en la nube.',
                      style: TextStyle(color: cs.onSurface.withOpacity(.75)),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Resumen arriba con estado y etiqueta de sangre si existe
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: cs.primary.withOpacity(.10),
                              child: const Icon(Icons.badge_outlined),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (_patient!['nombreCompleto'] ?? '—').toString(),
                                    style: const TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Matrícula: ${_patient!['matricula'] ?? '—'} · ${_patient!['programa'] ?? '—'}',
                                    style: TextStyle(color: cs.onSurface.withOpacity(.7)),
                                  ),
                                ],
                              ),
                            ),
                            if ((_patient!['tipoSangre'] ?? '').toString().isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  color: cs.primary.withOpacity(.08),
                                  border: Border.all(color: cs.primary.withOpacity(.22)),
                                ),
                                child: Text(
                                  _patient!['tipoSangre'].toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: cs.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _kv('Correo', _patient!['correo']),
                        _kv('Edad', _patient!['edad']),
                        _kv('Sexo', _patient!['sexo']),
                        _kv('Programa', _patient!['programa']),
                        _kv('Categoría', _patient!['categoria']),
                        _kv('Alergias', _patient!['alergias']),
                        _kv('Tipo de sangre', _patient!['tipoSangre']),
                        _kv('Enfermedad', _patient!['enfermedadCronica']),
                        _kv('Discapacidad', _patient!['discapacidad']),
                        _kv('Tipo de discapacidad', _patient!['tipoDiscapacidad']),
                        _kv('Unidad médica', _patient!['unidadMedica']),
                        _kv('Núm. de afiliación', _patient!['numeroAfiliacion']),
                        _kv('Uso Seguro Universitario', _patient!['usoSeguroUniversitario']),
                        _kv('Donante', _patient!['donante']),
                        _kv('Teléfono de emergencia', _patient!['emergenciaTelefono']),
                        _kv('Contacto de emergencia', _patient!['emergenciaContacto']),
                        const SizedBox(height: 6),
                        _kv('Actualizado', _patient!['timestamp']),
                      ],
                    ),
            ),

            const SizedBox(height: 12),

            // ===== Notas (NUBE) =====
            SectionCard(
              icon: Icons.notes_outlined,
              title: 'Notas — NUBE',
              child: (_notes.isEmpty)
                  ? Text('Sin notas en la nube para esta matrícula.',
                      style: TextStyle(color: cs.onSurface.withOpacity(.75)))
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _notes.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final n = _notes[i];
                        return ListTile(
                          leading: const Icon(Icons.cloud_done),
                          title: Text(n['departamento'] ?? '-'),
                          subtitle: Text(n['cuerpo'] ?? ''),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(n['tratante'] ?? '', style: const TextStyle(fontSize: 12)),
                              Text(n['createdAt'] ?? '',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

