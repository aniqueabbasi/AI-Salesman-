import 'package:flutter/material.dart';
import 'package:prac/AppScreens/Orders/OrderTrackingScreen.dart';
import 'package:prac/res/app_theme.dart';
import 'package:prac/res/ui_kit.dart';

/// Screen 12 — order confirmation. Dark surface so it reads as a moment of
/// completion rather than another list.
class OrderPlacedScreen extends StatelessWidget {
  final String orderId;
  final double total;
  final String? arrivalWindow;

  const OrderPlacedScreen({
    super.key,
    required this.orderId,
    required this.total,
    this.arrivalWindow,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 56, 30, 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppTheme.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 34, color: Colors.white),
              ),
              const SizedBox(height: 30),
              Text('Order placed',
                  style: AppTheme.display(44,
                      color: AppTheme.darkTextBright, height: 1.0)),
              const SizedBox(height: 16),
              Text(
                'A push notification will land at every tracking update.',
                style: AppTheme.ui(17,
                    color: AppTheme.darkTextSecondary, height: 1.55),
              ),
              const SizedBox(height: 34),

              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                ),
                child: Column(
                  children: [
                    _row(
                      label: 'ORDER ID',
                      valueWidget: Text(orderId,
                          style: AppTheme.mono(16,
                              color: AppTheme.accent, tracking: 0.06)),
                      labelIsMono: true,
                    ),
                    const SizedBox(height: 18),
                    _row(
                      label: 'Paid',
                      valueWidget: Text(formatPkr(total),
                          style: AppTheme.display(24,
                              color: AppTheme.darkTextBright)),
                    ),
                    const SizedBox(height: 14),
                    _row(
                      label: 'Arrives',
                      valueWidget: Text(
                        arrivalWindow ?? _defaultWindow(),
                        style: AppTheme.ui(15, color: AppTheme.darkTextBright),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),
              PrimaryButton(
                'Track order',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderTrackingScreen(orderId: orderId),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                'Keep shopping',
                onDark: true,
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Two-to-four days out, formatted the way the design shows it.
  String _defaultWindow() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    final from = now.add(const Duration(days: 2));
    final to = now.add(const Duration(days: 4));
    String fmt(DateTime d) =>
        '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
    return '${fmt(from)} → ${fmt(to)}';
  }

  Widget _row({
    required String label,
    required Widget valueWidget,
    bool labelIsMono = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: labelIsMono
              ? AppTheme.mono(12, color: AppTheme.darkTextMuted, tracking: 0.12)
              : AppTheme.ui(15, color: AppTheme.darkTextSecondary),
        ),
        const Spacer(),
        Flexible(child: valueWidget),
      ],
    );
  }
}
