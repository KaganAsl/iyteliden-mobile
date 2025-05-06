class CategoryResponse {
  
  final int categoryId;
  final String categoryName;

  CategoryResponse({
    required this.categoryId,
    required this.categoryName,
  });

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    return CategoryResponse(
      categoryId: json['categoryId'],
      categoryName: json['categoryName']);
  }
}