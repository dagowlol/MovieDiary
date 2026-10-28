import 'package:flutter/material.dart';
import 'package:movie/database/database_helper.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DatabaseHelper.ensureInitialized();
  runApp(const MovieDiaryApp());
}
