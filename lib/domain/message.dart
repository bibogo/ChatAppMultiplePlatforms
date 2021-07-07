import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  String text = '';
  DateTime dateCreated = DateTime.now();
  String uuId = '';
  bool isTyping = false;
  bool isReceived = false;

  Message.convertFromDoc(DocumentSnapshot doc)
      : text = doc.get('text'),
        dateCreated = doc.get('dateCreated').toDate(),
        uuId = doc.get('uuid'),
        isTyping = doc.get('isTyping'),
        isReceived = doc.get('isReceived');
  
  Map<String, dynamic> toJSON() {
    return {
      'text': text,
      'time': dateCreated.microsecondsSinceEpoch,
      'uuId': uuId,
      'isTyping': isTyping,
      'isReceived': isReceived
    };
  }
}
