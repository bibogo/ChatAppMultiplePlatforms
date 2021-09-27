import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app_multiple_platforms/controller/room.dart';
import 'package:chat_app_multiple_platforms/service/message_handler.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class LoadImageScreen extends StatefulWidget {
  final RoomController? controller;
  final DateTime? imgDate;
  final Map<String, dynamic>? img;

  LoadImageScreen({Key? key, this.controller, this.imgDate, this.img}) : super(key: key);

  @override
  _LoadImageScreenState createState() => _LoadImageScreenState();
}

class _LoadImageScreenState extends State<LoadImageScreen> {
  var pageController;
  ValueNotifier<String>? _titleNotifier;

  @override
  void initState() {
    widget.controller!.handler.imgList.sort((a, b) => -(a['date'] as DateTime).compareTo(b['date'] as DateTime));

    var index = widget.controller!.handler.imgList.indexWhere((item) => item['name'] == widget.img!['name']);
    var date = widget.controller!.handler.imgList.elementAt(index)['date'] as DateTime;
    
    _titleNotifier = ValueNotifier(DateFormat('MM/dd/yyyy').format(date));

    pageController = PageController(initialPage: index > 0 ? index : 0);

    super.initState();
  }

  List<Widget> _buildPageView() {
    List<Widget> widgets = [];
    if (widget.controller == null) return widgets;

    widget.controller!.handler.imgList.forEach((item) {
      widgets.add(Container(
        child: CachedNetworkImage(
          imageUrl: item['url'],
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
        ),
      ));
    });

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: InkWell(
          child: Icon(Icons.arrow_back),
          onTap: () {
            Navigator.of(context).pop();
          },
        ),
        title: ValueListenableBuilder(
          valueListenable: _titleNotifier!,
          builder: (context, value, child) {
            return Text('${value}');
          },
        ),
        elevation: 0.5,
        backgroundColor: Colors.transparent,
      ),
      body: PageView(
        controller: pageController,
        onPageChanged: _pageChanged,
        children: _buildPageView(),
      ),
    );
  }

  _pageChanged(int index) {
    var date = widget.controller!.handler.imgList.elementAt(index)['date'] as DateTime;
    print(date);
    _titleNotifier!.value = DateFormat('MM/dd/yyyy').format(date);
  }
}
