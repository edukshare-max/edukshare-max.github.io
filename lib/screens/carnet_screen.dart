// 📱 CARNET SCREEN - VISTA PRINCIPAL
// Muestra el carnet digital completo del estudiante

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/session_provider.dart';
import '../models/carnet_model.dart';
import '../theme/uagro_theme.dart';
import 'citas_screen.dart';

class CarnetScreen extends StatelessWidget {
  const CarnetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carnet Digital UAGro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.medical_services),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CitasScreen(),
                ),
              );
            },
            tooltip: 'Mis Citas',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<SessionProvider>().logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: Consumer<SessionProvider>(
        builder: (context, session, child) {
          if (session.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (session.carnet == null) {
            return const Center(
              child: Text('No se pudo cargar el carnet'),
            );
          }
          
          return _buildCarnetContent(context, session.carnet!);
        },
      ),
    );
  }
  
  Widget _buildCarnetContent(BuildContext context, CarnetModel carnet) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Logo UAGro
          Container(
            height: 60,
            child: const Text(
              'UNIVERSIDAD AUTÓNOMA DE GUERRERO',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: UAGroColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Carnet principal
          Card(
            elevation: 8,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [UAGroColors.primary, Color(0xFF0369A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  // Foto placeholder
                  Container(
                    width: 120,
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[300],
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 80,
                      color: Colors.grey,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Datos del estudiante
                  Text(
                    carnet.nombreCompleto,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Matrícula: ${carnet.matricula}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    carnet.correo,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    '${carnet.edad} años • ${carnet.sexo}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Información adicional
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Información Académica',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Programa:', carnet.programa),
                  _buildInfoRow('Categoría:', carnet.categoria),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Información Médica
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Información Médica',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Tipo de Sangre:', carnet.tipoSangre),
                  _buildInfoRow('Unidad Médica:', carnet.unidadMedica),
                  if (carnet.numeroAfiliacion.isNotEmpty)
                    _buildInfoRow('No. Afiliación:', carnet.numeroAfiliacion),
                  _buildInfoRow('Seguro Universitario:', carnet.usoSeguroUniversitario),
                  _buildInfoRow('Donante:', carnet.donante),
                  
                  const SizedBox(height: 12),
                  
                  // Enfermedades Crónicas
                  _buildMedicalSection(
                    'Enfermedades Crónicas:',
                    carnet.enfermedadCronica,
                    carnet.tieneEnfermedadCronica,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Alergias
                  _buildMedicalSection(
                    'Alergias:',
                    carnet.alergias,
                    carnet.tieneAlergias,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Discapacidad
                  if (carnet.tieneDiscapacidad) ...[
                    _buildInfoRow('Discapacidad:', carnet.discapacidad),
                    if (carnet.tipoDiscapacidad.isNotEmpty)
                      _buildInfoRow('Tipo:', carnet.tipoDiscapacidad),
                  ] else ...[
                    _buildInfoRow('Discapacidad:', 'No'),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Información de Contacto de Emergencia
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contacto de Emergencia',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Contacto:', carnet.emergenciaContacto),
                  _buildInfoRow('Teléfono:', carnet.emergenciaTelefono),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Notas del Expediente (si existen)
          if (carnet.expedienteNotas.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notas del Expediente',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Text(
                        carnet.expedienteNotas,
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // QR Code
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Código QR de Identificación',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  QrImageView(
                    data: carnet.matricula,
                    version: QrVersions.auto,
                    size: 200.0,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalSection(String label, String value, bool hasCondition) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: hasCondition ? Colors.red[50] : Colors.green[50],
        border: Border.all(
          color: hasCondition ? Colors.red[200]! : Colors.green[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasCondition ? Icons.warning : Icons.check_circle,
            color: hasCondition ? Colors.red[600] : Colors.green[600],
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: hasCondition ? Colors.red[800] : Colors.green[800],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: hasCondition ? Colors.red[800] : Colors.green[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}