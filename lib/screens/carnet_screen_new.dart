// 🏥 CARNET DIGITAL MODERNO - DISEÑO TIPO TARJETA DE SALUD
// Basado en el diseño HTML compartido, adaptado a Flutter con todas las funcionalidades existentes

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carnet_digital_uagro/providers/session_provider.dart';
import 'package:carnet_digital_uagro/models/carnet_model.dart';
import 'package:carnet_digital_uagro/models/promocion_salud_model.dart';
import 'package:carnet_digital_uagro/screens/citas_screen.dart';
import 'dart:ui';

class CarnetScreenNew extends StatefulWidget {
  const CarnetScreenNew({super.key});

  @override
  State<CarnetScreenNew> createState() => _CarnetScreenNewState();
}

class _CarnetScreenNewState extends State<CarnetScreenNew> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
    
    // Cargar promociones de salud al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionProvider>().loadPromociones();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1e3c72), // Fondo azul como el HTML
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1e3c72),
              Color(0xFF2a5298),
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<SessionProvider>(
            builder: (context, session, child) {
              if (session.carnet == null) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }
              
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildHealthCardApp(context, session.carnet!),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHealthCardApp(BuildContext context, CarnetModel carnet) {
    final size = MediaQuery.of(context).size;
    
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: size.width > 600 ? 420 : size.width - 40,
          maxHeight: size.height - 40,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHealthCardHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
                  child: Column(
                    children: [
                      _buildPatientPhoto(),
                      const SizedBox(height: 20),
                      _buildPatientInfo(carnet),
                      const SizedBox(height: 25),
                      _buildHealthDetails(carnet),
                      const SizedBox(height: 20),
                      _buildMedicalAlerts(carnet),
                      const SizedBox(height: 20),
                      _buildEmergencyContact(carnet),
                      const SizedBox(height: 20),
                      _buildValidityInfo(),
                      const SizedBox(height: 20),
                      _buildQRSection(carnet),
                      const SizedBox(height: 25),
                      _buildActionButtons(carnet),
                    ],
                  ),
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthCardHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8B1538), // Rojo UAGro
            Color(0xFFC41E3A), // Rojo medio
            Color(0xFF8B1538), // Rojo UAGro
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Stack(
        children: [
          // Patrón de fondo sutil
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          // Contenido del header
          Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                // Logo universitario
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'UAGro',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B1538),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 15),
                
                // Nombre de la universidad
                const Text(
                  'Universidad Autónoma de Guerrero',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                // Título del carnet
                const Text(
                  'CARNET DE SALUD',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 5),
                
                // Icono de salud
                const Text(
                  '🏥',
                  style: TextStyle(fontSize: 24),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientPhoto() {
    return Container(
      width: 110,
      height: 130,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFf8f9fa),
            Color(0xFFe9ecef),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8B1538),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '👤',
          style: TextStyle(
            fontSize: 42,
            color: Color(0xFF666666),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientInfo(CarnetModel carnet) {
    return Column(
      children: [
        // Nombre del estudiante
        Text(
          carnet.nombreCompleto.toUpperCase(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        // ID del estudiante
        Text(
          'ID Salud: SAL-${carnet.matricula}',
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF8B1538),
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Estado de salud
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF28a745),
                Color(0xFF20c997),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF28a745).withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: const Text(
            '✓ APTO PARA ACTIVIDADES',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthDetails(CarnetModel carnet) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFf8f9fa),
            Color(0xFFffffff),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFe9ecef),
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Información Personal
          _buildDetailSection(
            '👤 Información Personal',
            [
              _buildDetailRow('Edad:', '${carnet.edad} años'),
              _buildDetailRow('Tipo de Sangre:', carnet.tipoSangre),
              _buildDetailRow('Sexo:', carnet.sexo),
              _buildDetailRow('Programa:', carnet.programa),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Información Médica
          _buildDetailSection(
            '🏥 Información Médica',
            [
              _buildDetailRow('Unidad Médica:', carnet.unidadMedica),
              _buildDetailRow('No. Afiliación:', carnet.numeroAfiliacion),
              _buildDetailRow('Donante:', carnet.donante),
              _buildDetailRow('Categoría:', carnet.categoria),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8B1538),
          ),
        ),
        const SizedBox(height: 10),
        ...rows,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF333333),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalAlerts(CarnetModel carnet) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFf8d7da),
            Color(0xFFf5c6cb),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        border: const Border(
          left: BorderSide(
            color: Color(0xFFdc3545),
            width: 4,
          ),
        ),
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('⚠️', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Text(
                'Alertas Médicas',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF721c24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            carnet.alergias.isNotEmpty 
              ? '• ${carnet.alergias}\n• ${carnet.enfermedadCronica}' 
              : '• Sin alertas médicas registradas',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF721c24),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContact(CarnetModel carnet) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFfff3cd),
            Color(0xFFffeaa7),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        border: const Border(
          left: BorderSide(
            color: Color(0xFFffc107),
            width: 4,
          ),
        ),
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📞', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Text(
                'Contacto de Emergencia',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF856404),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${carnet.emergenciaContacto}\nTel: ${carnet.emergenciaTelefono}',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF856404),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidityInfo() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFe3f2fd),
            Color(0xFFbbdefb),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        border: const Border(
          left: BorderSide(
            color: Color(0xFF2196f3),
            width: 4,
          ),
        ),
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📅 Vigencia del Carnet',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1976d2),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Válido hasta: Diciembre ${DateTime.now().year}',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF1976d2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRSection(CarnetModel carnet) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF333333),
                Color(0xFF555555),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'QR\nSALUD\n📱',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Código de verificación médica',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF666666),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(CarnetModel carnet) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            label: '📱 Ver QR',
            isPrimary: true,
            onTap: () => _showQRModal(carnet),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            label: '📤 Compartir',
            isPrimary: false,
            onTap: () => _shareCarnet(carnet),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF8B1538),
                    Color(0xFFC41E3A),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFf8f9fa),
                    Color(0xFFe9ecef),
                  ],
                ),
          borderRadius: BorderRadius.circular(10),
          border: isPrimary
              ? null
              : Border.all(
                  color: const Color(0xFFdee2e6),
                  width: 2,
                ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: const Color(0xFF8B1538).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isPrimary ? Colors.white : const Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFf8f9fa),
            Color(0xFFffffff),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: const Border(
          top: BorderSide(
            color: Color(0xFFe9ecef),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            '🏥 Centro de Salud UAGro',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B1538),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Carnet Digital Oficial',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
            ),
          ),
          Text(
            'Generado: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  void _showQRModal(CarnetModel carnet) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🏥 Código QR Médico',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B1538),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF333333),
                      Color(0xFF555555),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'QR SALUD\n📱\nSCAN ME\n🏥',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Presenta este código al personal médico para acceder a tu información de salud completa',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1538),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Cerrar',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareCarnet(CarnetModel carnet) {
    Clipboard.setData(ClipboardData(
      text: 'Carnet de Salud Digital UAGro - ${carnet.nombreCompleto}\nID: SAL-${carnet.matricula}',
    ));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('¡Información del carnet copiada al portapapeles!'),
        backgroundColor: const Color(0xFF28a745),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}