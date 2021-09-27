import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app_multiple_platforms/controller/room.dart';
import 'package:chat_app_multiple_platforms/domain/message.dart';
import 'package:chat_app_multiple_platforms/domain/profile.dart';
import 'package:chat_app_multiple_platforms/main.dart';
import 'package:chat_app_multiple_platforms/service/firebase.dart';
import 'package:chat_app_multiple_platforms/view/images/load_images_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class Room extends StatefulWidget {
  const Room({Key? key}) : super(key: key);

  @override
  RoomState createState() => RoomState();
}

class RoomState extends State<Room> {
  Map<String, Widget?> widgets = {'message': null, 'typing': null, 'composer': null};
  Map<String, dynamic> messWidgets = {};

  RoomController? _roomController;
  final TextEditingController _message = TextEditingController(text: '');

  final ImagePicker _picker = ImagePicker();
  bool initFrame = false;

  @override
  void initState() {
    _roomController = RoomController(this.context, FirebaseMessaging.onMessage, FirebaseMessaging.onMessageOpenedApp);
    _roomController?.initDataMessageForm(app.currRoom['roomRef'] as DocumentReference);

    super.initState();
  }

  @override
  void dispose() {
    _roomController!.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = (app.currRoom['infoList'] as InfoList).names().join(', ');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(this.context);
          },
          icon: Icon(Icons.arrow_back),
        ),
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: (app.currRoom['roomRef'] as DocumentReference).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container();
              }
              List usersInfo = snapshot.data?.get('usersInfo');

              final infoList = InfoList.init(usersInfo);
              final info = infoList.find(uuid: app.profile!.uuid);
              
              return IconButton(
                onPressed: () {
                  _roomController!.switchNotification(!info!.notification);
                },
                icon: info!.notification 
                    ? FaIcon(FontAwesomeIcons.bellSlash, size: 18.0,) 
                    : FaIcon(FontAwesomeIcons.bell, size: 18.0,) ,
              );
            },
          ),
        ],
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
    if (widgets['message'] == null) {
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
          child: StreamBuilder<List<ChatMessageState>>(
            stream: _roomController!.handler.lStream.stream,
            builder: (sContext, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(),
                );
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
                      itemCount: snapshot.data!.length,
                      separatorBuilder: (BuildContext context, int index) {
                        return Container(
                          height: 10.0,
                        );
                      },
                      itemBuilder: (BuildContext context, int index) {
                        ChatMessageState _state = snapshot.data!.elementAt(index);

                        List a = [];

                        if (!messWidgets.containsKey(_state.id)) {
                          if (_state.chatMessage.type == 'IMAGE') {
                            messWidgets.putIfAbsent(
                                _state.id,
                                () => MessageImageBuilder(
                                      _state,
                                      _roomController!,
                                      lastItem: index == 0,
                                    ));
                          } else {
                            messWidgets.putIfAbsent(
                                _state.id,
                                () => MessageBuilder(
                                      _state,
                                      _roomController!,
                                      lastItem: index == 0,
                                    ));
                          }
                        }

                        return messWidgets['${_state.id}'] as Widget;
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
              try {
                List<XFile> pickedFile = await _picker.pickMultiImage(
                      imageQuality: 1,
                    ) ??
                    [];

                _roomController!.uploadPicture(app.currRoom['roomRef'] as DocumentReference, pickedFile, app.profile!);
              } catch (e) {
                print(e);
              }
            },
          ),
          Expanded(
            child: TextField(
              textCapitalization: TextCapitalization.sentences,
              controller: _message,
              onChanged: (value) {
                _roomController!.typingMessing(app.currRoom['roomRef'] as DocumentReference, app.profile!, value);
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
              if (_message.text.isNotEmpty) {
                _roomController!.sendMessage(app.currRoom['roomRef'] as DocumentReference, app.profile!, _message.text);
                _message.text = '';
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
          stream: _roomController!.timerStream!.stream,
          builder: (sContext, snapshot) {
            bool isTyping = false;
            List<Widget> widgets = [];

            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              snapshot.data!.docs.toSet().forEach((item) {
                if (item.get('isTyping') && item.get('uuid') != app.profile!.uuid && !isTyping) {
                  widgets.add(_userTyping(item.get('avatarURL')) ?? '');
                }
              });
            }
            return Row(
              mainAxisSize: MainAxisSize.max,
              children: widgets.toSet().toList(),
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
            child: url.isEmpty
                ? Icon(
                    Icons.account_circle,
                  )
                : CachedNetworkImage(
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
              child: Icon(
                FontAwesomeIcons.ellipsisH,
                size: 12.0,
                color: Colors.grey,
              ),
            ),
          ),
        )
      ],
    );
  }
}

