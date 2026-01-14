import 'package:flutter/material.dart';
import '../services/chat_service.dart';

class WorldChatScreen extends StatefulWidget {
  const WorldChatScreen({Key? key}) : super(key: key);

  @override
  _WorldChatScreenState createState() => _WorldChatScreenState();
}

class _WorldChatScreenState extends State<WorldChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
    _connectChat();
  }

  void _connectChat() async {
    // Đăng ký nhận tin nhắn
    _chatService.onGlobalMessageReceived = (user, msg, time) {
      if (mounted) {
        setState(() {
          _messages.insert(0, {'user': user, 'msg': msg, 'time': time});
        });
      }
    };
    await _chatService.connect();
  }

  @override
  void dispose() {
    _chatService.disconnect();
    super.dispose();
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    _chatService.sendGlobal(_controller.text.trim());
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat Thế Giới")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true, // Tin mới nhất ở dưới cùng (hoặc đảo ngược tùy ý)
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final item = _messages[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(item['user']![0].toUpperCase())),
                  title: Text(item['user']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  subtitle: Text(item['msg']!),
                  trailing: Text(item['time']!, style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
                    decoration: InputDecoration(
                      hintText: "Nhập tin nhắn...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send, color: Colors.blue), onPressed: _sendMessage),
              ],
            ),
          )
        ],
      ),
    );
  }
}