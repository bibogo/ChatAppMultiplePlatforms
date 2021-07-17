import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chat_app_multiple_platforms/config/app_store.dart';
import 'package:chat_app_multiple_platforms/controller/information.dart';
import 'package:chat_app_multiple_platforms/main.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class Information extends StatefulWidget {
  const Information({Key? key}) : super(key: key);

  @override
  _InformationState createState() => _InformationState();
}

class _InformationState extends State<Information> {
  double height = 0.0;
  double iconSize = 0.0;
  final ImagePicker _picker = ImagePicker();
  PickedFile? pickedFile;
  
  TextEditingController _email = TextEditingController(text: appStore!.profile!.email);
  TextEditingController _password = TextEditingController(text: appStore!.profile!.password);
  TextEditingController _displayName = TextEditingController(text: appStore!.profile!.displayName);
  TextEditingController _description = TextEditingController(text: appStore!.profile!.description);

  StreamController<bool> _dirtySteam = StreamController();
  StreamController<PickedFile> _imageStream = StreamController();

  InformationController _informationController = InformationController();
  
  @override
  void dispose() {
    _dirtySteam.close();
    _imageStream.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(this.context);
          },
          icon: Icon(Icons.arrow_back),
        ),
        title: Text('Information'),
        actions: [
          StreamBuilder<bool>(
            initialData: false,
            stream: _dirtySteam.stream,
            builder: (sContext, snapshot) {
              if (!snapshot.data!) {
                return Container();
              }
              
              return TextButton(
                child: Text(
                  'Save',
                  style: TextStyle(color: Colors.greenAccent, fontSize: 16.0),
                ),
                onPressed: () {
                  _informationController.changeUserProfile(pickedFile!);
                  _dirtySteam.add(false);
                },
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (lContext, constrains) {
          if (height == 0) {
            height = constrains.biggest.height * 0.23;
          }

          if (iconSize == 0) {
            iconSize = (constrains.biggest.height * 0.23) - 20;
          }

          return Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                height: height,
                child: Stack(
                  children: [
                    _buildAvatarImage(),
                    Align(
                      child: IconButton(
                        onPressed: () async {
                          try {
                            pickedFile = await _picker.getImage(
                              source: ImageSource.gallery,
                              maxWidth: AppStore.AVATAR_RESOLUTION_WIDTH,
                              maxHeight: AppStore.AVATAR_RESOLUTION_HEIGHT,
                              imageQuality: 1,
                            );
                            
                            _dirtySteam.add(true);
                            _imageStream.add(pickedFile!);
                          } catch (e) {
                            print(e);
                          }
                        },
                        icon: Icon(
                          Icons.edit,
                          size: 20.0,
                          color: Colors.lightBlue,
                        ),
                      ),
                      alignment: Alignment.topRight,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
                        child: TextField(
                          controller: _email,
                          enabled: false,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.email),
                            hintText: 'Email',
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
                        child: TextField(
                          controller: _password,
                          enabled: false,
                          obscureText: true,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.password),
                            hintText: 'Password',
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
                        child: TextField(
                          controller: _displayName,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.supervisor_account_outlined),
                            hintText: 'Display Name',
                          ),
                          onSubmitted: (value) {
                            _dirtySteam.add(true);
                            appStore!.profile!.displayName = value;
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
                        child: TextField(
                          controller: _description,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.description),
                            hintText: 'Description',
                          ),
                          onSubmitted: (value) {
                            _dirtySteam.add(true);
                            appStore!.profile!.description = value;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  _buildAvatarImage() {
    return StreamBuilder<PickedFile>(
      stream: _imageStream.stream,
      builder: (sContext, snapshot) {
        
        if (snapshot.data == null) {
          return Align(
            child: Icon(
              Icons.account_circle_sharp,
              size: iconSize,
              color: Color.fromRGBO(209, 215, 219, 1.0),
            ),
            alignment: Alignment.center,
          );
        } else {
          return Container(
            width: MediaQuery.of(this.context).size.width,
            height: height,
            child: Image.file(
              File(snapshot.data!.path),
              fit: BoxFit.fill,
            ),
          );
        }
        
      },
    );
    
  }
}
