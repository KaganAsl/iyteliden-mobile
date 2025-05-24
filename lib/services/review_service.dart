import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:iyteliden_mobile/models/request/review_request.dart';
import 'package:iyteliden_mobile/models/response/error_response.dart';
import 'package:iyteliden_mobile/models/response/review_response.dart';
import 'package:iyteliden_mobile/utils/dotenv.dart';

class ReviewService {
  
  final String url = Env.apiUrl;

  Future<(ReviewResponse?, ErrorResponse?)> createReview(String jwt, ReviewRequest data) async {
    final response = await http.post(
      Uri.parse('$url/reviews/create'),
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': jwt
      },
      body: jsonEncode(data.toJson())
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return (ReviewResponse.fromJson(json), null);
    } else {
      final json = jsonDecode(response.body);
      final error = ErrorResponse.fromJson(json);
      return (null, error);
    }
  }

  Future<(ReviewListResponse?, ErrorResponse?)> getReviews(String jwt, int userId, int page) async {
    final response = await http.get(
      Uri.parse('$url/reviews/get/$userId?page=$page'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': jwt
      },
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return (ReviewListResponse.fromJson(json), null);
    } else {
      final json = jsonDecode(response.body);
      final error = ErrorResponse.fromJson(json);
      return (null, error);
    }
  }

  Future<(double?, ErrorResponse?)> getRatingAverageForUser(String jwt, int userId) async {
    final response = await http.get(
      Uri.parse('$url/reviews/rating/$userId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': jwt
      },
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return (json as double, null);
    } else {
      final json = jsonDecode(response.body);
      final error = ErrorResponse.fromJson(json);
      return (null, error);
    }
  }
}