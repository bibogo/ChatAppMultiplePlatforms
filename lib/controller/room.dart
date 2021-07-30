import 'dart:convert';

import 'package:chat_app_multiple_platforms/domain/message.dart';
import 'package:chat_app_multiple_platforms/domain/profile.dart';
import 'package:chat_app_multiple_platforms/service/firebase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class RoomController {
  List<Map<String, dynamic>> messages = [];
  DocumentReference? doc;
  bool isTyping = false;

  Future<void> getMessage(DocumentReference? documentReference) async {
    QuerySnapshot<ChatMessage> mess = await FirebaseService.getListMessage(documentReference);
    List<QueryDocumentSnapshot<ChatMessage>> arr = mess.docs;

    arr.sort((a, b) => -(a.data().dateCreated.compareTo(b.data().dateCreated)));

    arr.forEach((item) {
      print('${item.data().text} -${item.data().dateCreated}');
      if (!item.data().isTyping && item.data().isReceived) {
        messages.add({'message': item.data(), 'query': item});
      }
    });
  }

  void sendMessage(DocumentReference documentReference, Profile profile, String message) async {
    if (doc != null) {
      await doc?.set({
        'text': message,
        'isTyping': false,
        'dateCreated': new DateTime.now(),
      }, SetOptions(merge: true)).then((value) {
        isTyping = false;
        doc = null;
      });
    } else {
      ChatMessage _message = ChatMessage()
        ..text = message
        ..dateCreated = new DateTime.now()
        ..uuid = profile.uuid
        ..isTyping = true
        ..isReceived = false
        ..userDocRef = profile.userDoc!.reference
        ..avatarURL = profile.avatarURL;

      await documentReference.collection('message').add(_message.toJSON());
    }

    DocumentSnapshot documentSnapshot = await documentReference.get();

    _sendNotification(await documentSnapshot.get('uuids'), message, profile);
  }

  Future<void> sendingMessage(DocumentReference documentReference, Profile profile, String message) async {
    if (doc == null && !isTyping) {
      isTyping = true;
      ChatMessage _message = ChatMessage()
        ..text = message
        ..dateCreated = new DateTime.now()
        ..uuid = profile.uuid
        ..isTyping = true
        ..isReceived = false
        ..userDocRef = profile.userDoc!.reference
        ..avatarURL = profile.avatarURL;

      doc = await documentReference.collection('message').add(_message.toJSON());
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

  uploadPicture(DocumentReference documentReference, List<XFile> pickedFile, Profile profile) async {
    try {
      List<String> urls = [];
      int index = 0;

      await _uploadPhotoSync(index, pickedFile, urls, documentReference.id);

      if (urls.length > 0) {
        ChatMessage _message = ChatMessage()
          ..text = ''
          ..dateCreated = new DateTime.now()
          ..uuid = profile.uuid
          ..isTyping = false
          ..isReceived = false
          ..userDocRef = profile.userDoc!.reference
          ..avatarURL = profile.avatarURL
          ..images = urls;

        await documentReference.collection('message').add(_message.toJSON());

        DocumentSnapshot documentSnapshot = await documentReference.get();

        await _sendNotification(await documentSnapshot.get('uuids'), 'Sent you a photo', profile);
      }
    } catch (e) {
      print(e);
    }
  }

  _uploadPhotoSync(int index, List<XFile> pickedFile, List<String> urls, String id) async {
    if (index <= pickedFile.length - 1) {
      final _image = pickedFile.elementAt(index);
      String fileName = DateFormat('yyyyMMddHHmmssS').format(DateTime.now());
      Reference ref = await FirebaseStorage.instance.ref('rooms').child(id).child('$fileName.png');
      await ref.putData(await _image.readAsBytes());

      urls.add(await ref.getDownloadURL());
      index++;

      await _uploadPhotoSync(index, pickedFile, urls, id);
    }
  }

  _sendNotification(List uuids, String message, Profile sender) async {
    List<Profile> profiles = [];
    List<String> tokens = [];

    await FirebaseService.buildProfile(profiles, 0, uuids);

    profiles.forEach((_profile) {
      if (_profile.fcmToken != null) tokens.add(_profile.fcmToken!);
    });

    if (tokens.length > 0) {
      String key = 'AAAAFGC0U5c:APA91bGgJDRh2KHXC8QfMYcSK5I0kKRDShFqzcXRHuR32TktbRvBlksKZriofb46aF9hh-tcsURl-BrTT4izgWHMxzjSLLY6GJH0FWlVpwebyTIrZE_W692BgO3dqaycainv3gzIUeUB';
      Map<String, String> headers = {'Authorization': 'key=$key', 'Content-Type': 'application/json'};
      print(tokens);
      String body = jsonEncode({
        "registration_ids": tokens,
        "collapse_key": "New Message",
        "priority": "high",
        "notification": {"title": sender.displayName, "body": message}
      });

      await http.post(Uri.parse('https://fcm.googleapis.com/fcm/send'), headers: headers, body: body).then((value) => print(value.body));
    }
  }
}
