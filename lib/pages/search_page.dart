import 'package:flutter/material.dart';
import 'package:iyteliden_mobile/models/response/product_response.dart';
import 'package:iyteliden_mobile/models/response/category_response.dart';
import 'package:iyteliden_mobile/models/response/location_response.dart';
import 'package:iyteliden_mobile/pages/product_details_page.dart';
import 'package:iyteliden_mobile/pages/products_by_category_page.dart';
import 'package:iyteliden_mobile/pages/products_by_location_page.dart';
import 'package:iyteliden_mobile/services/favorite_service.dart';
import 'package:iyteliden_mobile/services/product_service.dart';
import 'package:iyteliden_mobile/services/category_service.dart';
import 'package:iyteliden_mobile/services/location_service.dart';
import 'package:iyteliden_mobile/services/search_history_service.dart';
import 'package:iyteliden_mobile/services/user_service.dart';
import 'package:iyteliden_mobile/widgets/simple_product_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iyteliden_mobile/utils/app_colors.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<StatefulWidget> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final SearchHistoryService _searchHistoryService = SearchHistoryService();
  final CategoryService _categoryService = CategoryService();
  final LocationService _locationService = LocationService();
  
  late TabController _tabController;
  final List<SimpleProductResponse> _products = [];
  List<String> _searchHistory = [];
  List<CategoryResponse> _categories = [];
  List<Location> _locations = [];
  bool _isLoading = false;
  bool _isCategoriesLoading = false;
  bool _isLocationsLoading = false;
  int _currentPage = 0;
  int _totalPages = 1;
  String? _jwt;
  String _currentQuery = '';
  int? _userId;
  // ignore: unused_field
  bool _favoritesChanged = false;
  bool _showHistory = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    _tabController.dispose();
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
        _loadCategories();
        _loadLocations();
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

  Future<void> _loadCategories() async {
    if (_jwt == null || !mounted) return;
    
    setState(() {
      _isCategoriesLoading = true;
    });
    
    try {
      final (categories, error) = await _categoryService.getCategories(_jwt!);
      if (error == null && categories != null && mounted) {
        setState(() {
          _categories = categories;
          _isCategoriesLoading = false;
        });
      } else if (error != null && mounted) {
        setState(() {
          _isCategoriesLoading = false;
        });
        _showError("Failed to load categories: ${error.message}");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCategoriesLoading = false;
        });
        _showError("Error loading categories: ${e.toString()}");
      }
    }
  }

  Future<void> _loadLocations() async {
    if (_jwt == null || !mounted) return;
    
    setState(() {
      _isLocationsLoading = true;
    });
    
    try {
      final (locations, error) = await _locationService.getLocations(_jwt!);
      if (error == null && locations != null && mounted) {
        setState(() {
          _locations = locations;
          _isLocationsLoading = false;
        });
      } else if (error != null && mounted) {
        setState(() {
          _isLocationsLoading = false;
        });
        _showError("Failed to load locations: ${error.message}");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLocationsLoading = false;
        });
        _showError("Error loading locations: ${e.toString()}");
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
    if (_jwt == null || _currentQuery.isEmpty || !mounted) {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
      return;
    }

    // Products are cleared in onSubmitted for new searches (_currentPage == 0)
    setState(() {
      _isLoading = true;
      _showHistory = false; // Ensure history is hidden during search
    });
    
    // Add to search history only for new searches (page 0)
    if (_currentPage == 0) {
      await _searchHistoryService.addToSearchHistory(_currentQuery);
      await _loadSearchHistory();
    }
    
    final (data, error) = await ProductService().searchProducts(_jwt!, _currentQuery, _currentPage);
    
    if (!mounted) return;
    
    if (error != null || data == null) {
      _showError(error?.message ?? "Failed to search products.");
      // If it was a new search (page 0) that failed, products list remains empty.
      // If pagination failed, existing products are kept.
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } else {
      // Filter out user's own products AND sold products, handling null userIds and productStatus
      final filteredProducts = data.content.where((product) { 
        bool isNotSold = !(product.productStatus != null && product.productStatus!.toUpperCase() == 'SOLD');
        bool isNotCurrentUserProduct = product.userId == null || product.userId != _userId;
        return isNotSold && isNotCurrentUserProduct;
      }).toList();
      
      if (mounted) {
        setState(() {
          // if (_currentPage == 0) { _products.clear(); } // Already cleared in onSubmitted for new search
          _products.addAll(filteredProducts);
          _totalPages = data.page.totalPages;
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
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
      ),
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
              Text(
                "Recent Searches",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              TextButton(
                onPressed: _clearSearchHistory,
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
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
                leading: Icon(Icons.history, color: AppColors.primary),
                title: Text(query),
                trailing: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => _removeFromHistory(query),
                ),
                onTap: () {
                  _searchController.text = query;
                  setState(() {
                    _currentQuery = query;
                    _products.clear();
                    _currentPage = 0;
                    _showHistory = false;
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

  Widget _buildSearchByCategory() {
    if (_isCategoriesLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_categories.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "No categories available",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: Colors.grey[100],
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              category.categoryName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.primary,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductsByCategoryPage(
                    categoryId: category.categoryId,
                    categoryName: category.categoryName,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSearchByLocation() {
    if (_isLocationsLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_locations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "No locations available",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _locations.length,
      itemBuilder: (context, index) {
        final location = _locations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: Colors.grey[100],
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.location_on,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            title: Text(
              location.locationName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.primary,
            ),
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
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String liveSearchText = _searchController.text;
    Widget bodyContent;

    if (_showHistory && liveSearchText.isEmpty) {
      bodyContent = _buildSearchHistory();
    } else if (_isLoading && _products.isEmpty) { 
      // Show full page loader only if loading initial results and no products are yet visible
      bodyContent = const Center(child: CircularProgressIndicator(color: AppColors.primary));
    } else if (_products.isNotEmpty) {
      bodyContent = GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 3/4,
        ),
        itemCount: _products.length + (_isLoading ? 1 : 0), // _isLoading for pagination loader at the end
        itemBuilder: (context, index) {
          if (index >= _products.length) {
            // This is the pagination loader item
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
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
                _favoritesChanged = true;
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
      );
    } else { // No products to display, and not in the initial full-page loading state
      String message;
      if (_currentQuery.isNotEmpty && !_isLoading) {
        // A search for _currentQuery (submitted query) was completed, and it yielded no products
        message = "No products found for '$_currentQuery'";
      } else if (liveSearchText.isEmpty) {
        // No submitted query, and the search text field is also empty
        message = "Enter a search term to find products";
      } else {
        // Text is in the search field, but it hasn't been submitted yet (or submitted query was cleared)
        message = "Press Enter to search for '$liveSearchText'";
      }
      bodyContent = Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
              final queryToSubmit = value.trim();
              if (queryToSubmit.isEmpty) {
                setState(() {
                  _searchController.text = ''; // Ensure controller is also cleared if user submits empty space
                  _showHistory = true;
                  _products.clear();
                  _currentQuery = '';
                });
                return;
              }
              setState(() {
                _currentQuery = queryToSubmit; // Set the query to be searched
                _products.clear();
                _currentPage = 0;
                _showHistory = false;
              });
              _searchProducts();
            },
            onChanged: (value) { // value is the current text in the field
              setState(() {
                // _currentQuery (submitted query) is NOT updated here.
                if (value.isEmpty) {
                  _showHistory = true;
                  _products.clear();
                  _currentQuery = ''; // Clear submitted query if text field becomes empty
                } else {
                  _showHistory = false; // Hide history as soon as user types
                }
                // This setState will trigger a rebuild, allowing the bodyContent logic
                // to display the correct message based on liveSearchText and _currentQuery.
              });
            },
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Always return true to trigger refresh
            Navigator.pop(context, true);
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.background,
          unselectedLabelColor: AppColors.background,
          indicatorColor: AppColors.background,
          tabs: const [
            Tab(text: "Recent Searches"),
            Tab(text: "By Category"),
            Tab(text: "By Location"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Recent Searches Tab
          bodyContent,
          // Search by Category Tab
          _buildSearchByCategory(),
          // Search by Location Tab
          _buildSearchByLocation(),
        ],
      ),
    );
  }
}