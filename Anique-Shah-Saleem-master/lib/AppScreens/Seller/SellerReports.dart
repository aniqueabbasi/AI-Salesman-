import 'package:flutter/material.dart';

import 'package:prac/res/app_theme.dart';
import 'package:prac/res/ui_kit.dart';
import 'package:prac/services/api_service.dart';

/// Sales performance for the signed-in seller. Every figure is computed
/// server-side from that seller's own order lines.
class SellerReports extends StatefulWidget {
  const SellerReports({super.key});

  @override
  State<SellerReports> createState() => _SellerReportsState();
}

class _SellerReportsState extends State<SellerReports> {
  Map<String, dynamic>? _report;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final report = await ApiService.getSellerReport();
      if (!mounted) return;
      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  /// `412000` -> `412k`, so a headline figure never wraps.
  String _compact(num value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}m';
    }
    if (value >= 1000) {
      return '${(value / 1000).round()}k';
    }
    return value.round().toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.accent))
            : _error.isNotEmpty
                ? _buildError()
                : _buildReport(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error,
                textAlign: TextAlign.center,
                style: AppTheme.ui(14, color: AppTheme.darkTextSecondary)),
            const SizedBox(height: 20),
            SizedBox(
                width: 170, child: PrimaryButton('Retry', onPressed: _load)),
          ],
        ),
      ),
    );
  }

  Widget _buildReport() {
    final report = _report!;
    final series = ((report['series'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();
    final topSellers = ((report['top_sellers'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();
    final revenue = (report['revenue_total'] as num?)?.toDouble() ?? 0;
    final aov = (report['aov'] as num?)?.toDouble() ?? 0;
    final returns = (report['returns_pct'] as num?)?.toDouble() ?? 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: const Icon(Icons.arrow_back,
                    color: AppTheme.darkTextBright, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text('Reports · last 30 days'.toUpperCase(),
                    style: AppTheme.mono(11, color: AppTheme.darkTextMuted)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
            physics: const BouncingScrollPhysics(),
            children: [
              Text('Sales',
                  style: AppTheme.display(34, color: AppTheme.darkTextBright)),
              const SizedBox(height: 20),
              _buildChartCard(series, revenue),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _DarkTile(
                      label: 'AOV',
                      value: formatPkr(aov),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DarkTile(
                      label: 'Returns',
                      value: '${returns.toStringAsFixed(1)}%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Text('Top sellers'.toUpperCase(),
                  style: AppTheme.mono(11, color: AppTheme.darkTextMuted)),
              const SizedBox(height: 12),
              if (topSellers.isEmpty)
                Text('No sales recorded yet.',
                    style: AppTheme.ui(14, color: AppTheme.darkTextMuted))
              else
                for (var i = 0; i < topSellers.length; i++) ...[
                  _buildTopSellerRow(i, topSellers[i]),
                  if (i < topSellers.length - 1) const SizedBox(height: 14),
                ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard(List<Map<String, dynamic>> series, double revenue) {
    final values =
        series.map((s) => (s['value'] as num?)?.toDouble() ?? 0).toList();
    final peak = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a > b ? a : b);
    // The final bars are the most recent weeks, highlighted like the design.
    final highlightFrom = values.length - 2;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceAlt,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rs ${_compact(revenue)}',
              style: AppTheme.display(30, color: AppTheme.darkTextBright)),
          const SizedBox(height: 18),
          SizedBox(
            height: 132,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < values.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        children: [
                          // The bar takes whatever height is left once the
                          // label has been laid out, so the column can never
                          // exceed its box however tall the label renders.
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                widthFactor: 1,
                                // Floor of 4% so an empty week still reads as
                                // a bar rather than vanishing off the axis.
                                heightFactor: peak <= 0
                                    ? 0.04
                                    : (values[i] / peak).clamp(0.04, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: i >= highlightFrom
                                        ? AppTheme.accent
                                        : AppTheme.darkBorderStrong,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            (series[i]['label'] ?? '').toString(),
                            style: AppTheme.mono(9,
                                color: AppTheme.darkTextMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSellerRow(int index, Map<String, dynamic> entry) {
    return Row(
      children: [
        Text('${index + 1}'.padLeft(2, '0'),
            style: AppTheme.mono(11, color: AppTheme.darkTextMuted)),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            (entry['name'] ?? 'Unknown').toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.ui(14, color: AppTheme.darkTextPrimary),
          ),
        ),
        Text('${entry['units'] ?? 0}',
            style: AppTheme.mono(12, color: AppTheme.darkTextBright)),
      ],
    );
  }
}

class _DarkTile extends StatelessWidget {
  final String label;
  final String value;

  const _DarkTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceAlt,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: AppTheme.mono(10, color: AppTheme.darkTextMuted)),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: AppTheme.display(22, color: AppTheme.darkTextBright)),
          ),
        ],
      ),
    );
  }
}
