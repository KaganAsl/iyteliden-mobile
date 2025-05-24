import 'package:flutter/material.dart';
import 'package:iyteliden_mobile/models/response/product_response.dart';
import 'package:iyteliden_mobile/models/response/user_response.dart';
import 'package:iyteliden_mobile/pages/product_details_page.dart';
import 'package:iyteliden_mobile/services/favorite_service.dart';
import 'package:iyteliden_mobile/services/product_service.dart';
import 'package:iyteliden_mobile/services/user_service.dart';
import 'package:iyteliden_mobile/widgets/simple_product_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PublicProfilePage extends StatefulWidget {
  
  final int userId;
  final int? focusedProductId;
  final String? focusedProductStatus;

  const PublicProfilePage({
    super.key, 
    required this.userId,
    this.focusedProductId,
    this.focusedProductStatus,
  });

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {

  late Future<UserResponse> _userFuture;
  String? _jwt;

  @override
  void initState() {
    super.initState();
    _userFuture = _loadUser();
  }

  Future<UserResponse> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _jwt = prefs.getString("auth_token");
    if (_jwt == null) throw Exception("JWT not found");
    final (user, error) = await UserService().getUserProfile(_jwt!, widget.userId);
    if (error != null) {
      _showFeedbackSnackBar("Couldn't fetch user.", isError: true);
      throw Exception(error.message);
    }
    return user!;
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
  Widget build(BuildContext context) {
    return FutureBuilder<UserResponse>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(),);
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Failed to load user."),);
        }
        final user = snapshot.data!;
        return Scaffold(
          appBar: AppBar(
            title: Text(user.userName),
            backgroundColor: Colors.white,
            elevation: 1,
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Username: ${user.userName}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const Divider(height: 1,),
              Expanded(
                child: ProductList(
                  jwt: _jwt!,
                  ownerId: user.userId,
                  focusedProductId: widget.focusedProductId,
                  focusedProductStatus: widget.focusedProductStatus,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ProductList extends StatefulWidget {
  
  final String jwt;
  final int ownerId;
  final int? focusedProductId;
  final String? focusedProductStatus;

  const ProductList({
    super.key, 
    required this.jwt, 
    required this.ownerId,
    this.focusedProductId,
    this.focusedProductStatus,
  });

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {

  final List<SimpleProductResponse> _products = [];
  final ScrollController _controller = ScrollController();
  int _currentPage = 0;
  int _totalPages = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPage();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    if (_controller.position.pixels >= _controller.position.maxScrollExtent - 200 &&
        !_isLoading && _currentPage + 1 < _totalPages) {
      _currentPage += 1;
      _fetchPage();
    }
  }

  Future<void> _fetchPage() async {
    setState(() => _isLoading = true);
    final (pageData, error) = await ProductService().getSimpleProducts(widget.jwt, widget.ownerId, _currentPage);
    if (mounted) {
      if (error == null && pageData != null) {
        // Fetch favorite status for all products concurrently
        List<bool?> favoriteStatuses = await Future.wait(
          pageData.content.map((p) async {
            final (isFavorite, favError) = await FavoriteService().checkFavorite(widget.jwt, p.productId);
            if (favError == null) {
              return isFavorite;
            }
            return null; // Or handle error appropriately
          }).toList()
        );

        // Assign fetched favorite statuses to products
        for (int i = 0; i < pageData.content.length; i++) {
          pageData.content[i].isLiked = favoriteStatuses[i];
        }
        
        setState(() {
          _products.addAll(pageData.content);
          _totalPages = pageData.page.totalPages;

          if (widget.focusedProductId != null && widget.focusedProductStatus != null) {
            final index = _products.indexWhere((p) => p.productId == widget.focusedProductId);
            if (index != -1) {
            }
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error?.message ?? 'Failed to fetch products'), backgroundColor: Colors.redAccent));
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
        ? await service.unfavorite(widget.jwt, product.productId)
        : await service.favorite(widget.jwt, product.productId);

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
      return const Center(child: CircularProgressIndicator());
    }
    if (_products.isEmpty) {
      return const Center(child: Text("No products to display."));
    }
    return GridView.builder(
      controller: _controller,
      padding: EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.6,
      ),
      itemCount: _products.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _products.length) {
          return const Center(child: CircularProgressIndicator(),);
        }
        final product = _products[index];
        String? displayStatus = product.productStatus;
        if (widget.focusedProductId != null && product.productId == widget.focusedProductId) {
          displayStatus = widget.focusedProductStatus;
        }

        return SimpleProductCard(
          jwt: widget.jwt,
          product: product,
          productStatus: displayStatus,
          isFavorite: product.isLiked ?? false,
          onFavorite: () => _toggleFavorite(index),
          onTap: () async {
            final shouldRefresh = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailPage(productId: _products[index].productId),
              ),
            );
            if (shouldRefresh == true) {
              setState(() {
                _products.clear();
                _currentPage = 0;
              });
              _fetchPage();
            }
          },
        );
      },
    );
  }
}