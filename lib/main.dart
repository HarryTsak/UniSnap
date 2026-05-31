import 'package:flutter/material.dart';
import 'global_state.dart';
import 'services/helpers.dart';
import 'screens/camera_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestPermissions();
  await loadData();
  runApp(const UniSnapApp());
}

class UniSnapApp extends StatelessWidget {
  const UniSnapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, child) {
        return MaterialApp(
          title: 'UniSnap',
          debugShowCheckedModeBanner: false,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            brightness: Brightness.light,
            fontFamily: 'Roboto',
            scaffoldBackgroundColor: const Color(0xFFE5E5E5),
            cardColor: Colors.white,
            appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Colors.black87),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            fontFamily: 'Roboto',
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E1E1E), foregroundColor: Colors.white),
          ),
          home: const CameraScreen(),
        );
      },
    );
  }
}