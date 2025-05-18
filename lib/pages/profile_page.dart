import 'package:flutter/material.dart';
import 'package:iyteliden_mobile/models/response/product_response.dart';
import 'package:iyteliden_mobile/models/response/user_response.dart';
import 'package:iyteliden_mobile/pages/login_page.dart';
import 'package:iyteliden_mobile/pages/landing_page.dart';
import 'package:iyteliden_mobile/pages/product_details_page.dart';
import 'package:iyteliden_mobile/pages/edit_product_page.dart';
import 'package:iyteliden_mobile/services/product_service.dart';
import 'package:iyteliden_mobile/services/user_service.dart';
import 'package:iyteliden_mobile/utils/app_colors.dart';
import 'package:iyteliden_mobile/widgets/simple_product_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {

  const ProfilePage({super.key});

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
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log Out', style: TextStyle(color: Colors.red)),
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
            color: AppColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout_outlined),
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
            return const Center(child: CircularProgressIndicator(),);
          } if (snapshot.hasError) {
            return const Center(child: Text("Failed to load profile."));
          } if (!snapshot.hasData) {
            return const Center(child: Text("User has no data."));
          }
          final user = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Id: ${user.userId}", style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text("Email: ${user.mail}", style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text("Username: ${user.userName}", style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text("Status: ${user.status}", style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ProductList(
                  jwt: _jwt!,
                  ownerId: user.userId,
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
  const ProductList({super.key, required this.jwt, required this.ownerId});

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
      return const Center(child: CircularProgressIndicator());
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
        childAspectRatio: 3/4,
      ),
      itemCount: _products.length + (_isLoading && _currentPage + 1 < _totalPages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _products.length) {
          return const Center(child: CircularProgressIndicator(),);
        }
        final product = _products[index];
        return SimpleSelfProductCard(
          jwt: widget.jwt,
          product: product,
          onTap: () async {
            final shouldRefresh = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailPage(productId: product.productId),
              ),
            );
            if (shouldRefresh == true && mounted) {
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