import 'package:chat_app_multiple_platforms/domain/profile.dart';
import 'package:chat_app_multiple_platforms/main.dart';
import 'package:chat_app_multiple_platforms/service/firebase.dart';
import 'package:chat_app_multiple_platforms/view/chat-list/chat_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoginController {
  static void signIn(BuildContext context, email, password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      
      String uuid = userCredential.user!.uid;
      DocumentSnapshot<Profile> user = await FirebaseService.getUsersEqual(uuid);

      if (!user.exists) {
        
        String displayName = '${email}'.split('@')[0];

        appStore!.profile = Profile(uuid: uuid, email: email, password: password, displayName: '@$displayName');

        user.reference.set(appStore!.profile!);
        appStore!.profile!.userDoc = user;
      } else {
        appStore!.profile = user.data();
      }

      appStore!.profile!.password = password;
      
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ChatList()));
    } catch (error) {
      print(error);
    }
  }
}
