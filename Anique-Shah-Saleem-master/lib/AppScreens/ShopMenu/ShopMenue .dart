import 'package:flutter/material.dart';
import 'package:prac/AppScreens/ShopMenu/Jacket/JacketScreen.dart';
import 'package:prac/Authentication/Login.dart';
import 'package:prac/AppScreens/ShopMenu/Setting/Sizes.dart';
import 'package:prac/AppScreens/ShopMenu/NewArrival/AccessoriesScreen.dart';
import 'package:prac/AppScreens/ShopMenu/Setting/AdminPanel.dart';
import 'package:prac/AppScreens/ShopMenu/Shoes/ShoesScreen.dart';
import 'package:prac/Controller/ProductProvider.dart';
import 'package:prac/Controller/ChatbotProvider.dart';
import 'package:prac/models/Product.dart';
import 'package:prac/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import '../CartPage.dart';

import 'package:prac/res/app_theme.dart';
import 'package:prac/widgets/cart_badge_nav_icon.dart';

// Import our patched carousel components instead of the original ones
import 'package:prac/utils/patched_carousel_controller.dart';
import 'package:prac/utils/patched_carousel_slider.dart';

import 'Setting/Profile.dart';
import 'Shirt/ShirtScreen.dart';
import 'NewArrival/WomensClothingScreen.dart';
import 'NewArrival/KidsClothingScreen.dart';
import 'package:prac/widgets/loading_indicator.dart';
import 'package:prac/AppScreens/ProductDetailPage.dart';
import 'package:prac/widgets/chatbot_widget.dart';
import '../../widgets/product_card.dart';
import 'package:prac/AppScreens/ShopMenu/dummy_products.dart';


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

  List pages = [
    const ShirtScreen(),
    const ShoesScreen(),
    const WomensClothingScreen(),
    const JacketScreen()
  ];

  final PatchedCarouselController carouselController = PatchedCarouselController();
  int currentIndex = 0;
  int selectedItem = 0;
  String selectedCategory = 'All';
  late AnimationController _animationController;
  late TabController _tabController;
  
  // Add search controller and filtered products list
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
          debugPrint('[DEBUG] Tab changed, selectedCategory = "$selectedCategory"');
        });
      }
    });
    // Fetch products when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
      // ChatbotProvider now initializes automatically, no need to call initChatbot
    });
    
    // Add listener to search controller
    _searchController.addListener(_onSearchChanged);
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
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final allProducts = productProvider.products;

    if (_searchQuery.isEmpty) {
      filteredProducts = [];
      return;
    }

    // Filter products based on search query
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

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final chatProvider = Provider.of<ChatbotProvider>(context);
    final products = selectedCategory == 'All'
        ? productProvider.products
        : productProvider.getProductsByCategory(selectedCategory);
    final Size size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 600;

    // Banner images for carousel
    final List<String> bannerImages = [
      "assets/images/m1.jpg",
      "assets/images/m2.jpg",
      "assets/images/m3.jpg",
    ];

    List<Product> productsToShow = products.isNotEmpty
        ? products
        : (selectedCategory == 'Shirt'
            ? dummyShirts
            : (selectedCategory == 'Jean'
                ? dummyJeans
                : (selectedCategory == 'Shoes'
                    ? dummyShoes
                    : (selectedCategory == 'Jacket'
                        ? dummyJackets
                        : []))));

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            boxShadow: [
              BoxShadow(
                color: AppTheme.brandPrimary.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            border: Border(
              top: BorderSide(
                color: Colors.grey.shade800,
                width: 1.0,
              ),
            ),
          ),
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            selectedItemColor: AppTheme.brandSecondary,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: CartBadgeNavIcon(),
                activeIcon: Icon(Icons.shopping_cart),
                label: 'Cart',
              ),
            ],
            onTap: (index) {
              // If Cart icon is tapped, navigate to CartPage
              if (index == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartPage()),
                );
              }
            },
          ),
        ),
        // Keep the floating action button for chatbot
        floatingActionButton: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.brandPrimary.withValues(alpha: 0.5),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.brandGradient,
            ),
            child: FloatingActionButton(
              heroTag: 'chatbotButton',
              onPressed: () {
                chatProvider.toggleChat();
                _animationController.status == AnimationStatus.completed
                  ? _animationController.reverse()
                  : _animationController.forward();
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (_, child) {
                  return Transform.rotate(
                    angle: _animationController.value * 0.5,
                    child: Icon(
                      chatProvider.isChatOpen ? Icons.close : Icons.support_agent,
                      color: Colors.white,
                      size: 28,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            // Background with gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF121212), // Dark black background
                    Color(0xFF1E1E1E), // Slightly lighter black for depth
                  ],
                ),
              ),
            ),
          
            // Main content
            productProvider.isLoading
                ? const LoadingIndicator(message: 'Loading products...')
                : productProvider.error.isNotEmpty
                    ? ErrorMessage(
                        message:
                            'Failed to load products: ${productProvider.error}',
                        onRetry: () {
                          Provider.of<ProductProvider>(context, listen: false)
                              .fetchProducts();
                        },
                      )
                    : Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 16.0 : size.width * 0.05,
                          vertical: 8.0,
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // App Bar with profile and settings
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                                child: Container(
                                  height: 70,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.grey.shade900.withValues(alpha: 0.8),
                                        Colors.black.withValues(alpha: 0.7),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.grey.shade800,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 20),
                                      ShaderMask(
                                        shaderCallback: (Rect bounds) {
                                          return const LinearGradient(
                                            colors: [AppTheme.brandPrimary, AppTheme.accentColor],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ).createShader(bounds);
                                        },
                                        child: const Text(
                                          'AISalesman',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.5,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Home button with gradient
                                      Expanded(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Container(
                                              height: 40,
                                              decoration: BoxDecoration(
                                                gradient: AppTheme.brandGradient,
                                                borderRadius: BorderRadius.circular(20),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppTheme.brandPrimary.withValues(alpha: 0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: ElevatedButton.icon(
                                                onPressed: () {},
                                                icon: const Icon(
                                                  Icons.home_rounded,
                                                  size: 18,
                                                ),
                                                label: const Text(
                                                  'Home',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.transparent,
                                                  foregroundColor: Colors.white,
                                                  shadowColor: Colors.transparent,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Settings button with animation
                                            Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.grey.shade800,
                                                    Colors.grey.shade900,
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius: BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.2),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: IconButton(
                                                icon: ShaderMask(
                                                  shaderCallback: (Rect bounds) {
                                                    return AppTheme.brandGradient.createShader(bounds);
                                                  },
                                                  child: const Icon(
                                                    Icons.settings,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (BuildContext context) {
                                                      return Padding(
                                                        padding: const EdgeInsets.only(bottom: 60),
                                                        child: Dialog(
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(20),
                                                          ),
                                                          child: Container(
                                                            width: 500,
                                                            height: 600,
                                                            padding: const EdgeInsets.all(20),
                                                            child: Column(
                                                              mainAxisSize: MainAxisSize.min,
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                const Row(
                                                                  children: [
                                                                    Icon(Icons.settings),
                                                                    SizedBox(width: 15),
                                                                    Text('Settings',
                                                                      style: TextStyle(
                                                                          fontSize: 20,
                                                                          fontWeight: FontWeight.bold),
                                                                    ),
                                                                  ],
                                                                ),
                                                                const SizedBox(height: 30),
                                                                // Scrollable so the fixed-height dialog cannot overflow
                                                                // as entries are added.
                                                                Expanded(
                                                                  child: ListView(
                                                                    padding: EdgeInsets.zero,
                                                                    children: [
                                                                ListTile(
                                                                  leading: const Icon(Icons.person),
                                                                  title: const Text('Profile'),
                                                                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                                                  onTap: () {
                                                                    Navigator.push(
                                                                        context,
                                                                        MaterialPageRoute(
                                                                            builder: (context) => const Profile()));
                                                                  },
                                                                ),
                                                                ListTile(
                                                                  leading: const Icon(Icons.public),
                                                                  title: const Text('Country'),
                                                                  trailing: const Row(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: [
                                                                      Text('Pakistan', style: TextStyle(fontSize: 14)),
                                                                      SizedBox(width: 5),
                                                                      Icon(Icons.arrow_forward_ios, size: 16),
                                                                    ],
                                                                  ),
                                                                  onTap: () {
                                                                    Navigator.pop(context);
                                                                  },
                                                                ),
                                                                ListTile(
                                                                  leading: const Icon(Icons.attach_money),
                                                                  title: const Text('Currency'),
                                                                  trailing: const Row(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: [
                                                                      Text('Rupees', style: TextStyle(fontSize: 14)),
                                                                      SizedBox(width: 5),
                                                                      Icon(Icons.arrow_forward_ios, size: 16),
                                                                    ],
                                                                  ),
                                                                  onTap: () {
                                                                  },
                                                                ),
                                                                ListTile(
                                                                  leading: const Icon(Icons.snowshoeing),
                                                                  title: const Text('Sizes'),
                                                                  trailing: const Row(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: [
                                                                      Text('UK', style: TextStyle(fontSize: 14)),
                                                                      SizedBox(width: 5),
                                                                      Icon(Icons.arrow_forward_ios, size: 16),
                                                                    ],
                                                                  ),
                                                                  onTap: () {
                                                                    Navigator.push(
                                                                        context,
                                                                        MaterialPageRoute(
                                                                            builder: (context) => const SizesScreen()));
                                                                  },
                                                                ),
                                                                ListTile(
                                                                  leading: const Icon(Icons.admin_panel_settings),
                                                                  title: const Text('Admin Panel'),
                                                                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                                                  onTap: () {
                                                                    Navigator.push(
                                                                        context,
                                                                        MaterialPageRoute(
                                                                            builder: (context) => const AdminPanel()));
                                                                  },
                                                                ),
                                                                const ListTile(
                                                                  leading: Icon(Icons.info),
                                                                  title: Text('About AI Salesman'),
                                                                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                                                                ),
                                                                // Entry point to the auth screens. Without this a new
                                                                // seller could only reach sign-up via the checkout gate.
                                                                ListTile(
                                                                  leading: const Icon(Icons.login,
                                                                      color: Color(0xFF6C63FF)),
                                                                  title: const Text('Login / Sign up'),
                                                                  subtitle: const Text(
                                                                      'Customer or seller account',
                                                                      style: TextStyle(fontSize: 12)),
                                                                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                                                  onTap: () {
                                                                    Navigator.pop(context);
                                                                    Navigator.push(
                                                                        context,
                                                                        MaterialPageRoute(
                                                                            builder: (_) => const Login()));
                                                                  },
                                                                ),
                                                                ListTile(
                                                                  leading: const Icon(Icons.logout, color: Colors.red),
                                                                  title: const Text('Logout', style: TextStyle(color: Colors.red)),
                                                                  onTap: () async {
                                                                    // Captured before the await so navigation never
                                                                    // touches a stale BuildContext.
                                                                    final navigator = Navigator.of(context);
                                                                    final shouldLogout = await showDialog<bool>(
                                                                      context: context,
                                                                      builder: (context) => AlertDialog(
                                                                        title: const Text('Logout'),
                                                                        content: const Text('Are you sure you want to logout?'),
                                                                        actions: [
                                                                          TextButton(
                                                                            onPressed: () => Navigator.of(context).pop(false),
                                                                            child: const Text('Cancel'),
                                                                          ),
                                                                          TextButton(
                                                                            onPressed: () => Navigator.of(context).pop(true),
                                                                            child: const Text('Logout', style: TextStyle(color: Colors.red)),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    );

                                                                    if (shouldLogout == true) {
                                                                      // Clear any user data/session here if needed
                                                                      // For example: await AuthService().signOut();
                                                                      
                                                                      // Navigate to splash screen and remove all previous routes
                                                                      navigator.pushAndRemoveUntil(
                                                                        MaterialPageRoute(
                                                                          builder: (_) => const SplashScreen(),
                                                                        ),
                                                                        (route) => false,
                                                                      );
                                                                    }
                                                                  },
                                                                ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                TextButton(
                                                                  onPressed: () {
                                                                    Navigator.pop(context);
                                                                  },
                                                                  child: const Text('Close'),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              
                              // Search Row with enhanced styling
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.9),
                                      Colors.grey.shade200,
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 5,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                margin: const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  children: [
                                    const Icon(Icons.search, color: AppTheme.brandPrimary),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _searchController,
                                        style: const TextStyle(color: Colors.black),
                                        cursorColor: AppTheme.brandPrimary,
                                        decoration: InputDecoration(
                                          hintText: "  Search for products...",
                                          hintStyle: TextStyle(color: Colors.grey.shade700),
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.symmetric(vertical: 6.0),
                                          suffixIcon: _searchQuery.isNotEmpty ? 
                                            IconButton(
                                              icon: Icon(Icons.clear, color: Colors.grey.shade700, size: 20),
                                              onPressed: () {
                                                _searchController.clear();
                                              },
                                            ) : null,
                                        ),
                                        onFieldSubmitted: (value) {
                                          if (_searchQuery.isNotEmpty) {
                                            for (int i = 0; i < filters.length; i++) {
                                              if (filters[i].toLowerCase().contains(_searchQuery)) {
                                                setState(() {
                                                  selectedItem = i;
                                                  if (i == 0) {
                                                    _showAllProducts(context);
                                                  } else {
                                                    _showCategoryProducts(context, filters[i].toLowerCase());
                                                  }
                                                });
                                                break;
                                              }
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Display search results when searching
                              if (isSearching && filteredProducts.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.symmetric(vertical: 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8, bottom: 12),
                                        child: Row(
                                          children: [
                                            Container(
                                              height: 24,
                                              width: 4,
                                              decoration: BoxDecoration(
                                                gradient: AppTheme.brandGradient,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Search Results: $_searchQuery',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // Search results grid
                                      GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 0.85,
                                          crossAxisSpacing: 10,
                                          mainAxisSpacing: 10,
                                        ),
                                        itemCount: filteredProducts.length,
                                        itemBuilder: (context, index) {
                                          return ProductCard(product: filteredProducts[index]);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              
                              // "No results found" message when searching with no results
                              if (isSearching && filteredProducts.isEmpty)
                                Container(
                                  margin: const EdgeInsets.symmetric(vertical: 20),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade900.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(color: Colors.grey.shade800),
                                  ),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(Icons.search_off, size: 50, color: Colors.grey.shade400),
                                        const SizedBox(height: 10),
                                        Text(
                                          'No products found for "$_searchQuery"',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          'Try using different keywords or browse categories',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              
                              // Only show other sections when not searching
                              if (!isSearching) ...[
                                // Welcome message with personalization
                                Container(
                                  margin: const EdgeInsets.symmetric(vertical: 10),
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    gradient: const LinearGradient(
                                      colors: [AppTheme.brandPrimary, Color(0xFF9C27B0)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.brandPrimary.withValues(alpha: 0.5),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Enjoy surfing!',
                                            style: TextStyle(
                                                fontSize: 22, 
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white),
                                          ),
                                          SizedBox(height: 5),
                                          Text(
                                            'Discover today\'s fashion trends',
                                            style: TextStyle(
                                                fontSize: 14, 
                                                color: Colors.white70),
                                          ),
                                        ],
                                      ),
                                      Spacer(),
                                      Icon(Icons.shopping_bag_outlined, size: 40, color: Colors.white70),
                                    ],
                                  ),
                                ),
                              
                                // Featured Banner Carousel
                                const SizedBox(height: 15),
                                PatchedCarouselSlider(
                                  controller: carouselController,
                                  autoPlay: true,
                                  height: 180.0,
                                  viewportFraction: 0.8,
                                  items: bannerImages.map((item) => Container(
                                    margin: const EdgeInsets.all(5.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                      image: DecorationImage(
                                        image: AssetImage(item),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )).toList(),
                                ),
                                
                                // New Arrival Section
                                const SizedBox(height: 20),
                                Padding(
                                  padding: const EdgeInsets.only(left: 8, bottom: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        height: 24,
                                        width: 4,
                                        decoration: BoxDecoration(
                                          gradient: AppTheme.sunsetGradient,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'New Arrival',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Subcategory cards
                                SizedBox(
                                  height: 140,
                                  child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      _buildCategoryCard(
                                        'Accessories',
                                        'assets/images/accesories.jpg',
                                        () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const AccessoriesScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                      _buildCategoryCard(
                                        'Women\'s Clothing',
                                        'assets/images/women.jpeg',
                                        () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const WomensClothingScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                      _buildCategoryCard(
                                        "Kids' Clothing",
                                        'assets/images/kids.jpeg',
                                        () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const KidsClothingScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                ),
                                
                                // Featured Products Carousel
                                Container(
                                  margin: const EdgeInsets.symmetric(vertical: 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Featured Products header and filter row
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
                                        child: Row(
                                          children: [
                                            Container(
                                              height: 24,
                                              width: 4,
                                              decoration: BoxDecoration(
                                                gradient: AppTheme.luxuryGradient,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Featured Products',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        height: 40,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: filters.length,
                                          itemBuilder: (context, index) {
                                            final filter = filters[index];
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 5),
                                              child: Center(
                                                child: InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      selectedItem = index;
                                                      selectedCategory = filters[index];
                                                      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
                                                    });
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                                    decoration: BoxDecoration(
                                                      gradient: selectedItem == index 
                                                        ? AppTheme.brandGradient
                                                        : LinearGradient(
                                                            colors: [
                                                              Colors.grey.shade800.withValues(alpha: 0.7),
                                                              Colors.grey.shade900.withValues(alpha: 0.7),
                                                            ],
                                                            begin: Alignment.topCenter,
                                                            end: Alignment.bottomCenter,
                                                          ),
                                                      borderRadius: BorderRadius.circular(30),
                                                      boxShadow: [
                                                        if (selectedItem == index)
                                                          BoxShadow(
                                                            color: AppTheme.brandPrimary.withValues(alpha: 0.5),
                                                            blurRadius: 8,
                                                            spreadRadius: 1,
                                                            offset: const Offset(0, 3),
                                                          ),
                                                      ],
                                                    ),
                                                    child: Text(
                                                      filter,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: selectedItem == index ? Colors.white : Colors.grey.shade400,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Products Grid Based on Selected Category
                                Container(
                                  margin: const EdgeInsets.symmetric(vertical: 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8, bottom: 12),
                                        child: Row(
                                          children: [
                                            Container(
                                              height: 24,
                                              width: 4,
                                              decoration: BoxDecoration(
                                                gradient: AppTheme.sunsetGradient,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              selectedItem == 0 
                                                ? 'All Products' 
                                                : '${filters[selectedItem]} Collection',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // Responsive Product Grid
                                      if (productsToShow.isEmpty)
                                        const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 16),
                                          child: Text(
                                            'No products found',
                                            style: TextStyle(color: Colors.grey, fontSize: 18),
                                            textAlign: TextAlign.center,
                                          ),
                                        )
                                      else
                                        GridView.builder(
                                          shrinkWrap: true,
                                          physics: const BouncingScrollPhysics(),
                                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: isSmallScreen ? 2 : 3,
                                            childAspectRatio: 0.85,
                                            crossAxisSpacing: 10,
                                            mainAxisSpacing: 10,
                                          ),
                                          itemCount: productsToShow.length,
                                          itemBuilder: (context, index) {
                                            final product = productsToShow[index];
                                            return ProductCard(product: product);
                                          },
                                        ),
                                    ],
                                  ),
                                ),

                                // Popular Categories section removed per user request
                                const SizedBox.shrink(),
                                
                                // Featured Products Grid
                                const SizedBox(height: 20),
                                
                        

                                // Recently Viewed Products
                                if (productsToShow.isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.symmetric(vertical: 16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8, bottom: 12),
                                          child: Row(
                                            children: [
                                              Container(
                                                height: 24,
                                                width: 4,
                                                decoration: BoxDecoration(
                                                  gradient: AppTheme.sunsetGradient,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'Recently Viewed',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Add padding and minimum height to ensure no overflow
                                        Container(
                                          padding: const EdgeInsets.only(bottom: 20),
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: productsToShow.length > 6 ? 6 : productsToShow.length,
                                            itemBuilder: (context, index) {
                                              // Use reverse order to show most "recent" first
                                              final recentProduct = productsToShow[productsToShow.length - 1 - index];
                                              return Padding(
                                                padding: const EdgeInsets.only(bottom: 8.0),
                                                child: ProductCard(
                                                  product: recentProduct,
                                                  isHorizontal: true,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
            // Chatbot window when open
            if (chatProvider.isChatOpen)
              Positioned(
                right: 10,
                bottom: 80,
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.7,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  child: const ChatbotWidget(),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  // Helper method to build category cards
  Widget _buildCategoryCard(String title, String imageAsset, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Category image
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                imageAsset,
                fit: BoxFit.cover,
              ),
            ),
            // Dark overlay for better text visibility
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
            // Category title
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            // Add a ripple effect for better user experience
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: onTap,
                splashColor: Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Method to show products filtered by category
  void _showCategoryProducts(BuildContext context, String category) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final categoryProducts = productProvider.getProductsByCategory(category.toLowerCase());
    
    if (categoryProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No products found in $category category'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle and title
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        '$category Collection',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                // Products grid
                Expanded(
                  child: GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(15),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    itemCount: categoryProducts.length, // Show all category products
                    itemBuilder: (context, index) {
                      final product = categoryProducts[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailPage(
                                product: product,
                              ),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product image
                              AspectRatio(
                                aspectRatio: 1.0,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                  child: (product.images.isNotEmpty && product.images[0].startsWith('http'))
                                    ? Image.network(
                                        product.images[0],
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported)),
                                      )
                                    : Image.asset(
                                    product.images.isNotEmpty ? product.images[0] : 'assets/images/jacket1.jpg',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported)),
                                  ),
                                ),
                              ),
                              // Product details
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        product.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        'PKR ${product.price.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.brandSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Method to show all products
  void _showAllProducts(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final allProducts = productProvider.products;
    
    if (allProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No products available'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle and title
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'All Products',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                // Products grid
                Expanded(
                  child: GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(15),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    itemCount: allProducts.length, // Show all available products
                    itemBuilder: (context, index) {
                      final product = allProducts[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailPage(
                                product: product,
                              ),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product image
                              AspectRatio(
                                aspectRatio: 1.0,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                  child: (product.images.isNotEmpty && product.images[0].startsWith('http'))
                                    ? Image.network(
                                        product.images[0],
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported)),
                                      )
                                    : Image.asset(
                                    product.images.isNotEmpty ? product.images[0] : 'assets/images/jacket1.jpg',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported)),
                                  ),
                                ),
                              ),
                              // Product details
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        product.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'PKR ${product.price.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.brandSecondary,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppTheme.accentColor,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              product.category ?? 'Category',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: AppTheme.brandSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Error message widget (remains the same)
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
