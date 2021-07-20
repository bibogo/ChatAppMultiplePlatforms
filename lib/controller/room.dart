import 'package:chat_app_multiple_platforms/domain/message.dart';
import 'package:chat_app_multiple_platforms/domain/profile.dart';
import 'package:chat_app_multiple_platforms/service/firebase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomController {
  List<Map<String, dynamic>> messages = [];
  DocumentReference? doc;
  bool isTyping = false;

  Future<void> getMessage(DocumentReference? documentReference) async {
    QuerySnapshot<Message> mess = await FirebaseService.getListMessage(documentReference);
    List<QueryDocumentSnapshot<Message>> arr = mess.docs;

    arr.sort((a, b) => -(a.data().dateCreated.compareTo(b.data().dateCreated)));

    arr.forEach((item) {
      print('${item.data().text} -${item.data().dateCreated}');
      if (!item.data().isTyping && item.data().isReceived) {
        messages.add({'message': item.data(), 'query': item});
      }
    });
  }

  void sendMessage(DocumentReference? documentReference, Profile profile, String message) async {
    if (doc != null) {
      doc?.set({
        'text': message,
        'isTyping': false,
        'dateCreated': new DateTime.now(),
      }, SetOptions(merge: true)).then((value) {
        isTyping = false;
        doc = null;
      });
    } else {
      Message _message = Message()
        ..text = message
        ..dateCreated = new DateTime.now()
        ..uuid = profile.uuid
        ..isTyping = true
        ..isReceived = false
        ..userDocRef = profile.userDoc!.reference
        ..avatarURL = profile.avatarURL;

      documentReference!.collection('message').add(_message.toJSON());
    }
  }

  Future<void> sendingMessage(DocumentReference? documentReference, Profile profile, String message) async {
    if (doc == null && !isTyping) {
      isTyping = true;
      Message _message = Message()
        ..text = message
        ..dateCreated = new DateTime.now()
        ..uuid = profile.uuid
        ..isTyping = true
        ..isReceived = false
        ..userDocRef = profile.userDoc!.reference
        ..avatarURL = profile.avatarURL;

      doc = await documentReference!.collection('message').add(_message.toJSON());
    } else {
      if (message.isNotEmpty) {
        doc?.set({
          'text': message,
        }, SetOptions(merge: true));
      } else {
        await doc?.delete();
        isTyping = false;
        doc = null;
      }
    }
  }
}
