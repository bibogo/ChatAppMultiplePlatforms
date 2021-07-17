import 'package:chat_app_multiple_platforms/controller/room.dart';
import 'package:chat_app_multiple_platforms/domain/message.dart';
import 'package:chat_app_multiple_platforms/main.dart';
import 'package:chat_app_multiple_platforms/service/firebase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Room extends StatefulWidget {
  const Room({Key? key, this.documentReference, this.name}) : super(key: key);

  final DocumentReference? documentReference;
  final String? name;

  @override
  _RoomState createState() => _RoomState();
}

class _RoomState extends State<Room> {
  RoomController? _roomController;
  TextEditingController? _message;
  Widget? messageForm;
  Map<String, Widget?> widgets = {'message': null, 'typing': null, 'composer': null};
  bool initScreen = false;

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.name ?? ''}'),
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
          child: StreamBuilder<QuerySnapshot<Message>>(
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
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              textCapitalization: TextCapitalization.sentences,
              controller: _message,
              onChanged: (value) async {
                await _roomController!.sendingMessage(widget.documentReference, appStore!.profile!.uuid, value);
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
                _roomController!.sendMessage(widget.documentReference, appStore!.profile!.uuid, _message!.text);
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
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseService.getTypingMessage(widget.documentReference),
          builder: (sContext, snapshot) {
            bool isTyping = false;

            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              snapshot.data!.docs.every((item) {
                if (item.get('isTyping') && item.get('uuid') != appStore!.profile!.uuid && !isTyping) {
                  isTyping = true;
                  return false;
                }
                return true;
              });
            }

            return Container(
              child: Text(isTyping ? 'Typing...' : ''),
            );
          },
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
  Message? message;
  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    message = widget.messageMap?['message'] as Message;
    isMe = message!.uuId == appStore!.profile!.uuid;

    if (!message!.isReceived) {
      (widget.messageMap?['query'] as QueryDocumentSnapshot<Message>).reference.update({
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
              _buildMessage(),
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

    return Icon(
      Icons.account_circle_sharp,
      size: 36.0,
    );
  }

  _buildMessage() {
    final Widget msg = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: CustomPaint(
        painter: Bubble(isOwn: isMe),
        child: Container(
          padding: EdgeInsets.all(8),
          child: Text(message!.text),
        ),
      ),
    );

    return msg;
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
