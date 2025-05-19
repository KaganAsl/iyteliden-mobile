import 'package:flutter/material.dart';
import 'package:iyteliden_mobile/models/response/product_response.dart';
import 'package:iyteliden_mobile/services/product_service.dart';
import 'package:iyteliden_mobile/widgets/simple_product_card.dart';
import 'package:iyteliden_mobile/pages/product_details_page.dart'; // For navigation
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iyteliden_mobile/models/response/error_response.dart';
import 'package:iyteliden_mobile/services/favorite_service.dart';

class ProductsByLocationPage extends StatefulWidget {
  final int locationId;
  final String locationName;

  const ProductsByLocationPage({
    super.key,
    required this.locationId,
    required this.locationName,
  });

  @override
  State<ProductsByLocationPage> createState() => _ProductsByLocationPageState();
}

class _ProductsByLocationPageState extends State<ProductsByLocationPage> {
  final List<SimpleProductResponse> _products = [];
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  int _totalPages = 1;
  bool _isLoading = false;
  String? _jwt;
  bool _initialLoadError = false;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadJwtAndFetchInitialPage();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadJwtAndFetchInitialPage() async {
    final prefs = await SharedPreferences.getInstance();
    _jwt = prefs.getString("auth_token");
    _currentUserId = prefs.getInt("user_id");

    if (_jwt == null || _jwt!.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _initialLoadError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Authentication error. Please log in again.'),
          backgroundColor: Colors.redAccent,
        ));
      }
      return;
    }
    await _fetchProductsPage();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _currentPage + 1 < _totalPages) {
      _currentPage++;
      _fetchProductsPage();
    }
  }

  Future<void> _fetchProductsPage({bool clearCurrent = false}) async {
    if (!mounted || _jwt == null) return;

    if (clearCurrent) {
      setState(() {
        _products.clear();
        _currentPage = 0;
        _totalPages = 1;
        _initialLoadError = false;
      });
    }

    setState(() => _isLoading = true);

    // This method needs to be created in ProductService
    final (pageData, error) = await ProductService().getProductsByLocation(_jwt!, widget.locationId, _currentPage);

    if (mounted) {
      if (error == null && pageData != null) {
        setState(() {
          List<SimpleProductResponse> productsToDisplay;
          if (_currentUserId != null) {
            // Filter only if _currentUserId is known
            productsToDisplay = pageData.content.where((product) {
              // Keep product if its userId is null (doesn't belong to anyone specific)
              // or if its userId does not match the current user's ID.
              return product.userId == null || product.userId != _currentUserId;
            }).toList();
          } else {
            // If _currentUserId is null, show all products (no filter)
            productsToDisplay = List.from(pageData.content);
          }

          _products.addAll(productsToDisplay);
          _totalPages = pageData.page.totalPages;
          _isLoading = false;
          if (_products.isEmpty && _currentPage == 0) {
            // Handled by build method's empty state
          }
        });
      } else {
        setState(() {
          _isLoading = false;
          if (_currentPage == 0) _initialLoadError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error?.message ?? 'Failed to fetch products for ${widget.locationName}'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Products in ${widget.locationName}'),
      ),
      body: _buildProductList(),
    );
  }

  Widget _buildProductList() {
    if (_isLoading && _products.isEmpty && !_initialLoadError) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_initialLoadError && _products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Could not load products for ${widget.locationName}. Please try again later.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_products.isEmpty) {
      return Center(
        child: Text('No products found in ${widget.locationName}.'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchProductsPage(clearCurrent: true),
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75, // Common aspect ratio for product cards
        ),
        itemCount: _products.length + (_isLoading && _currentPage + 1 < _totalPages ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _products.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final product = _products[index];
          return SimpleProductCard( // Using SimpleProductCard
            jwt: _jwt!, // Ensure _jwt is available and non-null here
            product: product,
            isFavorite: product.isLiked ?? false, // Assuming SimpleProductResponse has isLiked
            onTap: () async {
             final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailPage(productId: product.productId),
                ),
              );
              // If coming back from product details and a favorite status might have changed
              if (result == true && mounted) {
                 _fetchProductsPage(clearCurrent: true);
              }
            },
            onFavorite: () {
              // Toggle favorite and update UI if needed
              // This might require a more complex state management or callback
              // For now, a full refresh could be an option, or manage favorite state locally
               _toggleFavorite(product);
            },
          );
        },
      ),
    );
  }

  // Placeholder for favorite toggling, can be expanded
  void _toggleFavorite(SimpleProductResponse product) async {
    if (_jwt == null) return;

    final favService = FavoriteService();
    ErrorResponse? error;

    // Determine current liked status, default to false if null
    bool currentIsLiked = product.isLiked ?? false;

    if (mounted) {
      // Optimistically update UI
      setState(() {
        product.isLiked = !currentIsLiked;
      });
    }

    if (currentIsLiked) { // If it was liked, now unfavorite it
      error = await favService.unfavorite(_jwt!, product.productId);
    } else { // If it was not liked, now favorite it
      error = await favService.favorite(_jwt!, product.productId);
    }

    if (mounted) {
      if (error != null) {
        // Revert optimistic update on error
        setState(() {
          product.isLiked = currentIsLiked; 
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message ?? "Error updating favorite status."),
            backgroundColor: Colors.redAccent,
          ),
        );
      } else {
        // Optional: Show success message or just rely on UI change
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text(currentIsLiked ? "${product.productName} unfavorited." : "${product.productName} favorited."),
        //     backgroundColor: Colors.green,
        //   ),
        // );
      }
    }
  }
} 