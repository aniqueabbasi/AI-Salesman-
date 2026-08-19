import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prac/AppScreens/CartPage.dart';
import 'package:prac/Authentication/Login.dart';
import 'package:prac/Controller/CartProvider.dart';
import 'package:prac/models/Product.dart';
import 'package:prac/res/app_theme.dart';
import 'package:prac/res/ui_kit.dart';
import 'package:prac/services/api_service.dart';
import 'package:prac/widgets/cart_badge_icon.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  final String? heroTag;
  final String? assetImage;

  const ProductDetailPage(
      {super.key, required this.product, this.heroTag, this.assetImage});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  var selectedSize = '';
  int quantity = 1;
  double userRating = 0; // Holds user-selected rating
  List<String> sizes = ['S', 'M', 'L', 'XL', 'XXL']; // Default sizes

  // Recommendation state
  List<Product> recommendedProducts = [];
  bool isLoadingRecommendations = false;
  String recommendationsError = '';

  /// Copy for the bundled demo artwork, used when a product carries no
  /// description of its own.
  static const Map<String, String> _assetDescriptions = {
    'assets/images/jean1.jpg':
        'Comfortable and stylish blue jeans for everyday wear.',
    'assets/images/green.jpg': 'Fresh green shirt for a smart casual look.',
    'assets/images/casual.jpg': 'Soft and comfy t-shirt for relaxed days.',
    'assets/images/m2.jpg': 'Trendy jacket to keep you warm and stylish.',
    'assets/images/m3.jpg': 'Perfect hoodie for urban adventures.',
    'assets/images/jean2.jpg': 'Slim fit jeans for a modern look.',
  };

  @override
  void initState() {
    super.initState();
    // Set appropriate sizes based on product category
    if (widget.product.sizes != null && widget.product.sizes!.isNotEmpty) {
      sizes = widget.product.sizes!;
    } else if (widget.product.category?.toLowerCase() == 'shoes') {
      sizes = ['7', '8', '9', '10', '11', '12'];
    } else if (widget.product.category?.toLowerCase() == 'jeans') {
      sizes = ['28', '30', '32', '34', '36', '38'];
    }

    if (sizes.isNotEmpty) {
      selectedSize = sizes[0];
    }
    fetchRecommendations();

    userRating = widget.product.details != null &&
            widget.product.details!['rating'] != null
        ? (widget.product.details!['rating'] as num).toDouble()
        : 4.5;
  }

  Future<void> fetchRecommendations() async {
    if (widget.product.category == null) return;
    setState(() {
      isLoadingRecommendations = true;
      recommendationsError = '';
    });
    try {
      final recs =
          await ApiService.getRecommendations(widget.product.category!);
      final List<Product> extracted = [];
      for (var rec in recs) {
        if (rec.id != widget.product.id) {
          extracted.add(rec);
          if (extracted.length >= 10) break;
        }
      }
      if (!mounted) return;
      setState(() {
        recommendedProducts = extracted;
        isLoadingRecommendations = false;
      });
    } catch (e) {
      debugPrint('[DEBUG] Failed to load recommendations: $e');
      if (!mounted) return;
      setState(() {
        recommendationsError = 'Could not load recommendations';
        isLoadingRecommendations = false;
      });
    }
  }

  void _incrementQuantity() => setState(() => quantity++);

  void _decrementQuantity() {
    setState(() {
      if (quantity > 1) quantity--;
    });
  }

  String get _description {
    final own = widget.product.description?.trim();
    if (own != null && own.isNotEmpty) return own;
    final asset = widget.assetImage;
    if (asset != null) return _assetDescriptions[asset] ?? '';
    return '';
  }

  /// Normalises whatever the catalogue stored into something the cart can
  /// render: an http URL or a bundled asset path.
  String get _cartImage {
    final images = widget.product.images;
    if (images.isEmpty) return 'assets/images/placeholder.jpg';

    var first = images.first.trim();
    if (first.isEmpty) return 'assets/images/placeholder.jpg';
    if (first.startsWith('http') || first.startsWith('assets/')) return first;

    first = first.replaceAll('\\', '/');
    if (first.startsWith('images/')) return 'assets/$first';
    return 'assets/images/${first.contains('/') ? first.split('/').last : first}';
  }

  Future<void> _addToCart() async {
    // Resolve everything that needs a BuildContext up front, so nothing reads
    // `context` after an await.
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      final loggedIn = await navigator.push(
        MaterialPageRoute(builder: (_) => const Login()),
      );
      if (loggedIn != true) return; // Only continue if login succeeded
    }

    if (selectedSize.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please select a size')),
      );
      return;
    }

    cartProvider.addProduct({
      'id': widget.product.id,
      'name': widget.product.name,
      'price': widget.product.price,
      'image': _cartImage,
      'category': widget.product.category ?? '',
      'quantity': quantity,
      'size': selectedSize,
    });

    messenger.showSnackBar(
      SnackBar(
        content: Text('${widget.product.name} added to cart'),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () => navigator.push(
            MaterialPageRoute(builder: (_) => const CartPage()),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final stock = product.stock;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      bottomNavigationBar: _buildBottomBar(),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildGallery()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(product.name,
                                    style: AppTheme.display(26)),
                              ),
                              const SizedBox(width: 12),
                              Text(formatPkr(product.price),
                                  style: AppTheme.display(24)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  [
                                    product.shopName?.trim(),
                                    product.category,
                                  ]
                                      .where((s) => s != null && s.isNotEmpty)
                                      .join(' · '),
                                  style: AppTheme.ui(14,
                                      color: AppTheme.textMuted),
                                ),
                              ),
                              if (product.discount > 0)
                                StatusTag('-${product.discount}%',
                                    tone: StatusTone.accent),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildRatingRow(stock),
                          const SizedBox(height: 24),
                          const Eyebrow('Size'),
                          const SizedBox(height: 10),
                          _buildSizePicker(),
                          const SizedBox(height: 24),
                          const Eyebrow('Quantity'),
                          const SizedBox(height: 10),
                          _buildQuantityStepper(),
                          if (_description.isNotEmpty) ...[
                            const SizedBox(height: 26),
                            const Eyebrow('Description'),
                            const SizedBox(height: 8),
                            Text(
                              _description,
                              style: AppTheme.ui(15,
                                  color: AppTheme.textSecondary, height: 1.5),
                            ),
                          ],
                          const SizedBox(height: 28),
                          _buildRecommendations(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fixed controls above the artwork. These used to float over the photo,
  /// which left them unreadable on busy product images.
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.borderSoft)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(Icons.arrow_back, size: 22, color: AppTheme.ink),
            ),
          ),
          Expanded(
            child: Text(
              widget.product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTheme.ui(14,
                  color: AppTheme.textSecondary, weight: FontWeight.w500),
            ),
          ),
          const SizedBox(
            width: 40,
            height: 40,
            child: Center(child: CartBadgeIcon(iconColor: AppTheme.ink)),
          ),
        ],
      ),
    );
  }

  /// Product artwork, full width and unobstructed.
  Widget _buildGallery() {
    final images = widget.product.images;
    final source = images.isNotEmpty && images.first.trim().isNotEmpty
        ? images.first.trim()
        : widget.assetImage;

    return SizedBox(
      height: 320,
      width: double.infinity,
      child: ProductImage(source, fit: BoxFit.cover),
    );
  }

  Widget _buildRatingRow(int? stock) {
    return Row(
      children: [
        for (int i = 1; i <= 5; i++)
          GestureDetector(
            onTap: () {
              // Held locally for now; not yet persisted to the backend.
              setState(() => userRating = i.toDouble());
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Icon(
                i <= userRating.round() ? Icons.star : Icons.star_border,
                size: 20,
                color: AppTheme.accent,
              ),
            ),
          ),
        const SizedBox(width: 8),
        Text(userRating.toStringAsFixed(1), style: AppTheme.mono(12)),
        const Spacer(),
        if (stock != null)
          Text(
            stock > 0 ? 'In stock · $stock' : 'Out of stock',
            style: AppTheme.mono(
              12,
              color: stock > 0 ? AppTheme.positive : AppTheme.accentPressed,
            ),
          ),
      ],
    );
  }

  Widget _buildSizePicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final size in sizes)
          FilterPill(
            size,
            selected: selectedSize == size,
            onTap: () => setState(() => selectedSize = size),
          ),
      ],
    );
  }

  Widget _buildQuantityStepper() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderMedium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove,
            onTap: quantity > 1 ? _decrementQuantity : null,
          ),
          SizedBox(
            width: 44,
            child: Center(
              child: Text('$quantity',
                  style: AppTheme.ui(16, weight: FontWeight.w600)),
            ),
          ),
          _StepperButton(icon: Icons.add, onTap: _incrementQuantity),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    if (isLoadingRecommendations) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (recommendationsError.isNotEmpty) {
      return Text(
        recommendationsError,
        style: AppTheme.ui(13, color: AppTheme.textMuted),
      );
    }

    if (recommendedProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Customers also liked',
          trailing: '${recommendedProducts.length}',
          trailingIsMono: true,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 176,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recommendedProducts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final rec = recommendedProducts[i];
              return _RecommendationCard(product: rec);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.borderSoft)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Eyebrow('Total'),
                const SizedBox(height: 2),
                Text(formatPkr(widget.product.price * quantity),
                    style: AppTheme.display(22)),
              ],
            ),
            const SizedBox(width: 18),
            Expanded(
                child: PrimaryButton('Add to cart', onPressed: _addToCart)),
          ],
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepperButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? AppTheme.textDisabled : AppTheme.ink,
        ),
      ),
    );
  }
}

/// Compact card used in the "Customers also liked" rail.
class _RecommendationCard extends StatelessWidget {
  final Product product;

  const _RecommendationCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)),
      ),
      child: SizedBox(
        width: 124,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: ProductImage(
                product.images.isNotEmpty ? product.images.first : null,
                width: 124,
                height: 118,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.ui(13, weight: FontWeight.w500, height: 1.2),
            ),
            const SizedBox(height: 2),
            Text(formatPkr(product.price), style: AppTheme.display(15)),
          ],
        ),
      ),
    );
  }
}