class MessageBuilder extends StatefulWidget {
  const MessageBuilder(this.messageState, this.roomController, {Key? key, this.lastItem = false}) : super(key: key);

  final RoomController roomController;
  final ChatMessageState messageState;
  final bool lastItem;

  @override
  MessageBuilderState createState() => MessageBuilderState();
}

class MessageBuilderState extends State<MessageBuilder> {
  bool init = false;

  @override
  void initState() {
    _syncFirebase();

    super.initState();
  }

  @override
  void didUpdateWidget(covariant MessageBuilder oldWidget) {
    _syncFirebase();

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    ChatMessage _message = widget.messageState.chatMessage;
    bool _isMe = app.profile!.uuid == _message.uuid;

    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: _isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIconNotOwn(_isMe, _message),
        Expanded(
          child: Column(
            crossAxisAlignment: _isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              _buildMessage(context, _message, _isMe),
            ],
          ),
        )
      ],
    );
  }

  _buildIconNotOwn(bool isMe, ChatMessage _message) {
    if (isMe) {
      return Container();
    }

    if (_message.avatarURL.isEmpty) {
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
          imageUrl: _message.avatarURL,
          fit: BoxFit.fill,
          placeholder: (context, url) => CircularProgressIndicator(),
          errorWidget: (context, url, error) => Icon(Icons.error),
        ),
      ),
    );
  }

  _buildMessage(BuildContext context, ChatMessage _message, bool _isMe) {
    if (_message.text.isEmpty) {
      return Container();
    }

    Widget msg = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: _buildTextMessage(_message, _isMe),
    );

    return msg;
  }

  _buildTextMessage(ChatMessage _message, bool _isMe) {
    return CustomPaint(
      painter: Bubble(isOwn: _isMe),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            child: Text(_message.text),
          ),
          Container(
            padding: EdgeInsets.all(8),
            child: Flex(
              direction: Axis.horizontal,
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    DateFormat('kk:mm').format(_message.dateCreated),
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 12.0),
                  ),
                ),
                Container(
                  width: 50.0,
                ),
                Align(
                    alignment: Alignment.centerRight,
                    child: (_isMe && widget.lastItem
                        ? Text(
                            widget.messageState.id.isEmpty ? 'Sending...' : 'Sent',
                            textAlign: TextAlign.right,
                            style: TextStyle(fontSize: 12.0),
                          )
                        : null)),
              ],
            ),
          )
        ],
      ),
    );
  }

  _syncFirebase() {
    ChatMessage _message = widget.messageState.chatMessage;

    if (_message.uuid != app.profile?.uuid && !_message.received.contains({'${app.profile?.uuid}': false})) {
      if (!_message.received.map((e) => e.keys).contains(app.profile?.uuid)) {
        _message.received.add({'${app.profile?.uuid}': true});
      } else {
        _message.received.forEach((e) {
          if (!e['${app.profile?.uuid}']) {
            e['${app.profile?.uuid}'] = true;
          }
        });
      }

      widget.messageState.docRef.update(_message.toJSON());
    }
    if (_message.isTyping) {
      _message.isTyping = false;
      widget.messageState.docRef.set(_message.toJSON());
    }
  }
}

class MessageImageBuilder extends StatefulWidget {
  const MessageImageBuilder(this.messageState, this.roomController, {Key? key, this.lastItem = false}) : super(key: key);

  final RoomController roomController;
  final ChatMessageState messageState;
  final bool lastItem;

  @override
  _MessageImageBuilderState createState() => _MessageImageBuilderState();
}

class _MessageImageBuilderState extends State<MessageImageBuilder> {
  Map<String, dynamic> fileBuilder = {};

