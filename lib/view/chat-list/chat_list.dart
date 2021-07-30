import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app_multiple_platforms/controller/chat_list.dart';
import 'package:chat_app_multiple_platforms/domain/profile.dart';
import 'package:chat_app_multiple_platforms/main.dart';
import 'package:chat_app_multiple_platforms/service/firebase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatList extends StatefulWidget {
  const ChatList({Key? key}) : super(key: key);

  @override
  _ChatListState createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  ChatListController? _chatListController;

  @override
  void initState() {
    _chatListController = ChatListController();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(onPressed: openAddDialog, icon: Icon(Icons.group_add)),
        title: Text('Chat List'),
        actions: [
          PopupMenuButton(
            icon: Icon(Icons.settings),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Text('Token'),
                value: 3,
              ),
              PopupMenuItem(
                child: Text('Information'),
                value: 1,
              ),
              PopupMenuItem(
                child: Text('Sign out'),
                value: 2,
              ),
            ],
            onSelected: (selected) {
              switch (selected) {
                case 1:
                  _chatListController?.navigateToInfo(this.context);
                  break;
                case 3:
                  _openTokenDialog();
                  break;
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService.getRoomChatContainsUser(appStore!.profile!),
        builder: (sContext, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: snapshot.data?.docs.length ?? 0,
            itemBuilder: (BuildContext context, int index) {
              DocumentSnapshot doc = snapshot.data?.docs.elementAt(index) as DocumentSnapshot;

              return InkWell(
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10), bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  child: FutureBuilder<List<Profile>>(
                    initialData: List<Profile>.empty(),
                    future: _chatListController!.getProfileFromRef(doc.get('uuids')),
                    builder: (fContext, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      List<String> names = [];

                      snapshot.data!.forEach((_profile) {
                        names.add(_profile.displayName);
                      });

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAvatarWidget(snapshot.data!),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    names.join(', '),
                                    style: TextStyle(
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                onTap: () {
                  _chatListController!.navigateToChatRoom(context, doc);
                },
              );
            },
            separatorBuilder: (BuildContext context, int index) => const Divider(),
          );
        },
      ),
    );
  }

  _buildAvatarWidget(List<Profile> profiles) {
    if (profiles.length == 1) {
      return Container(
        width: 80.0,
        height: 80.0,
        child: Center(
          child: _buildAvatarImage(profiles.elementAt(0).avatarURL),
        ),
      );
    } else if (profiles.length == 2) {
      return Container(
        width: 80.0,
        height: 80.0,
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: _buildAvatarImage(profiles.elementAt(0).avatarURL),
            ),
            Align(alignment: Alignment.bottomRight, child: _buildAvatarImage(profiles.elementAt(1).avatarURL)),
          ],
        ),
      );
    } else if (profiles.length == 3) {
      return Container(
        width: 80.0,
        height: 80.0,
        child: Column(
          children: [
            Row(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: _buildAvatarImage(profiles.elementAt(0).avatarURL),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: _buildAvatarImage(profiles.elementAt(1).avatarURL),
                )
              ],
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: _buildAvatarImage(profiles.elementAt(2).avatarURL),
            ),
          ],
        ),
      );
    } else if (profiles.length == 4) {
      return Container(
        width: 80.0,
        height: 80.0,
        child: Column(
          children: [
            Row(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: _buildAvatarImage(profiles.elementAt(0).avatarURL),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: _buildAvatarImage(profiles.elementAt(1).avatarURL),
                )
              ],
            ),
            Row(
              children: [
                Align(
                  alignment: Alignment.bottomLeft,
                  child: _buildAvatarImage(profiles.elementAt(2).avatarURL),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: _buildAvatarImage(profiles.elementAt(3).avatarURL),
                )
              ],
            ),
          ],
        ),
      );
    } else {
      return Container(
        width: 80.0,
        height: 80.0,
        child: Column(
          children: [
            Row(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: _buildAvatarImage(profiles.elementAt(0).avatarURL),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: _buildAvatarImage(profiles.elementAt(1).avatarURL),
                )
              ],
            ),
            Row(
              children: [
                Align(
                  alignment: Alignment.bottomLeft,
                  child: _buildAvatarImage(profiles.elementAt(3).avatarURL),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    height: 40.0,
                    width: 40.0,
                    decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(20.0)), color: Colors.green),
                    child: Center(
                      child: Text(
                        '${profiles.length}',
                        style: TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      );
    }
  }

  _buildAvatarImage(url) {
    return Container(
      height: 36.0,
      width: 36.0,
      padding: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(20.0))),
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(20.0)),
        child: '$url'.isNotEmpty ? CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.fill,
          placeholder: (context, url) => CircularProgressIndicator(),
          errorWidget: (context, url, error) => Icon(Icons.account_circle_sharp,
            size: 32,
            color: Color.fromRGBO(209, 215, 219, 1.0),),
        ) : Icon(Icons.account_circle_sharp,
          size: 32,
          color: Color.fromRGBO(209, 215, 219, 1.0),),
      ),
    );
  }

  openAddDialog() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext dContext) {
        double width = MediaQuery.of(dContext).size.width * 0.7;
        double height = MediaQuery.of(dContext).size.height * 0.6;
        return Center(
          child: Material(
            borderRadius: BorderRadius.all(Radius.circular(6.0)),
            child: Container(
              height: height,
              width: width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(6.0)),
                color: Colors.white,
              ),
              child: AddFriendContent(
                callback: (args) {
                  if (args['type'] == 'Add') {
                    Map<String, Profile> profile = args['profile'] as Map<String, Profile>;
                    _chatListController!.createChatRoom(context, appStore!.profile, List.from(profile.values));
                  }

                  Navigator.of(dContext).pop();
                },
              ),
            ),
          ),
        );
      },
    );
  }

  _openTokenDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dContext) {
        double width = MediaQuery.of(dContext).size.width * 0.7;
        return Center(
          child: Material(
            borderRadius: BorderRadius.all(Radius.circular(6.0)),
            child: Container(
              width: width,
              padding: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(6.0)),
                color: Colors.white,
              ),
              child: SelectableText(appStore!.profile!.fcmToken!, style: const TextStyle(fontSize: 12)),
            ),
          ),
        );
      },
    );
  }
}

