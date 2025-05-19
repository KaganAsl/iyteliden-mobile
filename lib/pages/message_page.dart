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

class _MessagePageState extends State<MessagePage> with WidgetsBindingObserver {
  final MessageService _messageService = MessageService();
  final ImageService _imageService = ImageService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Message> messages = [];
  bool isLoading = true;
  String? error;
  int currentPage = 0;
  bool hasMorePages = true;
  Timer? _pollingTimer;
  bool _isPolling = false;
  File? _selectedImage;
  final Map<String, String> _imageUrlCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMessages();
    _scrollController.addListener(_scrollListener);
    _startPolling(); // Start polling immediately
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPolling();
    _messageController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      if (!isLoading && hasMorePages) {
        _loadOlderMessages();
      }
    }
  }

  Future<void> _loadOlderMessages() async {
    if (isLoading || !hasMorePages) return;

    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwt = prefs.getString('auth_token');
      
      if (jwt == null) {
        setState(() {
          error = 'Not authenticated';
          isLoading = false;
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
        setState(() {
          error = errorResponse.message;
          isLoading = false;
        });
        return;
      }

      if (response != null) {
        setState(() {
          messages.addAll(response.content);
          hasMorePages = nextPage < response.page.totalPages - 1;
          currentPage = nextPage;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startPolling();
    } else if (state == AppLifecycleState.paused) {
      _stopPolling();
    }
  }

  void _startPolling() {
    if (!_isPolling) {
      _isPolling = true;
      _pollingTimer?.cancel(); // Cancel any existing timer
      _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        _loadMessages();
      });
    }
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
  }

  Future<void> _loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwt = prefs.getString('auth_token');
      
      if (jwt == null) {
        setState(() {
          error = 'Not authenticated';
          isLoading = false;
        });
        return;
      }

      final (response, errorResponse) = await _messageService.getUserConversationMessages(
        jwt,
        0, // Reset to first page
        widget.conversation,
      );
      
      if (errorResponse != null) {
        setState(() {
          error = errorResponse.message;
          isLoading = false;
        });
        return;
      }

      if (response != null) {
        setState(() {
          // Create a map of existing messages for quick lookup
          final existingMessageIds = messages.map((m) => m.messageId).toSet();
          
          // Add only new messages
          final newMessages = response.content.where(
            (newMsg) => !existingMessageIds.contains(newMsg.messageId)
          ).toList();
          
          if (newMessages.isNotEmpty) {
            // Add new messages at the beginning
            messages.insertAll(0, newMessages);
          }
          
          hasMorePages = 0 < response.page.totalPages - 1;
          currentPage = 0;
          isLoading = false;
        });

        // Scroll to bottom after messages are loaded
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _messageController.clear(); // Clear any text when image is selected
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty && _selectedImage == null) return;

    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('auth_token');
    
    if (jwt == null) {
      setState(() {
        error = 'Not authenticated';
      });
      return;
    }

    final messageData = {
      'productId': widget.conversation.productId,
      'recipientId': widget.conversation.isMyProduct 
          ? widget.conversation.recipientId 
          : null,
      'content': _messageController.text.isEmpty ? null : _messageController.text,
    };

    final optimisticMessage = Message(
      messageId: DateTime.now().millisecondsSinceEpoch,
      timestamp: DateTime.now(),
      productId: widget.conversation.productId,
      senderId: widget.conversation.isMyProduct 
          ? widget.conversation.senderId 
          : widget.conversation.recipientId,
      recipientId: widget.conversation.isMyProduct 
          ? widget.conversation.recipientId 
          : widget.conversation.senderId,
      content: _messageController.text.isEmpty ? null : _messageController.text,
      imageUrl: _selectedImage != null ? 'pending' : null,
      bidId: null,
      myMessage: true,
    );
    
    setState(() {
      messages.insert(0, optimisticMessage);
    });

    try {
      final (response, errorResponse) = await _messageService.sendMessage(
        jwt,
        messageData,
        _selectedImage ?? File(''),
      );

      if (errorResponse != null) {
        setState(() {
          messages.removeAt(0);
          error = errorResponse.message;
        });
        return;
      }

      if (response != null) {
        setState(() {
          messages[0] = response;
          _messageController.clear();
          _selectedImage = null;
        });
      }
    } catch (e) {
      setState(() {
        messages.removeAt(0);
        error = e.toString();
      });
    }
  }

  Widget _buildMessageBubble(Message message) {
    final isMe = message.myMessage;
    
    Widget messageContent;
    if (message.content != null) {
      messageContent = Text(
        message.content!,
        style: TextStyle(
          color: isMe ? Colors.white : Colors.black,
        ),
      );
    } else if (message.imageUrl != null) {
      if (_imageUrlCache.containsKey(message.imageUrl)) {
        messageContent = Image.network(
          _imageUrlCache[message.imageUrl]!,
          width: 200,
          fit: BoxFit.cover,
        );
      } else {
        messageContent = FutureBuilder(
          future: Future(() async {
            final prefs = await SharedPreferences.getInstance();
            final result = await _imageService.getImage(
              prefs.getString('auth_token') ?? '',
              message.imageUrl!,
            );
            if (result.$1 != null) {
              _imageUrlCache[message.imageUrl!] = result.$1!.url;
            }
            return result;
          }),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.$1 != null) {
              return Image.network(
                snapshot.data!.$1!.url,
                width: 200,
                fit: BoxFit.cover,
              );
            }
            return const SizedBox(
              width: 200,
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          },
        );
      }
    } else {
      messageContent = const Text('Unsupported message type');
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: messageContent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.conversation.productName),
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadMessages,
              child: isLoading && messages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                      ? Center(child: Text('Error: $error'))
                      : messages.isEmpty
                          ? const Center(child: Text('No messages yet'))
                          : ListView.builder(
                              controller: _scrollController,
                              reverse: true,
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
            ),
          ),
          if (_selectedImage != null)
            Container(
              height: 100,
              padding: const EdgeInsets.all(8),
              child: Stack(
                children: [
                  Image.file(
                    _selectedImage!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _selectedImage = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _selectedImage == null ? _pickImage : null,
                ),
                IconButton(
                  icon: const Icon(Icons.gavel),
                  onPressed: () {
                    // TODO: Implement bid functionality
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: _selectedImage == null,
                    decoration: InputDecoration(
                      hintText: _selectedImage != null 
                          ? 'Image selected' 
                          : 'Type a message...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}