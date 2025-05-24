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
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          } else if (snapshot.hasError) {
            // ... (your existing error handling for product not found, etc.)
            if (snapshot.error.toString().contains('404') ||
                snapshot.error.toString().contains('not found') ||
                snapshot.error.toString().contains('Failed to load product details.')) { // Broader check
              return Scaffold(
                appBar: AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                body: const Center(
                  child: Text('This product has been deleted or is no longer available.'),
                ),
              );
            }
            return Scaffold(body: Center(child: Text('Error loading product: ${snapshot.error}')));
          } else if (!snapshot.hasData) {
            return const Scaffold(body: Center(child: Text('No product details available.')));
          }
          final product = snapshot.data!;
          final imageCount = product.imageUrls.length;
          bool isSold = product.productStatus != null && product.productStatus!.toUpperCase() == 'SOLD';

          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
               leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () => Navigator.of(context).pop(_favoritesChanged),
              ),
              actions: [
                _isOwner
                    ? PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz),
                        itemBuilder: (popupContext) {
                          List<PopupMenuEntry<String>> menuItems = [];
                          if (!isSold) {
                            menuItems.add(const PopupMenuItem(value: 'edit', child: Text('Edit')));
                          }
                          menuItems.add(const PopupMenuItem(value: 'delete', child: Text('Delete')));
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
                                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                          : const Text('Delete', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        },
                      )
                    : IconButton(
                        icon: _isLiked ? const Icon(Icons.favorite, color: Colors.red) : const Icon(Icons.favorite_border),
                        onPressed: () {
                          _toggleFavoriteForProduct(product);
                        },
                      ),
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
                                  return const Center(child: CircularProgressIndicator(),);
                                }
                                if (imgSnapshot.hasError || imgSnapshot.data?.$1?.url == null) {
                                  return Container(
                                    height: 250,
                                    width: double.infinity,
                                    color: Colors.grey[200],
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Image not available',
                                          style: TextStyle(color: Colors.grey[600]),
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
                                          const Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Failed to load image',
                                            style: TextStyle(color: Colors.grey[600]),
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
                                icon: Icon(Icons.arrow_back),
                                onPressed: _currentImageIndex > 0
                                  ? () => setState(() {
                                    _currentImageIndex--;
                                  }) : null,
                              ),
                              Text('${_currentImageIndex + 1} / $imageCount'),
                              IconButton(
                                icon: const Icon(Icons.arrow_forward),
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
                    else const Icon(Icons.image_not_supported_outlined, size: 48),
                    const SizedBox(height: 16,),
                    Text(
                      product.productName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8,),
                    if (product.productStatus != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          "Status: ${product.productStatus}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSold ? Colors.red : Colors.green,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16,),
                    GestureDetector(
                      onTap: () {
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
                      child: Text(
                        "Seller: ${product.user.userName}",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Display Category
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0), // Added some padding
                      child: Row( // Changed to Row for a more compact display
                        children: [
                          const Text(
                            'Category: ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
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
                            child: Chip(
                              label: Text(product.category.categoryName),
                              backgroundColor: Colors.teal[50], // Different color for distinction
                              labelStyle: const TextStyle(color: Colors.black87),
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      product.description,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    // Display Locations
                    if (product.locations.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Available Locations:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 4.0,
                              children: product.locations.map((location) {
                                return GestureDetector(
                                  onTap: () {
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
                                  child: Chip(
                                    label: Text(location.locationName),
                                    backgroundColor: Colors.blueGrey[50],
                                    labelStyle: const TextStyle(color: Colors.black87),
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    if (!_isOwner)
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              final TextEditingController messageController = TextEditingController();
                              return AlertDialog(
                                title: const Text('Send Message'),
                                content: Card(
                                  elevation: 0,
                                  child: TextField(
                                    controller: messageController,
                                    decoration: const InputDecoration(
                                      hintText: 'Type your message...',
                                      border: OutlineInputBorder(),
                                    ),
                                    maxLines: 3,
                                    autofocus: true,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Cancel'),
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
                                        // Navigate back
                                        if (context.mounted) {
                                          Navigator.of(context).pop();
                                        }
                                      }
                                    },
                                    child: const Text('Send'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: const Text("Send Message"),
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