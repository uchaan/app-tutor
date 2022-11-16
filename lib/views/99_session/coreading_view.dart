import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:crayon/configs/server.dart';
import 'package:crayon/constants/bookRatio.dart';
import 'package:crayon/providers/current_session.dart';
import 'package:crayon/providers/user_state.dart';
import 'package:crayon/resources/session_method.dart';
import 'package:crayon/resources/youchan_painter.dart';
import 'package:flutter/material.dart';
import 'package:crayon/models/book.dart';
import 'package:crayon/resources/my_painter.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:crayon/global.dart' as global;
import 'package:hexcolor/hexcolor.dart';

class ReadBook extends StatefulWidget {
  final CurrentSession sessionInfo;

  final Book book;
  final UserState userState;

  ReadBook(
      {Key? key,
      required this.sessionInfo,
      required this.book,
      required this.userState})
      : super(key: key);

  @override
  _ReadBookState createState() => _ReadBookState();
}

class _ReadBookState extends State<ReadBook> {
  //painting
  bool isPainting = true;

  //current page index
  int _curPage = 1;

  double height = 0.0;
  double width = 0.0;
  double ratio = 0.0;

  double bookRatio = 0.0;
  double positionX = 0.0;
  double positionY = 0.0;
  double bookWidth = 0.0;
  double bookHeight = 0.0;

  //for highlighter
  late GestureDetector touch;
  late CustomPaint canvas;
  late MyPainter myPainter;
  late YouchanPainter youchanPainter;

  @override
  void initState() {
    //if bookmark exist, go to that page
    if (this.widget.book.title == global.bookmarkBookTitle &&
        this.widget.userState.childName == global.bookmarkChildName) {
      _curPage = global.bookmarkBookPage;
    }

    super.initState();
  }

  @override
  Future<void> didChangeDependencies() async {
    if (widget.userState.orientation == PORTRAIT) {
      if (Platform.isAndroid) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

        SystemChrome.setPreferredOrientations([
          //DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else if (Platform.isIOS)
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          //DeviceOrientation.landscapeRight,
        ]);
      widget.userState.changeOrientation(LANDSCAPE);
    }

    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    ratio = MediaQuery.of(context).devicePixelRatio;

    bookRatio = (this.widget.book.level == 1) ? levelOneRatio : levelTwoRatio;

    if (ratio / 2 > bookRatio) {
      bookWidth = bookRatio * height;
      bookHeight = height;
      positionX = (width / 2 - bookWidth);
      positionY = 0.0;
    } else {
      bookWidth = width / 2;
      bookHeight = width / 2 * (1 / bookRatio);
      positionX = 0.0;
      positionY = (height - bookHeight) / 2;
    }
    myPainter = new MyPainter(Color.fromRGBO(255, 255, 0, 0.5), height);
    youchanPainter = new YouchanPainter(
        Color.fromRGBO(255, 255, 0, 0.5), height, width, _curPage.toString());

    await getHighlights();
    await getBoundingBoxes();

    if (this.widget.sessionInfo.onLive) {
      this.widget.sessionInfo.updateBookTitle(this.widget.book.title);
      SessionMethods().updateBookinfoToFirestore(this.widget.sessionInfo);
    }
    super.didChangeDependencies();
  }

  @override
  dispose() {
    saveBookmark();

    super.dispose();
  }

  //get image url from firebase storage
  Future<String> loadImage(String title, int page) async {
    int currentPage = page;
    if (widget.book.level == 2) {
      currentPage -= 1;
    }
    if (page == 0) {
      return '';
    } else {
      var url =
          bookServerUrl + "/" + title + "/" + currentPage.toString() + '.JPG';
      return url;
    }
  }

