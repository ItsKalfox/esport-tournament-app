import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const kAccent = Color(0xFFFF8A00);
const kCardBg = Color(0xFF1A1A1A);
const kBorder = Color(0xFF2A2A2A);
const kTextPrimary = Color(0xFFE9E9E9);
const kTextSecondary = Color(0xFF9A9A9A);

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        content:
            "Hello! I'm your Esports AI Assistant. Ask me about tournaments, teams, strategies, or any gaming-related questions!",
        isUser: false,
      ),
    );
  }

  Future<void> _sendMessage() async {
    final userInput = _controller.text.trim();
    if (userInput.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(content: userInput, isUser: true));
      _isLoading = true;
    });
    _controller.clear();

    try {
      final url = Uri.parse(
        'https://groqchat-lskwx2g3ua-uc.a.run.app',
      );
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': userInput}),
      );

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception('Server error: ${resp.statusCode} ${resp.body}');
      }

      final data = jsonDecode(resp.body);
      final response =
          data['response'] as String? ??
          'Sorry, I could not process your request.';

      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(content: response, isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final errorMessage = e.toString();
      setState(() {
        _messages.add(
          ChatMessage(
            content: "Connection error: $errorMessage",
            isUser: false,
          ),
        );
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: kAccent,
              radius: 18,
              child: Icon(Icons.smart_toy, color: Colors.black, size: 20),
            ),
            SizedBox(width: 12),
            Text(
              'AI Assistant',
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _ChatBubble(message: message);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(kAccent),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Thinking...', style: TextStyle(color: kTextSecondary)),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF161616),
              border: Border(top: BorderSide(color: kBorder)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: kTextPrimary),
                      decoration: InputDecoration(
                        hintText: 'Ask about tournaments, teams...',
                        hintStyle: const TextStyle(color: kTextSecondary),
                        filled: true,
                        fillColor: kCardBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _isLoading ? null : _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: kAccent,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.send, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String content;
  final bool isUser;

  ChatMessage({required this.content, required this.isUser});
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser ? kAccent : kCardBg,
          borderRadius: BorderRadius.circular(16),
          border: message.isUser ? null : Border.all(color: kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isUser)
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.smart_toy, color: kAccent, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'AI Assistant',
                      style: TextStyle(
                        color: kAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              message.content,
              style: TextStyle(
                color: message.isUser ? Colors.black : kTextPrimary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
