import 'package:flutter/material.dart';
import 'package:iyteliden_mobile/models/response/error_response.dart';
import 'package:iyteliden_mobile/models/response/image_response.dart';
import 'package:iyteliden_mobile/models/response/product_response.dart';
import 'package:iyteliden_mobile/pages/profile_page.dart';
import 'package:iyteliden_mobile/pages/public_profile_page.dart';
import 'package:iyteliden_mobile/pages/products_by_location_page.dart';
import 'package:iyteliden_mobile/pages/products_by_category_page.dart';
import 'package:iyteliden_mobile/services/favorite_service.dart';
import 'package:iyteliden_mobile/services/image_service.dart';
import 'package:iyteliden_mobile/services/message_service.dart';
import 'package:iyteliden_mobile/services/product_service.dart';
import 'package:iyteliden_mobile/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iyteliden_mobile/pages/edit_product_page.dart';

class ProductDetailPage extends StatefulWidget {

  final int productId;
  const ProductDetailPage({super.key, required this.productId});

  @override
  State<StatefulWidget> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {

  late Future<DetailedProductResponse> _productDetails;
  String? _jwt;
  bool _isOwner = false;
  bool _isLiked = false;
  int _currentImageIndex = 0;
  bool _isDeleting = false;
  bool _favoritesChanged = false;

  // Define colors for easy use
  static const Color primaryRed = Color(0xFF9B0A1A);
  static const Color primaryDarkGray = Color(0xFF414143);
  static const Color primaryWhite = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _productDetails = _fetchProductDetails();
  }

  Future<DetailedProductResponse> _fetchProductDetails() async {
    final prefs = await SharedPreferences.getInstance();
    _jwt = prefs.getString("auth_token");
    final (productDetails, error) = await ProductService().getDetailedProduct(_jwt!, widget.productId);
    if (productDetails == null) {
      _showFeedbackSnackBar("Failed to load product details", isError: true);
      throw Exception(error?.message ?? "Failed to load product details.");
    }
    bool owner = await _checkOwnership(productDetails);
    if (!owner) {
      final (like, error) = await FavoriteService().checkFavorite(_jwt!, widget.productId);
      if (like != null) {
        setState(() {
          _isLiked = like;
        });
        productDetails.isLiked = _isLiked;
      }
    }
    return productDetails;
  }

  Future<bool> _checkOwnership(DetailedProductResponse product) async {
    final (isOwner, error) = await ProductService().isMyProduct(_jwt!, widget.productId);
    if (isOwner != null) {
      setState(() {
        _isOwner = isOwner;
      });
    }
    return _isOwner;
  }

