import 'package:flutter/material.dart';

import 'package:prac/models/Product.dart';
import 'package:prac/res/app_theme.dart';
import 'package:prac/res/ui_kit.dart';
import 'package:prac/services/api_service.dart';

/// Stock levels across the seller's listings, edited in bulk and saved in one
/// pass so a long adjustment session is a single round of writes.
class SellerInventory extends StatefulWidget {
  const SellerInventory({super.key});

  @override
  State<SellerInventory> createState() => _SellerInventoryState();
}

enum _StockFilter { all, low, out }

class _SellerInventoryState extends State<SellerInventory> {
  static const int lowStockThreshold = 5;

  List<Product> _products = [];
  final Map<String, int> _edited = {};
  _StockFilter _filter = _StockFilter.all;
  bool _isLoading = true;
  bool _isSaving = false;
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
      final products = await ApiService.getMyProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _edited.clear();
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

  int _stockOf(Product p) => _edited[p.id] ?? p.stock ?? 0;

  List<Product> get _visible {
    switch (_filter) {
      case _StockFilter.low:
        return _products
            .where((p) => _stockOf(p) > 0 && _stockOf(p) <= lowStockThreshold)
            .toList();
      case _StockFilter.out:
        return _products.where((p) => _stockOf(p) <= 0).toList();
      case _StockFilter.all:
        return _products;
    }
  }

  void _adjust(Product product, int delta) {
    final next = _stockOf(product) + delta;
    if (next < 0) return;
    setState(() => _edited[product.id] = next);
  }

  Future<void> _save() async {
    if (_edited.isEmpty) return;
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      // Sequential rather than parallel: the mock store writes the whole
      // collection on every change, so overlapping writes can lose an update.
      for (final entry in _edited.entries) {
        await ApiService.updateProductStock(entry.key, entry.value);
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Updated stock on ${_edited.length} listings')),
      );
      await _load();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      bottomNavigationBar: _edited.isEmpty ? null : _buildSaveBar(),
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              'Inventory',
              trailing: Text('${_products.length} SKUs',
                  style: AppTheme.mono(12)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 10),
              child: Row(
                children: [
                  FilterPill('All',
                      selected: _filter == _StockFilter.all,
                      onTap: () =>
                          setState(() => _filter = _StockFilter.all)),
                  const SizedBox(width: 8),
                  FilterPill('Low',
                      selected: _filter == _StockFilter.low,
                      onTap: () =>
                          setState(() => _filter = _StockFilter.low)),
                  const SizedBox(width: 8),
                  FilterPill('Out',
                      selected: _filter == _StockFilter.out,
                      onTap: () =>
                          setState(() => _filter = _StockFilter.out)),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error,
                  textAlign: TextAlign.center,
                  style: AppTheme.ui(14, color: AppTheme.textSecondary)),
              const SizedBox(height: 18),
              SizedBox(
                  width: 170,
                  child: PrimaryButton('Retry', onPressed: _load)),
            ],
          ),
        ),
      );
    }

    final visible = _visible;
    if (visible.isEmpty) {
      return Center(
        child: Text(
          _products.isEmpty
              ? 'No listings yet.'
              : 'Nothing in this bucket.',
          style: AppTheme.ui(14, color: AppTheme.textMuted),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
      physics: const BouncingScrollPhysics(),
      itemCount: visible.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final product = visible[index];
        final stock = _stockOf(product);
        final isOut = stock <= 0;
        final isLow = !isOut && stock <= lowStockThreshold;

        return SurfaceCard(
          borderColor: _edited.containsKey(product.id)
              ? AppTheme.accentWashBorder
              : null,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                child: ProductImage(
                  product.images.isNotEmpty ? product.images.first : null,
                  width: 46,
                  height: 46,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.ui(14,
                          weight: FontWeight.w600, height: 1.2),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isOut
                          ? 'OUT OF STOCK'
                          : (isLow ? 'LOW STOCK' : (product.category ?? '')),
                      style: AppTheme.mono(
                        10,
                        color: isOut
                            ? AppTheme.accentPressed
                            : (isLow ? AppTheme.accent : AppTheme.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
              _StockStepper(
                value: stock,
                onDecrement: () => _adjust(product, -1),
                onIncrement: () => _adjust(product, 1),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSaveBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.borderSoft)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.ink,
              disabledBackgroundColor: AppTheme.ink.withValues(alpha: 0.5),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text('Save stock changes (${_edited.length})',
                    style: AppTheme.ui(16,
                        color: Colors.white,
                        weight: FontWeight.w600,
                        height: 1.0)),
          ),
        ),
      ),
    );
  }
}

class _StockStepper extends StatelessWidget {
  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _StockStepper({
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: AppTheme.surfaceSunken,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepIcon(icon: Icons.remove, onTap: onDecrement),
          SizedBox(
            width: 30,
            child: Center(
              child: Text('$value',
                  style: AppTheme.mono(12, color: AppTheme.ink)),
            ),
          ),
          _StepIcon(icon: Icons.add, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _StepIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 32,
        height: 34,
        child: Icon(icon, size: 15, color: AppTheme.ink),
      ),
    );
  }
}
