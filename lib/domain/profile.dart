import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

class Profile {
  String uuid = '';
  String email = '';
  String password = '';
  String displayName = '';
  String description = '';
  String avatarURL = '';
  DocumentSnapshot? userDoc;
  String? fcmToken;

  Profile({this.uuid = '', this.email = '', this.password = '', this.displayName = ''});

  Profile.fromDoc(DocumentSnapshot doc)
      : uuid = doc.get('uuid'),
        email = doc.get('email'),
        displayName = doc.get('displayName'),
        description = doc.get('description'),
        avatarURL = doc.get('avatarURL'),
        userDoc = doc,
        fcmToken = doc.get('fcmToken');

  Map<String, dynamic> toJSON() => {
        'uuid': uuid,
        'email': email,
        'displayName': displayName,
        'description': description,
        'avatarURL': avatarURL,
        'fcmToken': fcmToken,
      };
}

class ProfileList {
  List<Profile> profiles = [];

  ProfileList(this.profiles);
  
  List<String> displayName() {
    return profiles.map((e) => e.displayName).toList();
  }

  List<String> uuids({String? ignore}) {
    return profiles.where((e) => e.uuid != ignore).map((e) => e.uuid).toList();
  }
  
  int length() => profiles.length;
  
  Profile elementAt(int index) => profiles.elementAt(index);
}
