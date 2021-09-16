import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_picker/image_picker.dart';

class ChatMessage {
  String text = '';
  DateTime dateCreated = DateTime.now();
  String uuid = '';
  bool isTyping = false;
  DocumentReference? userDocRef;
  String avatarURL = '';
  List? images;
  String type = 'NORMAL';
  List<Map<String, dynamic>> received = [];

  ChatMessage();

  ChatMessage.convertFromDoc(DocumentSnapshot doc)
      : text = doc.get('text'),
        dateCreated = doc.get('dateCreated').toDate(),
        uuid = doc.get('uuid'),
        isTyping = doc.get('isTyping'),
        userDocRef = doc.get('userDocRef'),
        avatarURL = doc.get('avatarURL'), images = doc.get('images'), type = doc.get('type'), received = List<Map<String, dynamic>>.from(doc.get('received'));

  Map<String, dynamic> toJSON() {
    return {
      'text': text,
      'dateCreated': dateCreated,
      'uuid': uuid,
      'isTyping': isTyping,
      'userDocRef': userDocRef,
      'avatarURL': avatarURL,
      'images': images ?? [],
      'type': type,
      'received': received
    };
  }
}

class ChatMessageState {
  String id;
  ChatMessage chatMessage;
  DocumentReference docRef;
  DocumentSnapshot? snapshot;
  List<Map<String, dynamic>>? files;
  
  ChatMessageState(this.id, this.chatMessage, this.docRef, this.snapshot, {this.files});
}
