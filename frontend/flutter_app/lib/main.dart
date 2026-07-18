// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ai_insurance_advisor/app/app.dart';
import 'package:ai_insurance_advisor/injection/dependency_injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ Charger le fichier .env
  await dotenv.load(fileName: ".env");
  print('✅ .env loaded');
  
  await setupDependencies();
  
  runApp(const AIInsuranceApp());
}