  //turn to next page
  void _toRightPage() {
    // save();
    myPainter.saveHighlightPerPage(_curPage.toString());

    //if last page, go to first page
    if (_curPage >= this.widget.book.pages) {
      setState(() {
        _curPage = 1;
      });
      youchanPainter.updateCurrentPage(_curPage.toString());
      youchanPainter.getBoundingBoxesPerPage();
      myPainter.getHighlightPerPage(_curPage.toString());

      return;
    }
    print(_curPage);

    setState(() {
      _curPage += 2;
    });
    if (this.widget.sessionInfo.onLive)
      this.widget.sessionInfo.updateTutorBookMark(_curPage);

    youchanPainter.updateCurrentPage(_curPage.toString());
    youchanPainter.getBoundingBoxesPerPage();
    myPainter.getHighlightPerPage(_curPage.toString());
  }

  //turn to previous page
  void _toLeftPage() {
    myPainter.saveHighlightPerPage(_curPage.toString());

    //if first page, go to last page
    if (_curPage == 1 || _curPage == 2) {
      if (widget.book.level == 2)
        setState(() {
          _curPage = widget.book.pages + 1;
        });
      else
        setState(() {
          _curPage = widget.book.pages;
        });

      youchanPainter.updateCurrentPage(_curPage.toString());
      youchanPainter.getBoundingBoxesPerPage();
      myPainter.getHighlightPerPage(_curPage.toString());

      return;
    }
    setState(() {
      _curPage -= 2;
    });

    if (this.widget.sessionInfo.onLive)
      this.widget.sessionInfo.updateTutorBookMark(_curPage);

    youchanPainter.updateCurrentPage(_curPage.toString());
    youchanPainter.getBoundingBoxesPerPage();
    myPainter.getHighlightPerPage(_curPage.toString());
  }
  /* 
  void panStart(DragStartDetails details) {
    // print(details.globalPosition);
    // print('loc: ${details.localPosition}');

    myPainter.startStroke(
        details.localPosition, context, bookWidth * 2, bookHeight);
  }

  void panUpdate(DragUpdateDetails details) {
    // print(details.globalPosition);

    myPainter.appendStroke(
        details.localPosition, context, bookWidth * 2, bookHeight);
  }

  void panEnd(DragEndDetails details) {
    // myPainter.points.add(Null);
    myPainter.endStroke();
  }
  */

  void panStart(DragStartDetails details) {
    youchanPainter.startStroke(
        details.localPosition, context, bookWidth * 2, bookHeight);
  }

  void panUpdate(DragUpdateDetails details) {
    youchanPainter.appendStroke(
        details.localPosition, context, bookWidth * 2, bookHeight);
  }

  void panEnd(DragEndDetails details) {
    youchanPainter.endStroke();
  }

  void delete() {
    myPainter.delete();
  }

  void deleteAll() {
    myPainter.deleteAll();
  }

  //save to firebase. when should I call this function?
  Future<void> saveHighlights() async {
    await myPainter.saveHighlights(
        widget.userState.childUid, widget.book.title);
  }

  Future<void> getHighlights() async {
    await myPainter.getHighlights(
        widget.userState.childUid, widget.book.title, global.bookmarkBookPage);
  }

  Future<void> getBoundingBoxes() async {
    await youchanPainter.getBoundingBoxes(
        widget.book.title, global.bookmarkBookPage);
  }

  saveBookmark() {
    global.bookmarkChildName = widget.userState.childName;
    global.bookmarkBookTitle = widget.book.title;
    global.bookmarkBookPage = _curPage;
    if (this.widget.sessionInfo.onLive)
      SessionMethods().updateBookinfoToFirestore(this.widget.sessionInfo);
  }

  void _exit() {
    myPainter.saveHighlightPerPage(_curPage.toString());
    saveHighlights();
    if (widget.userState.orientation == LANDSCAPE) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      widget.userState.changeOrientation(PORTRAIT);
    }

