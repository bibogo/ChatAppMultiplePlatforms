import 'package:chat_app_multiple_platforms/domain/profile.dart';
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
    
    DocumentReference room = await FirebaseService.createChatRoom(refs);
  }

  void navigateToInfo(BuildContext context) async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => Information()));
  }
  
  Future<List<Profile>> getProfileFromRef(List uuids) async {
    List<Profile> profiles = [];

    await FirebaseService.buildProfile(profiles, 0, uuids);
    
    return Future.value(profiles);
  }
  
  void navigateToChatRoom(BuildContext context, DocumentSnapshot docSnapshot) async {
    List uuids = docSnapshot.get('uuids') as List;
    List<Profile> profiles = [];
    List<String> names = [];
    
    for(DocumentReference uuid in uuids) {
      Profile _profile = (await uuid.withConverter<Profile>(fromFirestore: (snapshot, _) => Profile.fromDoc(snapshot), toFirestore: (model, _) => model.toJSON()).get()).data()!;

      names.add(_profile.displayName);
      profiles.add(_profile);
    }
    
    Navigator.push(context, MaterialPageRoute(builder: (context) => Room(documentReference: docSnapshot.reference, title: names.join(', '), profiles: profiles,)));
  }
}