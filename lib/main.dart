import 'package:flutter/material.dart';
import 'views/login_page.dart'; // Memanggil halaman login yang sudah dibuat

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Waste for Reward',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF135232),
        ),
        useMaterial3: true,
      ),
      home: const LoginPage(), // Mengarahkan tampilan awal ke Halaman Login
    );
  }
}
