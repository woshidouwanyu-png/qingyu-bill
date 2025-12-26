import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:qingyu_bill/models/budget.dart';
import 'package:qingyu_bill/models/frequent_note.dart';
import 'package:qingyu_bill/models/transaction.dart';
import 'package:qingyu_bill/models/voice_draft.dart';
import 'package:qingyu_bill/screens/home_screen.dart';
import 'package:qingyu_bill/screens/onboarding_screen.dart';
import 'package:qingyu_bill/services/data_service.dart';
import 'package:qingyu_bill/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(BudgetAdapter());
  Hive.registerAdapter(FrequentNoteAdapter());
  Hive.registerAdapter(VoiceDraftAdapter());

  await DataService().init();

  final onboarded = Hive.box('settings').get('onboarded', defaultValue: false) as bool;

  runApp(MyApp(onboarded: onboarded));
}

class MyApp extends StatelessWidget {
  final bool onboarded;
  const MyApp({super.key, required this.onboarded});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '轻语账单',
      theme: appTheme,
      home: onboarded ? const HomeScreen() : const OnboardingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}