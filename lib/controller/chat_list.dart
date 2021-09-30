import 'package:chat_app_multiple_platforms/domain/profile.dart';
import 'package:chat_app_multiple_platforms/main.dart';
import 'package:chat_app_multiple_platforms/service/firebase.dart';
import 'package:chat_app_multiple_platforms/view/information/information.dart';
import 'package:chat_app_multiple_platforms/view/room/room.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ChatListController {
  void createChatRoom(BuildContext context, Profile currProfile, List<Profile> profiles) async {
    List users = [currProfile.userDoc!.reference];
    List usersInfo = [
      {
        '${currProfile.uuid}': {
          'name': currProfile.displayName,
          'avatar': currProfile.avatarURL,
          'fcm': currProfile.fcmToken,
          'notification': true
        }
      }
    ];

    profiles.forEach((_profile) {
      users.add(_profile.userDoc!.reference);
      usersInfo.add({
        '${_profile.uuid}': {
          'name': _profile.displayName,
          'avatar': _profile.avatarURL,
          'fcm': _profile.fcmToken,
          'notification': true
        }
      });
    });

    await FirebaseService.createChatRoom(users, usersInfo);
  }

  void navigateToInfo(BuildContext context) async {
    Navigator.pushNamed(context, '/information');
  }

  Future<List<Profile>> getProfileFromRef(List uuids) async {
    List<Profile> profiles = [];

    await FirebaseService.buildProfile(profiles, 0, uuids);

    return Future.value(profiles);
  }

  void navigateToChatRoom(BuildContext context, DocumentReference _roomRef, InfoList _infoList) async {
    List userDocs = (await _roomRef.get(GetOptions(source: Source.server))).get('users');

    await updateFCMToken(_infoList, 0, userDocs, _roomRef) ;
    await _roomRef.update({'usersInfo': _infoList.toJSON()});
    app.currRoom['infoList'] = _infoList;
    app.currRoom['roomRef'] = _roomRef;
    
    Navigator.pushNamed(context, '/room');
  }
  
  Future<void> updateFCMToken(InfoList _infoList, int index, List userDocs, DocumentReference _roomRef) async {
    if (index <= userDocs.length - 1) {
      Map<String, dynamic> docRef = (await userDocs[index].get(GetOptions(source: Source.server))).data() as Map<String, dynamic>;
      print('${docRef['uuid']} - ${docRef['fcmToken']}');
      _infoList.updateFCM(docRef['uuid'], docRef['fcmToken']);
      
      
      index++;

      await updateFCMToken(_infoList, index, userDocs, _roomRef);
    }
  }
}
