import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<String?> getDeviceToken() async {
    return await _messaging.getToken();
  }

  // Add methods to handle foreground/background notifications, etc.
}
