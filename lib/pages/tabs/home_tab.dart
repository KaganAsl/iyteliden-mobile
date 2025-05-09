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

class _HomeTabState extends State<HomeTab> {

  final ScrollController _scrollController = ScrollController();
  final List<SimpleProductResponse> _products= [];
  bool _isLoading = false;
  int _currentPage = 0;
  int _totalPages = 1;
  String? _jwt;

  @override
  void initState() {
    super.initState();
    _loadJwtAndFirstPage();
    _scrollController.addListener(_onScroll);
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

  Future<void> _loadJwtAndFirstPage() async {
    final prefs = await SharedPreferences.getInstance();
    _jwt = prefs.getString("auth_token");
    if (_jwt == null) {
      _showFeedbackSnackBar("Authentication token missing.", isError: true);
      return;
    }
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    if (_jwt == null) return;
    setState(() => _isLoading = true);
    final (data, error) = await ProductService().getMainPage(_jwt!, _currentPage);
    if (mounted) {
      if (error != null || data == null) {
        _showFeedbackSnackBar(error?.message ?? "Failed to load products.", isError: true);
      } else {
        setState(() {
          _products.addAll(data.content);
          _totalPages = data.page.totalPages;
          _isLoading = false;
        });
      }
    }
    _fetchLikes();
  }

  void _fetchLikes() async {
    for (var product in _products) {
      final (liked, error) = await FavoriteService().checkFavorite(_jwt!, product.productId);
      if (error == null) {
        setState(() {
          product.isLiked = liked!;
        });
      }
    }
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
      _showFeedbackSnackBar(error.message, isError: true);
    }
  }

  void _showFeedbackSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(10),
      action: SnackBarAction(
        label: "OK",
        textColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  State<StatefulWidget> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final ScrollController _scrollController = ScrollController();
  final List<SimpleProductResponse> _products = [];
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
      _fetchProducts();
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
      _showError("Authentication token is missing.");
      return;
    }
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    if (_jwt == null) return;

    setState(() => _isLoading = true);
    final (data, error) = await ProductService().getAllProducts(_jwt!, _currentPage);
    if (mounted) {
      if (error != null || data == null) {
        _showError(error?.message ?? "Failed to load products.");
      } else {
        setState(() {
          _products.addAll(data.content);
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
            }
          },
        );
      },
    );
  }
}