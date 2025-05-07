import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:iyteliden_mobile/models/response/error_response.dart';
import 'package:iyteliden_mobile/models/response/location_response.dart';
import 'package:iyteliden_mobile/utils/dotenv.dart';

class LocationService {
  
  final String url = Env.apiUrl;

  Future<(List<Location>?, ErrorResponse?)> getLocations(String jwt) async {
    final response = await http.get(
      Uri.parse('$url/locations'),
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': jwt
      }
    );
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      final locations = jsonList.map((json) => Location.fromJson(json)).toList();
      return (locations, null);
    } else {
      final json = jsonDecode(response.body);
      final error = ErrorResponse.fromJson(json);
      return (null, error);
    }
  }

  Future<(Location?, ErrorResponse?)> getLocationWithId(String jwt, int locationId) async {
    final response = await http.get(
      Uri.parse('$url/locations/$locationId'),
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': jwt
      }
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return (Location.fromJson(json), null);
    } else {
      final json = jsonDecode(response.body);
      final error = ErrorResponse.fromJson(json);
      return (null, error);
    }
  }
}