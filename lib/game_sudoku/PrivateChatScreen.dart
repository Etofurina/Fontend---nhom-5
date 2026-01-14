
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/chat_service.dart';

class PrivateChatScreen extends StatefulWidget {
final String targetEmail; // Email người mình muốn chat
final String targetName;  // Tên hiển thị của họ

const PrivateChatScreen({
Key? key,
required this.targetEmail,
required this.targetName
}) : super(key: key);

@override
_PrivateChatScreenState createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
final ChatService _chatService = ChatService();
final TextEditingController _controller = TextEditingController();
final ScrollController _scrollController = ScrollController();

// List chứa tin nhắn
final List<Map<String, String>> _messages = [];

// Email của chính mình (để biết tin nhắn nào là của mình)
String _myEmail = "";
bool _isLoading = true;

@override
void initState() {
super.initState();
_initChat();
}

Future<void> _initChat() async {
// 1. Lấy Email của bản thân từ bộ nhớ máy
final prefs = await SharedPreferences.getInstance();
final savedEmail = prefs.getString('email') ?? ""; // Đảm bảo bạn đã lưu 'email' khi Login

setState(() {
_myEmail = savedEmail;
_isLoading = false;
});

// 2. Kết nối SignalR
await _chatService.connect();

// 3. Lắng nghe tin nhắn tới
_chatService.onPrivateMessageReceived = (sender, msg, time) {
if (!mounted) return;

// Logic lọc tin nhắn:
// Chỉ hiển thị nếu tin nhắn này thuộc cuộc trò chuyện giữa TÔI và NGƯỜI ĐÓ
// - Trường hợp 1: Người đó gửi cho tôi (sender == targetEmail)
// - Trường hợp 2: Tôi gửi cho người đó (sender == _myEmail) - Server phản hồi lại

bool isRelevant = (sender == widget.targetEmail) || (sender == _myEmail);

if (isRelevant) {
setState(() {
_messages.insert(0, {
'sender': sender,
'msg': msg,
'time': time
});
});
}
};
}

@override
void dispose() {
_chatService.disconnect();
_controller.dispose();
_scrollController.dispose();
super.dispose();
}

void _sendMessage() {
final text = _controller.text.trim();
if (text.isEmpty) return;

// Gửi tin nhắn qua SignalR
_chatService.sendPrivate(widget.targetEmail, text);

// Xóa ô nhập liệu
_controller.clear();
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(widget.targetName, style: const TextStyle(fontSize: 16)),
Text(widget.targetEmail, style: const TextStyle(fontSize: 12, color: Colors.white70)),
],
),
backgroundColor: Colors.blueAccent,
),
body: _isLoading
? const Center(child: CircularProgressIndicator())
    : Column(
children: [
// Khu vực hiển thị tin nhắn
Expanded(
child: _messages.isEmpty
? Center(child: Text("Hãy bắt đầu trò chuyện với ${widget.targetName}!", style: const TextStyle(color: Colors.grey)))
    : ListView.builder(
controller: _scrollController,
reverse: true, // Tin mới nhất ở dưới cùng
padding: const EdgeInsets.all(10),
itemCount: _messages.length,
itemBuilder: (context, index) {
final item = _messages[index];

// Kiểm tra xem tin nhắn này có phải của mình không
// Nếu sender trùng với email của mình -> Là mình gửi -> Hiện bên phải
final isMe = (item['sender'] == _myEmail);

return Align(
alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
child: Container(
margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
decoration: BoxDecoration(
color: isMe ? Colors.blue[100] : Colors.grey[200],
borderRadius: BorderRadius.only(
topLeft: const Radius.circular(12),
topRight: const Radius.circular(12),
bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
bottomRight: isMe ? Radius.zero : const Radius.circular(12),
),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
item['msg'] ?? "",
style: const TextStyle(fontSize: 16, color: Colors.black87),
),
const SizedBox(height: 4),
Text(
item['time'] ?? "",
style: TextStyle(fontSize: 10, color: Colors.grey[600]),
),
],
),
),
);
},
),
),

// Khu vực nhập tin nhắn
Container(
padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
decoration: BoxDecoration(
color: Colors.white,
boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, -2))],
),
child: Row(
children: [
Expanded(
child: TextField(
controller: _controller,
decoration: InputDecoration(
hintText: "Nhập tin nhắn...",
contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
filled: true,
fillColor: Colors.grey[100],
),
onSubmitted: (_) => _sendMessage(), // Cho phép nhấn Enter để gửi
),
),
const SizedBox(width: 8),
CircleAvatar(
backgroundColor: Colors.blueAccent,
child: IconButton(
icon: const Icon(Icons.send, color: Colors.white, size: 20),
onPressed: _sendMessage,
),
),
],
),
)
],
),
);
}
}