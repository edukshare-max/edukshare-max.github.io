// 📱 CARNET SCREEN - VISTA PRINCIPAL (DISEÑO UAGRO WALLET)
// Muestra el carnet digital completo con diseño profesional moderno

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carnet_digital_uagro/providers/session_provider.dart';
import 'package:carnet_digital_uagro/models/carnet_model.dart';
import 'package:carnet_digital_uagro/models/promocion_salud_model.dart';
import 'package:carnet_digital_uagro/theme/uagro_theme.dart';
import 'package:carnet_digital_uagro/screens/citas_screen.dart';
import 'dart:ui';

class CarnetScreen extends StatefulWidget {
  const CarnetScreen({super.key});

  @override
  State<CarnetScreen> createState() => _CarnetScreenState();
}

class _CarnetScreenState extends State<CarnetScreen> {
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    // Cargar promociones de salud al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionProvider>().loadPromociones();
    });
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco limpio
      appBar: AppBar(
        title: const Text('Carnet Digital UAGro', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: UAGroColors.primary,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        actions: [
          IconButton(
            icon: const Icon(Icons.medical_services_outlined),
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
            icon: const Icon(Icons.logout_outlined),
            onPressed: () {
              context.read<SessionProvider>().logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: Consumer<SessionProvider>(
        builder: (context, session, child) {
          if (session.isLoading && session.carnet == null) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (session.carnet == null) {
            return const Center(
              child: Text('No se pudo cargar la información del carnet.'),
            );
          }
          
          return _buildCarnetContent(context, session.carnet!);
        },
      ),
    );
  }
  
  Widget _buildCarnetContent(BuildContext context, CarnetModel carnet) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Logo UAGro con diseño moderno
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              'UNIVERSIDAD AUTÓNOMA DE GUERRERO',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: UAGroColors.primary,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // --- NUEVO CONTENEDOR COLAPSABLE ---
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Card principal que ahora funciona como cabecera del desplegable
                InkWell(
                  onTap: _toggleExpanded,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: _buildWalletCard(carnet, isHeader: true),
                ),
                // Contenido desplegable
                AnimatedCrossFade(
                  firstChild: _buildCollapsibleContent(carnet),
                  secondChild: Container(),
                  crossFadeState: _isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                  duration: const Duration(milliseconds: 300),
                ),
              ],
            ),
          ),
          // --- FIN DE CONTENEDOR COLAPSABLE ---

          const SizedBox(height: 20),
          
          // QR Code Card (Ahora fuera del desplegable para acceso rápido)
          _buildQrCard(carnet),
          const SizedBox(height: 20),
          
          // 🏥 ÁREA DE PROMOCIONES DE SALUD
          _buildPromocionesArea(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCollapsibleContent(CarnetModel carnet) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          const Divider(height: 1, thickness: 1, indent: 20, endIndent: 20),
          const SizedBox(height: 20),
          // Información Académica
          _buildSectionCard(
            title: 'INFORMACIÓN ACADÉMICA',
            icon: Icons.school_rounded,
            children: [
              _buildDetailRow(Icons.menu_book_rounded, 'Programa', carnet.programa),
              _buildDetailRow(Icons.style_rounded, 'Categoría', carnet.categoria),
            ],
          ),
          const SizedBox(height: 20),
          
          // Información Médica
          _buildSectionCard(
            title: 'INFORMACIÓN MÉDICA',
            icon: Icons.medical_services_rounded,
            children: [
              _buildDetailRow(Icons.bloodtype_rounded, 'Tipo de Sangre', carnet.tipoSangre),
              _buildDetailRow(Icons.local_hospital_rounded, 'Unidad Médica', carnet.unidadMedica),
              if (carnet.numeroAfiliacion.isNotEmpty)
                _buildDetailRow(Icons.badge_rounded, 'No. Afiliación', carnet.numeroAfiliacion),
              _buildDetailRow(Icons.health_and_safety_rounded, 'Seguro Universitario', carnet.usoSeguroUniversitario),
              _buildDetailRow(Icons.volunteer_activism_rounded, 'Donante', carnet.donante),
              
              const SizedBox(height: 12),
              
              // Enfermedades Crónicas
              _buildHealthStatusRow(
                'Enfermedades Crónicas',
                carnet.enfermedadCronica.isNotEmpty ? carnet.enfermedadCronica : 'Ninguna',
                carnet.tieneEnfermedadCronica,
              ),
              
              const SizedBox(height: 8),
              
              // Alergias
              _buildHealthStatusRow(
                'Alergias',
                carnet.alergias.isNotEmpty ? carnet.alergias : 'Ninguna',
                carnet.tieneAlergias,
              ),
              
              const SizedBox(height: 8),
              
              // Discapacidad
              if (carnet.tieneDiscapacidad) ...[
                _buildHealthStatusRow(
                  'Discapacidad',
                  '${carnet.discapacidad}${carnet.tipoDiscapacidad.isNotEmpty ? " - ${carnet.tipoDiscapacidad}" : ""}',
                  true,
                ),
              ] else ...[
                _buildHealthStatusRow('Discapacidad', 'No', false),
              ],
            ],
          ),
          const SizedBox(height: 20),
          
          // Contacto de Emergencia
          _buildSectionCard(
            title: 'CONTACTO DE EMERGENCIA',
            icon: Icons.emergency_rounded,
            children: [
              _buildDetailRow(Icons.person_rounded, 'Contacto', carnet.emergenciaContacto),
              _buildDetailRow(Icons.phone_rounded, 'Teléfono', carnet.emergenciaTelefono),
            ],
          ),
          
          // Notas del Expediente (si existen)
          if (carnet.expedienteNotas.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSectionCard(
              title: 'NOTAS DEL EXPEDIENTE',
              icon: Icons.note_rounded,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    carnet.expedienteNotas,
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  // NUEVOS MÉTODOS HELPER PARA DISEÑO WALLET
  
  Widget _buildWalletCard(CarnetModel carnet, {bool isHeader = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [UAGroColors.primary, Color(0xFF0369A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: UAGroColors.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'CARNET DIGITAL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    // Icono para indicar si es desplegable
                    if (isHeader)
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'ACTIVO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Datos Principales (sin foto)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center, // Centrado verticalmente
                  children: [
                    // Información Principal
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            carnet.nombreCompleto.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20, // Ligeramente más grande
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              carnet.matricula,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.email_rounded, color: Colors.white.withOpacity(0.8), size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  carnet.correo,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.cake_rounded, color: Colors.white.withOpacity(0.8), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '${carnet.edad} años • ${carnet.sexo}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: UAGroColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: UAGroColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937), // Gris oscuro
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, indent: 20, endIndent: 20),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.grey[600], size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthStatusRow(String title, String detail, bool hasCondition) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: hasCondition ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasCondition ? Colors.red[100]! : Colors.green[100]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasCondition ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
            color: hasCondition ? Colors.red[700] : Colors.green[700],
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: detail,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard(CarnetModel carnet) {
    // El QR ahora solo contiene la matrícula, el identificador único del alumno.
    final qrDataString = carnet.matricula;

    return _buildSectionCard(
      title: 'CÓDIGO QR DE IDENTIFICACIÓN',
      icon: Icons.qr_code_2_rounded,
      children: [
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!, width: 2),
                ),
                child: QrImageView(
                  data: qrDataString,
                  version: QrVersions.auto,
                  size: 180.0,
                  gapless: false,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: UAGroColors.primary,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: UAGroColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Usa este código para identificarte en eventos, servicios y obtener beneficios. Es tu llave de acceso única.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // � ÁREA DE PROMOCIONES ESTILO NETFLIX
  Widget _buildPromocionesArea() {
    return Consumer<SessionProvider>(
      builder: (context, session, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título de la sección
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1976D2).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.health_and_safety_rounded, 
                      color: Colors.white, 
                      size: 24
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PROMOCIONES DE SALUD',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1F2937),
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Campañas especiales para tu bienestar',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            if (session.promociones.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue[100]!, width: 2),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.health_and_safety_outlined,
                        size: 56,
                        color: Colors.blue[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No hay promociones disponibles',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pronto tendremos nuevas promociones de salud para ti',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // 🎬 CARRUSEL DE PROMOCIONES COMPACTO
              SizedBox(
                height: 320, // Reducido de 450 a 320
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: session.promociones.length,
                  itemBuilder: (context, index) {
                    final promocion = session.promociones[index];
                    return Container(
                      width: 320,
                      margin: const EdgeInsets.only(right: 16),
                      child: _buildNetflixCard(promocion),
                    );
                  },
                ),
              ),
              
              if (session.promociones.length > 1) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.swipe_left_rounded, 
                           size: 18, 
                           color: Colors.grey[500]),
                      const SizedBox(width: 8),
                      Text(
                        'Desliza para ver más promociones',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        );
      },
    );
  }

  // 🎯 TARJETA COLORIDA Y ATRACTIVA - CORREGIDA
  Widget _buildNetflixCard(PromocionSaludModel promocion) {
    // Verificar que promocion no sea null
    if (promocion == null) return Container();
    
    final cardData = _getCardDesign(promocion.categoria ?? 'promoción');
    final fechaCreacion = _parsearFecha(promocion.createdAt.toIso8601String());
    final fechaExpiracion = _calcularExpiracion(promocion.createdAt.toIso8601String());
    final diasRestantes = _calcularDiasRestantes(promocion.createdAt.toIso8601String());
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cardData['primaryColor'].withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _abrirEnlaceDirecto(promocion),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  cardData['primaryColor'].withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: cardData['primaryColor'].withOpacity(0.15),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER COMPACTO
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                    gradient: cardData['gradient'],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge + Urgencia
                        Row(
                          children: [
                            // Badge principal
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    cardData['icon'],
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    (promocion.categoria ?? 'Promoción').toUpperCase(),
                                    style: TextStyle(
                                      color: cardData['primaryColor'],
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const Spacer(),
                            
                            // Badge de urgencia
                            if (diasRestantes <= 3) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.3),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 12,
                                      color: Colors.red[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '¡${diasRestantes}d!',
                                      style: TextStyle(
                                        color: Colors.red[700],
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        
                        const Spacer(),
                        
                        // Título compacto
                        Text(
                          promocion.programa ?? promocion.departamento ?? 'Promoción de Salud',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                            letterSpacing: 0.3,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // CONTENIDO COMPACTO
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // DEPARTAMENTO DESTACADO
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                cardData['primaryColor'],
                                cardData['primaryColor'].withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: cardData['primaryColor'].withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  cardData['icon'],
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  promocion.departamento ?? 'Departamento de Salud',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // DESCRIPCIÓN (si existe)
                        if (promocion.descripcion != null && promocion.descripcion.isNotEmpty) ...[
                          Expanded(
                            child: Text(
                              promocion.descripcion,
                              style: const TextStyle(
                                color: Color(0xFF2C3E50),
                                fontSize: 12,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        
                        // FECHAS COMPACTAS
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                cardData['primaryColor'].withOpacity(0.06),
                                cardData['primaryColor'].withOpacity(0.12),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: cardData['primaryColor'].withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Fecha de publicación
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 12,
                                    color: cardData['primaryColor'],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    fechaCreacion,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: cardData['primaryColor'],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              // Días restantes
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: diasRestantes <= 3 
                                    ? Colors.red[100] 
                                    : cardData['primaryColor'].withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$diasRestantes días',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: diasRestantes <= 3 ? Colors.red[700] : cardData['primaryColor'],
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // BOTÓN COMPACTO
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () => _abrirEnlaceDirecto(promocion),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cardData['primaryColor'],
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shadowColor: cardData['primaryColor'].withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.open_in_new_rounded,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Ver Detalles',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Función helper para extraer dominio del link
  String _obtenerDominioDeLink(String link) {
    try {
      final uri = Uri.parse(link);
      String dominio = uri.host;
      
      // Remover 'www.' si existe
      if (dominio.startsWith('www.')) {
        dominio = dominio.substring(4);
      }
      
      return dominio;
    } catch (e) {
      return link.length > 30 ? '${link.substring(0, 30)}...' : link;
    }
  }
  
  // Función para parsear fecha de creación (CORREGIDA)
  String _parsearFecha(String? fechaISO) {
    if (fechaISO == null || fechaISO.isEmpty) {
      return 'Reciente';
    }
    
    try {
      final fecha = DateTime.parse(fechaISO);
      final meses = [
        '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
      ];
      
      return '${fecha.day} ${meses[fecha.month]} ${fecha.year}';
    } catch (e) {
      return 'Reciente';
    }
  }
  
  // Función para calcular fecha de expiración (CORREGIDA)
  String _calcularExpiracion(String? fechaISO) {
    if (fechaISO == null || fechaISO.isEmpty) {
      return '7 días';
    }
    
    try {
      final fecha = DateTime.parse(fechaISO);
      final expiracion = fecha.add(const Duration(days: 7));
      final meses = [
        '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
      ];
      
      return '${expiracion.day} ${meses[expiracion.month]} ${expiracion.year}';
    } catch (e) {
      return '7 días';
    }
  }
  
  // Función para calcular días restantes (CORREGIDA)
  int _calcularDiasRestantes(String? fechaISO) {
    if (fechaISO == null || fechaISO.isEmpty) {
      return 7; // Por defecto 7 días
    }
    
    try {
      final fecha = DateTime.parse(fechaISO);
      final expiracion = fecha.add(const Duration(days: 7));
      final ahora = DateTime.now();
      final diferencia = expiracion.difference(ahora);
      
      return diferencia.inDays.clamp(0, 7); // Mínimo 0, máximo 7
    } catch (e) {
      return 7;
    }
  }
  
  // Función anterior del botón - ahora reemplazada arriba
  Widget _buildNetflixCardOLD(promocion) {
    final cardData = _getCardDesign(promocion.categoria);
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _abrirEnlaceDirecto(promocion),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: cardData['gradient'],
            ),
            child: Stack(
              children: [
                // Patrón de fondo sutil
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      backgroundBlendMode: BlendMode.overlay,
                    ),
                    child: CustomPaint(
                      painter: _PatternPainter(
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                ),
                
                // Contenido principal
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              cardData['icon'],
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  promocion.departamento,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  promocion.programa,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Título principal
                      Text(
                        promocion.titulo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Descripción
                      Text(
                        promocion.descripcion,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const Spacer(),
                      
                      // Botón de acción principal
                      Container(
                        width: double.infinity,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () => _abrirEnlaceDirecto(promocion),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: cardData['primaryColor'],
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Ver ahora',
                                  style: TextStyle(
                                    color: cardData['primaryColor'],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Badge "NUEVO"
                if (_esPromocionReciente(promocion.createdAt))
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'NUEVO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🏥 CARD INDIVIDUAL DE PROMOCIÓN
  Widget _buildPromocionCard(promocion) {
    // Convertir color hex a Color
    Color cardColor;
    try {
      cardColor = Color(int.parse(promocion.colorTema.replaceFirst('#', '0xFF')));
    } catch (e) {
      cardColor = UAGroColors.primary;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cardColor,
            cardColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _mostrarDetallePromocion(promocion),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con icono y días restantes
                Row(
                  children: [
                    Text(
                      promocion.iconoTipo,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${promocion.diasRestantes} días',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Título
                Text(
                  promocion.titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                
                // Descripción
                Expanded(
                  child: Text(
                    promocion.descripcion,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Botón de acción
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Ver más',
                      style: TextStyle(
                        color: cardColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🏥 MOSTRAR DETALLE DE PROMOCIÓN
  void _mostrarDetallePromocion(promocion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Text(promocion.iconoTipo, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                promocion.titulo,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              promocion.descripcion,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.local_hospital, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  'Departamento: ${promocion.departamento}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  'Publicado: ${promocion.createdAt.day}/${promocion.createdAt.month}/${promocion.createdAt.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Marcar como vista y cerrar
              context.read<SessionProvider>().marcarPromocionVista(promocion.id);
              Navigator.of(context).pop();
            },
            child: const Text('Entendido'),
          ),
          if (promocion.link != null && promocion.link!.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                // TODO: Abrir enlace externo
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Abrir: ${promocion.link}')),
                );
              },
              child: const Text('Ver más'),
            ),
        ],
      ),
    );
  }

  // 🎨 OBTENER DISEÑO SEGÚN CATEGORÍA
  Map<String, dynamic> _getCardDesign(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'prevención':
        return {
          'gradient': const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32), Color(0xFF1B5E20)],
            stops: [0.0, 0.7, 1.0],
          ),
          'primaryColor': const Color(0xFF2E7D32),
          'icon': '🛡️',
        };
      case 'consulta médica':
      case 'consulta':
        return {
          'gradient': const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2196F3), Color(0xFF1565C0), Color(0xFF0D47A1)],
            stops: [0.0, 0.7, 1.0],
          ),
          'primaryColor': const Color(0xFF1565C0),
          'icon': '🏥',
        };
      case 'emergencia':
      case 'urgente':
        return {
          'gradient': const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF44336), Color(0xFFD32F2F), Color(0xFFB71C1C)],
            stops: [0.0, 0.7, 1.0],
          ),
          'primaryColor': const Color(0xFFD32F2F),
          'icon': '🚨',
        };
      case 'promoción':
      case 'promociones':
        return {
          'gradient': const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2196F3), Color(0xFF1976D2), Color(0xFF1565C0)],
            stops: [0.0, 0.7, 1.0],
          ),
          'primaryColor': const Color(0xFF1976D2),
          'icon': '📢',
        };
      case 'información del sistema':
      default:
        return {
          'gradient': const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2), Color(0xFF4A148C)],
            stops: [0.0, 0.7, 1.0],
          ),
          'primaryColor': const Color(0xFF7B1FA2),
          'icon': '📱',
        };
    }
  }

  // 🕒 VERIFICAR SI ES PROMOCIÓN RECIENTE
  bool _esPromocionReciente(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inDays <= 7;
  }

  // 🎬 ABRIR ENLACE DIRECTAMENTE
  void _abrirEnlaceDirecto(promocion) async {
    // Efecto visual de clic
    HapticFeedback.lightImpact();
    
    try {
      // Marcar como vista
      context.read<SessionProvider>().marcarPromocionVista(promocion.id);
      
      // Si hay enlace, abrirlo directamente
      if (promocion.link.isNotEmpty) {
        final Uri url = Uri.parse(promocion.link);
        
        // Intentar abrir el enlace
        if (await canLaunchUrl(url)) {
          await launchUrl(
            url,
            mode: LaunchMode.externalApplication, // Abrir en navegador externo
          );
          
          // Mostrar mensaje de confirmación
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.open_in_new, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Abriendo: ${_obtenerDominioDeLink(promocion.link)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green[700],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          // Si no se puede abrir, mostrar error
          throw 'No se pudo abrir el enlace';
        }
      } else {
        // Si no hay enlace, mostrar detalle
        _mostrarDetallePromocion(promocion);
      }
    } catch (e) {
      // Mostrar error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'No se pudo abrir el enlace. Verifica tu conexión.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // ⭐ LOADING ELEGANTE ESTILO STREAMING
  void _mostrarLoadingElegante() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1500),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(UAGroColors.primary),
                      strokeWidth: 3,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text(
                '🎬 Cargando promoción...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Preparando el mejor contenido para ti',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔗 MOSTRAR ENLACE FINAL ELEGANTE
  void _mostrarEnlaceFinal(promocion) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header colorido
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: _getCardDesign(promocion.categoria)['gradient'],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _getCardDesign(promocion.categoria)['icon'],
                      style: const TextStyle(fontSize: 48),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      promocion.titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // Contenido
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      promocion.descripcion,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Info adicional
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.business, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                promocion.departamento,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.link, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  promocion.link,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontFamily: 'monospace',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Botones de acción
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cerrar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              // Aquí se abriría el enlace real
                              _mostrarMensajeEnlace();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _getCardDesign(promocion.categoria)['primaryColor'],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.open_in_new, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Abrir enlace',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 📱 MENSAJE DE ENLACE SIMULADO
  void _mostrarMensajeEnlace() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.open_in_new, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            const Text('Enlace abierto exitosamente'),
          ],
        ),
        backgroundColor: UAGroColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ❌ ERROR AL ABRIR ENLACE
  void _mostrarErrorEnlace() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text('Error al procesar la promoción'),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// 🎨 PAINTER PARA PATRÓN DE FONDO
class _PatternPainter extends CustomPainter {
  final Color color;

  _PatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacing = 20.0;
    
    // Dibujar patrón de líneas diagonales
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}