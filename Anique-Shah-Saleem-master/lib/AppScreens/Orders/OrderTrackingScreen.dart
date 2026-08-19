import 'package:flutter/material.dart';
import 'package:prac/res/app_theme.dart';
import 'package:prac/res/ui_kit.dart';

/// One step on the delivery timeline.
class TrackingStep {
  final String title;
  final String? timestamp;
  final String? detail;
  final bool isDone;

  /// The step the parcel is sitting at right now — drawn with a halo.
  final bool isCurrent;

  const TrackingStep({
    required this.title,
    this.timestamp,
    this.detail,
    this.isDone = false,
    this.isCurrent = false,
  });
}

/// Screen 13 — order tracking. A vertical timeline where completed steps are
/// filled vermilion and future steps are hollow.
class OrderTrackingScreen extends StatelessWidget {
  final String orderId;
  final List<TrackingStep>? steps;
  final String? itemSummary;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
    this.steps,
    this.itemSummary,
  });

  List<TrackingStep> get _steps =>
      steps ??
      const [
        TrackingStep(
            title: 'Order confirmed', timestamp: 'Step 1', isDone: true),
        TrackingStep(
            title: 'Packed by seller', timestamp: 'Step 2', isDone: true),
        TrackingStep(
          title: 'In transit',
          timestamp: 'Step 3',
          detail: 'On the way to your city',
          isDone: true,
          isCurrent: true,
        ),
        TrackingStep(title: 'Out for delivery'),
        TrackingStep(title: 'Delivered'),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              'Tracking',
              trailing: Text(orderId,
                  style: AppTheme.mono(13,
                      color: AppTheme.accent, tracking: 0.06)),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  for (var i = 0; i < _steps.length; i++)
                    _buildStep(_steps[i], isLast: i == _steps.length - 1),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSunken,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd + 2),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            itemSummary ?? 'Items in this order',
                            style: AppTheme.ui(15),
                          ),
                        ),
                        Text('Help',
                            style: AppTheme.ui(14,
                                color: AppTheme.accent,
                                weight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
              child: SecondaryButton(
                'Chat with support',
                onPressed: () => Navigator.maybePop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(TrackingStep step, {required bool isLast}) {
    final Color railColor =
        step.isDone ? AppTheme.accent : AppTheme.borderMedium;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rail: dot + connecting line
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: step.isDone ? AppTheme.accent : AppTheme.surface,
                  shape: BoxShape.circle,
                  border: step.isDone
                      ? null
                      : Border.all(color: AppTheme.borderStrong, width: 2),
                  boxShadow: step.isCurrent
                      ? [
                          const BoxShadow(
                            color: AppTheme.accentWash,
                            spreadRadius: 6,
                          ),
                        ]
                      : null,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: railColor),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Copy
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: AppTheme.ui(
                      16,
                      color: step.isDone
                          ? AppTheme.textPrimary
                          : AppTheme.textDisabled,
                      weight: step.isDone ? FontWeight.w600 : FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                  if (step.timestamp != null) ...[
                    const SizedBox(height: 4),
                    Text(step.timestamp!,
                        style: AppTheme.mono(13,
                            color: AppTheme.textMuted,
                            weight: FontWeight.w500,
                            tracking: 0)),
                  ],
                  if (step.detail != null) ...[
                    const SizedBox(height: 6),
                    Text(step.detail!,
                        style:
                            AppTheme.ui(14, color: AppTheme.textSecondary)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
