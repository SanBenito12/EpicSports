import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'services/push_notification_service.dart'; // 🔔 NUEVO

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializar Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase inicializado correctamente');

    // 🔔 INICIALIZAR NOTIFICACIONES PUSH
    await PushNotificationService.initialize();
    debugPrint('✅ Servicio de notificaciones inicializado');

  } catch (e) {
    debugPrint('❌ Error al inicializar servicios: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EpicSports - MLB',
      theme: ThemeData(
        brightness: Brightness.dark, 
        primarySwatch: Colors.pink,
        // 🔔 COLORES PARA NOTIFICACIONES
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}