import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/views/can_input_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    const ProviderScope(
      child: TckkNfcApp(),
    ),
  );
}

class TckkNfcApp extends StatelessWidget {
  const TckkNfcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TCKK NFC Reader',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const CanInputView(),
    );
  }
}
