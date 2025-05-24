import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:iyteliden_mobile/models/request/bid_request.dart';
import 'package:iyteliden_mobile/models/response/bid_response.dart';
import 'package:iyteliden_mobile/models/response/error_response.dart';
import 'package:iyteliden_mobile/utils/dotenv.dart';

class BidService {
  final String url = Env.apiUrl;

  Future<(BidResponse?, ErrorResponse?)> placeBid(String jwt, BidRequest data)  async {
    final response = await http.post(
      Uri.parse('$url/bids'),
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': jwt
      },
      body: jsonEncode(data.toJson())
    );
    if (response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return (BidResponse.fromJson(json), null);
    } else {
      final json = jsonDecode(response.body);
      final error = ErrorResponse.fromJson(json);
      return (null, error);
    }
  }

  Future<(BidResponse?, ErrorResponse?)> acceptBid(String jwt, int bidId)  async {
    final response = await http.post(
      Uri.parse('$url/bids/accept/$bidId'),
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': jwt
      },
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return (BidResponse.fromJson(json), null);
    } else {
      final json = jsonDecode(response.body);
      final error = ErrorResponse.fromJson(json);
      return (null, error);
    }
  }

  Future<(BidResponse?, ErrorResponse?)> declineBid(String jwt, int bidId)  async {
    final response = await http.post(
      Uri.parse('$url/bids/decline/$bidId'),
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': jwt
      },
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return (BidResponse.fromJson(json), null);
    } else {
      final json = jsonDecode(response.body);
      final error = ErrorResponse.fromJson(json);
      return (null, error);
    }
  }

  Future<(BidResponse?, ErrorResponse?)> confirmBid(String jwt, int bidId)  async {
    final response = await http.post(
      Uri.parse('$url/bids/confirm/$bidId'),
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': jwt
      },
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return (BidResponse.fromJson(json), null);
    } else {
      final json = jsonDecode(response.body);
      final error = ErrorResponse.fromJson(json);
      return (null, error);
    }
  }

  Future<(BidResponse?, ErrorResponse?)> getBid(String jwt, int bidId)  async {
    final response = await http.get(
      Uri.parse('$url/bids/$bidId'),
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': jwt
      }
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return (BidResponse.fromJson(json), null);
    } else {
      final json = jsonDecode(response.body);
      final error = ErrorResponse.fromJson(json);
      return (null, error);
    }
  }
}