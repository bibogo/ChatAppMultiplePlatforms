import 'package:chat_app_multiple_platforms/domain/profile.dart';
import 'package:chat_app_multiple_platforms/main.dart';
import 'package:chat_app_multiple_platforms/service/firebase.dart';
import 'package:chat_app_multiple_platforms/view/chat-list/chat_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoginController {
  static void signIn(BuildContext context, email, password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      
      String uuid = userCredential.user!.uid;
      DocumentSnapshot<Profile> user = await FirebaseService.getUsersEqual(uuid);
      String? fcmToken = await FirebaseMessaging.instance.getToken(vapidKey: 'BGpdLRsMJKvFDD9odfPk92uBg-JbQbyoiZdah0XlUyrjG4SDgUsE1iC_kdRgt4Kn0CO7K3RTswPZt61NNuO0XoA');
      if (!user.exists) {
        
        String displayName = '${email}'.split('@')[0];

        app.profile = Profile(uuid: uuid, email: email, password: password, displayName: '@$displayName');
        app.profile?.fcmToken = fcmToken;

        user.reference.set(app.profile!);
        app.profile!.userDoc = user;
      } else {
        app.profile = user.data();
        app.profile?.fcmToken = fcmToken;
        await app.profile!.userDoc!.reference.update({'fcmToken': fcmToken});
      }

      app.profile!.password = password;
      
      Navigator.pushNamed(context, '/chatList');
    } catch (error) {
      print(error);
    }
  }
}
