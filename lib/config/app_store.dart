import 'package:chat_app_multiple_platforms/domain/profile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class App {
  static const AVATAR_RESOLUTION_WIDTH = 160.0;
  static const AVATAR_RESOLUTION_HEIGHT = 120.0;
  
  Profile? profile;
  GlobalKey<NavigatorState> navigatorKey = GlobalKey();
  MaterialPageRoute? route;
  Map<String, dynamic> currRoom = {
    'infoList': null,
    'roomRef': null
  };
}
