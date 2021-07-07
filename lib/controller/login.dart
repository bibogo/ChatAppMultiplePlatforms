import 'package:chat_app_multiple_platforms/main.dart';
import 'package:chat_app_multiple_platforms/view/chat-list/chat_list.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoginController {
  
  
  static void signIn(BuildContext context, email, password) async {
    try {
      appStore?.userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ChatList()));
    } catch (error) {
      print(error);
    }
  }
}