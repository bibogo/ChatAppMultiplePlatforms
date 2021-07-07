import 'package:chat_app_multiple_platforms/config/app_store.dart';
import 'package:chat_app_multiple_platforms/service/firebase.dart';
import 'package:chat_app_multiple_platforms/view/login/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ChatApp());
}

AppStore? appStore;

class ChatApp extends StatelessWidget {
  const ChatApp({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    appStore = AppStore();

    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(),
    );
  }
}
