import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Reusable pieces of the AI Salesman design system.
///
/// Screens compose these rather than re-deriving paddings, radii and colours,
/// so the flow stays consistent as it grows.

/// Small uppercase mono label that sits above a section or form field.
class Eyebrow extends StatelessWidget {
  final String text;
  final Color? color;

  const Eyebrow(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTheme.mono(12, color: color ?? AppTheme.textMuted),
    );
  }
}

/// Section title with an optional trailing action or mono tag.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;
  final bool trailingIsMono;

  const SectionHeader(
    this.title, {
    super.key,
    this.trailing,
    this.onTrailingTap,
    this.trailingIsMono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: Text(title, style: AppTheme.display(20))),
        if (trailing != null)
          GestureDetector(
            onTap: onTrailingTap,
            child: Text(
              trailing!,
              style: trailingIsMono
                  ? AppTheme.mono(12, color: AppTheme.accent)
                  : AppTheme.ui(14,
                      color: AppTheme.accent, weight: FontWeight.w500),
            ),
          ),
      ],
    );
  }
}

/// Full-width vermilion call to action. One per screen.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isBusy;
  final IconData? icon;

  const PrimaryButton(
    this.label, {
    super.key,
    this.onPressed,
    this.isBusy = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isBusy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accent,
          disabledBackgroundColor: AppTheme.accent.withValues(alpha: 0.55),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd + 2),
          ),
        ),
        child: isBusy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: Colors.white),
                    const SizedBox(width: 10),
                  ],
                  Text(label,
                      style: AppTheme.ui(17,
                          color: Colors.white,
                          weight: FontWeight.w600,
                          height: 1.0)),
                ],
              ),
      ),
    );
  }
}

/// Outlined secondary action. Ink on light screens, light on dark screens.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool onDark;

  const SecondaryButton(
    this.label, {
    super.key,
    this.onPressed,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = onDark ? AppTheme.darkTextBright : AppTheme.ink;
    final border = onDark ? AppTheme.darkBorderStrong : AppTheme.ink;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          side: BorderSide(color: border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd + 2),
          ),
        ),
        child: Text(label,
            style:
                AppTheme.ui(17, color: fg, weight: FontWeight.w500, height: 1.0)),
      ),
    );
  }
}

/// Pill filter used for categories and list filters.
class FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const FilterPill(
    this.label, {
    super.key,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.ink : AppTheme.surfaceSunken,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Text(
          label,
          style: AppTheme.ui(
            14,
            color: selected ? AppTheme.surface : AppTheme.textSecondary,
            weight: selected ? FontWeight.w500 : FontWeight.w400,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

/// Small status tag - PACKED / NEW / SHIPPED / LOW STOCK.
class StatusTag extends StatelessWidget {
  final String label;
  final StatusTone tone;

  const StatusTag(this.label, {super.key, this.tone = StatusTone.neutral});

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    switch (tone) {
      case StatusTone.accent:
        bg = AppTheme.accentWash;
        fg = AppTheme.accentPressed;
        break;
      case StatusTone.positive:
        bg = const Color(0xFFE7F3F0);
        fg = AppTheme.positive;
        break;
      case StatusTone.neutral:
        bg = AppTheme.surfaceSunken;
        fg = AppTheme.textSecondary;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(label.toUpperCase(),
          style: AppTheme.mono(12, color: fg, tracking: 0.06)),
    );
  }
}

enum StatusTone { neutral, accent, positive }

/// Card surface used across lists and grids.
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final VoidCallback? onTap;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: AppTheme.surfaceRaised,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: borderColor ?? AppTheme.borderSoft),
        ),
        child: child,
      ),
    );
  }
}

/// Renders a product image from a network URL or a bundled asset, with a
/// consistent placeholder while loading and on failure.
class ProductImage extends StatelessWidget {
  final String? source;
  final double? width;
  final double? height;
  final BoxFit fit;

  const ProductImage(
    this.source, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final src = source?.trim();

    Widget fallback([IconData icon = Icons.image_outlined]) => Container(
          width: width,
          height: height,
          color: AppTheme.surfaceSunken,
          alignment: Alignment.center,
          child: Icon(icon, color: AppTheme.borderStrong, size: 28),
        );

    if (src == null || src.isEmpty) return fallback();

    if (src.startsWith('http')) {
      return Image.network(
        src,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: width,
            height: height,
            color: AppTheme.surfaceSunken,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (_, __, ___) => fallback(Icons.broken_image_outlined),
      );
    }

    return Image.asset(
      src,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => fallback(Icons.broken_image_outlined),
    );
  }
}

/// Back chevron + title row used as a lightweight screen header.
class ScreenHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final bool showBack;

  const ScreenHeader(
    this.title, {
    super.key,
    this.trailing,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderSoft)),
      ),
      child: Row(
        children: [
          if (showBack) ...[
            GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: const Icon(Icons.arrow_back, color: AppTheme.ink, size: 22),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(child: Text(title, style: AppTheme.display(26))),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Formats a rupee amount the way the design does: `₨ 2,990`.
String formatPkr(num value) {
  final whole = value.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) buf.write(',');
    buf.write(whole[i]);
  }
  return '₨ $buf';
}
