import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_page/login_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for a pure mobile experience
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configure modern edge-to-edge transparent system overlay for mobile
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFFF3F7FC),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const TaskChatApp());
}

class TaskChatApp extends StatelessWidget {
  const TaskChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskChat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF036838),
          primary: const Color(0xFF036838),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF3F7FC),
      ),
      home: const LoginPage(),
    );
  }
}