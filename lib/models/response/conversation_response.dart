class ConversationResponse {
  final List<Conversation> content;
  final PageInfo page;
  
  ConversationResponse({
    required this.content,
    required this.page,
  });

  factory ConversationResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> contentJson = json['content'] as List<dynamic>;
    final content = contentJson
        .map((conversation) => Conversation.fromJson(conversation))
        .toList();
    
    final pageInfo = PageInfo.fromJson(json['page']);
    
    return ConversationResponse(
      content: content,
      page: pageInfo,
    );
  }
}

class PageInfo {
  final int size;
  final int number;
  final int totalElements;
  final int totalPages;

  PageInfo({
    required this.size,
    required this.number,
    required this.totalElements,
    required this.totalPages,
  });

  factory PageInfo.fromJson(Map<String, dynamic> json) {
    return PageInfo(
      size: json['size'] as int,
      number: json['number'] as int,
      totalElements: json['totalElements'] as int,
      totalPages: json['totalPages'] as int,
    );
  }
}

class Conversation {
  final String username;
  final String productName;
  final String? coverImgKey;
  final int productId;
  final int senderId;
  final int recipientId;
  final bool isMyProduct;

  Conversation({
    required this.username,
    required this.productName,
    required this.coverImgKey,
    required this.productId,
    required this.senderId,
    required this.recipientId,
    required this.isMyProduct,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      username: json['username'] as String,
      productName: json['productName'] as String,
      coverImgKey: json['coverImgKey'] as String?,
      productId: json['productId'] as int,
      senderId: json['senderId'] as int,
      recipientId: json['recipientId'] as int,
      isMyProduct: json['myProduct'] as bool,
    );
  }
}