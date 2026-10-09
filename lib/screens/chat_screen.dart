import 'package:flutter/material.dart';
import '../main.dart';
import '../models/models.dart';
import '../services/chat_service.dart';

/// The private chat between the two paired partners. Real-time via a
/// Postgres INSERT subscription — see ChatService.watchMessages.
class ChatScreen extends StatefulWidget {
  final Pairing pairing;
  const ChatScreen({super.key, required this.pairing});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatService = ChatService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _chatService.watchMessages(widget.pairing.id, (m) {
      setState(() => _messages.add(m));
      _scrollToBottom();
    });
  }

  Future<void> _load() async {
    final history = await _chatService.loadHistory(widget.pairing.id);
    setState(() {
      _messages.addAll(history);
      _loading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _send() async {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    _textController.clear();
    await _chatService.send(widget.pairing.id, text);
  }

  @override
  Widget build(BuildContext context) {
    final myId = supabase.auth.currentUser!.id;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      final isMine = m.senderId == myId;
                      return Align(
                        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
                          decoration: BoxDecoration(
                            color: isMine
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(m.content ?? ''),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      maxLength: ChatService.maxMessageLength,
                      decoration: const InputDecoration(
                        hintText: 'Say something...',
                        counterText: '', // keep the composer clean; length is still enforced
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                    tooltip: 'Send message',
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
