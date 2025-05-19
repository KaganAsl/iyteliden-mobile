import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iyteliden_mobile/models/response/category_response.dart';
import 'package:iyteliden_mobile/models/response/location_response.dart';
// Changed from ProductResponse to DetailedSelfProductResponse
import 'package:iyteliden_mobile/models/response/product_response.dart'; 
import 'package:iyteliden_mobile/services/category_service.dart';
import 'package:iyteliden_mobile/services/image_service.dart';
import 'package:iyteliden_mobile/services/location_service.dart';
import 'package:iyteliden_mobile/services/product_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProductPage extends StatefulWidget {
  final int productId; // Changed to int based on ProductService methods

  const EditProductPage({super.key, required this.productId});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageService = ImageService();
  
  final List<File> _newSelectedImages = [];
  List<String> _existingImageUrls = []; 
  List<String> _existingImageKeys = [];
  final List<Location> _selectedLocations = [];
  CategoryResponse? _selectedCategory;
  
  List<Location> _locations = [];
  List<CategoryResponse> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;
  // Changed from ProductResponse to DetailedSelfProductResponse
  DetailedSelfProductResponse? _product; 

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwt = prefs.getString('auth_token');
      
      if (jwt == null) {
        throw Exception('Not authenticated');
      }

      final productService = ProductService();
      final locationService = LocationService();
      final categoryService = CategoryService();

      // Fetch existing product details - Changed to getSelfDetailedProduct
      final (productDetails, productError) = await productService.getSelfDetailedProduct(jwt, widget.productId);
      if (productError != null) {
         _showFeedbackSnackBar("Error fetching product details: ${productError.message}", isError: true);
        throw Exception(productError.message);
      }
      if (productDetails == null) {
        _showFeedbackSnackBar("Product not found.", isError: true);
        throw Exception("Product not found.");
      }
      _product = productDetails;

      _productNameController.text = _product!.productName;
      _descriptionController.text = _product!.description;
      _priceController.text = _product!.price.toString();
      for (var key in _product!.imageUrls) {
        final (img, err) = await _imageService.getImage(jwt, key);
        if (err!= null) {
          _showFeedbackSnackBar("Error fetching image: ${err.message}", isError: true);
          throw Exception(err.message);
        }
        _existingImageUrls.add(img!.url);
        _existingImageKeys.add(key);
      }
      
      final (locations, locationError) = await locationService.getLocations(jwt);
      final (categories, categoryError) = await categoryService.getCategories(jwt);

      if (locationError != null) {
        _showFeedbackSnackBar("Error fetching locations: ${locationError.message}", isError: true);
      }
      if (categoryError != null) {
         _showFeedbackSnackBar("Error fetching categories: ${categoryError.message}", isError: true);
      }

      setState(() {
        _locations = locations ?? [];
        _categories = categories ?? [];
        if (_product!.category != null && _categories.isNotEmpty) { // category is not nullable in DetailedSelfProductResponse
          _selectedCategory = _categories.firstWhere((cat) => cat.categoryId == _product!.category.categoryId, orElse: () => _categories.first);
        }
        if (_product!.locations.isNotEmpty && _locations.isNotEmpty) { // locations is not nullable
          _selectedLocations.addAll(
            _locations.where((loc) => _product!.locations.any((prodLoc) => prodLoc.locationId == loc.locationId))
          );
        }

      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
       _showFeedbackSnackBar("Error: $e", isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    
    if (images.isNotEmpty) {
      setState(() {
        _newSelectedImages.addAll(images.map((xFile) => File(xFile.path)));
      });
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _newSelectedImages.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      // Here you might want to call an API to delete the image from the server
      // For now, just remove from the list
      _existingImageUrls.removeAt(index);
      _existingImageKeys.removeAt(index);
      // Potentially, you'd add the image URL to a list of images to be deleted on update.
    });
  }

  Future<void> _updateProduct() async { // Changed from _createProduct
    if (!_formKey.currentState!.validate()) return;
    if (_existingImageUrls.isEmpty && _newSelectedImages.isEmpty) { // Added check for at least one image
      _showFeedbackSnackBar('Please add or keep at least one image', isError: true);
      return;
    }
    if (_selectedLocations.isEmpty) {
       _showFeedbackSnackBar('Please select at least one location', isError: true);
      return;
    }
    if (_selectedCategory == null) {
      _showFeedbackSnackBar('Please select a category', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwt = prefs.getString('auth_token');
      
      if (jwt == null) {
        throw Exception('Not authenticated');
      }

      final productService = ProductService();
      final productUpdateData = {
        // productId is now part of the URL path for update, not in body
        'productName': _productNameController.text,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'categoryId': _selectedCategory!.categoryId,
      };

      final (response, error) = await productService.updateProduct(
        jwt,
        widget.productId, // Pass productId for the URL
        productUpdateData, 
        _newSelectedImages, 
        _selectedLocations.map((l) => l.locationId).toList(),
        _existingImageKeys, // Pass existing image URLs to be kept
      );


      if (error != null) {
        _showFeedbackSnackBar("Error updating product: ${error.message}", isError: true);
        throw Exception(error.message);
      }

      if (mounted) {
        _showFeedbackSnackBar('Product updated successfully!');
        Navigator.pop(context, true); 
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
       _showFeedbackSnackBar("Error: $e", isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
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
        title: const Text('Edit Product'), // Changed
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage != null
            ? Center(child: Text(_errorMessage!)) // Display error message
            : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Product Name
                    TextFormField(
                      controller: _productNameController,
                      decoration: const InputDecoration(labelText: 'Product Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter product name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter product description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Price
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter product price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Category Dropdown
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Category", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            if (_categories.isNotEmpty)
                              DropdownButtonFormField<CategoryResponse>(
                                value: _selectedCategory,
                                items: _categories.map((CategoryResponse category) {
                                  return DropdownMenuItem<CategoryResponse>(
                                    value: category,
                                    child: Text(category.categoryName),
                                  );
                                }).toList(),
                                onChanged: (CategoryResponse? newValue) {
                                  setState(() {
                                    _selectedCategory = newValue;
                                  });
                                },
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                ),
                                validator: (value) => value == null ? 'Please select a category' : null,
                              )
                            else
                              const Text("Loading categories..."),
                          ],
                        ),
                      )
                    ),
                    const SizedBox(height: 16),

                    // Location Selection (Multi-select chips)
                    Card(
                       child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Locations", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            if (_locations.isNotEmpty)
                              Wrap(
                                spacing: 8.0,
                                children: _locations.map((location) {
                                  final bool isSelected = _selectedLocations.any((sl) => sl.locationId == location.locationId);
                                  return FilterChip(
                                    label: Text(location.locationName),
                                    selected: isSelected,
                                    onSelected: (bool selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedLocations.add(location);
                                        } else {
                                          _selectedLocations.removeWhere((sl) => sl.locationId == location.locationId);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              )
                            else
                              const Text("Loading locations..."),
                          ],
                        ),
                       ),
                    ),
                    const SizedBox(height: 24),


                    // Image Selection
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Images',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Display existing images
                            if (_existingImageUrls.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _existingImageUrls.asMap().entries.map((entry) {
                                  int idx = entry.key;
                                  String imageUrl = entry.value;
                                  return Stack(
                                    children: [
                                      Image.network(imageUrl, width: 100, height: 100, fit: BoxFit.cover),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: IconButton(
                                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                                          onPressed: () => _removeExistingImage(idx),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            const SizedBox(height: 8),
                            // Display newly selected images
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ..._newSelectedImages.asMap().entries.map((entry) {
                                  int idx = entry.key;
                                  File imageFile = entry.value;
                                  return Stack(
                                    children: [
                                      Image.file(imageFile, width: 100, height: 100, fit: BoxFit.cover),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: IconButton(
                                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                                          onPressed: () => _removeNewImage(idx),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                                // Button to add more images
                                SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.add_a_photo),
                                    label: const Text('Add', textAlign: TextAlign.center),
                                    onPressed: _pickImages,
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _updateProduct,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Update Product'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 