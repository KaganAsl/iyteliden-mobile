import 'package:flutter/material.dart';
import 'package:iyteliden_mobile/models/response/product_response.dart';
import 'package:iyteliden_mobile/models/response/user_response.dart';
import 'package:iyteliden_mobile/pages/landing_page.dart';
import 'package:iyteliden_mobile/pages/product_details_page.dart';
import 'package:iyteliden_mobile/pages/edit_product_page.dart';
import 'package:iyteliden_mobile/services/product_service.dart';
import 'package:iyteliden_mobile/services/user_service.dart';
import 'package:iyteliden_mobile/utils/app_colors.dart';
import 'package:iyteliden_mobile/widgets/simple_product_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  final int? focusedProductId;
  final String? focusedProductStatus;

  const ProfilePage({
    super.key,
    this.focusedProductId,
    this.focusedProductStatus,
  });

  @override
  State<StatefulWidget> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  
  late Future<SelfUserResponse> _futureProfile;
  String? _jwt;

  @override
  void initState() {
    super.initState();
    _futureProfile = _loadProfile();
  }

  Future<SelfUserResponse> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _jwt = prefs.getString("auth_token");
    if (_jwt == null || _jwt!.isEmpty) {
      _showFeedbackSnackBar("Can't load profile", isError: true);
      throw Exception("JWT is missing");
    } 
    final (userResponse, errorResponse) = await UserService().getSelfUserProfile(_jwt!);
    if (errorResponse != null) {
        _showFeedbackSnackBar(errorResponse.message, isError: true);
        throw Exception(errorResponse.message);
    }
    return userResponse!;
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out', style: TextStyle(color: AppColors.primary)),
        content: const Text('Are you sure you want to log out?', style: TextStyle(color: AppColors.text),),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.text)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log Out', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final prefs = await SharedPreferences.getInstance();
      prefs.remove("auth_token");
      prefs.remove("auth_expiry");
      _showFeedbackSnackBar("Successfully logged out.");
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LandingPage()),
        (Route<dynamic> route) => false,
      );
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(
            color: AppColors.background,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.background),
        elevation: 1,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: AppColors.background),
            tooltip: 'Edit Profile',
            onPressed: () {
              // TODO: Navigate to EditProfilePage
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit Profile functionality to be implemented.')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout_outlined, color: AppColors.background),
            tooltip: 'Log Out',
            onPressed: () {
              _logout();
            },
          ),
        ],
      ),
      body: FutureBuilder<SelfUserResponse>(
        future: _futureProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          } if (snapshot.hasError) {
            return Center(child: Text("Failed to load profile.", style: TextStyle(color: AppColors.secondary)));
          } if (!snapshot.hasData) {
            return const Center(child: Text("User has no data."));
          }
          final user = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[300],
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.grey[600],
                      ),
                      // TODO: Replace with NetworkImage(user.profilePictureUrl) when available
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.userName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.mail,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "User ID: ${user.userId}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              // Add more ListTiles for other info if needed, e.g., Join Date when available
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
                child: Text(
                  "My Products",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
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
          );
        },

      ),
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
  final List<SimpleSelfProductResponse> _products = [];
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_controller.position.pixels >=
            _controller.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _currentPage + 1 < _totalPages) {
      _currentPage += 1;
      _fetchPage();
    }
  }

  Future<void> _fetchPage({bool clearCurrent = false}) async {
    if (clearCurrent) {
      setState(() {
        _products.clear();
        _currentPage = 0;
        _totalPages = 1;
      });
    }
    setState(() => _isLoading = true);
    final (pageData, error) = await ProductService()
        .getSelfSimpleProducts(widget.jwt, widget.ownerId, _currentPage);
    if (mounted) {
      if (error == null && pageData != null) {
        setState(() {
          _products.addAll(pageData.content);
          _totalPages = pageData.page.totalPages;

          if (widget.focusedProductId != null && widget.focusedProductStatus != null) {
            final index = _products.indexWhere((p) => p.productId == widget.focusedProductId);
            if (index != -1) {
              _products[index].productStatus = widget.focusedProductStatus;
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error?.message ?? 'Failed to fetch products'),
          backgroundColor: Colors.redAccent,
        ));
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_products.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_products.isEmpty) {
      return const Center(child: Text("No products to display."));
    }

    return GridView.builder(
      controller: _controller,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.6,
      ),
      itemCount: _products.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _products.length) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        final product = _products[index];
        String? displayStatus = product.productStatus;
        if (widget.focusedProductId != null && product.productId == widget.focusedProductId && widget.focusedProductStatus != null) {
          displayStatus = widget.focusedProductStatus;
        }

        return SimpleSelfProductCard(
          jwt: widget.jwt,
          product: product,
          productStatus: displayStatus,
          onTap: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailPage(productId: product.productId),
              ),
            );
            if (result == true && mounted) {
              _fetchPage(clearCurrent: true);
            }
          },
          onEdit: () async {
            final updated = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditProductPage(productId: product.productId),
              ),
            );
            if (updated == true && mounted) {
              _fetchPage(clearCurrent: true);
            }
          },
          onDelete: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Product'),
                content: const Text('Are you sure you want to delete this product? This action cannot be undone.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );

            if (confirm == true && mounted) {
              final error = await ProductService().deleteProduct(widget.jwt, product.productId);
              if (mounted) {
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Failed to delete product: ${error.message}'),
                    backgroundColor: Colors.redAccent,
                  ));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Product deleted successfully'),
                    backgroundColor: Colors.green,
                  ));
                  _fetchPage(clearCurrent: true);
                }
              }
            }
          },
        );
      },
    );
  }
}