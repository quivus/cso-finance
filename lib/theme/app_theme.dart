import 'package:flutter/material.dart';

class AppPalette {
  final Brightness brightness;
  final Color bgDeep;
  final Color bgSurface;
  final Color bgSurfaceAlt;
  final Color bgSurfaceHigh;
  final Color primary;
  final Color primaryDim;
  final Color accentCyan;
  final Color accentAmber;
  final Color danger;
  final Color success;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;
  final List<Color> categoryPalette;

  const AppPalette({
    required this.brightness,
    required this.bgDeep,
    required this.bgSurface,
    required this.bgSurfaceAlt,
    required this.bgSurfaceHigh,
    required this.primary,
    required this.primaryDim,
    required this.accentCyan,
    required this.accentAmber,
    required this.danger,
    required this.success,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.categoryPalette,
    required Color bgTransparent,
  });

  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    bgTransparent: Colors.transparent,
    bgDeep: Color(0xFF060A1C),
    bgSurface: Color(0xFF0B1230),
    bgSurfaceAlt: Color(0xFF101A3D),
    bgSurfaceHigh: Color(0xFF16224E),
    primary: Color(0xFF1B3A6B),
    primaryDim: Color(0xFF13284A),
    accentCyan: Color(0xFF3E63A6),
    accentAmber: Color(0xFFFFB454),
    danger: Color(0xFFFF6B6B),
    success: Color(0xFF4ADE80),
    textPrimary: Color(0xFFEAF0FF),
    textSecondary: Color(0xFF8C9BC4),
    divider: Color(0xFF243266),
    categoryPalette: [
      Color(0xFF4C6FFF),
      Color.fromARGB(255, 40, 10, 109),
      Color(0xFFFFB454),
      Color(0xFF9C6BFF),
      Color(0xFF4ADE80),
      Color(0xFFFF6B9D),
      Color(0xFF5FA8FF),
      Color(0xFFF472B6),
    ],
  );

  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    bgTransparent: Colors.transparent,
    bgDeep: Color(0xFFF3F5FB),
    bgSurface: Color(0xFFFFFFFF),
    bgSurfaceAlt: Color(0xFFEEF1FA),
    bgSurfaceHigh: Color(0xFFE1E7F7),
    primary: Color(0xFF16305C),
    primaryDim: Color(0xFFB9C4DE),
    accentCyan: Color(0xFF2C4A80),
    accentAmber: Color(0xFFC97A1E),
    danger: Color(0xFFD8453F),
    success: Color(0xFF1F9D57),
    textPrimary: Color(0xFF12172E),
    textSecondary: Color(0xFF5B6480),
    divider: Color(0xFFDCE1F0),
    categoryPalette: [
      Color(0xFF3552E0),
      Color(0xFF0C93B0),
      Color(0xFFC97A1E),
      Color(0xFF7A48D6),
      Color(0xFF1F9D57),
      Color(0xFFD24E82),
      Color(0xFF2E6FCB),
      Color(0xFFC23F80),
    ],
  );

  LinearGradient get primaryGradient =>
      LinearGradient(colors: [primary, primary]);

  LinearGradient get heroGradient =>
      LinearGradient(colors: [bgSurface, bgSurface]);

  Color? get bgTransparent => null;
}

class _PaletteScope extends InheritedWidget {
  final AppPalette palette;

  const _PaletteScope({required this.palette, required super.child});

  @override
  bool updateShouldNotify(_PaletteScope oldWidget) =>
      oldWidget.palette != palette;
}

extension AppPaletteContext on BuildContext {
  AppPalette get colors {
    final scope = dependOnInheritedWidgetOfExactType<_PaletteScope>();
    return scope?.palette ?? AppPalette.dark;
  }
}

Widget appThemeScope(AppPalette palette, Widget child) {
  return _PaletteScope(
    palette: palette,
    child: Theme(data: buildAppTheme(palette), child: child),
  );
}

class AppThemeController {
  AppThemeController._();

  static final ValueNotifier<bool?> isDark = ValueNotifier<bool?>(null);

  static void set(bool value) {
    isDark.value = value;
  }
}

class AppScaffold extends StatelessWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool?>(
      valueListenable: AppThemeController.isDark,
      builder: (context, override, _) {
        final brightness = override == null
            ? MediaQuery.platformBrightnessOf(context)
            : (override ? Brightness.dark : Brightness.light);
        final palette = brightness == Brightness.dark
            ? AppPalette.dark
            : AppPalette.light;
        return appThemeScope(palette, child);
      },
    );
  }
}

class AppText {
  AppText._();

