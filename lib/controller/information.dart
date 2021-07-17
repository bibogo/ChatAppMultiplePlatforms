import 'dart:io';

import 'package:chat_app_multiple_platforms/config/app_store.dart';
import 'package:chat_app_multiple_platforms/main.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as image;

class InformationController {
  InformationController();
  
  Future<void> changeUserProfile(PickedFile pickedFile) async {
    try {
      Reference ref = await FirebaseStorage.instance.ref('users').child(appStore!.profile!.uuid).child('avatar.png');
      await ref.putData(await pickedFile.readAsBytes());

      appStore!.profile!.avatarURL = await ref.getDownloadURL();
      
      await appStore!.profile!.userDoc!.reference.update(appStore!.profile!.toJSON());
          
    } catch (e) {
     print(e);
    }
  }
  
  abc(PickedFile pickedFile) async {
    final ByteData assetImageByteData = await rootBundle.load(pickedFile.path);
    image.Image baseSizeImage = image.decodeImage(assetImageByteData.buffer.asUint8List())!;
    image.Image resizeImage1 = image.copyResize(baseSizeImage, height: 400, width: 400);
    image.Image resizeImage2 = image.copyResize(baseSizeImage, height: 165, width: 165);


    Reference ref1 = await FirebaseStorage.instance.ref('users').child(appStore!.profile!.uuid).child('avatar400x400.png');
    Reference ref2 = await FirebaseStorage.instance.ref('users').child(appStore!.profile!.uuid).child('avatar165x165.png');

    await ref1.putData(resizeImage1.getBytes());
    await ref2.putData(resizeImage2.getBytes());

    appStore!.profile!.avatarURL = await ref1.getDownloadURL();

    await appStore!.profile!.userDoc!.reference.update(appStore!.profile!.toJSON());
  }
}