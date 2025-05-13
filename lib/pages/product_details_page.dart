import 'package:flutter/material.dart';
import 'package:iyteliden_mobile/models/response/error_response.dart';
import 'package:iyteliden_mobile/models/response/image_response.dart';
import 'package:iyteliden_mobile/models/response/product_response.dart';
import 'package:iyteliden_mobile/pages/profile_page.dart';
import 'package:iyteliden_mobile/pages/public_profile_page.dart';
import 'package:iyteliden_mobile/services/favorite_service.dart';
import 'package:iyteliden_mobile/services/image_service.dart';
import 'package:iyteliden_mobile/services/product_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      _showFeedbackSnackBar(liked ? "Removed from favorites" : "Added to favorites");
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
                snapshot.error.toString().contains('Failed to load product details')) { // Broader check
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
                        itemBuilder: (popupContext) => [ // Use a different context name if needed
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            // TODO - edit button
                          } else if (value == 'delete') {
                            // Use the context from the PopupMenuButton's itemBuilder for showDialog
                            showDialog(
                              context: context, // This context is from the itemBuilder
                              builder: (BuildContext dialogBuilderContext) { // Context for the dialog
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
                                        // ---- START OF INTEGRATED DELETE LOGIC ----
                                        if (!mounted) return;

                                        // (1) Update UI state for the button within the dialog & pop dialog
                                        // This setState call is for the _ProductDetailPageState.
                                        // It will rebuild the ProductDetailPage, which might be fine if the dialog
                                        // button's state is derived from _isDeleting.
                                        setState(() { _isDeleting = true; });
                                        Navigator.of(dialogBuilderContext).pop(); // Pop the dialog

                                        // (2) Retrieve and Correct the JWT
                                        // _jwt is already loaded in initState and potentially re-checked/re-loaded if necessary
                                        String? currentRawJwt = _jwt;
                                        String correctedJwt = currentRawJwt?.replaceAll("Bearer\n", "Bearer ") ?? "";
                                        correctedJwt = correctedJwt.trim();

                                        // (3) Validate the corrected JWT
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
                                            // SUCCESS!
                                            _showFeedbackSnackBar('Product deleted successfully!', isError: false);

                                            // Navigate away. After this, the current page is disposed.
                                            // Use this.context (the page's context) for page navigation.
                                            // Ensure ProfilePage handles its own data refresh (e.g. in its initState)
                                            await Navigator.of(this.context).pushAndRemoveUntil(
                                              MaterialPageRoute(builder: (newContext) => const ProfilePage()),
                                              (Route<dynamic> route) => route.isFirst,
                                            );
                                            // IMPORTANT: Since the page is replaced, we return to prevent
                                            // any further operations (like setState in finally) on this disposed widget.
                                            return;
                                          }
                                        } catch (e) {
                                          if (!mounted) return;
                                          finalErrorMessageForSnackbar = 'An unexpected error occurred: ${e.toString()}';
                                        }

                                        // This part is reached only if there was an error and navigation did not occur.
                                        if (mounted) {
                                          setState(() { _isDeleting = false; });
                                          _showFeedbackSnackBar(finalErrorMessageForSnackbar, isError: true);
                                                                                }
                                        // ---- END OF INTEGRATED DELETE LOGIC ----
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
                    : IconButton( // Favorite button if not owner
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
                            builder: (_) => ProfilePage(),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PublicProfilePage(userId: product.user.userId),
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
                  Text(
                    product.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  if (!_isOwner)
                    ElevatedButton(
                      onPressed: () {
                        // Implement message functionality here
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