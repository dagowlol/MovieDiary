import 'package:flutter/material.dart';
import 'package:movie/features/movie_form/movie_form_screen.dart';

class MovieDiaryApp extends StatelessWidget {
  const MovieDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Movie Diary',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0F14),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF7BA34),
          surface: Color(0xFF161922),
        ),
        useMaterial3: true,
      ),
      home: const MovieFormScreen(),
    );
  }
}
