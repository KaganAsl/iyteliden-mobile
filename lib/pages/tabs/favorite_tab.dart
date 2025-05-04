import 'package:flutter/material.dart';
import 'package:iyteliden_mobile/models/response/product_response.dart';
import 'package:iyteliden_mobile/services/favorite_service.dart';
import 'package:iyteliden_mobile/widgets/simple_product_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteTab extends StatefulWidget {
  const FavoriteTab({super.key});

  @override
  State<StatefulWidget> createState() => _FavoriteTabState();
}

class _FavoriteTabState extends State<FavoriteTab> {
  
  final ScrollController _scrollController = ScrollController();
  final List<SimpleProductResponse> _favorites = [];
  bool _isLoading = false;
  int _currentPage = 0;
  int _totalPages = 1;
  String? _jwt;

  @override
  void initState() {
    super.initState();
    _loadJWTAndFirstPage();
    _scrollController.addListener(_onScroll);
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

  Future<void> _loadJWTAndFirstPage() async {
    final prefs = await SharedPreferences.getInstance();
    _jwt = prefs.getString("auth_token");
    if (_jwt == null) {
      _showError("Authentication token missing.");
      return;
    }
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    if (_jwt == null) return;

    setState(() => _isLoading = true);
    final (data, error) = await FavoriteService().getAllFavorites(_jwt!, _currentPage);
    if (mounted) {
      if (error != null || data == null) {
        _showError(error?.message ?? "Failed to load favorites.");
      } else {
        setState(() {
          _favorites.addAll(data.content);
          _totalPages = data.page.totalPages;
        });
      }
      setState(() => _isLoading = false);
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
    if (_favorites.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator(),);
    }
    if (_favorites.isEmpty) {
      return const Center(child: Text("You have no favorite product."),);
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
          return const Center(child: CircularProgressIndicator(),);
        }
        final product = _favorites[index];
        return SimpleProductCard(
          jwt: _jwt!,
          product: product,
          isFavorite: product.isLiked ?? true,
          onFavorite: () => _toggleFavorite(index),
        );
      },
    );
  }
}