typedef AddFriendContentCallback = Function(Map<String, dynamic> args);

class AddFriendContent extends StatefulWidget {
  AddFriendContent({Key? key, this.callback}) : super(key: key);

  AddFriendContentCallback? callback;

  @override
  _AddFriendContentState createState() => _AddFriendContentState();
}

class _AddFriendContentState extends State<AddFriendContent> with SingleTickerProviderStateMixin {
  List<Profile> allProfiles = [];

  Map<String, Profile> profileSelected = {};

  ValueNotifier<int> addedNotifier = ValueNotifier(0);
  ValueNotifier<String> _keySearchNotifier = ValueNotifier('');

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Please enter email or name',
            ),
          ),
        ),
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Builder(
              builder: (context) {
                final TabController tabController = DefaultTabController.of(context)!;
                tabController.addListener(() {
                  if (!tabController.indexIsChanging) {
                    setState(() {});
                  }
                });

                return Column(
                  children: [
                    TabBar(
                      tabs: [
                        Tab(
                          child: Text(
                            'All',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                        Tab(
                          child: ValueListenableBuilder(
                            valueListenable: addedNotifier,
                            builder: (context, value, widget) {
                              print(value);

                              return Row(
                                children: [
                                  Text('Added', style: TextStyle(color: Colors.black)),
                                  Visibility(
                                    visible: profileSelected.keys.length > 0,
                                    child: Container(
                                      width: 20.0,
                                      height: 20.0,
                                      decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(10.0)), color: Colors.redAccent),
                                      child: Center(
                                        child: Text('${profileSelected.keys.length}'),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: tabController,
                        children: [
                          StreamBuilder<QuerySnapshot<Profile>>(
                            stream: FirebaseService.getUsersNotEqual(appStore!.profile!.uuid),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              if (snapshot.hasData) {
                                allProfiles.clear();

                                snapshot.data!.docs.forEach((element) {
                                  allProfiles.add(element.data());
                                });
                              }

                              return ValueListenableBuilder<String>(
                                valueListenable: _keySearchNotifier,
                                builder: (context, value, child) {
                                  List<Profile> profileFiltered = [];

                                  if (value.isEmpty) {
                                    profileFiltered = allProfiles;
                                  } else {
                                    profileFiltered = List.from(allProfiles.where((_profile) => _profile.email.toLowerCase().startsWith(value) || _profile.displayName.toLowerCase().startsWith(value)));
                                  }

                                  return ListView.separated(
                                    itemCount: profileFiltered.length,
                                    separatorBuilder: (context, index) {
                                      return Container(
                                        height: 8.0,
                                      );
                                    },
                                    itemBuilder: (context, index) {
                                      return FriendRow(
                                        isChecked: profileSelected[profileFiltered.elementAt(index).uuid] == null ? false : true,
                                        profile: profileFiltered.elementAt(index),
                                        friendRowCallback: (Map<String, dynamic> args) {
                                          Profile profile = args['profile'] as Profile;

                                          if (args['checked'] as bool == true) {
                                            profileSelected[profile.uuid] = profile;
                                          } else {
                                            profileSelected.remove(profile.uuid);
                                          }

                                          addedNotifier.value = profileSelected.keys.length;
                                        },
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                          ListView.separated(
                            itemCount: profileSelected.keys.length,
                            separatorBuilder: (context, index) {
                              return Container(
                                height: 8.0,
                              );
                            },
                            itemBuilder: (context, index) {
                              String uuid = profileSelected.keys.elementAt(index);
                              Profile? profile = profileSelected[uuid];

                              return FriendRow(
                                isChecked: true,
                                profile: profile,
                                friendRowCallback: (Map<String, dynamic> args) {
                                  Profile profile = args['profile'] as Profile;

                                  if (args['checked'] as bool == true) {
                                    profileSelected[profile.uuid] = profile;
                                  } else {
                                    profileSelected.remove(profile.uuid);
                                  }

                                  setState(() {});
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey, width: 0.5))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  onPressed: () {
                    widget.callback!({'type': 'Cancel'});
                  },
                  child: Text('Cancel')),
              TextButton(
                  onPressed: () {
                    widget.callback!({'type': 'Add', 'profile': profileSelected});
                  },
                  child: Text('Add')),
            ],
          ),
        )
      ],
    );
  }
}

typedef FriendRowCallback = Function(Map<String, dynamic> args);

class FriendRow extends StatefulWidget {
  FriendRow({Key? key, @required this.profile, this.isChecked = false, this.friendRowCallback}) : super(key: key);

  Profile? profile;
  bool isChecked;
  FriendRowCallback? friendRowCallback;

  @override
  _FriendRowState createState() => _FriendRowState();
}

class _FriendRowState extends State<FriendRow> {
  bool initFirst = true;
  bool checked = false;

  ValueNotifier<bool>? _valueNotifier;

  @override
  void initState() {
    checked = widget.isChecked;
    _valueNotifier = ValueNotifier(checked);
    super.initState();
  }

  @override
  void didUpdateWidget(covariant FriendRow oldWidget) {
    checked = widget.isChecked;
    _valueNotifier = ValueNotifier(checked);

    super.didUpdateWidget(widget);
  }

  @override
  Widget build(BuildContext context) {
    Profile _profile = widget.profile!;

    return InkWell(
      child: Row(
        children: [
          ValueListenableBuilder(
            valueListenable: _valueNotifier!,
            builder: (context, bool val, child) {
              return Checkbox(
                value: val,
                onChanged: (value) {
                  checked = !checked;
                  _valueNotifier!.value = checked;

                  widget.friendRowCallback!({'checked': checked, 'profile': _profile});
                },
              );
            },
          ),
          _profile.avatarURL.isNotEmpty
              ? Container(
                  height: 44.0,
                  width: 44.0,
                  decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(22.0))),
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(22.0)),
                    child: CachedNetworkImage(
                      imageUrl: _profile.avatarURL,
                      fit: BoxFit.fill,
                      placeholder: (context, url) => CircularProgressIndicator(),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    ),
                  ),
                )
              : Icon(
                  Icons.account_circle,
                  size: 44.0,
                ),
          Container(
            width: 8.0,
          ),
          Text(_profile.displayName),
        ],
      ),
      onTap: () {
        checked = !checked;
        _valueNotifier!.value = checked;

        widget.friendRowCallback!({'checked': checked, 'profile': _profile});
      },
    );
  }
}
