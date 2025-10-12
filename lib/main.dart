// 🚀 CARNET DIGITAL UAGRO - PUNTO DE ENTRADA
// Aplicación web con autenticación y gestión de estado

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carnet_digital_uagro/providers/session_provider.dart';
import 'package:carnet_digital_uagro/screens/login_screen.dart';
import 'package:carnet_digital_uagro/screens/carnet_screen.dart';
import 'package:carnet_digital_uagro/screens/carnet_screen_new.dart';
import 'package:carnet_digital_uagro/screens/vacunas_screen.dart';
import 'package:carnet_digital_uagro/theme/uagro_theme.dart';

void main() {
  runApp(const CarnetDigitalApp());
}

class CarnetDigitalApp extends StatelessWidget {
  const CarnetDigitalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SessionProvider(),
      child: MaterialApp(
        title: 'Carnet Digital UAGro',
        theme: UAGroTheme.lightTheme,
        home: const SessionRestoreScreen(), // 🔄 Nueva pantalla de splash con restauración
        routes: {
          '/login': (context) => const LoginScreen(),
          '/carnet': (context) => const CarnetScreen(),
          '/carnet-new': (context) => const CarnetScreenNew(),
          '/vacunas': (context) => const VacunasScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// 🔄 PANTALLA DE SPLASH CON RESTAURACIÓN DE SESIÓN
class SessionRestoreScreen extends StatefulWidget {
  const SessionRestoreScreen({super.key});

  @override
  State<SessionRestoreScreen> createState() => _SessionRestoreScreenState();
}

class _SessionRestoreScreenState extends State<SessionRestoreScreen> {
  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    // Esperar un momento para mostrar splash
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    final sessionProvider = context.read<SessionProvider>();
    final restored = await sessionProvider.restoreSession();
    
    if (!mounted) return;
    
    // Navegar según resultado
    if (restored) {
      Navigator.of(context).pushReplacementNamed('/carnet');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0f4c75), // Azul UAGro profundo
              const Color(0xFF1e3a8a), // Azul moderno
              const Color(0xFF0f172a), // Azul oscuro elegante
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo moderno con animación sutil
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.school_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Título moderno
              const Text(
                'Carnet Digital',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Subtítulo
              Text(
                'Universidad Autónoma de Guerrero',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.8),
                  letterSpacing: 0.3,
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Indicador de carga moderno
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Texto de carga
              Text(
                'Restaurando sesión...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
