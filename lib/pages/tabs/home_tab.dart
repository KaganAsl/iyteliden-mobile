import 'package:flutter/material.dart';
import 'package:iyteliden_mobile/models/response/product_response.dart';
import 'package:iyteliden_mobile/pages/product_details_page.dart';
import 'package:iyteliden_mobile/services/favorite_service.dart';
import 'package:iyteliden_mobile/services/product_service.dart';
import 'package:iyteliden_mobile/widgets/simple_product_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});
  
  @override
  State<StatefulWidget> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final List<SimpleProductResponse> _products = [];
  bool _isLoading = false;
  int _currentPage = 0;
  int _totalPages = 1;
  String? _jwt;
  bool _isInitialized = false;

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

    for (int i = 0; i < _products.length; i++) {
      try {
        final (isFavorite, error) = await FavoriteService().checkFavorite(_jwt!, _products[i].productId);
        if (error == null && mounted && isFavorite != _products[i].isLiked) {
          setState(() {
            _products[i].isLiked = isFavorite;
          });
        }
      } catch (e) {
        // Silently handle errors to avoid disrupting the UI
        print("Error refreshing favorite status: $e");
      }
    }
  }

  void _onScroll() {
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
    super.dispose();
  }

  Future<void> _loadJWTAndFirstPage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _jwt = prefs.getString("auth_token");
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

    try {
      setState(() => _isLoading = true);
      final (data, error) = await ProductService().getAllProducts(_jwt!, _currentPage);
      
      if (!mounted) return;
      
      if (error != null || data == null) {
        _showError(error?.message ?? "Failed to load products.");
        setState(() => _isLoading = false);
      } else {
        setState(() {
          _products.addAll(data.content);
          _totalPages = data.page.totalPages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError("Error loading products: ${e.toString()}");
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
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_products.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator(),);
    }
    if (_products.isEmpty) {
      return const Center(child: Text("No products available."),);
    }
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3/4,
      ),
      itemCount: _products.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _products.length) {
          return const Center(child: CircularProgressIndicator(),);
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
              final (isFavorite, error) = await FavoriteService().checkFavorite(_jwt!, _products[index].productId);
              if (error == null && mounted) {
                setState(() {
                  _products[index].isLiked = isFavorite;
                });
              }
              
              _refreshFavoriteStatuses();
            }
          },
        );
      },
    );
  }
}