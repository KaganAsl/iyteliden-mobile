import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iyteliden_mobile/models/request/bid_request.dart';
import 'package:iyteliden_mobile/models/request/review_request.dart';
import 'package:iyteliden_mobile/models/response/bid_response.dart';
import 'package:iyteliden_mobile/models/response/conversation_response.dart';
import 'package:iyteliden_mobile/models/response/error_response.dart';
import 'package:iyteliden_mobile/models/response/location_response.dart';
import 'package:iyteliden_mobile/models/response/message_response.dart';
import 'package:iyteliden_mobile/services/bid_service.dart';
import 'package:iyteliden_mobile/services/image_service.dart';
import 'package:iyteliden_mobile/services/message_service.dart';
import 'package:iyteliden_mobile/services/product_service.dart';
import 'package:iyteliden_mobile/services/review_service.dart';
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
          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
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
  final ProductService _productService = ProductService();
  final BidService _bidService = BidService();
  final ReviewService _reviewService = ReviewService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  
  List<Message> messages = [];
  List<Location> locations = [];
  BidRequest? bidRequest;
  int? bidId;
  double? bidPrice;
  Location? _selectedLocation;
  String? error;
  bool isLoading = true;
  bool isLoadingMore = false;
  int currentPage = 0;
  bool hasMorePages = true;
  Timer? _messageTimer;
  File? _selectedImage;
  final Map<String, String> _imageUrlCache = {};
  final Map<int, BidResponse> _bidCache = {};

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _startMessagePolling();
    _loadBidData();
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
        _refreshVisibleBids();
      }
    });
  }

  Future<void> _refreshVisibleBids() async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('auth_token');
    if (jwt == null || !mounted) return;

    bool bidsUpdated = false;
    // Iterate over a copy of messages to avoid issues if messages list is modified during async operations (though less likely here).
    List<Message> currentMessages = List.from(messages);

    for (var message in currentMessages) {
      if (message.bidId != null) {
        final (bidResponse, bidError) = await _bidService.getBid(jwt, message.bidId!);
        
        // Ensure component is still mounted after async operation
        if (!mounted) return;

        if (bidError == null && bidResponse != null) {
          final cachedBid = _bidCache[message.bidId];
          // Check if the bid status or other relevant details have changed
          if (cachedBid == null ||
              cachedBid.status != bidResponse.status ||
              cachedBid.price != bidResponse.price) { // You can add more fields to compare if needed
            _bidCache[message.bidId!] = bidResponse;
            bidsUpdated = true;
          }
        }
        // Optionally, handle bidError if you want to show an error for a specific bid refresh failing
      }
    }

    if (bidsUpdated && mounted) {
      setState(() {});
    }
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
    if (_messageController.text.trim().isEmpty && _selectedImage == null && bidId == null) return;

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
      "content": ((_selectedImage != null) || (bidId != null)) ? null : message,
      "bidId": bidId,
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

  Future<int> _placeBid() async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('auth_token');
    if (jwt == null) {
      _showFeedbackSnackBar("Not Authenticated", isError: true);
      return -1;
    }
    if (bidRequest != null) {
      final (res, err) = await _bidService.placeBid(jwt, bidRequest!);
      if (err != null) {
        _showFeedbackSnackBar(err.message, isError: true);
        return -1;
      } else if (res != null) {
        return res.bidId;
      }
    }
    return -1;
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

  void _loadBidData() async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('auth_token');
    if (jwt == null) {
      _showFeedbackSnackBar("Not Authenticated", isError: true);
      return;
    }
    final (res, err) = await _productService.getProductLocations(jwt, widget.conversation.productId);
    if (err != null) {
      _showFeedbackSnackBar(err.message, isError: true);
      return;
    } else if (res != null) {
      setState(() {
        locations = res;
      });
    }
  }

  Widget _buildMessageBubble(Message message) {
    final isMe = message.myMessage;
    final hasImage = message.imageUrl != null && message.imageUrl!.isNotEmpty;
    final hasBid = message.bidId != null;
    
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
            if (hasBid)
              FutureBuilder<(BidResponse?, ErrorResponse?)>(
                future: () async {
                  if (_bidCache.containsKey(message.bidId)) {
                    return (_bidCache[message.bidId], null);
                  }
                  final prefs = await SharedPreferences.getInstance();
                  final jwt = prefs.getString('auth_token');
                  if (jwt == null) return (null, null);
                  final result = await _bidService.getBid(jwt, message.bidId!);
                  if (result.$1 != null) {
                    _bidCache[message.bidId!] = result.$1!;
                  }
                  return result;
                }(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !_bidCache.containsKey(message.bidId)) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }

                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.$1 == null) {
                    return const Text('Error loading bid details');
                  }

                  final bid = snapshot.data!.$1!;
                  
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.white.withOpacity(0.2) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (bid.status == 'UNAVAILABLE')
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Product is sold',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text('Bidder: ${bid.bidderName}', style: widget.conversation.isMyProduct ? TextStyle(color: Colors.black):TextStyle(color: Colors.white),),
                        Text('Price: ₺${bid.price.toStringAsFixed(2)}', style: widget.conversation.isMyProduct ? TextStyle(color: Colors.black):TextStyle(color: Colors.white),),
                        Text('Date: ${_formatDateTime(bid.datetime)}', style: widget.conversation.isMyProduct ? TextStyle(color: Colors.black):TextStyle(color: Colors.white),),
                        Text('Status: ${bid.status}', style: widget.conversation.isMyProduct ? TextStyle(color: Colors.black):TextStyle(color: Colors.white),),
                        const SizedBox(height: 8),
                        if (widget.conversation.isMyProduct)
                          if (bid.status == 'PENDING')
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () async {
                                    final prefs = await SharedPreferences.getInstance();
                                    final jwt = prefs.getString('auth_token');
                                    if (jwt == null) return;
                                    
                                    final (response, error) = await _bidService.acceptBid(jwt, bid.bidId);
                                    if (error != null) {
                                      _showFeedbackSnackBar(error.message, isError: true);
                                    } else if (response != null) {
                                      setState(() {
                                        _bidCache[bid.bidId] = response;
                                      });
                                    }
                                  },
                                  child: const Text('Accept'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final prefs = await SharedPreferences.getInstance();
                                    final jwt = prefs.getString('auth_token');
                                    if (jwt == null) return;
                                    
                                    final (response, error) = await _bidService.declineBid(jwt, bid.bidId);
                                    if (error != null) {
                                      _showFeedbackSnackBar(error.message, isError: true);
                                    } else if (response != null) {
                                      setState(() {
                                        _bidCache[bid.bidId] = response;
                                      });
                                    }
                                  },
                                  child: const Text('Decline'),
                                ),
                              ],
                            ),
                        if (!widget.conversation.isMyProduct)
                          if (bid.status == 'PENDING')
                            const Text(
                              'Waiting for response...',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            )
                          else if (bid.status == 'ACCEPTED')
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () async {
                                    final prefs = await SharedPreferences.getInstance();
                                    final jwt = prefs.getString('auth_token');
                                    if (jwt == null) return;
                                    
                                    final (response, error) = await _bidService.confirmBid(jwt, bid.bidId);
                                    if (error != null) {
                                      _showFeedbackSnackBar(error.message, isError: true);
                                    } else if (response != null) {
                                      setState(() {
                                        _bidCache[bid.bidId] = response;
                                      });
                                    }
                                  },
                                  child: const Text('Confirm'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final prefs = await SharedPreferences.getInstance();
                                    final jwt = prefs.getString('auth_token');
                                    if (jwt == null) return;
                                    
                                    final (response, error) = await _bidService.declineBid(jwt, bid.bidId);
                                    if (error != null) {
                                      _showFeedbackSnackBar(error.message, isError: true);
                                    } else if (response != null) {
                                      setState(() {
                                        _bidCache[bid.bidId] = response;
                                      });
                                    }
                                  },
                                  child: const Text('Deny'),
                                ),
                              ],
                            )
                          else if (bid.status == 'COMPLETED')
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                TextButton(
                                  onPressed: () async {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        int selectedRating = 0;
                                        String reviewContent = '';
                                        final contentController = TextEditingController();
                                        
                                        return StatefulBuilder(
                                          builder: (BuildContext context, StateSetter setDialogState) {
                                            return AlertDialog(
                                              backgroundColor: Colors.white,
                                              title: Text('Write a Review', style: TextStyle(color: AppColors.text)),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('Rating:', style: TextStyle(fontWeight: FontWeight.bold)),
                                                  SizedBox(height: 8),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: List.generate(5, (index) {
                                                      return IconButton(
                                                        onPressed: () {
                                                          setDialogState(() {
                                                            selectedRating = index + 1;
                                                          });
                                                        },
                                                        icon: Icon(
                                                          index < selectedRating ? Icons.star : Icons.star_border,
                                                          color: Colors.amber,
                                                          size: 30,
                                                        ),
                                                      );
                                                    }),
                                                  ),
                                                  SizedBox(height: 16),
                                                  Text('Review:', style: TextStyle(fontWeight: FontWeight.bold)),
                                                  SizedBox(height: 8),
                                                  TextField(
                                                    controller: contentController,
                                                    maxLength: 1000,
                                                    maxLines: 4,
                                                    decoration: InputDecoration(
                                                      hintText: 'Write your review here...',
                                                      border: OutlineInputBorder(),
                                                    ),
                                                    onChanged: (value) {
                                                      reviewContent = value;
                                                    },
                                                  ),
                                                ],
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: Text('Cancel', style: TextStyle(color: AppColors.primary)),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    if (selectedRating == 0) {
                                                      _showFeedbackSnackBar("Please select a rating", isError: true);
                                                      return;
                                                    }
                                                    if (reviewContent.trim().isEmpty) {
                                                      _showFeedbackSnackBar("Please write a review", isError: true);
                                                      return;
                                                    }
                                                    
                                                    final prefs = await SharedPreferences.getInstance();
                                                    final jwt = prefs.getString('auth_token');
                                                    if (jwt == null) {
                                                      _showFeedbackSnackBar("Not Authenticated", isError: true);
                                                      return;
                                                    }
                                                    
                                                    final reviewRequest = ReviewRequest(
                                                      recipientId: widget.conversation.recipientId,
                                                      content: reviewContent.trim(),
                                                      rating: selectedRating,
                                                      productId: widget.conversation.productId,
                                                      bidId: bid.bidId,
                                                    );
                                                    
                                                    final (response, error) = await _reviewService.createReview(jwt, reviewRequest);
                                                    if (error != null) {
                                                      _showFeedbackSnackBar(error.message, isError: true);
                                                    } else {
                                                      _showFeedbackSnackBar("Review submitted successfully!");
                                                      Navigator.of(context).pop();
                                                    }
                                                  },
                                                  child: Text('Submit Review', style: TextStyle(color: AppColors.primary)),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                  child: const Text('Make Review')
                                ),
                              ],
                            )
                          else if (bid.status == 'REVIEWED')
                            const Text(
                              'Product Reviewed.',
                              style: TextStyle(
                                color: Color.fromARGB(255, 162, 230, 153),
                              ),
                            )
                      ],
                    ),
                  );
                },
              ),
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
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
                ? Center(child: CircularProgressIndicator(color: AppColors.primary))
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
                                return Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(color: AppColors.primary),
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
                  color: Colors.grey.withValues(alpha: 0.2),
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
                  widget.conversation.isMyProduct ? const SizedBox() :
                  IconButton(
                    icon: const Icon(Icons.gavel, color: AppColors.primary,),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return StatefulBuilder(
                            builder: (BuildContext context, StateSetter setDialogState) {
                              return AlertDialog(
                                backgroundColor: Colors.white,
                                titleTextStyle: TextStyle(
                                  color: AppColors.text,
                                  fontSize: 16,
                                ),
                                title: const Text('Make an Offer'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Enter your offer amount',
                                        prefixText: '₺',
                                        border: const OutlineInputBorder(),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: AppColors.primary),
                                        ),
                                        labelStyle: TextStyle(color: AppColors.text),
                                        floatingLabelStyle: TextStyle(color: AppColors.primary),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          bidPrice = double.tryParse(value);
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: locations.map((l) {
                                        final isSelected = _selectedLocation == null ? false : _selectedLocation!.isEqual(l);
                                        return FilterChip(
                                          label: Text(l.locationName),
                                          selected: isSelected,
                                          backgroundColor: Colors.grey[200],
                                          selectedColor: AppColors.primary.withOpacity(0.3),
                                          onSelected: (selected) {
                                            setDialogState(() {
                                              if (selected) {
                                                _selectedLocation = l;
                                              } else {
                                                _selectedLocation = null;
                                              }
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    style: TextButton.styleFrom(foregroundColor: Colors.black12),
                                    child: const Text('Cancel', style: TextStyle(color: AppColors.text),),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      if (_selectedLocation == null) {
                                        _showFeedbackSnackBar("Choose one location", isError: true);
                                      } else if (bidPrice == null) {
                                        _showFeedbackSnackBar("Specify bid", isError: true);
                                      } else if (bidPrice! < 0) {
                                        _showFeedbackSnackBar("At least 0", isError: true);
                                      } else {
                                        BidRequest req = BidRequest(productId: widget.conversation.productId, price: bidPrice!, locationId: _selectedLocation!.locationId);
                                        bidRequest = req;
                                        final res = await _placeBid();
                                        if (res == -1) {
                                          _showFeedbackSnackBar("Bid couldn't send.", isError: true);
                                        } else {
                                          setState(() {
                                            bidId = res;
                                          });
                                          await _sendMessage();
                                          setState(() {
                                            bidId = null;
                                            bidRequest = null;
                                            bidId = null;
                                            bidPrice = null;
                                            _selectedLocation = null;
                                          });
                                          Navigator.of(context).pop();
                                        }
                                      }
                                    },
                                    style: TextButton.styleFrom(foregroundColor: Colors.black12),
                                    child: const Text('Make Offer', style: TextStyle(color: AppColors.primary),),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
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