    widget.userState.changeStateTo(NAVIGATION);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: HexColor('F7F7F7'),
        body: Center(
          child: Stack(
            children: [
              Positioned(
                // 왼쪽 페이지
                top: positionY,
                left: positionX,
                height: bookHeight,
                width: bookWidth,
                child: new FutureBuilder(
                    future: loadImage(widget.book.title,
                        _curPage % 2 == 0 ? _curPage - 1 : _curPage),
                    builder:
                        (BuildContext context, AsyncSnapshot<String> image) {
                      if (image.hasData) {
                        //print(_curPage);

                        return CachedNetworkImage(
                          imageUrl: image.data.toString(),
                          imageBuilder: (context, imageProvider) => Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                alignment: Alignment.centerRight,
                                image: imageProvider,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          placeholder: (context, url) => Container(),
                          errorWidget: (context, url, error) => Container(),
                        );
                      } else {
                        return Container();
                      }
                    }),
              ),
              Positioned(
                // 오른쪽 페이지
                top: positionY,
                left: positionX + bookWidth,
                height: bookHeight,
                width: bookWidth,
                child: new FutureBuilder(
                    future: loadImage(widget.book.title,
                        _curPage % 2 == 0 ? _curPage : _curPage + 1),
                    builder:
                        (BuildContext context, AsyncSnapshot<String> image) {
                      if (image.hasData) {
                        return Container(
                          alignment: Alignment.centerLeft,
                          child: CachedNetworkImage(
                            imageUrl: image.data.toString(),
                            imageBuilder: (context, imageProvider) => Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  alignment: Alignment.centerLeft,
                                  image: imageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            placeholder: (context, url) => Container(),
                            errorWidget: (context, url, error) => Container(),
                          ),
                        );
                      } else {
                        return Container();
                      }
                    }),
              ),
              Positioned(
                // 제스처 디텍터
                top: positionY,
                left: positionX,
                height: bookHeight,
                width: bookWidth * 2,
                child: Center(
                  child: new CustomPaint(
                    // painter: myPainter,
                    painter: youchanPainter,
                    child: isPainting
                        ? GestureDetector(
                            onPanStart: panStart,
                            onPanUpdate: panUpdate,
                            onPanEnd: panEnd,
                          )
                        : Container(),
                  ),
                ),
              ),
              Positioned(
                // 왼쪽 노치
                bottom: 0,
                left: 0,
                width: 50,
                height: height,
                child: Container(
                  alignment: Alignment.center,
                  color: Colors.grey.withOpacity(0.3),
                ),
              ),
              Positioned(
                  // 나가기 버튼
                  top: 5,
                  left: 5,
                  width: 40,
                  height: 40,
                  child: FloatingActionButton(
                    heroTag: "btn1",
                    onPressed: () => _exit(),
                    child: Icon(Icons.exit_to_app),
                    backgroundColor: Colors.blueGrey,
                  )),
              Positioned(
                  // 삭제 버튼
                  top: 80,
                  left: 5,
                  width: 40,
                  height: 40,
                  child: FloatingActionButton(
                    heroTag: "btn2",
                    onPressed: () => delete(),
                    child: const Icon(Icons.replay_rounded),
                    backgroundColor: Colors.blueGrey,
                  )),
              Positioned(
                  // 앞 페이지로 넘기기 버튼
                  top: 150,
                  left: 5,
                  width: 40,
                  height: 40,
                  child: FloatingActionButton(
                    heroTag: "leftBtn",
                    onPressed: () => _toLeftPage(),
                    child: const Icon(Icons.arrow_left),
                    backgroundColor: Colors.blueGrey,
                  )),
              Positioned(
                  // 뒤 페이지로 넘기기 버튼
                  top: 200,
                  left: 5,
                  width: 40,
                  height: 40,
                  child: FloatingActionButton(
                    heroTag: "rightBtn",
                    onPressed: () => _toRightPage(),
                    child: const Icon(Icons.arrow_right),
                    backgroundColor: Colors.blueGrey,
                  )),
            ],
          ),
        ));
  }
}
