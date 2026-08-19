import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prac/AppScreens/Seller/SellerSignIn.dart';
import 'package:prac/AppScreens/ShopMenu/NewArrival/AccessoriesScreen.dart';
import 'package:prac/AppScreens/ShopMenu/Setting/AdminPanel.dart';
import 'package:prac/AppScreens/ShopMenu/Setting/Sizes.dart';
import 'package:prac/AppScreens/ShopMenu/dummy_products.dart';
import 'package:prac/Authentication/Login.dart';
import 'package:prac/Controller/ChatbotProvider.dart';
import 'package:prac/Controller/ProductProvider.dart';
import 'package:prac/models/Product.dart';
import 'package:prac/res/app_theme.dart';
import 'package:prac/res/ui_kit.dart';
import 'package:prac/screens/splash_screen.dart';
import 'package:prac/widgets/cart_count_button.dart';
import 'package:prac/widgets/chatbot_widget.dart';
import 'package:prac/widgets/loading_indicator.dart';

// Patched carousel components, used instead of the upstream package.
import 'package:prac/utils/patched_carousel_controller.dart';
import 'package:prac/utils/patched_carousel_slider.dart';

import '../CartPage.dart';
import '../../widgets/product_card.dart';
import 'NewArrival/KidsClothingScreen.dart';
import 'NewArrival/WomensClothingScreen.dart';
import 'Setting/Profile.dart';

/// One slide of the home carousel: artwork plus the copy laid over it.
class _Banner {
  final String image;
  final String eyebrow;
  final String title;

  const _Banner(this.image, this.eyebrow, this.title);
}

class ShopMenue extends StatefulWidget {
  const ShopMenue({super.key});

  @override
  State<ShopMenue> createState() => _ShopMenueState();
}

class _ShopMenueState extends State<ShopMenue> with TickerProviderStateMixin {
  final List<String> filters = const [
    'All',
    'Shirt',
    'Jean',
    'Shoes',
    'Jacket',
    "Women's Clothing"
  ];

  static const List<_Banner> _banners = [
    _Banner('assets/images/m1.jpg', 'New arrivals', 'Winter layers · 30% off'),
    _Banner('assets/images/m2.jpg', 'Just landed', 'Denim, restocked'),
    _Banner('assets/images/m3.jpg', 'Editors pick', 'Six shirts for the season'),
  ];

  final PatchedCarouselController carouselController =
      PatchedCarouselController();
  int selectedItem = 0;
  String selectedCategory = 'All';
  late AnimationController _animationController;
  late TabController _tabController;

  /// Shown in the greeting. Only the profile screen writes this key, so it is
  /// blank until the shopper fills their profile in.
  String _shopperName = '';

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Product> filteredProducts = [];
  bool isSearching = false;

