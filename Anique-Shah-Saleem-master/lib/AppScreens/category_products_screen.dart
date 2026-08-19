import 'package:flutter/material.dart';

import 'package:prac/AppScreens/ProductDetailPage.dart';
import 'package:prac/models/Product.dart';
import 'package:prac/res/app_theme.dart';
import 'package:prac/res/ui_kit.dart';
import 'package:prac/services/api_service.dart';

// Import dummy products
import 'package:prac/AppScreens/ShopMenu/dummy_products.dart'
    show dummyShirts, dummyJeans, dummyShoes, dummyJackets;

/// How the list is ordered. `none` keeps the catalogue's own order.
enum _PriceSort { none, lowToHigh, highToLow }

class CategoryProductsScreen extends StatefulWidget {
  final String category;

  const CategoryProductsScreen({Key? key, required this.category})
      : super(key: key);

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  List<Product> _products = [];
  bool _isLoading = true;
  String _errorMessage = '';

  _PriceSort _priceSort = _PriceSort.none;
  bool _inStockOnly = false;
  String? _size;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final category = widget.category.toLowerCase().trim();

      late final List<Product> loaded;
      if (category == 'jeans' || category == 'jean') {
        loaded = dummyJeans;
      } else if (category == 'shirts' || category == 'shirt') {
        loaded = dummyShirts;
      } else if (category == 'jackets' || category == 'jacket') {
        loaded = dummyJackets;
      } else if (category == 'shoes' || category == 'shoe') {
        loaded = dummyShoes;
      } else {
        loaded = await ApiService.getProductsByCategory(widget.category);
      }

      if (!mounted) return;
      setState(() => _products = loaded);
    } catch (e) {
      debugPrint('Error while loading products: $e');
      if (!mounted) return;
      setState(() => _errorMessage = 'Failed to load products. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Every size offered across the loaded catalogue, used to populate the
  /// size filter sheet.
  List<String> get _availableSizes {
    final sizes = <String>{};
    for (final p in _products) {
      sizes.addAll(p.sizes ?? const []);
    }
    final list = sizes.toList()..sort();
    return list;
  }

  List<Product> get _visibleProducts {
    var list = List<Product>.from(_products);

    if (_inStockOnly) {
      // stock is null for the bundled catalogue; treat unknown as available.
      list = list.where((p) => (p.stock ?? 1) > 0).toList();
    }
    if (_size != null) {
      list = list.where((p) => (p.sizes ?? const []).contains(_size)).toList();
    }
    switch (_priceSort) {
      case _PriceSort.lowToHigh:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case _PriceSort.highToLow:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case _PriceSort.none:
        break;
    }
    return list;
  }

  void _cyclePriceSort() {
    setState(() {
      if (_priceSort == _PriceSort.none) {
        _priceSort = _PriceSort.lowToHigh;
      } else if (_priceSort == _PriceSort.lowToHigh) {
        _priceSort = _PriceSort.highToLow;
      } else {
        _priceSort = _PriceSort.none;
      }
    });
  }

  String get _priceLabel {
    if (_priceSort == _PriceSort.lowToHigh) return 'Price ↑';
    if (_priceSort == _PriceSort.highToLow) return 'Price ↓';
    return 'Price';
  }

  Future<void> _pickSize() async {
    final sizes = _availableSizes;
    if (sizes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No size data for these products')),
      );
      return;
    }

    final picked = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Size', style: AppTheme.display(24)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in sizes)
                    FilterPill(
                      s,
                      selected: s == _size,
                      onTap: () => Navigator.pop(context, s),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              SecondaryButton(
                'Clear size',
                onPressed: () => Navigator.pop(context, null),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;
    // A dismissed sheet returns null too; only act when the sheet was used.
    setState(() => _size = picked);
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleProducts;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              widget.category,
              trailing: Text(
                '${visible.length} items',
                style: AppTheme.mono(12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 10),
              child: Row(
                children: [
                  FilterPill(
                    _priceLabel,
                    selected: _priceSort != _PriceSort.none,
                    onTap: _cyclePriceSort,
                  ),
                  const SizedBox(width: 8),
                  FilterPill(
                    _size ?? 'Size',
                    selected: _size != null,
                    onTap: _pickSize,
                  ),
                  const SizedBox(width: 8),
                  FilterPill(
                    'In stock',
                    selected: _inStockOnly,
                    onTap: () => setState(() => _inStockOnly = !_inStockOnly),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody(visible)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<Product> visible) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage,
                  textAlign: TextAlign.center,
                  style: AppTheme.ui(15, color: AppTheme.textSecondary)),
              const SizedBox(height: 20),
              SizedBox(
                  width: 180,
                  child: PrimaryButton('Retry', onPressed: _loadProducts)),
            ],
          ),
        ),
      );
    }

    if (visible.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inventory_2_outlined,
                  size: 32, color: AppTheme.textMuted),
              const SizedBox(height: 12),
              Text('Nothing matches', style: AppTheme.display(20)),
              const SizedBox(height: 6),
              Text(
                'Try clearing a filter to see more of this category.',
                textAlign: TextAlign.center,
                style: AppTheme.ui(14, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
      physics: const BouncingScrollPhysics(),
      itemCount: visible.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _ProductRow(product: visible[index]),
    );
  }
}

/// One row of the category list: thumbnail, name, shop, price and stock.
class _ProductRow extends StatelessWidget {
  final Product product;

  const _ProductRow({required this.product});

  @override
  Widget build(BuildContext context) {
    final stock = product.stock;
    final String stockLabel;
    if (stock == null) {
      stockLabel = '';
    } else if (stock <= 0) {
      stockLabel = 'Out of stock';
    } else {
      stockLabel = '$stock left';
    }

    return SurfaceCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: ProductImage(
              product.images.isNotEmpty ? product.images.first : null,
              width: 66,
              height: 78,
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
                  style: AppTheme.ui(15, weight: FontWeight.w600, height: 1.2),
                ),
                const SizedBox(height: 2),
                Text(
                  product.shopName?.trim().isNotEmpty == true
                      ? product.shopName!
                      : (product.category ?? ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.ui(13, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 8),
                Text(formatPkr(product.price), style: AppTheme.display(18)),
                if (stockLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    stockLabel,
                    style: AppTheme.mono(
                      11,
                      color: stock != null && stock <= 0
                          ? AppTheme.accentPressed
                          : AppTheme.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (product.discount > 0)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: StatusTag('-${product.discount}%',
                  tone: StatusTone.accent),
            ),
        ],
      ),
    );
  }
}
