import 'package:chat_app_multiple_platforms/service/firebase.dart';
import 'package:chat_app_multiple_platforms/view/room/room.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ChatListController {

  void createChatRoom(BuildContext context, currentUser, userLinked, usernameLinked) async {
    DocumentReference room = await FirebaseService.createChatRoom(currentUser, userLinked);

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Room(documentReference: room, name: usernameLinked,)));
  }
}