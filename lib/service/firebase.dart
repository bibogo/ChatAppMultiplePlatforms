import 'package:chat_app_multiple_platforms/domain/message.dart';
import 'package:chat_app_multiple_platforms/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static void initFirebase() async {
    await Firebase.initializeApp();
  }

  static Stream<QuerySnapshot> getUsers(currentUser) {
    return FirebaseFirestore.instance.collection('users').where('id', isNotEqualTo: currentUser).snapshots(includeMetadataChanges: true);
  }

  static Future<DocumentReference> createChatRoom(currentUser, userLinked) async {
    QuerySnapshot<Map<String, dynamic>> room = await FirebaseFirestore.instance.collection('rooms').where('uuids', arrayContainsAny: [currentUser, userLinked]).get();

    if (room.docs.isNotEmpty) {
      return room.docs.first.reference;
    } else {
      CollectionReference messageRoom = FirebaseFirestore.instance.collection('rooms');

      return messageRoom.add({
        'uuids': [currentUser, userLinked]
      });
    }
  }

  static Future<QuerySnapshot<Message>> getListMessage(DocumentReference? documentReference) async {
    if (documentReference == null) {
      return Future<QuerySnapshot<Message>>.value();
    }

    return FirebaseFirestore.instance.doc('${documentReference.path}').collection('message')
        .where('isReceived', isEqualTo: true)
        .limit(20)
        .withConverter<Message>(fromFirestore: (snapshot, _) => Message.convertFromDoc(snapshot), toFirestore: (model, _) => model.toJSON())
        .get();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getTypingMessage(DocumentReference? documentReference) {
    if (documentReference == null) {
      return Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    return FirebaseFirestore.instance.doc('${documentReference.path}').collection('message').where('isTyping', isEqualTo: true).snapshots(includeMetadataChanges: true);
  }

  static Stream<QuerySnapshot<Message>> getMessageNoReceive(DocumentReference? documentReference) {
    if (documentReference == null) {
      return Stream<QuerySnapshot<Message>>.empty();
    }

    return FirebaseFirestore.instance.doc('${documentReference.path}').collection('message').where('isReceived', isEqualTo: false).withConverter<Message>(fromFirestore: (snapshot, _) => Message.convertFromDoc(snapshot), toFirestore: (model, _) => model.toJSON()).snapshots(includeMetadataChanges: true);
  }
}
