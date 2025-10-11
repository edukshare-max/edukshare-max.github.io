// 🚀 CARNET DIGITAL UAGRO - PUNTO DE ENTRADA
// Aplicación web con autenticación y gestión de estado

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carnet_digital_uagro/providers/session_provider.dart';
import 'package:carnet_digital_uagro/screens/login_screen.dart';
import 'package:carnet_digital_uagro/screens/carnet_screen.dart';
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
      backgroundColor: UAGroColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo UAGro
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.school,
                size: 60,
                color: UAGroColors.primary,
              ),
            ),
            
            const SizedBox(height: 32),
            
            const Text(
              'Carnet Digital Universitario',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 8),
            
            const Text(
              'Universidad Autónoma de Guerrero',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            
            const SizedBox(height: 48),
            
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              'Restaurando sesión...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
