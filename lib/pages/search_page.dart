import 'package:flutter/material.dart';
import 'package:iyteliden_mobile/models/response/product_response.dart';
import 'package:iyteliden_mobile/pages/product_details_page.dart';
import 'package:iyteliden_mobile/services/favorite_service.dart';
import 'package:iyteliden_mobile/services/product_service.dart';
import 'package:iyteliden_mobile/services/search_history_service.dart';
import 'package:iyteliden_mobile/services/user_service.dart';
import 'package:iyteliden_mobile/widgets/simple_product_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<StatefulWidget> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final SearchHistoryService _searchHistoryService = SearchHistoryService();
  
  final List<SimpleProductResponse> _products = [];
  List<String> _searchHistory = [];
  bool _isLoading = false;
  int _currentPage = 0;
  int _totalPages = 1;
  String? _jwt;
  String _currentQuery = '';
  int? _userId;
  bool _favoritesChanged = false;
  bool _showHistory = true;

  @override
  void initState() {
    super.initState();
    _loadJWT();
    _loadSearchHistory();
    // Auto focus the search field when the page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadSearchHistory() async {
    final history = await _searchHistoryService.getSearchHistory();
    if (mounted) {
      setState(() {
        _searchHistory = history;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadJWT() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwt = prefs.getString("auth_token");
      if (jwt != null && mounted) {
        setState(() {
          _jwt = jwt;
        });
        _loadUserProfile();
      }
    } catch (e) {
      if (mounted) {
        _showError("Failed to load authentication data: ${e.toString()}");
      }
    }
  }

  Future<void> _loadUserProfile() async {
    if (_jwt == null || !mounted) return;
    
    try {
      final (profile, error) = await UserService().getSelfUserProfile(_jwt!);
      if (error == null && profile != null && mounted) {
        setState(() {
          _userId = profile.userId;
        });
      } else if (error != null && mounted) {
        _showError("Failed to load user profile: ${error.message}");
      }
    } catch (e) {
      if (mounted) {
        _showError("Error loading user profile: ${e.toString()}");
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _currentPage + 1 < _totalPages) {
      _currentPage += 1;
      _searchProducts();
    }
  }

  Future<void> _searchProducts() async {
    if (_jwt == null || _currentQuery.isEmpty || !mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _showHistory = false;
      });
      
      // Add to search history
      await _searchHistoryService.addToSearchHistory(_currentQuery);
      await _loadSearchHistory();
      
      final (data, error) = await ProductService().searchProducts(_jwt!, _currentQuery, _currentPage);
      
      if (!mounted) return;
      
      if (error != null || data == null) {
        _showError(error?.message ?? "Failed to search products.");
        setState(() => _isLoading = false);
      } else {
        // Filter out user's own products, handling null userIds
        final filteredProducts = data.content.where((product) => 
          product.userId == null || product.userId != _userId
        ).toList();
        
        if (mounted) {
          setState(() {
            _products.addAll(filteredProducts);
            _totalPages = data.page.totalPages;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError("Error searching products: ${e.toString()}");
      }
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
    } else {
      // Set flag that favorites changed
      _favoritesChanged = true;
    }
  }

  Future<void> _clearSearchHistory() async {
    await _searchHistoryService.clearSearchHistory();
    if (mounted) {
      setState(() {
        _searchHistory.clear();
      });
    }
  }

  Future<void> _removeFromHistory(String query) async {
    await _searchHistoryService.removeFromSearchHistory(query);
    if (mounted) {
      setState(() {
        _searchHistory.remove(query);
      });
    }
  }

  Widget _buildSearchHistory() {
    if (_searchHistory.isEmpty) {
      return const Center(
        child: Text(
          "No recent searches",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Recent Searches",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _clearSearchHistory,
                child: const Text("Clear All"),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _searchHistory.length,
            itemBuilder: (context, index) {
              final query = _searchHistory[index];
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(query),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _removeFromHistory(query),
                ),
                onTap: () {
                  _searchController.text = query;
                  setState(() {
                    _currentQuery = query;
                    _products.clear();
                    _currentPage = 0;
                  });
                  _searchProducts();
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onSubmitted: (value) {
              setState(() {
                _currentQuery = value;
                _products.clear();
                _currentPage = 0;
              });
              _searchProducts();
            },
            onChanged: (value) {
              setState(() {
                _currentQuery = value;
                if (value.isEmpty) {
                  _showHistory = true;
                  _products.clear();
                }
              });
            },
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Always return true to trigger refresh
            Navigator.pop(context, true);
          },
        ),
      ),
      body: _showHistory && _currentQuery.isEmpty
          ? _buildSearchHistory()
          : _products.isEmpty && !_isLoading
              ? Center(
                  child: Text(
                    _currentQuery.isEmpty
                        ? "Enter a search term to find products"
                        : _isLoading 
                            ? "Searching..."
                            : "No products found for '$_currentQuery'",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : GridView.builder(
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
                      return const Center(child: CircularProgressIndicator());
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
                            builder: (context) => ProductDetailPage(productId: product.productId),
                          ),
                        );
                        if (shouldRefresh == true && mounted) {
                          // Mark that favorites have changed if the product details page says so
                          _favoritesChanged = true;
                          
                          // Check the current favorite status for this product
                          final (isFavorite, error) = await FavoriteService().checkFavorite(_jwt!, product.productId);
                          if (error == null && mounted) {
                            setState(() {
                              product.isLiked = isFavorite;
                            });
                          }
                        }
                      },
                    );
                  },
                ),
    );
  }
}