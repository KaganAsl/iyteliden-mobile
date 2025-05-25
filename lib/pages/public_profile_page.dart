import 'package:flutter/material.dart';
import 'package:iyteliden_mobile/models/response/product_response.dart';
import 'package:iyteliden_mobile/models/response/user_response.dart';
import 'package:iyteliden_mobile/pages/product_details_page.dart';
import 'package:iyteliden_mobile/pages/user_reviews_page.dart';
import 'package:iyteliden_mobile/services/favorite_service.dart';
import 'package:iyteliden_mobile/services/product_service.dart';
import 'package:iyteliden_mobile/services/review_service.dart';
import 'package:iyteliden_mobile/services/user_service.dart';
import 'package:iyteliden_mobile/widgets/simple_product_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iyteliden_mobile/utils/app_colors.dart';

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
  final ReviewService _reviewService = ReviewService();
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

  Future<double> _loadRating(int userId) async {
    if (_jwt == null) throw Exception("JWT not found");
    final (res, err) = await _reviewService.getRatingAverageForUser(_jwt!, userId);
    if (err != null) {
    }
    return res!;
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
          return Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Failed to load user."),);
        }
        final user = snapshot.data!;
        return Scaffold(
          appBar: AppBar(
            title: Text(user.userName, style: TextStyle(color: AppColors.background)),
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: AppColors.background),
            elevation: 1,
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[300],
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.grey[600],
                      ),
                      // TODO: Replace with NetworkImage(user.profilePictureUrl) if available in UserResponse
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.userName, 
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "User ID: ${user.userId}", 
                          style: TextStyle(fontSize: 14, color: Colors.grey[600])
                        ),
                        const SizedBox(height: 8),
                        // Rating display
                        FutureBuilder<double>(
                          future: _loadRating(user.userId),
                          builder: (context, ratingSnapshot) {
                            if (ratingSnapshot.connectionState == ConnectionState.waiting) {
                              return Row(
                                children: [
                                  SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Loading rating...",
                                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                  ),
                                ],
                              );
                            }
                            
                            if (ratingSnapshot.hasError || !ratingSnapshot.hasData) {
                              return Row(
                                children: [
                                  Icon(Icons.star_border, size: 16, color: Colors.grey[400]),
                                  const SizedBox(width: 4),
                                  Text(
                                    "No rating yet",
                                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                  ),
                                ],
                              );
                            }
                            
                            final rating = ratingSnapshot.data!;
                            final fullStars = rating.floor();
                            final hasHalfStar = rating - fullStars >= 0.5;
                            
                            return Row(
                              children: [
                                // Display stars
                                Row(
                                  children: List.generate(5, (index) {
                                    if (index < fullStars) {
                                      return Icon(Icons.star, size: 16, color: Colors.amber);
                                    } else if (index == fullStars && hasHalfStar) {
                                      return Icon(Icons.star_half, size: 16, color: Colors.amber);
                                    } else {
                                      return Icon(Icons.star_border, size: 16, color: Colors.grey[400]);
                                    }
                                  }),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "${rating.toStringAsFixed(1)} / 5.0",
                                  style: TextStyle(
                                    fontSize: 14, 
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        // Reviews button
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserReviewsPage(
                                  userId: user.userId,
                                  userName: user.userName,
                                ),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.rate_review_outlined,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          label: Text(
                            "View Reviews",
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 12.0, bottom: 8.0),
                child: Text(
                  "${user.userName}'s Products",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color ?? AppColors.text, 
                  ),
                ),
              ),
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
        if (pageData.content.isNotEmpty) {
          final productIds = pageData.content.map((p) => p.productId).toList();
          final favoriteMap = await FavoriteService().checkMultipleFavorites(widget.jwt, productIds);
          
          // Assign fetched favorite statuses to products
          for (var product in pageData.content) {
            product.isLiked = favoriteMap[product.productId] ?? false;
          }
        }
        
        setState(() {
          _products.addAll(pageData.content);
          _totalPages = pageData.page.totalPages;

          if (widget.focusedProductId != null && widget.focusedProductStatus != null) {
            final index = _products.indexWhere((p) => p.productId == widget.focusedProductId);
            if (index != -1) {
            }
          }

          // Sort products: available first, then sold
          _products.sort((a, b) {
            final aIsSold = a.productStatus?.toUpperCase() == 'SOLD';
            final bIsSold = b.productStatus?.toUpperCase() == 'SOLD';
            
            if (aIsSold && !bIsSold) return 1; // a is sold, b is not -> b comes first
            if (!aIsSold && bIsSold) return -1; // a is not sold, b is -> a comes first
            return 0; // both have same status, keep original order
          });
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

    // Optimistically update UI
    if (mounted) {
      setState(() {
        product.isLiked = !liked;
      });
    }

    final service = FavoriteService();
    final error = liked
        ? await service.unfavorite(widget.jwt, product.productId)
        : await service.favorite(widget.jwt, product.productId);

    // Revert if error or if widget is no longer mounted
    if (error != null && mounted) {
      setState(() {
        product.isLiked = liked;
      });
      _showError(error.message);
    } else if (error == null && mounted) {
      // Optionally show success feedback for the user
      // _showSuccessMessage(liked ? "Removed from favorites" : "Added to favorites");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_products.isEmpty && _isLoading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
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
          return Center(child: CircularProgressIndicator(color: AppColors.primary));
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
            if (shouldRefresh == true && mounted) {
              // Update just this product's favorite status instead of full refresh
              final (isFavorite, error) = await FavoriteService().checkFavorite(widget.jwt, _products[index].productId);
              if (error == null && isFavorite != null && mounted) {
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