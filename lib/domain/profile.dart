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

class UsersInfo {
  String uuid = '';
  String name = '';
  String avatar = '';
  String fcm = '';
  bool notification = true;

  UsersInfo.fromJSON(this.uuid, Map info)
      : name = info['name'],
        avatar = info['avatar'],
        fcm = info['fcm'],
        notification = info['notification'];
}

class InfoList {
  List<UsersInfo> informations = [];

  InfoList(this.informations);
  
  InfoList.init(List usersInfo) {
    usersInfo.forEach((item) {
      Map info = Map.from((item as Map).values.first);
      informations.add(UsersInfo.fromJSON((item as Map).keys.first, info));
    });
  }

  List<String> names() {
    return informations.map((item) => item.name).toList();
  }

  List<String> uuids({String? ignore}) {
    return informations.where((item) => item.uuid != ignore).map((item) => item.uuid).toList();
  }

  List<String> avatars({String? ignore}) {
    return informations.where((item) => item.avatar != ignore).map((item) => item.avatar).toList();
  }
  
  UsersInfo? find({String? uuid}) {
    var info = null;
    informations.every((item) {
      if (item.uuid == uuid) {
        info = item;
        return false;
      }
      
      return true;
    });
    return info;
  }

  int length() => informations.length;

  UsersInfo elementAt(int index) => informations.elementAt(index);
  
  InfoList updateNotification(String uuid, bool turnOn) {
    final index = informations.indexWhere((item) => item.uuid == uuid);
    
    if (index >= 0) {
      var item = informations.elementAt(index);
      item.notification = turnOn;

      informations[index] = item;
    }
    
    return InfoList(informations);
  }
  
  List toJSON() {
    List results = [];

    informations.forEach((item) {
      results.add({
        '${item.uuid}': {
          'name': item.name,
          'avatar': item.avatar,
          'fcm': item.fcm,
          'notification': item.notification
        }
      });
    });
    
    return results;
  }
}
