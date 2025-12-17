import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenRouter Chat Bot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const ChatScreen(),
    );
  }
}

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  Message({required this.text, required this.isUser, required this.timestamp});
}

class OpenRouterService {
  final Dio _dio;
  static const String apiUrl = 'http://localhost:3000/api/chat'; 

  OpenRouterService() : _dio = Dio() {
    _dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  Future<String> sendMessage(List<Map<String, String>> messages) async {
    try {
      final response = await _dio.post(apiUrl, data: {'messages': messages});

      if (response.statusCode == 200) {
        return response.data['message'].toString().trim();
      } else {
        throw Exception('API xatosi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Server bilan ulanish xatosi: $e');
    }
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  final OpenRouterService _apiService = OpenRouterService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addMessage(
      'Assalomu alaykum! Men OpenRouter API orqali ishlaydigan chat botman. Sizga qanday yordam bera olaman?',
      false,
    );
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add(Message(text: text, isUser: isUser, timestamp: DateTime.now()));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = text.trim();
    _addMessage(userMessage, true);
    _controller.clear();

    setState(() { _isLoading = true; });

    try {
      final int startIndex = _messages.length > 10 ? _messages.length - 10 : 0;
      final conversationHistory = _messages
          .skip(startIndex)
          .map((msg) => {
                'role': msg.isUser ? 'user' : 'assistant',
                'content': msg.text,
              })
          .toList();

      conversationHistory.add({'role': 'user', 'content': userMessage});

      final response = await _apiService.sendMessage(conversationHistory);
      _addMessage(response, false);
    } catch (e) {
      _addMessage('❌ Xatolik: ${e.toString().replaceAll('Exception: ', '')}', false);
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _addMessage('Suhbat tozalandi. Yangi savol bering!', false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        title: const Text('OpenRouter Bot'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return const Center(child: CircularProgressIndicator());
                }
                final message = _messages[index];
                return Align(
                  alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: message.isUser ? Colors.blue : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(color: message.isUser ? Colors.white : Colors.black),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_isLoading,
                    onSubmitted: (_) => _sendMessage(_controller.text),
                    decoration: InputDecoration(
                      hintText: 'Xabar yozing...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(_isLoading ? Icons.hourglass_empty : Icons.send),
                  onPressed: _isLoading ? null : () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
