import 'package:flutter/material.dart';

String formatKilometers(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => '.',
);

class AppColors {
  static const red = Color(0xFFE21B23), redDark = Color(0xFFB81218);
  static const ink = Color(0xFF151C27), muted = Color(0xFF575E70);
  static const bg = Color(0xFFF9F9FF), border = Color(0xFFE7EAF3);
  static const green = Color(0xFF008438), amber = Color(0xFFF59E0B);
  static const redTint = Color(0xFFFDECEC), greenTint = Color(0xFFE6F6EA);
  static const amberTint = Color(0xFFFEF3DC), darkSurface = Color(0xFF151C27);
  // Cool blue-tinted surface containers (Stitch-inspired).
  static const surfaceLow = Color(0xFFF0F3FF);
  static const surfaceHigh = Color(0xFFE2E8F8);
  static const navy = Color(0xFF2A313D);
}

/// Subtle card shadow used across white surfaces.
const cardShadow = [
  BoxShadow(color: Color(0x14101828), blurRadius: 18, offset: Offset(0, 5)),
];

class AppPage extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? bottomBar;
  const AppPage({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.bottomBar,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
      actions: actions,
      leading: Navigator.canPop(context)
          ? IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
            )
          : null,
    ),
    body: SafeArea(child: child),
    bottomNavigationBar: bottomBar,
  );
}

class ScrollPage extends StatelessWidget {
  final Widget child;
  const ScrollPage({super.key, required this.child});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
    child: child,
  );
}

class CardBox extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final VoidCallback? onTap;
  const CardBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = Colors.white,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    // Fill the available width (also inside start-aligned columns) but keep
    // shrink-wrapping where the width is unbounded, e.g. in a plain Row.
    builder: (context, constraints) => SizedBox(
      width: constraints.hasBoundedWidth ? double.infinity : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: cardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onTap;
  const SectionTitle(this.title, {super.key, this.action, this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 24),
    child: Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -.3,
          ),
        ),
        const Spacer(),
        if (action != null)
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: Size.zero,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  action!,
                  style: const TextStyle(
                    color: AppColors.red,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const Icon(Icons.arrow_forward, size: 14, color: AppColors.red),
              ],
            ),
          ),
      ],
    ),
  );
}

class Pill extends StatelessWidget {
  final String text;
  final bool active;
  final bool selectedTint;
  const Pill(
    this.text, {
    super.key,
    this.active = false,
    this.selectedTint = false,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    decoration: BoxDecoration(
      color: active
          ? AppColors.red
          : selectedTint
          ? AppColors.redTint
          : AppColors.surfaceLow,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: active || selectedTint ? AppColors.red : Colors.transparent,
      ),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: active
            ? Colors.white
            : selectedTint
            ? AppColors.red
            : AppColors.muted,
      ),
    ),
  );
}

class StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  const StatusChip(this.text, this.color, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
    ),
  );
}

void push(BuildContext context, Widget page) =>
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));

class InfoRow extends StatelessWidget {
  final String a, b;
  const InfoRow(this.a, this.b, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            a,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ),
        Text(
          b,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ],
    ),
  );
}