  static TextStyle display(BuildContext context) => TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
    color: context.colors.textPrimary,
    height: 1.1,
  );

  static TextStyle title(BuildContext context) => TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: context.colors.textPrimary,
  );

  static TextStyle subtitle(BuildContext context) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: context.colors.textSecondary,
  );

  static TextStyle body(BuildContext context) => TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w500,
    color: context.colors.textPrimary,
    height: 1.4,
  );

  static TextStyle bodyMuted(BuildContext context) => TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    color: context.colors.textSecondary,
    height: 1.4,
  );

  static TextStyle caption(BuildContext context) => TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.1,
    color: context.colors.textSecondary,
  );

  static TextStyle numeric(BuildContext context) => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: context.colors.textPrimary,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle numericLarge(BuildContext context) => TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    color: context.colors.textPrimary,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

ThemeData buildAppTheme(AppPalette palette) {
  return ThemeData(
    useMaterial3: true,
    brightness: palette.brightness,
    scaffoldBackgroundColor: palette.bgDeep,
    colorScheme: ColorScheme(
      brightness: palette.brightness,
      primary: palette.primary,
      onPrimary: Colors.white,
      secondary: palette.accentCyan,
      onSecondary: Colors.white,
      error: palette.danger,
      onError: Colors.white,
      surface: palette.bgSurface,
      onSurface: palette.textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.bgDeep,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: palette.textPrimary,
      ),
      iconTheme: IconThemeData(color: palette.textPrimary),
    ),
    dividerColor: palette.divider,
    splashFactory: InkRipple.splashFactory,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.bgSurfaceAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintStyle: TextStyle(
        color: palette.textSecondary,
        fontWeight: FontWeight.w500,
      ),
      labelStyle: TextStyle(
        color: palette.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: palette.divider, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: palette.primary, width: 1.8),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: palette.divider),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.bgSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titleTextStyle: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: palette.textPrimary,
      ),
      contentTextStyle: TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
        color: palette.textPrimary,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.bgSurfaceHigh,
      contentTextStyle: TextStyle(
        color: palette.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.textSecondary,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: palette.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    drawerTheme: DrawerThemeData(backgroundColor: palette.bgSurface),
  );
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.colors;
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? palette.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.divider, width: 1),
      ),
      child: child,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry padding;

  const SectionLabel(
    this.text, {
    super.key,
    this.padding = const EdgeInsets.fromLTRB(4, 0, 4, 10),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(text.toUpperCase(), style: AppText.caption(context)),
    );
  }
}

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.colors;
    final disabled = onPressed == null;
    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed,
          child: Container(
            width: expand ? double.infinity : null,
            padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: palette.primaryGradient,
              boxShadow: disabled
                  ? []
                  : [
                      BoxShadow(
                        color: palette.primary.withOpacity(0.35),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CategoryProgressBar extends StatelessWidget {
  final double progress;
  final Color color;

  const CategoryProgressBar({
    super.key,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Container(
                height: 6,
                width: constraints.maxWidth,
                color: palette.bgSurfaceHigh,
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                height: 6,
                width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: color.withOpacity(0.5), blurRadius: 6),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

IconData categoryIcon(String category) {
  switch (category) {
    case 'Event Operations & Materials':
      return Icons.event_available_rounded;
    case 'Promotional Material':
      return Icons.campaign_rounded;
    case 'Guest Tokens & Recognition':
      return Icons.card_giftcard_rounded;
    case 'Organizational Supplies':
      return Icons.inventory_2_rounded;
    case 'Emergency & Contingency Fund':
      return Icons.health_and_safety_rounded;
    case 'Training & Officer Development':
      return Icons.school_rounded;
    case 'Documentation':
      return Icons.description_rounded;
    case 'Savings & Future Projects':
      return Icons.savings_rounded;
    default:
      return Icons.folder_rounded;
  }
}

Color categoryColor(BuildContext context, int index) {
  final palette = context.colors;
  return palette.categoryPalette[index % palette.categoryPalette.length];
}

String formatCurrency(num value) {
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts[0];
  final isNegative = whole.startsWith('-');
  final digits = isNegative ? whole.substring(1) : whole;
  final buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    final posFromEnd = digits.length - i;
    buffer.write(digits[i]);
    if (posFromEnd > 1 && posFromEnd % 3 == 1) buffer.write(',');
  }
  return '${isNegative ? '-' : ''}₱${buffer.toString()}.${parts[1]}';
}

String formatDateTime(DateTime dt) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  final period = dt.hour >= 12 ? 'PM' : 'AM';
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year} · $hour12:$minute $period';
}
