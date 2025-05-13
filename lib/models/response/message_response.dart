import 'package:iyteliden_mobile/models/response/page_info_response.dart';

class Message {
  
  final int messageId;
  final DateTime timestamp;
  final int productId;
  final int senderId;
  final int recipientId;
  final String? content;
  final String? imageUrl;
  final int? bidId;
  final bool myMessage;

  Message({required this.messageId, required this.timestamp, required this.productId, required this.senderId, required this.recipientId, required this.content, required this.imageUrl, required this.bidId, required this.myMessage});

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      messageId: json['messageId'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      productId: json['productId'] as int,
      senderId: json['senderId'] as int,
      recipientId: json['recipientId'] as int,
      content: json['content'] as String?,
      imageUrl: json['imageUrl'] as String?,
      bidId: json['bidId'] as int?,
      myMessage: json['myMessage'] as bool,
    );
  }
}

class MessageResponse {
  
  final List<Message> content;
  final PageInfoResponse page;

  MessageResponse({required this.content, required this.page});

  factory MessageResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> contentJson = json['content'] as List<dynamic>;
    final content = contentJson
        .map((message) => Message.fromJson(message))
        .toList();
    
    final pageInfo = PageInfoResponse.fromJson(json['page']);
    
    return MessageResponse(
      content: content,
      page: pageInfo,
    );
  }
}