import 'package:flutter/material.dart';
import 'package:happychat/pages/home_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://vezdckpnvxrpophmgleq.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZlemRja3BudnhycG9waG1nbGVxIiwicm9sZSI6ImFub24iLCJpYXQiOjE2NTEyMTA0ODMsImV4cCI6MTk2Njc4NjQ4M30.uJFMJA51p2qxF1fAXLMDP_qo1Ob7e5dWsJJ2gENLBQQ',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}
