import 'package:flutter/material.dart';
import 'package:iyteliden_mobile/models/response/conversation_response.dart';
import 'package:iyteliden_mobile/services/image_service.dart';
import 'package:iyteliden_mobile/services/message_service.dart';
import 'package:iyteliden_mobile/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iyteliden_mobile/pages/message_page.dart';

class MessagesTab extends StatefulWidget {
  const MessagesTab({super.key});

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  final MessageService _messageService = MessageService();
  final ImageService _imageService = ImageService();
  List<Conversation> conversations = [];
  bool isLoading = true;
  String? error;
  int currentPage = 0;
  bool hasMorePages = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
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

      final (response, errorResponse) = await _messageService.getUserConversations(jwt, currentPage);
      
      if (errorResponse != null) {
        setState(() {
          error = errorResponse.message;
          isLoading = false;
        });
        return;
      }

      if (response != null) {
        setState(() {
          conversations = response.content;
          hasMorePages = currentPage < response.page.totalPages - 1;
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
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (error != null) {
      return Center(child: Text('Error: $error'));
    }

    if (conversations.isEmpty) {
      return const Center(child: Text('No conversations yet'));
    }

    return ListView.builder(
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return FutureBuilder(
          future: Future(() async {
            if (conversation.coverImgKey == null) return null;
            final prefs = await SharedPreferences.getInstance();
            return _imageService.getImage(
              prefs.getString('auth_token') ?? '',
              conversation.coverImgKey!,
            );
          }),
          builder: (context, snapshot) {
            String imageUrl = '';
            if (snapshot.hasData && snapshot.data!.$1 != null) {
              imageUrl = snapshot.data!.$1!.url;
            }

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: imageUrl.isNotEmpty
                    ? NetworkImage(imageUrl)
                    : null,
                child: imageUrl.isEmpty
                    ? const Icon(Icons.image_not_supported)
                    : null,
              ),
              title: Text(conversation.productName),
              subtitle: Text(conversation.username),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MessagePage(
                      conversation: conversation,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