  @override
  void initState() {
    if (widget.messageState.files!.where((e) => e['file'] != null).isNotEmpty) {
      widget.roomController.uploadPhoto(widget.messageState).then((value) => widget.roomController.updatePhotoData(widget.messageState, value));
    }

    super.initState();
  }

  @override
  void didUpdateWidget(covariant MessageImageBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    ChatMessage _message = widget.messageState.chatMessage;
    bool _isMe = app.profile!.uuid == _message.uuid;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: _isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIconNotOwn(_isMe, _message),
        Expanded(
          child: _buildMessage(context, _message, _isMe),
        )
      ],
    );
  }

  _buildIconNotOwn(bool isMe, ChatMessage _message) {
    if (isMe) {
      return Container();
    }

    if (_message.avatarURL.isEmpty) {
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
          imageUrl: _message.avatarURL,
          fit: BoxFit.fill,
          placeholder: (context, url) => CircularProgressIndicator(),
          errorWidget: (context, url, error) => Icon(Icons.error),
        ),
      ),
    );
  }

  _buildMessage(BuildContext context, ChatMessage _message, bool _isMe) {
    if ((_message.images ?? []).length == 0) {
      return Container();
    }

    final maxWidth = MediaQuery.of(context).size.width * 0.75;

    Widget msg = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: _buildImagesMessage(_message, _isMe),
    );

    return msg;
  }

  _buildImagesMessage(ChatMessage _message, bool _isMe) {
    List<Widget> widgets = [];

    widget.messageState.files?.forEach((item) {
      Widget _child = item['url'] != '' ? _buildImageLoaded(item['url']) : _buildImageLoading(item['file']);
      widgets.add(InkWell(
        child: Container(
          height: 140.0,
          width: 100.0,
          decoration: BoxDecoration(border: Border.all(width: 1.0, color: Colors.white), borderRadius: BorderRadius.all(Radius.circular(4.0)), color: Colors.black),
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(4.0)),
            child: _child,
          ),
        ),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => LoadImageScreen(controller: widget.roomController, img: item, imgDate: _message.dateCreated,)));
        },
      ));
    });

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: _isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: _isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: widgets,
        ),
        Container(
            width: widgets.length > 3 ? 240.0 : (widgets.length * 100),
            padding: EdgeInsets.only(top: 8.0, right: 8.0, bottom: 8.0),
            child: Flex(
              direction: Axis.horizontal,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    DateFormat('kk:mm').format(_message.dateCreated),
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 12.0),
                  ),
                ),
                Expanded(child: Container()),
                Align(
                    alignment: Alignment.centerRight,
                    child: (_isMe && widget.lastItem
                        ? Text(
                            widget.messageState.id.isEmpty ? 'Sending...' : 'Sent',
                            textAlign: TextAlign.right,
                            style: TextStyle(fontSize: 12.0),
                          )
                        : null)),
              ],
            ))
      ],
    );
  }

  _buildImageLoading(XFile xFile) {
    return FutureBuilder<Uint8List>(
      future: xFile.readAsBytes(),
      builder: (fContext, snapshot) {
        if (snapshot.data == null) {
          return Stack(
            children: [
              Center(
                child: Icon(
                  FontAwesomeIcons.image,
                  color: Colors.grey,
                ),
              ),
              Container(
                color: Colors.black.withOpacity(0.4),
              ),
              Center(
                child: Container(
                  width: 24.0,
                  height: 24.0,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              )
            ],
          );
        }

        return Image.memory(snapshot.data!);
      },
    );
  }

  _buildImageLoaded(imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.fill,
      placeholder: (context, url) => Stack(
        children: [
          Center(
            child: Icon(
              FontAwesomeIcons.image,
              color: Colors.grey,
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.4),
          ),
          Center(
            child: Container(
              width: 24.0,
              height: 24.0,
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          )
        ],
      ),
      errorWidget: (context, url, error) => Stack(
        children: [
          Center(
            child: Icon(
              FontAwesomeIcons.image,
              color: Colors.grey,
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.4),
          ),
          Center(child: Icon(Icons.error)),
        ],
      ),
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
        path = Path()
          ..lineTo(-10, 0)
          ..lineTo(0, 5);
      }
      if (isOwn) {
        path = Path()
          ..lineTo(size.width + 5, 0)
          ..lineTo(size.width, 5);
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
