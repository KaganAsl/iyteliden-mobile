import 'package:flutter/material.dart';
import 'package:iyteliden_mobile/models/response/product_response.dart';
import 'package:iyteliden_mobile/pages/product_details_page.dart';
import 'package:iyteliden_mobile/services/favorite_service.dart';
import 'package:iyteliden_mobile/services/product_service.dart';
import 'package:iyteliden_mobile/widgets/simple_product_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iyteliden_mobile/utils/app_colors.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});
  
  @override
  State<StatefulWidget> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final List<SimpleProductResponse> _products = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  int _currentPage = 0;
  int _totalPages = 1;
  String? _jwt;
  int? _userId;
  bool _isInitialized = false;
  
  // Cache for favorite statuses to avoid redundant API calls
  final Map<int, bool> _favoriteCache = {};
  DateTime? _lastFavoriteRefresh;
  
  // Debouncing for scroll events
  DateTime? _lastScrollCheck;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadJWTAndFirstPage();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This will refresh favorite statuses when the tab becomes visible
    if (_isInitialized && _products.isNotEmpty && _jwt != null) {
      _refreshFavoriteStatuses();
    }
  }

  // Add new method to refresh favorite statuses
  Future<void> _refreshFavoriteStatuses() async {
    if (_jwt == null || _products.isEmpty || !mounted) return;

    // Only refresh if cache is older than 30 seconds or doesn't exist
    final now = DateTime.now();
    if (_lastFavoriteRefresh != null && 
        now.difference(_lastFavoriteRefresh!).inSeconds < 30) {
      return;
    }

    try {
      final productIds = _products.map((p) => p.productId).toList();
      final favoriteMap = await FavoriteService().checkMultipleFavorites(_jwt!, productIds);
      
      if (mounted) {
        // Update cache
        _favoriteCache.addAll(favoriteMap);
        _lastFavoriteRefresh = now;
        
        setState(() {
          for (var product in _products) {
            final newFavoriteStatus = favoriteMap[product.productId];
            if (newFavoriteStatus != null) {
              product.isLiked = newFavoriteStatus;
            }
          }
        });
      }
    } catch (e) {
      // Silently handle errors to avoid disrupting the UI
    }
  }

  void _onScroll() {
    // Debounce scroll events to improve performance
    final now = DateTime.now();
    if (_lastScrollCheck != null && 
        now.difference(_lastScrollCheck!).inMilliseconds < 100) {
      return;
    }
    _lastScrollCheck = now;
    
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _currentPage + 1 < _totalPages) {
      _currentPage += 1;
      _fetchProducts();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _favoriteCache.clear();
    super.dispose();
  }
  // Helper method to update a single product's favorite status
  Future<void> _updateSingleProductFavoriteStatus(int productIndex) async {
    if (_jwt == null || !mounted || productIndex >= _products.length) return;
    
    final productId = _products[productIndex].productId;
    
    // Clear cache for this specific product
    _favoriteCache.remove(productId);
    
    try {
      final (isFavorite, error) = await FavoriteService().checkFavorite(_jwt!, productId);
      if (error == null && isFavorite != null && mounted) {
        setState(() {
          _products[productIndex].isLiked = isFavorite;
        });
        // Update cache with new status
        _favoriteCache[productId] = isFavorite;
      }
    } catch (e) {
      // Silently handle errors to avoid disrupting the UI
    }
  }

  Future<void> _loadJWTAndFirstPage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _jwt = prefs.getString("auth_token");
        _userId = prefs.getInt("user_id");
      });
      
      if (_jwt == null) {
        if (mounted) {
          _showError("Authentication token is missing.");
        }
        setState(() => _isLoading = false);
        return;
      }
      
      await _fetchProducts();
      _isInitialized = true;
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError("Failed to load auth token: ${e.toString()}");
      }
    }
  }

  Future<void> _fetchProducts() async {
    if (_jwt == null || !mounted) return;

    setState(() => _isLoading = true);
    
    try {
      final (data, error) = await ProductService().getAllProducts(_jwt!, _currentPage);
      
      if (!mounted) return;
      
      if (error != null || data == null) {
        _showError(error?.message ?? "Failed to load products.");
      } else {
        List<SimpleProductResponse> newProducts = data.content;
        
        // Filter products
        final productsToDisplay = newProducts.where((product) {
          bool isNotSold = !(product.productStatus != null && product.productStatus!.toUpperCase() == 'SOLD');
          bool isNotCurrentUserProduct = _userId == null || product.userId == null || product.userId != _userId;
          return isNotSold && isNotCurrentUserProduct;
        }).toList();
        
        // Only update state if we have products to add or if this is the first page
        if (productsToDisplay.isNotEmpty || _currentPage == 0) {
          setState(() {
            _products.addAll(productsToDisplay);
            _totalPages = data.page.totalPages;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _showError("Error loading products: ${e.toString()}");
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _toggleFavorite(int index) async {
    final product = _products[index];
    final liked = product.isLiked ?? false;

    setState(() {
      product.isLiked = !liked;
    });

    final service = FavoriteService();
    final error = liked
        ? await service.unfavorite(_jwt!, product.productId)
        : await service.favorite(_jwt!, product.productId);

    if (error != null) {
      setState(() {
        product.isLiked = liked; // revert
      });
      _showError(error.message);
    } else {
      // Update cache with the new favorite status
      _favoriteCache[product.productId] = !liked;
    }
  }

  // Add refresh method
  Future<void> _onRefresh() async {
    if (_isRefreshing || _jwt == null) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      // Reset pagination and clear products
      _currentPage = 0;
      _totalPages = 1;
      _products.clear();
      _favoriteCache.clear();
      _lastFavoriteRefresh = null;
      
      // Fetch fresh data
      await _fetchProducts();
      
      // Refresh favorite statuses
      if (_products.isNotEmpty) {
        await _refreshFavoriteStatuses();
      }
    } catch (e) {
      if (mounted) {
        _showError("Failed to refresh: ${e.toString()}");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_products.isEmpty && _isLoading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_products.isEmpty && !_isRefreshing) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: const Center(
              child: Text("No products available."),
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 3/4,
        ),
        itemCount: _products.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _products.length) {
            return Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final product = _products[index];
          return SimpleProductCard(
            jwt: _jwt!,
            product: product,
            isFavorite: product.isLiked ?? false,
            onFavorite: () => _toggleFavorite(index),
            onTap: () async {
              final shouldRefresh = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailPage(productId: _products[index].productId),
                ),
              );
              if (shouldRefresh == true && mounted) {
                await _updateSingleProductFavoriteStatus(index);
              }
            },
          );
        },
      ),
    );
  }
}