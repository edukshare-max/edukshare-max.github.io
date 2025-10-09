// 🚀 CARNET DIGITAL UAGRO - PUNTO DE ENTRADA
// Aplicación web con autenticación y gestión de estado

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carnet_digital_uagro/providers/session_provider.dart';
import 'package:carnet_digital_uagro/screens/login_screen.dart';
import 'package:carnet_digital_uagro/screens/carnet_screen.dart';
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
        home: Consumer<SessionProvider>(
          builder: (context, session, child) {
            if (session.isAuthenticated) {
              return const CarnetScreen();
            } else {
              return const LoginScreen();
            }
          },
        ),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/carnet': (context) => const CarnetScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
