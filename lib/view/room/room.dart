import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app_multiple_platforms/controller/room.dart';
import 'package:chat_app_multiple_platforms/domain/message.dart';
import 'package:chat_app_multiple_platforms/domain/profile.dart';
import 'package:chat_app_multiple_platforms/main.dart';
import 'package:chat_app_multiple_platforms/service/firebase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class Room extends StatefulWidget {
  Room({Key? key, this.documentReference, this.title, this.profiles}) : super(key: key);

  final DocumentReference? documentReference;
  final String? title;
  List<Profile>? profiles;

  @override
  _RoomState createState() => _RoomState();
}

class _RoomState extends State<Room> {
  RoomController? _roomController;
  TextEditingController? _message;
  Widget? messageForm;
  Map<String, Widget?> widgets = {'message': null, 'typing': null, 'composer': null};
  bool initScreen = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    _roomController = RoomController();
    _message = TextEditingController(text: '');

    _roomController?.getMessage(widget.documentReference).then((item) {
      setState(() {
        initScreen = true;
      });
    });

    super.initState();

    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        Navigator.pushNamed(context, '/message',
            arguments: MessageArguments(message, true));
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
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
                // TODO add a proper drawable resource to android, for now using
                //      one that already exists in example app.
                icon: 'launch_background',
              ),
            ));
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      Navigator.pushNamed(context, '/message',
          arguments: MessageArguments(message, true));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title ?? ''}'),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(this.context);
          },
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _buildAllWidget(),
        ),
      ),
    );
  }

  List<Widget> _buildAllWidget() {
    if (widgets['message'] == null && initScreen) {
      initScreen = false;
      widgets['message'] = _buildMessageForm();
    }

    if (widgets['typing'] == null) {
      widgets['typing'] = _buildTyping();
    }

    if (widgets['composer'] == null) {
      widgets['composer'] = _buildMessageComposer();
    }

    return [widgets['message'] ?? Expanded(child: Container()), widgets['typing']!, widgets['composer']!];
  }

  _buildMessageForm() {
    return Expanded(
      child: Container(
        child: ClipRect(
          child: StreamBuilder<QuerySnapshot<ChatMessage>>(
            stream: FirebaseService.getMessageNoReceive(widget.documentReference),
            builder: (sContext, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                snapshot.data!.docs.forEach((item) {
                  if (!item.data().isTyping && !item.data().isReceived) {
                    _roomController?.messages = List<Map<String, dynamic>>.of([
                          {'message': item.data(), 'query': item}
                        ]) +
                        _roomController!.messages;
                  }
                });
              }

              return Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: ListView.separated(
                      shrinkWrap: true,
                      reverse: true,
                      padding: EdgeInsets.only(top: 15.0),
                      itemCount: _roomController?.messages.length ?? 0,
                      separatorBuilder: (BuildContext context, int index) {
                        return Container(
                          height: 10.0,
                        );
                      },
                      itemBuilder: (BuildContext context, int index) {
                        return MessageBuilder(messageMap: _roomController?.messages.elementAt(index));
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  _buildMessageComposer() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black, width: 0.2, style: BorderStyle.solid))),
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      height: 70.0,
      child: Row(
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.photo),
            iconSize: 25.0,
            color: Theme.of(context).primaryColor,
            onPressed: () async {
              print('Upload Image');

              try {
                List<XFile> pickedFile = await _picker.pickMultiImage(
                  imageQuality: 1,
                ) ?? [];

                _roomController!.uploadPicture(widget.documentReference!, pickedFile, appStore!.profile!);

              } catch (e) {
                print(e);
              }
            },
          ),
          Expanded(
            child: TextField(
              textCapitalization: TextCapitalization.sentences,
              controller: _message,
              onChanged: (value) async {
                await _roomController!.sendingMessage(widget.documentReference!, appStore!.profile!, value);
              },
              decoration: InputDecoration.collapsed(
                hintText: 'Send a message...',
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            iconSize: 25.0,
            color: Theme.of(context).primaryColor,
            onPressed: () async {
              if (_message!.text.isNotEmpty) {
                _roomController!.sendMessage(widget.documentReference!, appStore!.profile!, _message!.text);
                _message!.text = '';
              }
            },
          ),
        ],
      ),
    );
  }

  _buildTyping() {
    // message != null &&
    return Container(
      height: 30.0,
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseService.getTypingMessage(widget.documentReference),
          builder: (sContext, snapshot) {
            bool isTyping = false;
            List<Widget> widgets = [];

            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              snapshot.data!.docs.forEach((item) {
                if (item.get('isTyping') && item.get('uuid') != appStore!.profile!.uuid && !isTyping) {
                  widgets.add(_userTyping(item.get('avatarURL')) ?? '');
                }
              });
            }

            return Row(
              mainAxisSize: MainAxisSize.max,
              children: widgets,
            );
          },
        ),
      ),
    );
  }

  _userTyping(String url) {
    return Row(
      children: [
        Container(
          width: 26.0,
          height: 26.0,
          margin: const EdgeInsets.symmetric(horizontal: 2.0),
          decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(13.0))),
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(13.0)),
            child: url.isEmpty ? Icon(Icons.account_circle, ) : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.fill,
              placeholder: (context, url) => CircularProgressIndicator(),
              errorWidget: (context, url, error) => Icon(Icons.error),
            ),
          ),
        ),
        CustomPaint(
          size: Size(30.0, 26.0),
          painter: Bubble(isOwn: false),
          child: Container(
            padding: EdgeInsets.all(8),
            child: Center(
              child: Icon(FontAwesomeIcons.ellipsisH, size: 12.0, color: Colors.grey,),
            ),
          ),
        )
      ],
    );
  }
}

