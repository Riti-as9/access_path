import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'store.dart';
import 'extras.dart';
import 'shell_screen.dart';
import 'ui_kit.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStore()..load()),
        ChangeNotifierProvider(create: (_) => ExtrasStore()),
      ],
      child: const AccessPathApp(),
    ),
  );
}

TextTheme _easyText(TextTheme t) {
  TextStyle? e(TextStyle? s, {double ls = 0.5, double h = 1.5}) =>
      s?.copyWith(letterSpacing: ls, height: h, wordSpacing: 2);
  return t.copyWith(
    titleLarge: e(t.titleLarge, ls: 0.3, h: 1.3),
    titleMedium: e(t.titleMedium, ls: 0.4, h: 1.4),
    titleSmall: e(t.titleSmall),
    bodyLarge: e(t.bodyLarge),
    bodyMedium: e(t.bodyMedium),
    bodySmall: e(t.bodySmall),
    labelLarge: e(t.labelLarge, h: 1.3),
    labelMedium: e(t.labelMedium, h: 1.3),
  );
}

class AccessPathApp extends StatelessWidget {
  const AccessPathApp({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final ex = context.watch<ExtrasStore>();

    var theme = buildTheme(dark: store.highContrast);
    if (ex.easyReading) {
      theme = theme.copyWith(textTheme: _easyText(theme.textTheme));
    }

    return MaterialApp(
      title: 'AccessPath',
      debugShowCheckedModeBanner: false,
      theme: theme,
      themeAnimationDuration: const Duration(milliseconds: 400),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(ex.textScale),
        ),
        child: child!,
      ),

      home: const AppShell(),
    );
  }
}