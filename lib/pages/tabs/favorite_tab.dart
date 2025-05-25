import 'package:flutter/material.dart';
import 'package:iyteliden_mobile/models/response/product_response.dart';
import 'package:iyteliden_mobile/pages/product_details_page.dart';
import 'package:iyteliden_mobile/services/favorite_service.dart';
import 'package:iyteliden_mobile/utils/app_colors.dart';
import 'package:iyteliden_mobile/widgets/simple_product_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteTab extends StatefulWidget {
  const FavoriteTab({super.key});

  @override
  State<StatefulWidget> createState() => _FavoriteTabState();
}

class _FavoriteTabState extends State<FavoriteTab> with AutomaticKeepAliveClientMixin {
  
  final ScrollController _scrollController = ScrollController();
  final List<SimpleProductResponse> _favorites = [];
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
    if (_isInitialized && _favorites.isNotEmpty && _jwt != null) {
      _refreshFavorites();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _currentPage + 1 < _totalPages) {
      _currentPage += 1;
      _fetchFavorites();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshFavorites() async {
    if (!mounted || _jwt == null) return;
    
    try {
      // Complete reset to get fresh data
      setState(() {
        _favorites.clear();
        _currentPage = 0;
      });
      await _fetchFavorites();
    } catch (e) {
      _showError("Error");
    }
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
      
      await _fetchFavorites();
      _isInitialized = true;
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError("Failed to load auth token: ${e.toString()}");
      }
    }
  }

  Future<void> _fetchFavorites() async {
    if (_jwt == null || !mounted) return;

    try {
      setState(() => _isLoading = true);
      final (data, error) = await FavoriteService().getAllFavorites(_jwt!, _currentPage);
      
      if (!mounted) return;
      
      if (error != null || data == null) {
        _showError(error?.message ?? "Failed to load favorites.");
        setState(() => _isLoading = false);
      } else {
        setState(() {
          _favorites.addAll(data.content);
          _totalPages = data.page.totalPages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError("Error loading favorites: ${e.toString()}");
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _toggleFavorite(int index) async {
    final product = _favorites[index];
    final liked = product.isLiked ?? true;

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
    } else if (liked) {
      // Remove from list if unfavorited
      setState(() {
        _favorites.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_favorites.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary),);
    }
    if (_favorites.isEmpty) {
      return const Center(child: Text("You don't have any favorite products."),);
    }
    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3/4,
      ),
      itemCount: _favorites.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _favorites.length) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary),);
        }
        final product = _favorites[index];
        return SimpleProductCard(
          jwt: _jwt!,
          product: product,
          isFavorite: product.isLiked ?? true,
          onFavorite: () => _toggleFavorite(index),
          onTap: () async {
            final shouldRefresh = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailPage(productId: _favorites[index].productId),
              ),
            );
            if (shouldRefresh == true && mounted) {
              // Refresh all favorites since status might have changed
              _refreshFavorites();
            }
          },
        );
      },
    );
  }
}