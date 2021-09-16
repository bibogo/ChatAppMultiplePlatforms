import 'package:chat_app_multiple_platforms/domain/profile.dart';
import 'package:chat_app_multiple_platforms/main.dart';
import 'package:chat_app_multiple_platforms/service/firebase.dart';
import 'package:chat_app_multiple_platforms/view/information/information.dart';
import 'package:chat_app_multiple_platforms/view/room/room.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ChatListController {
  void createChatRoom(BuildContext context, Profile? currProfile, List<Profile> profiles) async {
    List<DocumentReference> refs = [currProfile!.userDoc!.reference];

    profiles.forEach((_profile) {
      refs.add(_profile.userDoc!.reference);
    });

    await FirebaseService.createChatRoom(refs);
  }

  void navigateToInfo(BuildContext context) async {
    Navigator.pushNamed(context, '/information');
  }

  Future<List<Profile>> getProfileFromRef(List uuids) async {
    List<Profile> profiles = [];

    await FirebaseService.buildProfile(profiles, 0, uuids);

    return Future.value(profiles);
  }

  void navigateToChatRoom(BuildContext context, DocumentReference _roomRef, ProfileList _profileList) async {
    app.currRoom['profiles'] = _profileList;
    app.currRoom['roomRef'] = _roomRef;
    
    Navigator.pushNamed(context, '/room');
  }
}
