import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/synthwave_theme.dart';
import 'ui/screens/main_shell.dart';

void main() {
  runApp(
    const ProviderScope(
      child: OpenFitApp(),
    ),
  );
}

class OpenFitApp extends StatelessWidget {
  const OpenFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Open Fit',
      debugShowCheckedModeBanner: false,
      theme: SynthwaveTheme.dark,
      home: const MainShell(),
    );
  }
}
