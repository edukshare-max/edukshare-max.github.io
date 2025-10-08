// 🏥 CITAS SCREEN - CITAS MÉDICAS
// Vista de citas médicas del estudiante

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../models/cita_model.dart';
import '../theme/uagro_theme.dart';

class CitasScreen extends StatefulWidget {
  const CitasScreen({super.key});

  @override
  State<CitasScreen> createState() => _CitasScreenState();
}

class _CitasScreenState extends State<CitasScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar citas al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionProvider>().loadCitas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Citas Médicas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<SessionProvider>().loadCitas();
            },
          ),
        ],
      ),
      body: Consumer<SessionProvider>(
        builder: (context, session, child) {
          if (session.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (session.citas.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No tienes citas programadas',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<SessionProvider>().loadCitas(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: session.citas.length,
              itemBuilder: (context, index) {
                final cita = session.citas[index];
                return _buildCitaCard(cita);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCitaCard(CitaModel cita) {
    Color statusColor;
    IconData statusIcon;
    
    switch (cita.estado.toLowerCase()) {
      case 'confirmada':
        statusColor = UAGroColors.success;
        statusIcon = Icons.check_circle;
        break;
      case 'pendiente':
        statusColor = UAGroColors.warning;
        statusIcon = Icons.schedule;
        break;
      case 'cancelada':
        statusColor = UAGroColors.error;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con estado
            Row(
              children: [
                Icon(
                  statusIcon,
                  color: statusColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  cita.estado.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: UAGroColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    cita.tipo,
                    style: const TextStyle(
                      fontSize: 12,
                      color: UAGroColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Fecha y hora
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatFecha(cita.fecha),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  cita.hora,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Doctor
            if (cita.doctor.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dr. ${cita.doctor}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            
            // Motivo
            if (cita.motivo.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.description,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cita.motivo,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            // Notas
            if (cita.notas != null && cita.notas!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notas:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cita.notas!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
            
            // Botones de acción (solo para citas pendientes)
            if (cita.estado.toLowerCase() == 'pendiente') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelarCita(cita),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancelar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: UAGroColors.error,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmarCita(cita),
                      icon: const Icon(Icons.check),
                      label: const Text('Confirmar'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    
    return '${fecha.day} de ${months[fecha.month - 1]} ${fecha.year}';
  }

  void _cancelarCita(CitaModel cita) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Cita'),
        content: const Text('¿Estás seguro de que quieres cancelar esta cita?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implementar cancelación en el backend
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Funcionalidad próximamente disponible'),
                ),
              );
            },
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );
  }

  void _confirmarCita(CitaModel cita) {
    // TODO: Implementar confirmación en el backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad próximamente disponible'),
      ),
    );
  }
}