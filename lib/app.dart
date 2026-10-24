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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const MovieFormScreen(),
    );
  }
}


