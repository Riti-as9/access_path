import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'store.dart';
import 'home_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppStore()..load(),
      child: const AccessPathApp(),
    ),
  );
}

class AccessPathApp extends StatelessWidget {
  const AccessPathApp({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1565C0),
      brightness: store.highContrast ? Brightness.dark : Brightness.light,
    );
    return MaterialApp(
      title: 'AccessPath',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: scheme, useMaterial3: true),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(store.textScale)),
        child: child!,
      ),
      home: const HomeScreen(),
    );
  }
}
