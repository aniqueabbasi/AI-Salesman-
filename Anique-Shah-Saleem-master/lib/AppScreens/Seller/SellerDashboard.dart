import 'package:flutter/material.dart';

import 'package:prac/AppScreens/Seller/AddProductScreen.dart';
import 'package:prac/AppScreens/Seller/SellerInventory.dart';
import 'package:prac/AppScreens/Seller/SellerOrderDetail.dart';
import 'package:prac/AppScreens/Seller/SellerProfile.dart';
import 'package:prac/AppScreens/Seller/SellerReports.dart';
import 'package:prac/models/Product.dart';
import 'package:prac/res/app_theme.dart';
import 'package:prac/res/ui_kit.dart';
import 'package:prac/screens/splash_screen.dart';
import 'package:prac/services/api_service.dart';
import 'package:prac/services/auth_service.dart';

/// Screen 16 — seller home. Revenue, the dispatch queue and stock health, all
/// scoped server-side to this seller. Customers never reach this screen; the
/// backend enforces the role on every write.
class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  static const int lowStockThreshold = 5;

  List<Product> _products = [];
  List<Map<String, dynamic>> _orders = [];
  Map<String, dynamic> _summary = const {};
  bool _isLoading = true;
  String? _error;
  String _shopName = 'My Shop';

  @override
  void initState() {
    super.initState();
    _loadSeller();
    _loadAll();
  }

  Future<void> _loadSeller() async {
    final shop = await AuthService.getShopName();
    if (!mounted) return;
    if (shop != null && shop.isNotEmpty) setState(() => _shopName = shop);
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Independent reads, so let them overlap rather than run in sequence.
      final results = await Future.wait([
        ApiService.getMyProducts(),
        ApiService.getSellerOrders(),
        ApiService.getSellerSummary(),
      ]);
      if (!mounted) return;
      setState(() {
        _products = results[0] as List<Product>;
        _orders = results[1] as List<Map<String, dynamic>>;
        _summary = results[2] as Map<String, dynamic>;
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

  Future<void> _openAddProduct() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    );
    if (created == true) {
      await _loadAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product published to the storefront')),
      );
    }
  }

  Future<void> _openOrder(Map<String, dynamic> order) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => SellerOrderDetail(order: order)),
    );
    if (changed == true) await _loadAll();
  }

  Future<void> _confirmLogout() async {
    final navigator = Navigator.of(context);
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: Text('Log out', style: AppTheme.display(22)),
        content: Text('Sign out of this shop?',
            style: AppTheme.ui(15, color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel',
                style: AppTheme.ui(15, color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Log out',
                style: AppTheme.ui(15,
                    color: AppTheme.accentPressed, weight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await AuthService.clearToken();
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    }
  }

  /// `412000` -> `412k`, so the tile never wraps.
  String _compact(num value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}m';
    if (value >= 1000) return '${(value / 1000).round()}k';
    return value.round().toString();
  }

  List<Product> get _lowStock => _products
      .where((p) => (p.stock ?? 0) <= lowStockThreshold)
      .toList()
    ..sort((a, b) => (a.stock ?? 0).compareTo(b.stock ?? 0));

  List<Map<String, dynamic>> get _toFulfil => _orders
      .where((o) => const {'pending', 'packed', 'confirmed', 'processing'}
          .contains((o['status'] ?? '').toString()))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddProduct,
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.add, size: 20),
        label: Text('New listing',
            style: AppTheme.ui(15,
                color: Colors.white, weight: FontWeight.w600, height: 1.0)),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : RefreshIndicator(
                    onRefresh: _loadAll,
                    color: AppTheme.accent,
                    child: _buildBody(),
                  ),
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
            Text(_error!,
                textAlign: TextAlign.center,
                style: AppTheme.ui(14, color: AppTheme.textSecondary)),
            const SizedBox(height: 20),
            SizedBox(
                width: 170, child: PrimaryButton('Retry', onPressed: _loadAll)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final revenue = (_summary['revenue_30d'] as num?)?.toDouble() ?? 0;
    final change = _summary['revenue_change_pct'] as num?;
    final ordersTotal = (_summary['orders_total'] as num?)?.toInt() ?? 0;
    final toDispatch = (_summary['to_dispatch'] as num?)?.toInt() ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 96),
      physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics()),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Eyebrow('Seller dashboard'),
                  const SizedBox(height: 4),
                  Text(_shopName,
                      style: AppTheme.display(30),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            GestureDetector(
              onTap: _confirmLogout,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.logout, size: 20, color: AppTheme.textMuted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        // IntrinsicHeight gives the Row a bounded cross-axis extent. Without
        // it, `stretch` inside a vertically scrolling list resolves to an
        // infinite height and the whole subtree fails to lay out.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Revenue · 30d',
                  value: 'Rs ${_compact(revenue)}',
                  footnote: change == null
                      ? 'no prior period'
                      : '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                  footnoteIsPositive: change == null ? null : change >= 0,
                  dark: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  label: 'Orders',
                  value: '$ordersTotal',
                  footnote: '$toDispatch to dispatch',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        SectionHeader(
          'Orders to fulfil',
          trailing: _orders.isEmpty ? null : 'See all',
          onTrailingTap: _orders.isEmpty
              ? null
              : () => _showAllOrders(),
        ),
        const SizedBox(height: 10),
        if (_toFulfil.isEmpty)
          _buildEmpty('Nothing waiting to ship.')
        else
          for (final order in _toFulfil.take(3)) ...[
            _buildOrderRow(order),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 26),
        SectionHeader(
          'Low stock',
          trailing: '${_lowStock.length}',
          trailingIsMono: true,
        ),
        const SizedBox(height: 10),
        if (_lowStock.isEmpty)
          _buildEmpty('Every listing is comfortably stocked.')
        else
          for (final product in _lowStock.take(4)) ...[
            _buildLowStockRow(product),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  void _showAllOrders() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 12),
                child: Row(
                  children: [
                    Expanded(
                        child: Text('All orders',
                            style: AppTheme.display(24))),
                    Text('${_orders.length}', style: AppTheme.mono(12)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
                  itemCount: _orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _buildOrderRow(_orders[index], popFirst: true),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderRow(Map<String, dynamic> order, {bool popFirst = false}) {
    final id = (order['id'] ?? '').toString();
    final ref = id.length <= 6
        ? id
        : '#${id.substring(id.length - 6).toUpperCase()}';
    final items = (order['items'] as List?) ?? const [];
    final units = items.fold<int>(
        0, (sum, i) => sum + (((i as Map)['quantity'] as num?)?.toInt() ?? 0));
    final subtotal = (order['seller_subtotal'] as num?)?.toDouble() ?? 0;
    final status = (order['status'] ?? 'pending').toString();

    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () {
        if (popFirst) Navigator.pop(context);
        _openOrder(order);
      },
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ref, style: AppTheme.mono(11)),
                const SizedBox(height: 4),
                Text(
                  '$units item${units == 1 ? '' : 's'} · ${formatPkr(subtotal)}',
                  style: AppTheme.ui(14, weight: FontWeight.w500),
                ),
              ],
            ),
          ),
          StatusTag(status, tone: _toneFor(status)),
        ],
      ),
    );
  }

  static StatusTone _toneFor(String status) {
    switch (status) {
      case 'pending':
        return StatusTone.accent;
      case 'delivered':
        return StatusTone.positive;
      default:
        return StatusTone.neutral;
    }
  }

  Widget _buildLowStockRow(Product product) {
    final stock = product.stock ?? 0;
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SellerInventory()),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: ProductImage(
              product.images.isNotEmpty ? product.images.first : null,
              width: 38,
              height: 38,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.ui(14, weight: FontWeight.w500),
            ),
          ),
          Text(
            stock <= 0 ? 'out' : '$stock left',
            style: AppTheme.mono(11,
                color: stock <= 0
                    ? AppTheme.accentPressed
                    : AppTheme.accent),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSunken,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Text(message,
          textAlign: TextAlign.center,
          style: AppTheme.ui(13, color: AppTheme.textMuted)),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.borderSoft)),
      ),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.ink,
        unselectedItemColor: AppTheme.textMuted,
        selectedLabelStyle: AppTheme.ui(11, weight: FontWeight.w500),
        unselectedLabelStyle: AppTheme.ui(11),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined), label: 'Listings'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined), label: 'Reports'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
        onTap: (index) {
          switch (index) {
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SellerInventory()),
              ).then((_) => _loadAll());
              break;
            case 2:
              if (_orders.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No orders yet.')),
                );
              } else {
                _showAllOrders();
              }
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SellerReports()),
              );
              break;
            case 4:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SellerProfile()),
                // The shop name may have changed, so refresh the header.
              ).then((_) {
                _loadSeller();
                _loadAll();
              });
              break;
            default:
              break;
          }
        },
      ),
    );
  }
}

/// Headline metric tile. The dark variant carries the primary figure.
class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String footnote;
  final bool dark;
  final bool? footnoteIsPositive;

  const _StatTile({
    required this.label,
    required this.value,
    required this.footnote,
    this.dark = false,
    this.footnoteIsPositive,
  });

  @override
  Widget build(BuildContext context) {
    final Color footnoteColor;
    if (footnoteIsPositive == null) {
      footnoteColor = dark ? AppTheme.darkTextMuted : AppTheme.textMuted;
    } else if (footnoteIsPositive!) {
      footnoteColor = dark ? AppTheme.positiveOnDark : AppTheme.positive;
    } else {
      footnoteColor = AppTheme.accent;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: dark ? AppTheme.ink : AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
            color: dark ? AppTheme.ink : AppTheme.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase(),
              style: AppTheme.mono(10,
                  color: dark ? AppTheme.darkTextMuted : AppTheme.textMuted)),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: AppTheme.display(28,
                    color: dark ? AppTheme.darkTextBright : AppTheme.ink)),
          ),
          const SizedBox(height: 6),
          Text(footnote, style: AppTheme.mono(10, color: footnoteColor)),
        ],
      ),
    );
  }
}
