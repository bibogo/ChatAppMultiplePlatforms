import 'dart:convert';

import 'package:chat_app_multiple_platforms/config/app_store.dart';
import 'package:chat_app_multiple_platforms/service/firebase.dart';
import 'package:chat_app_multiple_platforms/view/chat-list/chat_list.dart';
import 'package:chat_app_multiple_platforms/view/images/load_images_screen.dart';
import 'package:chat_app_multiple_platforms/view/information/information.dart';
import 'package:chat_app_multiple_platforms/view/login/login.dart';
import 'package:chat_app_multiple_platforms/view/room/room.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
}

AndroidNotificationChannel? channel;
FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  if (!kIsWeb) {
    channel = const AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      'This channel is used for important notifications.', // description
      importance: Importance.high,
    );

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    await flutterLocalNotificationsPlugin!
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel!);
    
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }
  
  runApp(ChatApp());
}

App app = App();

class ChatApp extends StatefulWidget {
  const ChatApp({Key? key}) : super(key: key);

  @override
  _ChatAppState createState() => _ChatAppState();
}

class _ChatAppState extends State<ChatApp> {
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: app.navigatorKey,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/chatList': (context) => const ChatList(),
        '/information': (context) => const Information(),
        '/room': (context) => Room(),
      },
      title: 'Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}