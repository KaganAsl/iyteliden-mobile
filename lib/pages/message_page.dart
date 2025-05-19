import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iyteliden_mobile/models/response/conversation_response.dart';
import 'package:iyteliden_mobile/models/response/message_response.dart';
import 'package:iyteliden_mobile/services/image_service.dart';
import 'package:iyteliden_mobile/services/message_service.dart';
import 'package:iyteliden_mobile/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MessagePage extends StatefulWidget {
  final Conversation conversation;

  const MessagePage({
    super.key,
    required this.conversation,
  });

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class MessageImage extends StatefulWidget {
  final String imageKey;
  final Future<String?> Function(String) getImageUrl;

  const MessageImage({
    super.key,
    required this.imageKey,
    required this.getImageUrl,
  });

  @override
  State<MessageImage> createState() => _MessageImageState();
}

class _MessageImageState extends State<MessageImage> with AutomaticKeepAliveClientMixin {
  String? _cachedUrl;
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    if (_cachedUrl != null) return;
    
    final url = await widget.getImageUrl(widget.imageKey);
    if (mounted) {
      setState(() {
        _cachedUrl = url;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: SizedBox(
          width: 120,
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_cachedUrl == null) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          _cachedUrl!,
          width: 180,
          height: 180,
          fit: BoxFit.cover,
          cacheWidth: 360,
          cacheHeight: 360,
        ),
      ),
    );
  }
}

class _MessagePageState extends State<MessagePage> {
  final MessageService _messageService = MessageService();
  final ImageService _imageService = ImageService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  
  List<Message> messages = [];
  String? error;
  bool isLoading = true;
  bool isLoadingMore = false;
  int currentPage = 0;
  bool hasMorePages = true;
  Timer? _messageTimer;
  File? _selectedImage;
  final Map<String, String> _imageUrlCache = {};

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _startMessagePolling();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!isLoadingMore && hasMorePages) {
        _loadMoreMessages();
      }
    }
  }

  Future<void> _loadMoreMessages() async {
    if (isLoadingMore || !hasMorePages) return;

    setState(() {
      isLoadingMore = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('auth_token');

    if (jwt == null) {
      _showFeedbackSnackBar("Not Authenticated", isError: true);
      setState(() {
        isLoadingMore = false;
      });
      return;
    }

    final nextPage = currentPage + 1;
    final (response, errorResponse) = await _messageService.getUserConversationMessages(
      jwt,
      nextPage,
      widget.conversation,
    );

    if (errorResponse != null) {
      _showFeedbackSnackBar(errorResponse.message, isError: true);
      setState(() {
        isLoadingMore = false;
      });
      return;
    }

    if (response != null) {
      setState(() {
        for (var message in response.content) {
          if (!messages.any((m) => m.messageId == message.messageId)) {
            messages.add(message);
          }
        }
        hasMorePages = nextPage < response.page.totalPages - 1;
        currentPage = nextPage;
        isLoadingMore = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _messageTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('auth_token');

    if (jwt == null) {
      _showFeedbackSnackBar("Not Authenticated", isError: true);
      setState(() {
        error = "Not Authenticated";
        isLoading = false;
      });
      return;
    }

    final (response, errorResponse) = await _messageService.getUserConversationMessages(jwt, currentPage, widget.conversation);

    if (errorResponse != null) {
      setState(() {
        error = errorResponse.message;
        isLoading = false;
      });
      return;
    }
    if (response != null) {
      setState(() {
        for (var message in response.content) {
          if (!messages.any((m) => m.messageId == message.messageId)) {
            messages.add(message);
          }
        }
        hasMorePages = currentPage < response.page.totalPages - 1;
        isLoading = false;
      }); 
    }
  }

  void _loadNewMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('auth_token');

    if (jwt == null) {
      _showFeedbackSnackBar("Not Authenticated", isError: true);
      setState(() {
        error = "Not Authenticated";
        isLoading = false;
      });
      return;
    }

    final (response, errorResponse) = await _messageService.getUserConversationMessages(jwt, currentPage, widget.conversation);

    if (errorResponse != null) {
      setState(() {
        error = errorResponse.message;
        isLoading = false;
      });
      return;
    }
    if (response != null) {
      setState(() {
        for (var message in response.content) {
          if (!messages.any((m) => m.messageId == message.messageId)) {
            messages.insert(0, message);
          }
        }
        hasMorePages = currentPage < response.page.totalPages - 1;
        isLoading = false;
      }); 
    }
  }

  void _startMessagePolling() {
    // Poll for new messages every 5 seconds
    _messageTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _loadNewMessages();
      }
    });
  }

  Future<String?> _getImageUrl(String key) async {
    if (_imageUrlCache.containsKey(key)) {
      return _imageUrlCache[key];
    }

    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('auth_token');

    if (jwt == null) {
      _showFeedbackSnackBar("Not Authenticated", isError: true);
      setState(() {
        error = "Not Authenticated";
        isLoading = false;
      });
      return null;
    }
    final (response, errorResponse) = await _imageService.getImage(jwt, key);
    if (errorResponse != null) {
      setState(() {
        error = errorResponse.message;
        isLoading = false;
      });
      return null;
    }
    if (response != null) {
      _imageUrlCache[key] = response.url;
      return response.url;
    }
    return null;
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

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _messageController.clear();
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty && _selectedImage == null) return;

    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('auth_token');

    if (jwt == null) {
      _showFeedbackSnackBar("Not Authenticated", isError: true);
      return;
    }

    final message = _messageController.text.trim();
    _messageController.clear();

    final Map<String, dynamic> messageData = {
      "productId": widget.conversation.productId,
      "content": _selectedImage != null ? null : message,
      "bidId": null,
      "recipientId": widget.conversation.isMyProduct ? widget.conversation.recipientId : null,
    };

    final (response, errorResponse) = await _messageService.sendMessage(
      jwt,
      messageData,
      _selectedImage ?? File(''),
    );

    if (errorResponse != null) {
      _showFeedbackSnackBar(errorResponse.message, isError: true);
      return;
    }

    if (response != null) {
      setState(() {
        messages.insert(0, response);
        _selectedImage = null;
      });
      _scrollToBottom();
    }
  }

  void _removeSelectedImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildMessageBubble(Message message) {
    final isMe = message.myMessage;
    final hasImage = message.imageUrl != null && message.imageUrl!.isNotEmpty;
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              MessageImage(
                imageKey: message.imageUrl!,
                getImageUrl: _getImageUrl,
              ),
            if (message.content != null && message.content!.isNotEmpty)
              Text(
                message.content!,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black,
                  fontSize: 16,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              _formatMessageTime(message.timestamp),
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.conversation.productName),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
                    : Stack(
                        children: [
                          ListView.builder(
                            reverse: true,
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            itemCount: messages.length + (hasMorePages ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == messages.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              return _buildMessageBubble(messages[index]);
                            },
                          ),
                          if (isLoadingMore)
                            const Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: LinearProgressIndicator(),
                            ),
                        ],
                      ),
          ),
          if (_selectedImage != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[100],
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImage!,
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: _removeSelectedImage,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image, color: AppColors.primary),
                    onPressed: _selectedImage == null ? _pickImage : null,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: _selectedImage == null,
                      decoration: InputDecoration(
                        hintText: _selectedImage == null ? 'Type a message...' : 'Image selected',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppColors.primary),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}