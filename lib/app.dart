import 'package:flutter/material.dart';

// TODO: Root application widget - configure theme, routes, and home screen
class MovieDiaryApp extends StatelessWidget {
  const MovieDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Movie Diary',
      home: Scaffold(
        body: Center(
          child: Text('Movie Diary'),
        ),
      ),
    );
  }
}

