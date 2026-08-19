import 'package:flutter/material.dart';

import 'package:prac/res/app_theme.dart';
import 'package:prac/res/ui_kit.dart';
import 'package:prac/services/api_service.dart';

/// One order as the seller sees it: only their own lines, the buyer's delivery
/// details, and the status ladder they can advance it along.
class SellerOrderDetail extends StatefulWidget {
  final Map<String, dynamic> order;

  const SellerOrderDetail({super.key, required this.order});

  @override
  State<SellerOrderDetail> createState() => _SellerOrderDetailState();
}

class _SellerOrderDetailState extends State<SellerOrderDetail> {
  /// Forward-only progression the seller drives.
  static const List<String> ladder = [
    'pending',
    'packed',
    'shipped',
    'delivered',
  ];

  late String _status;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _status = (widget.order['status'] ?? 'pending').toString();
  }

  String get _orderRef {
    final id = (widget.order['id'] ?? '').toString();
    return id.length <= 6 ? id : '#${id.substring(id.length - 6).toUpperCase()}';
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await ApiService.updateSellerOrderStatus(
        widget.order['id'].toString(),
        _status,
      );
      messenger.showSnackBar(
        SnackBar(content: Text('Order marked $_status')),
      );
      navigator.pop(true); // tell the dashboard to refresh
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = (widget.order['items'] as List?) ?? const [];
    final subtotal = (widget.order['seller_subtotal'] as num?)?.toDouble() ?? 0;
    final currentIndex = ladder.indexOf(_status);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      bottomNavigationBar: _buildSaveBar(),
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              'Order',
              trailing: Text(_orderRef, style: AppTheme.mono(12)),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildBuyerCard(),
                  const SizedBox(height: 18),
                  for (final item in items) ...[
                    _buildItemRow(item as Map<String, dynamic>),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Order total',
                            style: AppTheme.ui(15,
                                weight: FontWeight.w600)),
                      ),
                      Text(formatPkr(subtotal), style: AppTheme.display(22)),
                    ],
                  ),
                  const SizedBox(height: 26),
                  const Eyebrow('Update status'),
                  const SizedBox(height: 10),
                  for (var i = 0; i < ladder.length; i++) ...[
                    _buildStatusOption(i, currentIndex),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuyerCard() {
    final order = widget.order;
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text((order['buyer_name'] ?? 'Customer').toString(),
              style: AppTheme.ui(15, weight: FontWeight.w600)),
          if (order['buyer_address'] != null) ...[
            const SizedBox(height: 4),
            Text(order['buyer_address'].toString(),
                style: AppTheme.ui(13,
                    color: AppTheme.textSecondary, height: 1.45)),
          ],
          const SizedBox(height: 8),
          Text(
            [
              (order['payment_method'] ?? 'COD').toString(),
              if (order['buyer_phone'] != null) order['buyer_phone'].toString(),
            ].join(' · '),
            style: AppTheme.mono(11),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(Map<String, dynamic> item) {
    final images = (item['images'] as List?) ?? const [];
    final price = (item['price'] as num?)?.toDouble() ?? 0;
    final quantity = (item['quantity'] as num?)?.toInt() ?? 1;

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: ProductImage(
            images.isNotEmpty ? images.first.toString() : null,
            width: 46,
            height: 46,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text((item['name'] ?? '').toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.ui(14, weight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text('×$quantity', style: AppTheme.mono(11)),
            ],
          ),
        ),
        Text(formatPkr(price * quantity), style: AppTheme.display(16)),
      ],
    );
  }

  Widget _buildStatusOption(int index, int currentIndex) {
    final status = ladder[index];
    final isCurrent = status == _status;
    // Reached already, so shown as history rather than an action.
    final isPast = index < currentIndex;
    // Only the immediate next step is selectable; skipping stages would leave
    // the buyer's tracking history with holes in it.
    final isSelectable = index == currentIndex + 1;

    final label = isPast || isCurrent
        ? _titleCase(status)
        : 'Mark as $status';

    Color border;
    Color textColor;
    if (isCurrent) {
      border = AppTheme.accent;
      textColor = AppTheme.ink;
    } else if (isSelectable) {
      border = AppTheme.ink;
      textColor = AppTheme.ink;
    } else {
      border = AppTheme.borderSoft;
      textColor = AppTheme.textDisabled;
    }

    return GestureDetector(
      onTap: isSelectable ? () => setState(() => _status = status) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppTheme.surfaceRaised,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: border,
            width: isCurrent || isSelectable ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isPast || isCurrent
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 18,
              color: isCurrent
                  ? AppTheme.accent
                  : (isPast ? AppTheme.positive : textColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: AppTheme.ui(14,
                      color: textColor, weight: FontWeight.w500)),
            ),
            if (isCurrent)
              Text('CURRENT', style: AppTheme.mono(10, color: AppTheme.accent)),
          ],
        ),
      ),
    );
  }

  static String _titleCase(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

  Widget _buildSaveBar() {
    final unchanged = _status == (widget.order['status'] ?? 'pending').toString();

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.borderSoft)),
      ),
      child: SafeArea(
        top: false,
        child: PrimaryButton(
          'Save and notify buyer',
          isBusy: _isSaving,
          onPressed: unchanged ? null : _save,
        ),
      ),
    );
  }
}
