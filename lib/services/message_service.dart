import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:iyteliden_mobile/models/response/conversation_response.dart';
import 'package:iyteliden_mobile/models/response/error_response.dart';
import 'package:iyteliden_mobile/models/response/message_response.dart';
import 'package:iyteliden_mobile/utils/dotenv.dart';

class MessageService {
  
  final String url = Env.apiUrl;

  Future<(ConversationResponse?, ErrorResponse?)> getUserConversations(String jwt, int page) async {
    final response = await http.get(
      Uri.parse('$url/messages/conversations?page=$page'),
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': jwt
      }
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return (ConversationResponse.fromJson(json), null);
    } else {
      final json = jsonDecode(response.body);
      final error = ErrorResponse.fromJson(json);
      return (null, error);
    }
  }

  Future<(MessageResponse?, ErrorResponse?)> getUserConversationMessages(String jwt, int page, Conversation conversation) async {
    final uri = conversation.isMyProduct ? Uri.parse('$url/messages/conversation/${conversation.productId}?otherUserId=${conversation.recipientId}&page=$page') : Uri.parse('$url/messages/conversation/${conversation.productId}?page=$page');
    final response = await http.get(
      uri,
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': jwt
      }
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return (MessageResponse.fromJson(json), null);
    } else {
      final json = jsonDecode(response.body);
      final error = ErrorResponse.fromJson(json);
      return (null, error);
    }
  }

  Future<(Message?, ErrorResponse?)> sendMessage(String jwt, Map<String, dynamic> messageData, File file) async {
    final uri = Uri.parse('$url/messages/send');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = jwt;

    // Add message data as JSON part
    final messageJson = jsonEncode(messageData);
    request.files.add(
      http.MultipartFile.fromString(
        'messageData',
        messageJson,
        contentType: MediaType('application', 'json'),
      )
    );

    // Add file if provided
    if (file.path.isNotEmpty) {
      final String fileName = file.path.split('/').last;
      final String extension = fileName.split('.').last.toLowerCase();
      
      String mimeType;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        default:
          return (null, ErrorResponse(
            message: 'Unsupported file type',
            status: 400,
            timestamp: DateTime.now()
          ));
      }

      request.files.add(
        await http.MultipartFile.fromPath('file', file.path, contentType: MediaType.parse(mimeType))
      );
    } else {
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);
        return (Message.fromJson(json), null);
      } else {
        final json = jsonDecode(response.body);
        return (null, ErrorResponse.fromJson(json));
      }
    } catch (e) {
      return (null, ErrorResponse(
        message: e.toString(),
        status: 500,
        timestamp: DateTime.now()
      ));
    }
  }

  Future<(Message?, ErrorResponse?)> sendSimpleMessage(String jwt, String content, int productId) async {
    final uri = Uri.parse('$url/messages/send');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = jwt;

    // Add message data as JSON part
    final messageJson = "{\"productId\": $productId, \"content\": \"$content\", \"bidId\": null, \"recipientId\": null}";
    request.files.add(
      http.MultipartFile.fromString(
        'messageData',
        messageJson,
        contentType: MediaType('application', 'json'),
      )
    );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);
        return (Message.fromJson(json), null);
      } else {
        final json = jsonDecode(response.body);
        return (null, ErrorResponse.fromJson(json));
      }
    } catch (e) {
      return (null, ErrorResponse(
        message: e.toString(),
        status: 500,
        timestamp: DateTime.now()
      ));
    }
  }
}