// 🔐 LOGIN SCREEN - AUTENTICACIÓN CON SASU
// Email institucional + matrícula para acceso

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../theme/uagro_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _matriculaController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _matriculaController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Prevenir múltiples submissions
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final sessionProvider = context.read<SessionProvider>();
      
      // 🏥 Verificar salud del backend primero (no bloqueante)
      sessionProvider.checkBackend();
      
      final success = await sessionProvider.login(
        _emailController.text.trim(),
        _matriculaController.text.trim(),
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed('/carnet');
      } else if (mounted) {
        final errorType = sessionProvider.errorType ?? 'UNKNOWN';
        final errorMessage = sessionProvider.error ?? 'Error de autenticación';
        
        // Mostrar mensaje específico según tipo de error
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
    // Iconos y títulos personalizados según tipo de error
    IconData icon;
    String title;
    Color color;
    
    switch (errorType) {
      case 'CREDENTIALS':
        icon = Icons.lock_outline;
        title = 'Credenciales Incorrectas';
        color = Colors.orange;
        break;
      case 'TIMEOUT':
        icon = Icons.hourglass_empty;
        title = 'Servidor Iniciando';
        color = Colors.blue;
        break;
      case 'NETWORK':
        icon = Icons.wifi_off;
        title = 'Sin Conexión';
        color = Colors.red;
        break;
      case 'SERVER':
        icon = Icons.dns_outlined;
        title = 'Error del Servidor';
        color = Colors.deepOrange;
        break;
      default:
        icon = Icons.error_outline;
        title = 'Error';
        color = Colors.grey;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(icon, size: 48, color: color),
        title: Text(
          title,
          style: TextStyle(color: color),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            if (errorType == 'TIMEOUT') ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Text(
                'Esto es normal si el servidor estaba inactivo.\nPor favor espere 30-60 segundos.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
          if (errorType == 'TIMEOUT' || errorType == 'NETWORK')
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleLogin(); // Reintentar
              },
              child: const Text('Reintentar'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UAGroColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo UAGro
                    Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        color: UAGroColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.school,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    const Text(
                      'Carnet Digital Universitario',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: UAGroColors.primary,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    const Text(
                      'CRES Llano Largo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: UAGroColors.primary,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    const Text(
                      'Universidad Autónoma de Guerrero',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Email institucional
                    SizedBox(
                      width: 400,
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Institucional',
                          hintText: 'ejemplo@uagro.mx',
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese su email institucional';
                          }
                          if (!value.contains('@')) {
                            return 'Ingrese un email válido';
                          }
                          return null;
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Matrícula
                    SizedBox(
                      width: 400,
                      child: TextFormField(
                        controller: _matriculaController,
                        decoration: const InputDecoration(
                          labelText: 'Matrícula',
                          hintText: '123456',
                          prefixIcon: Icon(Icons.badge),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese su matrícula';
                          }
                          // Permitir matrículas de cualquier longitud (3+ dígitos)
                          if (value.trim().length < 3) {
                            return 'La matrícula debe tener al menos 3 caracteres';
                          }
                          return null;
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Botón de login
                    SizedBox(
                      width: 400,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Iniciar Sesión',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Información adicional
                    const Text(
                      'Use sus credenciales institucionales\npara acceder a su carnet digital',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}