  List<String> categorySuggestions = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _tabController = TabController(length: filters.length, vsync: this);
    // Keep selectedCategory in sync with tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          selectedCategory = filters[_tabController.index];
          selectedItem = _tabController.index;
        });
      }
    });
    // Fetch products when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    });

    _loadShopperName();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadShopperName() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _shopperName = prefs.getString('name')?.trim() ?? '');
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      isSearching = _searchQuery.isNotEmpty;

      final categories = ['Shirt', 'Jean', 'Shoes', 'Jacket'];
      categorySuggestions = [];

      if (_searchQuery.isNotEmpty) {
        for (var cat in categories) {
          if (cat.toLowerCase().contains(_searchQuery)) {
            categorySuggestions.add(cat);
          }
        }
      }

      // If only one suggestion matches and the query matches it exactly, auto-select it
      if (categorySuggestions.length == 1 &&
          categorySuggestions[0].toLowerCase() == _searchQuery) {
        int index = filters.indexOf(categorySuggestions[0]);
        if (index != -1) {
          _tabController.animateTo(index);
          selectedItem = index;
          selectedCategory = categorySuggestions[0];
          _searchController.clear();
          _searchQuery = '';
          isSearching = false;
          filteredProducts = [];
          categorySuggestions = [];
          return;
        }
      }

      // Only filter products if not matching a category
      if (categorySuggestions.isEmpty) {
        _filterProducts();
      }
    });
  }

  void _filterProducts() {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    final allProducts = productProvider.products;

    if (_searchQuery.isEmpty) {
      filteredProducts = [];
      return;
    }

    filteredProducts = allProducts.where((product) {
      final name = product.name.toLowerCase();
      final category = product.category?.toLowerCase() ?? '';
      final description = product.description?.toLowerCase() ?? '';

      return name.contains(_searchQuery) ||
          category.contains(_searchQuery) ||
          description.contains(_searchQuery);
    }).toList();

    // If searching for a category, update the selected tab
    for (int i = 0; i < filters.length; i++) {
      if (filters[i].toLowerCase().contains(_searchQuery)) {
        _tabController.animateTo(i);
        selectedItem = i;
        break;
      }
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _animationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// "Good morning" / "Good afternoon" / "Good evening".
  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// The catalogue uses singular category keys; the chips read better plural.
  String _chipLabel(String filter) {
    switch (filter) {
      case 'Shirt':
        return 'Shirts';
      case 'Jean':
        return 'Jeans';
      case 'Jacket':
        return 'Jackets';
      default:
        return filter;
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final chatProvider = Provider.of<ChatbotProvider>(context);
    final products = selectedCategory == 'All'
        ? productProvider.products
        : productProvider.getProductsByCategory(selectedCategory);

    // Fall back to the bundled catalogue while the API has nothing for the
    // selected category, so the grid is never empty on a cold start.
    final List<Product> productsToShow = products.isNotEmpty
        ? products
        : (selectedCategory == 'Shirt'
            ? dummyShirts
            : (selectedCategory == 'Jean'
                ? dummyJeans
                : (selectedCategory == 'Shoes'
                    ? dummyShoes
                    : (selectedCategory == 'Jacket' ? dummyJackets : []))));

    return Scaffold(
      backgroundColor: AppTheme.surface,
      bottomNavigationBar: _buildBottomNav(context),
      floatingActionButton: _buildAssistantFab(chatProvider),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 4, 22, 12),
                  child: _buildSearchField(),
                ),
                _buildCategoryChips(),
                const SizedBox(height: 4),
                Expanded(
                  child: _buildBody(
                    context,
                    productProvider: productProvider,
                    productsToShow: productsToShow,
                  ),
                ),
              ],
            ),
            if (chatProvider.isChatOpen)
              Positioned(
                right: 10,
                bottom: 80,
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.7,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  clipBehavior: Clip.antiAlias,
                  child: const ChatbotWidget(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Eyebrow(_greeting),
                const SizedBox(height: 4),
                Text(
                  _shopperName.isEmpty ? 'Welcome' : _shopperName,
                  style: AppTheme.display(30),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const CartCountButton(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderMedium),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: AppTheme.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              cursorColor: AppTheme.accent,
              style: AppTheme.ui(15),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: 'Search shirts, jeans, shoes…',
                hintStyle: AppTheme.ui(15, color: AppTheme.textMuted),
              ),
              onSubmitted: (_) {
                if (_searchQuery.isEmpty) return;
                // A query naming a category jumps straight into that
                // collection rather than filtering the home grid.
                for (int i = 0; i < filters.length; i++) {
                  if (filters[i].toLowerCase().contains(_searchQuery)) {
                    setState(() {
                      selectedItem = i;
                      selectedCategory = filters[i];
                    });
                    if (i == 0) {
                      _showAllProducts(context);
                    } else {
                      _showCategoryProducts(context, filters[i]);
                    }
                    break;
                  }
                }
              },
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: _searchController.clear,
              child: const Icon(Icons.close,
                  size: 18, color: AppTheme.textMuted),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return FilterPill(
            _chipLabel(filters[index]),
            selected: selectedItem == index,
            onTap: () {
              setState(() {
                selectedItem = index;
                selectedCategory = filters[index];
              });
              Provider.of<ProductProvider>(context, listen: false)
                  .fetchProducts();
            },
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------
  // Body
  // ---------------------------------------------------------------

  Widget _buildBody(
    BuildContext context, {
    required ProductProvider productProvider,
    required List<Product> productsToShow,
  }) {
    if (productProvider.isLoading) {
      return const LoadingIndicator(message: 'Loading products…');
    }

    if (productProvider.error.isNotEmpty) {
      return ErrorMessage(
        message: productProvider.error,
        onRetry: () => Provider.of<ProductProvider>(context, listen: false)
            .fetchProducts(),
      );
    }

    if (isSearching) return _buildSearchResults();

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildBannerCarousel(),
        const SizedBox(height: AppTheme.spaceLg),
        const SectionHeader('Shop by category'),
        const SizedBox(height: AppTheme.spaceSm),
        _buildCategoryRow(context),
        const SizedBox(height: AppTheme.spaceLg),
        SectionHeader(
          selectedCategory == 'All'
              ? 'Recommended for you'
              : '${_chipLabel(selectedCategory)} collection',
          trailing: '${productsToShow.length} items',
          trailingIsMono: true,
        ),
        const SizedBox(height: AppTheme.spaceSm),
        if (productsToShow.isEmpty)
          _buildEmptyState('Nothing here yet',
              'No products in this category. Try another one.')
        else
          _buildProductGrid(productsToShow),
      ],
    );
  }

  Widget _buildSearchResults() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
      physics: const BouncingScrollPhysics(),
      children: [
        SectionHeader(
          'Results',
          trailing: '${filteredProducts.length} found',
          trailingIsMono: true,
        ),
        const SizedBox(height: AppTheme.spaceSm),
        if (filteredProducts.isEmpty)
          _buildEmptyState('No matches for "$_searchQuery"',
              'Try different keywords, or pick a category above.')
        else
          _buildProductGrid(filteredProducts),
      ],
    );
  }

  Widget _buildProductGrid(List<Product> items) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isSmallScreen ? 2 : 3,
        // ProductCard fills whatever cell it is given; the taller ratio leaves
        // the artwork room to breathe above the ~97px name/price block.
        childAspectRatio: 0.66,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => ProductCard(product: items[index]),
    );
  }

  Widget _buildEmptyState(String title, String detail) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSunken,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderSoft),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 32, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          Text(title, style: AppTheme.display(18), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            detail,
            style: AppTheme.ui(14, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCarousel() {
    return PatchedCarouselSlider(
      controller: carouselController,
      autoPlay: true,
      height: 168,
      viewportFraction: 1.0,
      items: _banners.map(_buildBannerSlide).toList(),
    );
  }

  Widget _buildBannerSlide(_Banner banner) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            banner.image,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: AppTheme.surfaceSunken),
          ),
          // Scrim so the copy stays readable over any artwork.
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppTheme.ink.withValues(alpha: 0.72),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    banner.eyebrow.toUpperCase(),
                    style: AppTheme.mono(11, color: AppTheme.accent),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    banner.title,
                    style: AppTheme.display(22, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCategoryCard(
            'Accessories',
            'assets/images/accesories.jpg',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccessoriesScreen()),
            ),
          ),
          _buildCategoryCard(
            "Women's",
            'assets/images/women.jpeg',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WomensClothingScreen()),
            ),
          ),
          _buildCategoryCard(
            "Kids'",
            'assets/images/kids.jpeg',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const KidsClothingScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
      String title, String imageAsset, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 128,
        margin: const EdgeInsets.only(right: 10),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.borderSoft),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              imageAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: AppTheme.surfaceSunken),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppTheme.ink.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  title,
                  style: AppTheme.ui(14,
                      color: Colors.white, weight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Chrome
  // ---------------------------------------------------------------

  Widget _buildAssistantFab(ChatbotProvider chatProvider) {
    return GestureDetector(
      onTap: () {
        chatProvider.toggleChat();
        _animationController.status == AnimationStatus.completed
            ? _animationController.reverse()
            : _animationController.forward();
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.accent,
          shape: BoxShape.circle,
          boxShadow: AppTheme.floatShadow,
        ),
        alignment: Alignment.center,
        child: chatProvider.isChatOpen
            ? const Icon(Icons.close, color: Colors.white, size: 24)
            : Text(
                'AI',
                style: AppTheme.mono(15, color: Colors.white, tracking: 0.06),
              ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.borderSoft)),
      ),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        // Home is the only tab that renders here; the rest push a route and
        // return, so the highlight stays on Home.
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.ink,
        unselectedItemColor: AppTheme.textMuted,
        selectedLabelStyle: AppTheme.ui(11, weight: FontWeight.w500),
        unselectedLabelStyle: AppTheme.ui(11),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined), label: 'Shop'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined), label: 'Cart'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
        onTap: (index) => _onNavTap(context, index),
      ),
    );
  }

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 1:
        _showAllProducts(context);
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CartPage()),
        );
        break;
      case 3:
        // There is no order-history screen yet; tracking needs a specific id.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your orders will appear here.')),
        );
        break;
      case 4:
        _openSettings(context);
        break;
      default:
        break;
    }
  }

  /// Account and app settings, reached from the Profile tab.
  void _openSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        maxChildSize: 0.92,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusXl)),
          ),
          child: Column(
            children: [
              _buildSheetHandle('Settings'),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    _settingsTile(
                      icon: Icons.person_outline,
                      title: 'Profile',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const Profile())),
                    ),
                    _settingsTile(
                      icon: Icons.public,
                      title: 'Country',
                      value: 'Pakistan',
                      onTap: () {},
                    ),
                    _settingsTile(
                      icon: Icons.attach_money,
                      title: 'Currency',
                      value: 'Rupees',
                      onTap: () {},
                    ),
                    _settingsTile(
                      icon: Icons.straighten,
                      title: 'Sizes',
                      value: 'UK',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SizesScreen())),
                    ),
                    _settingsTile(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Admin panel',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const AdminPanel())),
                    ),
                    _settingsTile(
                      icon: Icons.info_outline,
                      title: 'About AI Salesman',
                      onTap: () {},
                    ),
                    const Divider(height: 24),
                    _settingsTile(
                      icon: Icons.login,
                      title: 'Login / Sign up',
                      subtitle: 'Customer account',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const Login()));
                      },
                    ),
                    _settingsTile(
                      icon: Icons.storefront_outlined,
                      title: 'Sell on AI Salesman',
                      subtitle: 'Open your shop dashboard',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SellerSignIn()));
                      },
                    ),
                    _settingsTile(
                      icon: Icons.logout,
                      title: 'Logout',
                      danger: true,
                      onTap: () => _confirmLogout(context),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    // Captured before the await so navigation never touches a stale context.
    final navigator = Navigator.of(context);
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Text('Log out', style: AppTheme.display(22)),
        content: Text('Are you sure you want to log out?',
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
                    color: AppTheme.negative, weight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    }
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    String? value,
    bool danger = false,
    VoidCallback? onTap,
  }) {
    final color = danger ? AppTheme.negative : AppTheme.ink;
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(title,
          style: AppTheme.ui(16, color: color, weight: FontWeight.w500)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, style: AppTheme.ui(13, color: AppTheme.textMuted)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null) ...[
            Text(value, style: AppTheme.ui(14, color: AppTheme.textMuted)),
            const SizedBox(width: 6),
          ],
          const Icon(Icons.arrow_forward_ios,
              size: 14, color: AppTheme.textMuted),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildSheetHandle(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderSoft)),
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderStrong,
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(title, style: AppTheme.display(24)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // Product sheets
  // ---------------------------------------------------------------

  /// Shared sheet used by the category and "all products" launchers.
  void _showProductSheet(
    BuildContext context,
    String title,
    List<Product> items,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.92,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusXl)),
          ),
          child: Column(
            children: [
              _buildSheetHandle(title),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(18),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.66,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) =>
                      ProductCard(product: items[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Method to show products filtered by category
  void _showCategoryProducts(BuildContext context, String category) {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    final categoryProducts =
        productProvider.getProductsByCategory(category.toLowerCase());

    if (categoryProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No products found in $category')),
      );
      return;
    }

    _showProductSheet(context, '$category collection', categoryProducts);
  }

  // Method to show all products
  void _showAllProducts(BuildContext context) {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    final allProducts = productProvider.products;

    if (allProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No products available')),
      );
      return;
    }

    _showProductSheet(context, 'All products', allProducts);
  }
}

/// Full-bleed error state with a retry affordance.
class ErrorMessage extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorMessage({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: AppTheme.accentWash,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.priority_high,
                  color: AppTheme.accent, size: 26),
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load products',
              style: AppTheme.display(22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.ui(14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: 180,
              child: PrimaryButton('Retry', onPressed: onRetry),
            ),
          ],
        ),
      ),
    );
  }
}
