import 'package:chat_app_multiple_platforms/domain/message.dart';
import 'package:chat_app_multiple_platforms/domain/profile.dart';
import 'package:chat_app_multiple_platforms/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static void initFirebase() async {
    await Firebase.initializeApp();
  }

  static Future<DocumentSnapshot<Profile>> getUsersEqual(uuid) {
    return FirebaseFirestore.instance.collection('users').doc(uuid).withConverter<Profile>(fromFirestore: (snapshot, _) => Profile.fromDoc(snapshot), toFirestore: (model, _) => model.toJSON()).get();
  }

  static Stream<QuerySnapshot<Profile>> getUsersNotEqual(currentUser) {
    return FirebaseFirestore.instance.collection('users').where('uuid', isNotEqualTo: currentUser).withConverter<Profile>(fromFirestore: (snapshot, _) => Profile.fromDoc(snapshot), toFirestore: (model, _) => model.toJSON()).snapshots(includeMetadataChanges: true);
  }

  static Future<DocumentReference> createChatRoom(List users, List usersInfo) async {
    QuerySnapshot<Map<String, dynamic>> room = await FirebaseFirestore.instance.collection('rooms').where('uuids', isEqualTo: users).get();

    if (room.docs.isNotEmpty) {
      return room.docs.first.reference;
    } else {
      CollectionReference messageRoom = FirebaseFirestore.instance.collection('rooms');

      return messageRoom.add({'users': users, 'usersInfo': usersInfo});
    }
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getRoomChatContainsUser(Profile profile) {
    return FirebaseFirestore.instance.collection('rooms').where('users', arrayContains: profile.userDoc!.reference).snapshots();
  }

  static Future<QuerySnapshot<ChatMessage>> getListMessage(DocumentReference? documentReference) async {
    if (documentReference == null) {
      return Future<QuerySnapshot<ChatMessage>>.value();
    }

    return FirebaseFirestore.instance.doc('${documentReference.path}').collection('messages')
        .where('type', whereIn: ['NORMAL', 'IMAGE'])
        .orderBy('dateCreated')
        .withConverter<ChatMessage>(fromFirestore: (snapshot, _) => ChatMessage.convertFromDoc(snapshot), toFirestore: (model, _) => model.toJSON()).get();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getTypingMessage(DocumentReference? documentReference) {
    if (documentReference == null) {
      return Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    return FirebaseFirestore.instance.doc('${documentReference.path}').collection('messages').where('isTyping', isEqualTo: true).snapshots(includeMetadataChanges: true);
  }

  static Stream<QuerySnapshot<ChatMessage>> syncingMessage(DocumentReference? documentReference) {
    if (documentReference == null) {
      return Stream<QuerySnapshot<ChatMessage>>.empty();
    }

    return FirebaseFirestore.instance.doc('${documentReference.path}').collection('messages')
        .where('uuid', isNotEqualTo: app.profile?.uuid)
        .where('received', arrayContains: {'${app.profile?.uuid}': false})
        .orderBy('uuid').orderBy('dateCreated', descending: true)
        .where('isTyping', isEqualTo: false)
        .withConverter<ChatMessage>(fromFirestore: (snapshot, _) => ChatMessage.convertFromDoc(snapshot), toFirestore: (model, _) => model.toJSON())
        .snapshots();
  }

  static Future<void> buildProfile(List<Profile> profiles, int index, List uuids) async {
    if (index <= uuids.length - 1) {
      DocumentReference<Map<String, dynamic>> docRef = uuids.elementAt(index) as DocumentReference<Map<String, dynamic>>;
      profiles.add(Profile.fromDoc(await docRef.get()));
      index++;

      await FirebaseService.buildProfile(profiles, index, uuids);
    }
  }
  
  static Future<QuerySnapshot<Map<String, dynamic>>> requestTyping(DocumentReference? documentReference) async {
    var now = DateTime.now();
    var previous10s = now.subtract(Duration(seconds: 10));
    
    return FirebaseFirestore.instance.doc('${documentReference!.path}').collection('messages')
        .where('dateCreated', isGreaterThan: previous10s)
        .where('type', isEqualTo: 'TYPING').get(GetOptions(source: Source.server));
  }
}

class StorageService {
  static Future<String> getAvatarURLByUUID(uuid) => FirebaseStorage.instance.ref().child('users').child(uuid).child('avatar.png').getDownloadURL();
}
