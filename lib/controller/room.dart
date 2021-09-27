import 'dart:async';
import 'dart:convert';

import 'package:chat_app_multiple_platforms/domain/message.dart';
import 'package:chat_app_multiple_platforms/domain/profile.dart';
import 'package:chat_app_multiple_platforms/main.dart';
import 'package:chat_app_multiple_platforms/service/firebase.dart';
import 'package:chat_app_multiple_platforms/service/message_handler.dart';
import 'package:chat_app_multiple_platforms/view/room/room.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class RoomController {
  BuildContext _context;
  StreamSubscription<RemoteMessage>? onMessageSS;
  StreamSubscription<RemoteMessage>? onMessageOpenedAppSS;
  MessagesHandler handler = MessagesHandler();
  StreamSubscription? listeningRoom;

  RoomController(this._context, Stream<RemoteMessage> onMessageStream, Stream<RemoteMessage> onMessageOpenedAppStream) {
    messages = [];
    localMessages = {};

    _initFirebaseMessaging(onMessageStream, onMessageOpenedAppStream);

    _syncUserInformation();

    _openTimer();
  }

  _initFirebaseMessaging(Stream<RemoteMessage> onMessageStream, Stream<RemoteMessage> onMessageOpenedAppStream) {
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        Navigator.pushNamed(_context, '/room');
      }
    });

    onMessageOpenedAppSS = onMessageOpenedAppStream.listen((RemoteMessage message) {
      Navigator.pushNamed(_context, '/room');
    });

    onMessageSS = onMessageStream.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null && !kIsWeb) {
        flutterLocalNotificationsPlugin!.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel!.id,
                channel!.name,
                channel!.description,
                icon: 'launch_background',
              ),
            ));
      }
    });
  }

  _syncUserInformation() {
    listeningRoom = (app.currRoom['roomRef'] as DocumentReference).snapshots().listen((event) {
      List usersInfo = event.get('usersInfo');

      final infoList = InfoList.init(usersInfo);
      
      app.currRoom['infoList'] = infoList;
    });
  }
  
  switchNotification(bool turnOn) async {
    if (turnOn && onMessageSS!.isPaused) {
      onMessageSS!.resume();
    } else if (!turnOn && !onMessageSS!.isPaused) {
      onMessageSS!.pause();
    }
    app.currRoom['infoList'] = (app.currRoom['infoList'] as InfoList).updateNotification(app.profile!.uuid, turnOn);

    await (app.currRoom['roomRef'] as DocumentReference).update({'usersInfo': (app.currRoom['infoList'] as InfoList).toJSON()});
  }
  
  dispose() {
    onMessageSS!.cancel();
    onMessageOpenedAppSS!.cancel();
    listeningRoom!.cancel();
    
    timer!.cancel();
  }

  List<ChatMessageState> messages = []; //main list
  Map<String, dynamic> localMessages = {};
  int indexIncrease = 1;

  _messageStream() {
    final docRef = app.currRoom['roomRef'] as DocumentReference;
    FirebaseService.syncingMessage(docRef).listen((event) {
      event.docs.forEach((item) {
        ChatMessage _message = item.data();
        List<Map<String, dynamic>> filesData = [];
        
        if (_message.type == 'IMAGE') {
          _message.images?.forEach((item) {
            filesData.add({'name': item['name'], 'url': item['url']});
          });
        }

        ChatMessageState _messageState = ChatMessageState(item.id, _message, item.reference, item, files: filesData);
        handler.add(_messageState.id, _messageState);
      });

      handler.reload();
    });
  }

  DocumentReference? doc;
  bool isTyping = false;

  Future<void> initDataMessageForm(DocumentReference documentReference) async {
    QuerySnapshot<ChatMessage> mess = await FirebaseService.getListMessage(documentReference);
    handler.init(mess.docs, callback: (args) {
      indexIncrease = args['indexIncrease'];
    });

    handler.reload();

    _messageStream();
  }

  final _typingId = '${app.profile!.uuid}-TYPING';
  ChatMessage _messageTyping = ChatMessage()
    ..type = 'TYPING'
    ..uuid = app.profile!.uuid
    ..isTyping = true
    ..userDocRef = app.profile!.userDoc!.reference
    ..avatarURL = app.profile!.avatarURL;

  void sendMessage(DocumentReference docRef, Profile profile, String message) async {
    if (indexIncrease > 1) indexIncrease++;
    
    ChatMessage _message = ChatMessage()
      ..text = message
      ..dateCreated = new DateTime.now()
      ..uuid = profile.uuid
      ..isTyping = true
      ..userDocRef = profile.userDoc!.reference
      ..avatarURL = profile.avatarURL;

    (app.currRoom['infoList'] as InfoList).uuids(ignore: profile.uuid).forEach((item) {
        _message.received.add({'${item}': false});
    });
    
    final id = '${profile.uuid}-$indexIncrease';
    _messageTyping.isTyping = false;
    await docRef.collection('messages').doc(_typingId).set(_messageTyping.toJSON());

    final _state = ChatMessageState(id, _message, docRef.collection('messages').doc(id), null);
    handler.add(id, _state);
    handler.reload();
    
    _sendNotification(app.currRoom['infoList'] as InfoList, message, profile);
  }

  //status: IS_TYPING, TYPING, SENDING, SEND

  uploadPicture(DocumentReference docRef, List<XFile> pickedFile, Profile profile) async {
    if (indexIncrease > 1) indexIncrease++;

    final now = new DateTime.now();
    List<Map<String, dynamic>> files = [];
    List<Map<String, dynamic>> filesData = [];

    for(int i = 0; i < pickedFile.length; i++) {
      final fileName = '${DateFormat('yyyyMMddHHmmssS').format(now)}-$i';

      files.add({'name': fileName, 'file': pickedFile.elementAt(i), 'url': ''});
      filesData.add({'name': fileName, 'url': ''});
    }

    ChatMessage _message = ChatMessage()
      ..text = ''
      ..dateCreated = now
      ..uuid = profile.uuid
      ..isTyping = false
      ..userDocRef = profile.userDoc!.reference
      ..avatarURL = profile.avatarURL
      ..images = filesData
      ..type = 'IMAGE';

    (app.currRoom['infoList'] as InfoList).uuids(ignore: profile.uuid).forEach((item) {
      _message.received.add({'${item}': false});
    });

    final id = '${profile.uuid}-$indexIncrease';
    
    handler.add(id, ChatMessageState(id, _message, docRef.collection('messages').doc(id), null, files: files));
    handler.reload();
  }
  
  updatePhotoData(ChatMessageState _state, List<Map<String, dynamic>> files) {
    
    ChatMessage _message = _state.chatMessage;

    _message.images = files;

    _state.docRef.set(_message.toJSON());
  }
  
  Future<List<Map<String, dynamic>>> uploadPhoto(ChatMessageState _state) async {
    List<Map<String, dynamic>> urls = [];
    int index = 0;
    
    await _uploadPhotoSync(index, _state.files!, urls, _state.docRef.id);
    return urls;
  }

  _uploadPhotoSync(int index, List<Map<String, dynamic>> pickedFile, List<Map<String, dynamic>> urls, String id) async {
    if (index <= pickedFile.length - 1) {
      final _image = pickedFile.elementAt(index);
      
      Reference ref = await FirebaseStorage.instance.ref('rooms').child(id).child('${_image['name']}.png');
      await ref.putData(await (_image['file'] as XFile).readAsBytes());

      urls.add({'name': _image['name'], 'url': await ref.getDownloadURL()});
      index++;

      await _uploadPhotoSync(index, pickedFile, urls, id);
    }
  }

  _sendNotification(InfoList infoList, String message, Profile sender) async {
    List<Profile> profiles = [];
    List<String> tokens = [];

    infoList.informations.forEach((item) {
      if (item.fcm != null && item.uuid != sender.uuid && item.notification) tokens.add(item.fcm);
    });

    if (tokens.length > 0) {
      String key = 'AAAAFGC0U5c:APA91bGgJDRh2KHXC8QfMYcSK5I0kKRDShFqzcXRHuR32TktbRvBlksKZriofb46aF9hh-tcsURl-BrTT4izgWHMxzjSLLY6GJH0FWlVpwebyTIrZE_W692BgO3dqaycainv3gzIUeUB';
      Map<String, String> headers = {'Authorization': 'key=$key', 'Content-Type': 'application/json'};
      String body = jsonEncode({
        "registration_ids": tokens,
        "collapse_key": "New Message",
        "priority": "high",
        "notification": {"title": sender.displayName, "body": message}
      });

      await http.post(Uri.parse('https://fcm.googleapis.com/fcm/send'), headers: headers, body: body);
    }
  }

  typingMessing(DocumentReference docRef, Profile profile, String message) async {
    _messageTyping.dateCreated = new DateTime.now();
    
    if (!message.isEmpty) {
      await docRef.collection('messages').doc(_typingId).set(_messageTyping.toJSON());
    } else {
      _messageTyping.isTyping = false;
      await docRef.collection('messages').doc(_typingId).set(_messageTyping.toJSON());
    }
  }

  Timer? timer;
  StreamController<QuerySnapshot>? timerStream;
  Future<QuerySnapshot<Map<String, dynamic>>>? requestTypingFuture; 
  
  _openTimer() {
    timerStream = StreamController();
    timer = Timer.periodic(Duration(seconds: 1), _requestTyping);
  }
  
  void _requestTyping(timer) async {
    if (requestTypingFuture != null) requestTypingFuture!.ignore();
    
    requestTypingFuture = FirebaseService.requestTyping(app.currRoom['roomRef'] as DocumentReference);

    requestTypingFuture!.then((value) {
      timerStream!.add(value);
    });
  }
}
