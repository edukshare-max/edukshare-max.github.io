// 🔐 LOGIN SCREEN MODERNO - DISEÑO UAGro PROFESIONAL
// Animaciones suaves y diseño institucional

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/session_provider.dart';
import '../theme/uagro_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> 
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  
  // Controladores de animación para elementos dinámicos
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _floatingController;
  
  @override
  void initState() {
    super.initState();
    
    // Animación de rotación continua para el logo
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    
    // Animación de pulso para elementos dinámicos
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    // Animación flotante para partículas
    _floatingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _floatingController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Función para obtener colores dinámicos de partículas
  Color _getParticleColor(int index) {
    final colors = [
      const Color(0xFF3b82f6), // Azul médico
      const Color(0xFF8B1538), // Rojo UAGro
      const Color(0xFF059669), // Verde salud
      const Color(0xFF7c3aed), // Morado
      const Color(0xFFf59e0b), // Naranja
      const Color(0xFFef4444), // Rojo coral
    ];
    return colors[index % colors.length];
  }

  // Función para obtener iconos dinámicos de partículas
  IconData _getParticleIcon(int index) {
    final icons = [
      Icons.add,
      Icons.favorite,
      Icons.local_hospital,
      Icons.healing,
      Icons.medical_services,
      Icons.health_and_safety,
      Icons.vaccines,
      Icons.monitor_heart,
    ];
    return icons[index % icons.length];
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final sessionProvider = context.read<SessionProvider>();
      
      sessionProvider.checkBackend();
      
      final success = await sessionProvider.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed('/carnet');
      } else if (mounted) {
        final errorType = sessionProvider.errorType ?? 'UNKNOWN';
        final errorMessage = sessionProvider.error ?? 'Error de autenticación';
        
        _showErrorDialog(errorType, errorMessage);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('CONNECTION', 
            'No se pudo conectar con el servidor. Intente más tarde.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String errorType, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red[600],
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Error de Autenticación',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 16, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Entendido',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 768;
    
    return Scaffold(
      body: Stack(
        children: [
          // Fondo médico con gradiente animado
          AnimatedContainer(
            duration: const Duration(seconds: 3),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFf8fafc), // Gris muy claro
                  Color(0xFFe2e8f0), // Gris claro
                  Color(0xFFcbd5e1), // Gris medio
                  Color(0xFF94a3b8), // Gris azulado
                ],
                stops: [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
          
          // Partículas médicas súper dinámicas
          ...List.generate(8, (index) => Positioned(
            top: 80 + (index * 60) % 400,
            left: (index * 80 + 40) % (size.width - 40),
              child: AnimatedBuilder(
              animation: Listenable.merge([_rotationController, _floatingController]),
              builder: (context, child) {
                final rotation = _rotationController.value * 2 * 3.14159 * (index.isEven ? 1 : -1);
                final floating = _floatingController.value * 20;
                final scale = 0.8 + (_floatingController.value * 0.4);
                
                return Transform.translate(
                  offset: Offset(
                    math.sin(rotation + index) * 15,
                    floating + math.cos(rotation + index) * 10,
                  ),
                  child: Transform.rotate(
                    angle: rotation,
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 25 + (index % 3) * 5,
                        height: 25 + (index % 3) * 5,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              _getParticleColor(index).withOpacity(0.8),
                              _getParticleColor(index).withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getParticleIcon(index),
                          size: 15 + (index % 2) * 3,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          )),
          
          // Contenido principal
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 450 : size.width * 0.9,
                  ),
                  margin: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Contenedor principal con animación
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 1200),
                          curve: Curves.easeOutCubic,
                          padding: EdgeInsets.all(isDesktop ? 50 : 40),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF3b82f6).withOpacity(0.1),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Badge de seguridad
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF22c55e).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFF22c55e).withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.lock,
                                          color: Color(0xFF16a34a),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Seguro',
                                          style: TextStyle(
                                            color: const Color(0xFF16a34a),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              
                              // Logo UAGro profesional
                              _buildMedicalLogo(),
                              const SizedBox(height: 28),
                              
                              // Títulos organizados profesionalmente - COMPACTO
                              Column(
                                children: [
                                  // Título principal en una sola línea
                                  const Text(
                                    'UNIVERSIDAD AUTÓNOMA DE GUERRERO',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1e293b),
                                      letterSpacing: 0.8,
                                      height: 1.2,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.visible,
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Línea decorativa animada más delgada
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 1500),
                                    width: 100,
                                    height: 2,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF8B1538),
                                          Color(0xFFC41E3A),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Subtítulo médico más compacto
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3b82f6).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFF3b82f6).withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Text(
                                      'SISTEMA DE SALUD DIGITAL',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF3b82f6),
                                        letterSpacing: 0.6,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.visible,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),
                              
                              Text(
                                'Acceso seguro para estudiantes,\npersonal médico y administrativo.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: const Color(0xFF64748b),
                                  height: 1.6,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 35),
                              
                              // Formulario
                              _buildLoginForm(isDesktop),
                              
                              // Línea de heartbeat
                              const SizedBox(height: 30),
                              _buildHeartbeatLine(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _floatingController]),
      builder: (context, child) {
        final double scale = 1.0 + (_pulseController.value * 0.08);
        final double verticalOffset = math.sin(_floatingController.value * 2 * math.pi) * 6;

        return Transform.translate(
          offset: Offset(0, verticalOffset),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF8B1538),
                    Color(0xFFC41E3A),
                    Color(0xFF8B1538),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B1538).withOpacity(0.25 + (_pulseController.value * 0.1)),
                    blurRadius: 12 + (_pulseController.value * 6),
                    offset: const Offset(0, 8),
                    spreadRadius: _pulseController.value * 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Anillo externo ligeramente luminoso (sin rotación)
                  Positioned.fill(
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.35 + (_pulseController.value * 0.08)),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  // Símbolo central de salud estático
                  const Center(
                    child: Icon(
                      Icons.health_and_safety,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeartbeatLine() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 2000),
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: const Color(0xFF3b82f6).withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animación de pulso en el icono del corazón
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1500),
              tween: Tween(begin: 0.8, end: 1.2),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Icon(
                    Icons.favorite,
                    color: const Color(0xFF8B1538).withOpacity(0.6),
                    size: 16,
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Text(
              'CRES Llano Largo - Sistema Seguro',
              style: TextStyle(
                color: const Color(0xFF64748b),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 12),
            // Segundo corazón con animación desfasada
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1500),
              tween: Tween(begin: 1.2, end: 0.8),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Icon(
                    Icons.favorite,
                    color: const Color(0xFF8B1538).withOpacity(0.6),
                    size: 16,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm(bool isDesktop) {
    return Column(
      children: [
        // Campo de usuario con animación dinámica
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = 1.0 + (_pulseController.value * 0.02);
            return Transform.scale(
              scale: scale,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF3b82f6).withOpacity(0.1 + (_pulseController.value * 0.2)),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3b82f6).withOpacity(0.05 + (_pulseController.value * 0.1)),
                      blurRadius: 10 + (_pulseController.value * 8),
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Usuario',
                    prefixIcon: Transform.rotate(
                      angle: _floatingController.value * 0.3,
                      child: const Icon(
                        Icons.person_outline,
                        color: Color(0xFF3b82f6),
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    labelStyle: const TextStyle(
                      color: Color(0xFF64748b),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su usuario';
                    }
                    return null;
                  },
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),

        // Campo de contraseña con animación dinámica
        AnimatedBuilder(
          animation: Listenable.merge([_pulseController, _floatingController]),
          builder: (context, child) {
            final scale = 1.0 + (_pulseController.value * 0.015);
            final rotation = _floatingController.value * 0.25;
            return Transform.scale(
              scale: scale,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF8B1538).withOpacity(0.1 + (_pulseController.value * 0.2)),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B1538).withOpacity(0.05 + (_pulseController.value * 0.1)),
                      blurRadius: 10 + (_pulseController.value * 6),
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Transform.rotate(
                      angle: rotation,
                      child: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFF8B1538),
                      ),
                    ),
                    suffixIcon: Transform.scale(
                      scale: 1.0 + (_pulseController.value * 0.1),
                      child: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: const Color(0xFF64748b),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    labelStyle: const TextStyle(
                      color: Color(0xFF64748b),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su contraseña';
                    }
                    return null;
                  },
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 30),

        // Botón de acceso dinámico estilo UAGro
        AnimatedBuilder(
          animation: Listenable.merge([_pulseController, _rotationController]),
          builder: (context, child) {
            final scale = 1.0 + (_pulseController.value * 0.03);
            final shadowIntensity = 0.4 + (_pulseController.value * 0.2);
            return Transform.scale(
              scale: scale,
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(const Color(0xFF8B1538), const Color(0xFFC41E3A), _rotationController.value)!,
                      Color.lerp(const Color(0xFFC41E3A), const Color(0xFF8B1538), _rotationController.value)!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B1538).withOpacity(shadowIntensity),
                      blurRadius: 15 + (_pulseController.value * 10),
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : _handleLogin,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      alignment: Alignment.center,
                      child: _isLoading
                          ? Transform.rotate(
                              angle: _rotationController.value * 2 * 3.14159,
                              child: const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Transform.rotate(
                                  angle: _floatingController.value * 0.2,
                                  child: const Icon(
                                    Icons.login,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'INGRESAR AL SISTEMA',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}