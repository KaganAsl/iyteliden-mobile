import 'package:flutter/material.dart';
import 'package:iyteliden_mobile/models/response/review_response.dart';
import 'package:iyteliden_mobile/pages/product_details_page.dart';
import 'package:iyteliden_mobile/services/review_service.dart';
import 'package:iyteliden_mobile/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserReviewsPage extends StatefulWidget {
  final int userId;
  final String userName;

  const UserReviewsPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserReviewsPage> createState() => _UserReviewsPageState();
}

class _UserReviewsPageState extends State<UserReviewsPage> {
  final ReviewService _reviewService = ReviewService();
  final ScrollController _scrollController = ScrollController();

  List<ReviewResponse> _reviews = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  int currentPage = 0;
  int totalPages = 1;
  String? _jwt;

  @override
  void initState() {
    super.initState();
    _loadJwtAndReviews();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadJwtAndReviews() async {
    final prefs = await SharedPreferences.getInstance();
    _jwt = prefs.getString("auth_token");
    if (_jwt != null) {
      await _loadReviews();
    } else {
      setState(() {
        isLoading = false;
      });
      _showError("Authentication token not found");
    }
  }

  Future<void> _loadReviews() async {
    if (_jwt == null) return;

    setState(() {
      if (currentPage == 0) {
        isLoading = true;
      } else {
        isLoadingMore = true;
      }
    });

    final (reviewListResponse, error) = await _reviewService.getReviews(_jwt!, widget.userId, currentPage);

    if (mounted) {
      if (error == null && reviewListResponse != null) {
        setState(() {
          if (currentPage == 0) {
            _reviews = reviewListResponse.content;
          } else {
            _reviews.addAll(reviewListResponse.content);
          }
          totalPages = reviewListResponse.page.totalPages;
          isLoading = false;
          isLoadingMore = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isLoadingMore = false;
        });
        _showError(error?.message ?? "Failed to load reviews");
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore && currentPage + 1 < totalPages) {
      currentPage += 1;
      _loadReviews();
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  Widget _buildStarRating(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          size: 16,
          color: Colors.amber,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.userName}'s Reviews"),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _reviews.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.rate_review_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        "No reviews yet",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "This user hasn't received any reviews.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _reviews.length + (isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= _reviews.length) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      );
                    }

                    final review = _reviews[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailPage(productId: review.productId),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        shadowColor: const Color.fromARGB(183, 155, 10, 27),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStarRating(review.rating),
                                  Text(
                                    "Product Name: ${review.productName}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                review.content,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "From User: ${review.writerName}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
} 