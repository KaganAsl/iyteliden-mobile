import 'package:flutter/material.dart';
import 'package:iyteliden_mobile/models/response/error_response.dart';
import 'package:iyteliden_mobile/models/response/image_response.dart';
import 'package:iyteliden_mobile/models/response/product_response.dart';
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DetailedProductResponse>(
      future: _productDetails,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData) {
          return const Center(child: Text('No product details available.'));
        }
        final product = snapshot.data!;
        final imageCount = product.imageUrls.length;
        return Scaffold(
            appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            actions: [
              _isOwner
              ? PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    // TODO - edit button
                  } else if (value == 'delete') {
                    // TODO - delete button
                  }
                },
              )
              : IconButton(
                icon: _isLiked ? const Icon(Icons.favorite) : const Icon(Icons.favorite_border),
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
                              final imgUrl = imgSnapshot.data?.$1?.url;
                              if (imgUrl == null) {
                                return const Icon(Icons.broken_image_outlined, size: 48);
                              }
                              return Image.network(imgUrl, fit: BoxFit.contain);
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