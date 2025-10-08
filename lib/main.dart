// 📱 CARNET DIGITAL UAGRO - MAIN APP
// Sistema de identificación digital UAGro integrado con SASU

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/session_provider.dart';
import 'screens/login_screen.dart';
import 'screens/carnet_screen.dart';
import 'screens/citas_screen.dart';
import 'theme/uagro_theme.dart';

void main() {
  runApp(const CarnetDigitalApp());
}

class CarnetDigitalApp extends StatelessWidget {
  const CarnetDigitalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionProvider()),
      ],
      child: MaterialApp(
        title: 'Carnet Digital UAGro',
        theme: UAGroTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        
        // Rutas de navegación
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/carnet': (context) => const CarnetScreen(),
          '/citas': (context) => const CitasScreen(),
        },
        
        // Pantalla de inicio basada en estado de sesión
        home: Consumer<SessionProvider>(
          builder: (context, session, child) {
            if (session.isAuthenticated) {
              return const CarnetScreen();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
