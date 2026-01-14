
import 'package:signalr_netcore/http_connection_options.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';
import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import '../constants.dart';

class ChatService {
  // LƯU Ý QUAN TRỌNG:
  // 1. URL của Conveyor (conveyor.cloud) thường thay đổi nếu bạn tắt mở lại Visual Studio.
  // 2. Hãy thử paste link này vào trình duyệt điện thoại trước. Nếu thấy trang web Conveyor, hãy bấm "Continue" để bỏ qua cảnh báo SSL.
  static const String _hubUrl = AppConstants.chatHubUrl;

  HubConnection? _hubConnection;

  // Callbacks để cập nhật UI
  Function(String user, String message, String time)? onGlobalMessageReceived;
  Function(String sender, String message, String time)? onPrivateMessageReceived;

  // 1. Hàm kết nối
  Future<void> connect() async {
    // Nếu đang kết nối hoặc đã kết nối rồi thì không làm gì cả
    if (_hubConnection?.state == HubConnectionState.Connected ||
        _hubConnection?.state == HubConnectionState.Connecting) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      debugPrint("❌ ChatService: CHƯA CÓ TOKEN. Không thể kết nối.");
      return;
    }

    // Cấu hình kết nối
    _hubConnection = HubConnectionBuilder()
        .withUrl(_hubUrl, options: HttpConnectionOptions(
      accessTokenFactory: () async => token,
      // FIX 1: Ép buộc dùng WebSockets để bỏ qua bước Negotiate HTTP (thường bị chậm/lỗi trên Android)
      transport: HttpTransportType.WebSockets,
      // Bật log để dễ debug
      logMessageContent: true,
    ))
        .withAutomaticReconnect() // Tự động kết nối lại nếu rớt mạng
        .build();

    // Đăng ký lắng nghe sự kiện từ Server
    _hubConnection?.on("ReceiveGlobalMessage", _handleGlobalMessage);
    _hubConnection?.on("ReceivePrivateMessage", _handlePrivateMessage);

    // Bắt đầu kết nối với Timeout an toàn
    try {
      debugPrint("⏳ Đang kết nối tới SignalR...");

      // FIX 2: Tăng thời gian chờ lên 30 giây (mặc định quá ngắn)
      await _hubConnection!.start()?.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException("Quá thời gian chờ kết nối (30s).");
        },
      );

      debugPrint("✅ Kết nối Chat thành công! ID: ${_hubConnection?.connectionId}");
    } catch (e) {
      debugPrint("❌ Lỗi kết nối Chat SignalR: $e");
      // Có thể thêm logic thông báo cho người dùng tại đây
    }
  }

  // 2. Ngắt kết nối
  void disconnect() {
    _hubConnection?.stop();
    debugPrint("Đã ngắt kết nối Chat.");
  }

  // 3. Gửi tin nhắn Global
  Future<void> sendGlobal(String message) async {
    if (message.trim().isEmpty) return;

    if (_hubConnection?.state == HubConnectionState.Connected) {
      try {
        await _hubConnection?.invoke("SendMessageToGlobal", args: [message]);
      } catch (e) {
        debugPrint("❌ Lỗi gửi tin Global: $e");
      }
    } else {
      debugPrint("⚠️ Chưa kết nối, đang thử kết nối lại...");
      await connect();
    }
  }

  // 4. Gửi tin nhắn Private
  Future<void> sendPrivate(String targetEmail, String message) async {
    if (message.trim().isEmpty) return;

    if (_hubConnection?.state == HubConnectionState.Connected) {
      try {
        await _hubConnection?.invoke("SendPrivateMessage", args: [targetEmail, message]);
      } catch (e) {
        debugPrint("❌ Lỗi gửi tin Private: $e");
      }
    }
  }

  // --- Các hàm xử lý nội bộ ---

  void _handleGlobalMessage(List<dynamic>? args) {
    if (args != null && args.length >= 3 && onGlobalMessageReceived != null) {
      // args[0]: User, args[1]: Message, args[2]: Time
      onGlobalMessageReceived!(args[0].toString(), args[1].toString(), args[2].toString());
    }
  }

  void _handlePrivateMessage(List<dynamic>? args) {
    if (args != null && args.length >= 3 && onPrivateMessageReceived != null) {
      onPrivateMessageReceived!(args[0].toString(), args[1].toString(), args[2].toString());
    }
  }
}