class MessageBuilder extends StatefulWidget {
  const MessageBuilder({Key? key, this.messageMap}) : super(key: key);

  final Map<String, dynamic>? messageMap;

  @override
  _MessageBuilderState createState() => _MessageBuilderState();
}

class _MessageBuilderState extends State<MessageBuilder> {
  bool isMe = false;
  ChatMessage? message;
  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    message = widget.messageMap?['message'] as ChatMessage;
    isMe = message!.uuid == appStore!.profile!.uuid;

    if (!message!.isReceived) {
      (widget.messageMap?['query'] as QueryDocumentSnapshot<ChatMessage>).reference.update({
        'isReceived': true,
      });
    }

    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIconNotOwn(),
        Expanded(
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              _buildMessage(context),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                child: Text(
                  DateFormat('kk:mm').format(message!.dateCreated),
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 12.0),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  _buildIconNotOwn() {
    if (isMe) {
      return Container();
    }

    if (message!.avatarURL.isEmpty) {
      return Icon(
        Icons.account_circle_sharp,
        size: 40.0,
      );
    }

    return Container(
      height: 36.0,
      width: 36.0,
      padding: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(20.0))),
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(20.0)),
        child: CachedNetworkImage(
          imageUrl: message!.avatarURL,
          fit: BoxFit.fill,
          placeholder: (context, url) => CircularProgressIndicator(),
          errorWidget: (context, url, error) => Icon(Icons.error),
        ),
      ),
    );
  }

  _buildMessage(BuildContext context) {
    ChatMessage _message = message!;
    if (_message.text.isEmpty && (_message.images ?? []).length == 0) {
      return Container();
    }

    Widget child = Container();

    if (!_message.text.isEmpty) {
      child = _buildTextMessage(_message.text);
    }

    if ((_message.images ?? []).length > 0) {
      child = _buildImagesMessage(_message.images!);
    }

    Widget msg = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: child,
    );

    return msg;
  }

  _buildTextMessage(String text) {
    return CustomPaint(
      painter: Bubble(isOwn: isMe),
      child: Container(
        padding: EdgeInsets.all(8),
        child: Text(text),
      ),
    );
  }

  _buildImagesMessage(List images) {
    List<Widget> widgets = [];
    
    images.forEach((item) {
      widgets.add(
          Container(
            height: 120.0,
            width: 80.0,
            decoration: BoxDecoration(
                border: Border.all(width: 1.0, color: Colors.white),
                borderRadius: BorderRadius.all(Radius.circular(4.0))
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(4.0)),
              child: CachedNetworkImage(
                imageUrl: item,
                fit: BoxFit.cover,
                placeholder: (context, url) => Stack(
                  children: [
                    Center(
                      child: Icon(FontAwesomeIcons.image, color: Colors.grey,),
                    ),
                    Container(color: Colors.black.withOpacity(0.4),),
                    Center(
                      child: Container(
                        width: 24.0,
                        height: 24.0,
                        child: CircularProgressIndicator(color: Colors.white, ),
                      ),
                    )
                  ],
                ),
                errorWidget: (context, url, error) => Stack(
                  children: [
                    Center(
                      child: Icon(FontAwesomeIcons.image, color: Colors.grey,),
                    ),
                    Container(color: Colors.black.withOpacity(0.4),),
                    Center(
                      child: Icon(Icons.error)),
                  ],
                ),
              ),
            ),
          )
      );
    });
    
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: widgets,
    );
  }
}

class Bubble extends CustomPainter {
  Bubble({@required this.isOwn = true});

  final bool isOwn;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = (isOwn ? Color.fromRGBO(209, 215, 219, 1.0) : Colors.white);

    Path? paintBubbleTail() {
      Path? path;
      if (!isOwn) {
        path = Path()..lineTo(-10, 0)..lineTo(0, 5);
      }
      if (isOwn) {
        path = Path()..lineTo(size.width + 5, 0)..lineTo(size.width, 5);
      }
      return path;
    }

    if (isOwn) {
      final RRect bubbleBody = RRect.fromRectAndCorners(Rect.fromLTWH(0, 0, size.width, size.height), topLeft: Radius.circular(6.0), bottomRight: Radius.circular(6.0), bottomLeft: Radius.circular(6.0));

      canvas.drawRRect(bubbleBody, paint);
    } else {
      final RRect bubbleBody = RRect.fromRectAndCorners(Rect.fromLTWH(0, 0, size.width, size.height), topRight: Radius.circular(6.0), bottomRight: Radius.circular(6.0), bottomLeft: Radius.circular(6.0));

      canvas.drawRRect(bubbleBody, paint);
    }

    final Path? bubbleTail = paintBubbleTail();

    canvas.drawPath(bubbleTail!, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
