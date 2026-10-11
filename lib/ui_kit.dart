import 'package:flutter/material.dart';

// ---------- Score helpers (moved here so every screen shares them) ----------
Color scoreColor(double? s) {
  if (s == null) return Colors.grey.shade600;
  if (s >= 75) return const Color(0xFF2E7D32);
  if (s >= 50) return const Color(0xFFEF6C00);
  return const Color(0xFFC62828);
}

// A word next to the colour, so colour is never the only signal
String scoreWord(double? s) {
  if (s == null) return 'No data';
  if (s >= 75) return 'Good';
  if (s >= 50) return 'Fair';
  return 'Poor';
}

// ---------- Icons ("signs") ----------
IconData criterionIcon(String label) {
  final l = label.toLowerCase();
  if (l.contains('step')) return Icons.accessible;
  if (l.contains('lift') || l.contains('elev')) return Icons.elevator;
  if (l.contains('wash') || l.contains('toilet') || l.contains('rest')) {
    return Icons.wc;
  }
  if (l.contains('seat')) return Icons.event_seat;
  if (l.contains('way') || l.contains('sign') || l.contains('nav')) {
    return Icons.signpost;
  }
  return Icons.check_circle_outline;
}

IconData categoryIcon(String category) {
  final c = category.toLowerCase();
  if (c.contains('shop') || c.contains('mall')) return Icons.shopping_bag;
  if (c.contains('gov') || c.contains('civil') || c.contains('bank')) {
    return Icons.account_balance;
  }
  if (c.contains('lib')) return Icons.local_library;
  if (c.contains('health') || c.contains('hosp')) return Icons.local_hospital;
  if (c.contains('outdoor') || c.contains('park')) return Icons.park;
  if (c.contains('edu') || c.contains('college') || c.contains('school')) {
    return Icons.school;
  }
  if (c.contains('rail') || c.contains('transport') || c.contains('bus')) {
    return Icons.directions_transit;
  }
  if (c.contains('food') || c.contains('cafe') || c.contains('restaurant')) {
    return Icons.restaurant;
  }
  return Icons.place;
}

IconData profileIcon(String label) {
  final l = label.toLowerCase();
  if (l.contains('wheel')) return Icons.accessible;
  if (l.contains('vision') || l.contains('blind')) return Icons.visibility;
  if (l.contains('elder') || l.contains('stroller')) return Icons.elderly;
  if (l.contains('hear') || l.contains('deaf')) return Icons.hearing;
  return Icons.person;
}

// ---------- Theme ----------
ThemeData buildTheme({required bool dark}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF1565C0),
    brightness: dark ? Brightness.dark : Brightness.light,
  );
  final bg = dark ? const Color(0xFF0F1318) : const Color(0xFFF3F6FB);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
        letterSpacing: -0.3,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(color: scheme.outlineVariant),
      showCheckmark: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: ZoomPageTransitionsBuilder()},
    ),
  );
}

// ---------- Animated score ring (counts up) ----------
class ScoreRing extends StatelessWidget {
  final double? score;
  final double size;
  final double stroke;
  const ScoreRing({
    super.key,
    required this.score,
    this.size = 64,
    this.stroke = 7,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = scoreColor(score);
    final color = dark
        ? HSLColor.fromColor(base).withLightness(0.62).toColor()
        : base;
    final target = (score ?? 0) / 100;
    return Semantics(
      label: score == null
          ? 'No accessibility score yet'
          : 'Accessibility score ${score!.round()} out of 100, ${scoreWord(score)}',
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: target),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: stroke,
                    color: color.withAlpha(40),
                  ),
                ),
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: v,
                    strokeWidth: stroke,
                    strokeCap: StrokeCap.round,
                    color: color,
                    backgroundColor: Colors.transparent,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      score == null ? '-' : (v * 100).round().toString(),
                      style: TextStyle(
                        fontSize: size * 0.32,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    if (size >= 64)
                      Text(
                        scoreWord(score),
                        style: TextStyle(
                          fontSize: size * 0.15,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- Fade + slide entrance ----------
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final int index;
  const FadeSlideIn({super.key, required this.child, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final i = index > 6 ? 6 : index;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + i * 70),
      curve: Curves.easeOutCubic,
      builder: (context, v, c) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, 26 * (1 - v)), child: c),
      ),
      child: child,
    );
  }
}

// ---------- Small rounded info pill ----------
class InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const InfoPill({super.key, required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withAlpha(28),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: c),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Section heading ----------
class SectionTitle extends StatelessWidget {
  final String text;
  final IconData? icon;
  const SectionTitle(this.text, {super.key, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}