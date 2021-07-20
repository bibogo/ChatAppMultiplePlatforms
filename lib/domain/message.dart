import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  String text = '';
  DateTime dateCreated = DateTime.now();
  String uuid = '';
  bool isTyping = false;
  bool isReceived = false;
  DocumentReference? userDocRef;
  String avatarURL = '';
  List? images;

  Message();

  Message.convertFromDoc(DocumentSnapshot doc)
      : text = doc.get('text'),
        dateCreated = doc.get('dateCreated').toDate(),
        uuid = doc.get('uuid'),
        isTyping = doc.get('isTyping'),
        isReceived = doc.get('isReceived'),
        userDocRef = doc.get('userDocRef'),
        avatarURL = doc.get('avatarURL'), images = doc.get('images');

  Map<String, dynamic> toJSON() {
    return {
      'text': text,
      'dateCreated': dateCreated,
      'uuid': uuid,
      'isTyping': isTyping,
      'isReceived': isReceived,
      'userDocRef': userDocRef,
      'avatarURL': avatarURL,
      'images': images ?? [],
    };
  }
}
