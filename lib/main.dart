import 'package:flutter/material.dart';
import 'package:pictidy/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PicTidyApp());
}

class PicTidyApp extends StatelessWidget {
  const PicTidyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PicTidy',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

