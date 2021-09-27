import 'dart:async';
import 'dart:isolate';

import 'package:chat_app_multiple_platforms/domain/message.dart';
import 'package:chat_app_multiple_platforms/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

typedef MessCallback = Function(Map<String, dynamic> args);

class MessagesHandler {
  List<ChatMessageState> messages = [];
  Map<String, dynamic> options = {};
  StreamController<List<ChatMessageState>> lStream = StreamController.broadcast();
  List<Map<String, dynamic>> imgList = [];

  void init(List<QueryDocumentSnapshot<ChatMessage>> lData, {MessCallback? callback}) {
    var _increasement = 1;
    
    lData.forEach((item) {
      ChatMessage _message = item.data();
      
      if (!_message.isTyping) {
        messages.add(ChatMessageState(item.id, _message, item.reference, item, files: List.from(_message.images!)));
        options.putIfAbsent(item.id, () => {'index': messages.length - 1});
      }

      if (item.data().uuid == app.profile!.uuid) {
        var increase = item.id.length > 1 ? int.parse(item.id.split('-')[1]) : _increasement;
        if (increase > _increasement) _increasement = increase;
        else _increasement++;
      }
      
      if (_message.type == 'IMAGE') {
        _message.images!.forEach((item) {
          imgList.add({
            'url': item['url'],
            'name': item['name'],
            'date': DateUtils.dateOnly(_message.dateCreated)
          });
        });
      }
    });

    callback!({'indexIncrease': _increasement});
  }
  
  void add(String id, ChatMessageState value) {
    var _messages = List<ChatMessageState>.from(messages);
    
    if (_messages.length == 0) {
      messages.add(value);
      options.putIfAbsent(id, () => {'index': 0});
    } else {
      if (!options.containsKey(value.id)) {
        for(int i = _messages.length - 1; i>= 0; i--) {
          if (_messages.elementAt(i).chatMessage.dateCreated.isBefore(value.chatMessage.dateCreated)) {
            messages.insert(i+1, value);
            options.putIfAbsent(id, () => {'index': i});

            break;
          } else {
            options.update(_messages.elementAt(i).id, (value) => {'index': i + 1});
          }
        }
      }
      
    }
  }

  void update(String id, ChatMessageState value) {
    if (options.containsKey(id)) {
      var index = options[id]['index'];

      messages.replaceRange(index, index+1, [value]);
    }
  }
  
  void reload() {
    lStream.add(List<ChatMessageState>.from(messages.reversed));
  }
}