  void _showFeedbackSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final snackBar = SnackBar(
      content: Text(message, style: const TextStyle(color: primaryWhite)),
      backgroundColor: isError ? primaryRed : Colors.green, // Keeping green for success for now
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(10),
      action: SnackBarAction(
        label: "OK",
        textColor: primaryWhite,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _toggleFavoriteForProduct(DetailedProductResponse product) async {
    final liked = product.isLiked ?? true;
    setState(() {
      product.isLiked = !liked;
      _isLiked = !liked;
    });

    final service = FavoriteService();
    final error = liked
        ? await service.unfavorite(_jwt!, product.productId)
        : await service.favorite(_jwt!, product.productId);

    if (error != null) {
      setState(() {
        product.isLiked = liked; // revert
        _isLiked = liked;
      });
      _showFeedbackSnackBar(error.message, isError: true);
    } else {
      _favoritesChanged = true;
      _showFeedbackSnackBar(liked ? "Removed from favorites." : "Added to favorites.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DetailedProductResponse>(
        future: _productDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(backgroundColor: primaryWhite, body: Center(child: CircularProgressIndicator(color: primaryRed)));
          } else if (snapshot.hasError) {
            // ... (your existing error handling for product not found, etc.)
            if (snapshot.error.toString().contains('404') ||
                snapshot.error.toString().contains('not found') ||
                snapshot.error.toString().contains('Failed to load product details.')) { // Broader check
              return Scaffold(
                backgroundColor: primaryWhite,
                appBar: AppBar(
                  backgroundColor: primaryWhite,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: primaryDarkGray),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                body: const Center(
                  child: Text(
                    'This product has been deleted or is no longer available.',
                    style: TextStyle(color: primaryDarkGray),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return Scaffold(
              backgroundColor: primaryWhite,
              body: Center(child: Text('Error loading product: ${snapshot.error}', style: const TextStyle(color: primaryDarkGray)))
            );
          } else if (!snapshot.hasData) {
            return const Scaffold(
              backgroundColor: primaryWhite,
              body: Center(child: Text('No product details available.', style: TextStyle(color: primaryDarkGray)))
            );
          }
          final product = snapshot.data!;
          final imageCount = product.imageUrls.length;
          bool isSold = product.productStatus != null && product.productStatus!.toUpperCase() == 'SOLD';

          return Scaffold(
            backgroundColor: primaryWhite,
            appBar: AppBar(
              title: Text(
                product.productName,
                style: const TextStyle(
                  color: primaryDarkGray,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              backgroundColor: primaryWhite,
              elevation: 0,
               leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: primaryDarkGray),
                onPressed: () => Navigator.of(context).pop(_favoritesChanged),
              ),
              actions: [
                _isOwner
                    ? PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz, color: primaryDarkGray),
                        itemBuilder: (popupContext) {
                          List<PopupMenuEntry<String>> menuItems = [];
                          if (!isSold) {
                            menuItems.add(const PopupMenuItem(value: 'edit', child: Text('Edit')));
                          }
                          menuItems.add(const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: primaryRed))));
                          return menuItems;
                        },
                        onSelected: (value) async {
                          if (value == 'edit') {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditProductPage(productId: widget.productId),
                              ),
                            );
                            if (result == true && mounted) {
                              setState(() {
                                _productDetails = _fetchProductDetails();
                                _favoritesChanged = true;
                              });
                            }
                          } else if (value == 'delete') {
                            showDialog(
                              context: context,
                              builder: (BuildContext dialogBuilderContext) {
                                return AlertDialog(
                                  title: const Text('Delete Product'),
                                  content: const Text('Are you sure you want to delete this product? This action cannot be undone.'),
                                  actions: [
                                    TextButton(
                                      onPressed: _isDeleting ? null : () => Navigator.of(dialogBuilderContext).pop(),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: _isDeleting ? null : () async {
                                        if (!mounted) return;

                                        setState(() { _isDeleting = true; });
                                        Navigator.of(dialogBuilderContext).pop();

                                        String? currentRawJwt = _jwt;
                                        String correctedJwt = currentRawJwt?.replaceAll("Bearer\n", "Bearer ") ?? "";
                                        correctedJwt = correctedJwt.trim();

                                        if (correctedJwt.isEmpty ||
                                            !correctedJwt.startsWith("Bearer ") ||
                                            correctedJwt.length < "Bearer ".length + 30) {
                                          _showFeedbackSnackBar('Authentication error - token invalid or missing.', isError: true);
                                          if (mounted) {
                                            setState(() { _isDeleting = false; });
                                          }
                                          return;
                                        }

                                        String? finalErrorMessageForSnackbar;

                                        try {
                                          final error = await ProductService().deleteProduct(correctedJwt, widget.productId);

                                          if (!mounted) return;

                                          if (error != null) {
                                            finalErrorMessageForSnackbar = error.message;
                                          } else {
                                            _showFeedbackSnackBar('Product deleted successfully!', isError: false);

                                            await Navigator.of(this.context).pushAndRemoveUntil(
                                              MaterialPageRoute(builder: (newContext) => const ProfilePage()),
                                              (Route<dynamic> route) => route.isFirst,
                                            );
                                            return;
                                          }
                                        } catch (e) {
                                          if (!mounted) return;
                                          finalErrorMessageForSnackbar = 'An unexpected error occurred: ${e.toString()}';
                                        }

                                        if (mounted) {
                                          setState(() { _isDeleting = false; });
                                          _showFeedbackSnackBar(finalErrorMessageForSnackbar, isError: true);
                                        }
                                      },
                                      child: _isDeleting
                                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: primaryRed))
                                          : const Text('Delete', style: TextStyle(color: primaryRed)),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        },
                      )
                    : !_isOwner && !isSold 
                        ? IconButton(
                            icon: _isLiked ? const Icon(Icons.favorite, color: primaryRed) : const Icon(Icons.favorite_border, color: primaryDarkGray),
                            onPressed: () {
                              _toggleFavoriteForProduct(product);
                            },
                          )
                        : const SizedBox.shrink(),
              ],
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageCount > 0)
                      Column(
                        children: [
                          SizedBox(
                            height: 250,
                            child: FutureBuilder<(ImageResponse?, ErrorResponse?)>(
                              future: ImageService().getImage(_jwt!, product.imageUrls[_currentImageIndex]),
                              builder: (context, imgSnapshot) {
                                if (imgSnapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator(color: primaryRed),);
                                }
                                if (imgSnapshot.hasError || imgSnapshot.data?.$1?.url == null) {
                                  return Container(
                                    height: 250,
                                    width: double.infinity,
                                    color: Colors.grey[200],
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.broken_image_outlined, size: 48, color: primaryDarkGray),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Image not available',
                                          style: TextStyle(color: primaryDarkGray),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return Image.network(
                                  imgSnapshot.data!.$1!.url,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 250,
                                      width: double.infinity,
                                      color: Colors.grey[200],
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.broken_image_outlined, size: 48, color: primaryDarkGray),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Failed to load image',
                                            style: TextStyle(color: primaryDarkGray),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(Icons.arrow_back, color: _currentImageIndex > 0 ? primaryDarkGray : Colors.grey[400]),
                                onPressed: _currentImageIndex > 0
                                  ? () => setState(() {
                                    _currentImageIndex--;
                                  }) : null,
                              ),
                              Text('${_currentImageIndex + 1} / $imageCount', style: const TextStyle(color: primaryDarkGray)),
                              IconButton(
                                icon: Icon(Icons.arrow_forward, color: _currentImageIndex < imageCount - 1 ? primaryDarkGray : Colors.grey[400]),
                                onPressed: _currentImageIndex < imageCount - 1
                                    ? () => setState(() {
                                          _currentImageIndex++;
                                        })
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      )
                    else const Icon(Icons.image_not_supported_outlined, size: 48, color: primaryDarkGray),
                    const SizedBox(height: 16,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${product.price.toStringAsFixed(2)} ₺',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                            if (product.productStatus != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  "Status: ${product.productStatus}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSold ? primaryRed : Colors.green,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!_isOwner && !isSold)
                              ElevatedButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      final TextEditingController messageController = TextEditingController();
                                      return AlertDialog(
                                        backgroundColor: primaryWhite,
                                        title: const Text('Send Message', style: TextStyle(color: primaryDarkGray)),
                                        content: Card(
                                          color: primaryWhite,
                                          elevation: 0,
                                          child: TextField(
                                            controller: messageController,
                                            style: const TextStyle(color: primaryDarkGray),
                                            decoration: InputDecoration(
                                              hintText: 'Type your message...',
                                              hintStyle: TextStyle(color: primaryDarkGray.withOpacity(0.6)),
                                              border: const OutlineInputBorder(),
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(color: primaryDarkGray.withOpacity(0.5)),
                                              ),
                                              focusedBorder: const OutlineInputBorder(
                                                borderSide: BorderSide(color: primaryRed),
                                              ),
                                            ),
                                            maxLines: 3,
                                            autofocus: true,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(),
                                            child: const Text('Cancel', style: TextStyle(color: primaryDarkGray)),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              if (messageController.text.trim().isEmpty) {
                                                _showFeedbackSnackBar('Message cannot be empty', isError: true);
                                                return;
                                              }

                                              Navigator.of(context).pop(); // Close dialog
                                              
                                              final prefs = await SharedPreferences.getInstance();
                                              final jwt = prefs.getString('auth_token');
                                              
                                              if (jwt == null) {
                                                _showFeedbackSnackBar('Not authenticated', isError: true);
                                                return;
                                              }

                                              final (message, error) = await MessageService().sendSimpleMessage(
                                                jwt,
                                                messageController.text.trim(),
                                                widget.productId
                                              );

                                              if (error != null) {
                                                _showFeedbackSnackBar(error.message, isError: true);
                                                return;
                                              }

                                              if (message != null) {
                                                _showFeedbackSnackBar('Message sent successfully! You can see in messages tab.');
                                              }
                                            },
                                            child: const Text('Send', style: TextStyle(color: primaryRed)),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.background,
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                  elevation: 2.0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                child: const Text("Message", style: TextStyle(fontSize: 16))
                                ,
                              ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                if (_isOwner) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProfilePage(
                                        focusedProductId: product.productId,
                                        focusedProductStatus: product.productStatus,
                                      ),
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PublicProfilePage(
                                        userId: product.user.userId,
                                        focusedProductId: product.productId,
                                        focusedProductStatus: product.productStatus,
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.background,
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                elevation: 2.0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              child: Text(
                                "Seller: ${product.user.userName}",
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Description:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryDarkGray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description,
                      style: const TextStyle(fontSize: 16, color: primaryDarkGray),
                    ),
                    const SizedBox(height: 16,),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Category:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: () async {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductsByCategoryPage(
                                    categoryId: product.category.categoryId,
                                    categoryName: product.category.categoryName,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.background,
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              elevation: 2.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: Text(product.category.categoryName),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8,),
                    if (product.locations.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Available Locations:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 4.0,
                              children: product.locations.map((location) {
                                return ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProductsByLocationPage(
                                          locationId: location.locationId,
                                          locationName: location.locationName,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.background,
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                    elevation: 2.0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                  child: Text(location.locationName),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }
    );
  }
}