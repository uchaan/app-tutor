import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'dart:math';

class YouchanPainter extends ChangeNotifier implements CustomPainter {
  // class variables
  Color initialColor;
  double height;
  double width;
  List<List<Offset>> strokes = [];
  Map<String, dynamic> _boundingBoxes = {};
  String _curPage;
  List? pageBoundingBoxes;

  var logger = Logger();

  // constructor
  YouchanPainter(this.initialColor, this.height, this.width, this._curPage);

  // get bounding boxes from firestore
  Future<void> getBoundingBoxes(String bookTitle, int currPage) async {
    DocumentReference documentReference =
        FirebaseFirestore.instance.collection('books-word').doc(bookTitle);

    DocumentSnapshot documentSnapshot = await documentReference.get();

    if (documentSnapshot.exists) {
      _boundingBoxes = documentSnapshot.data() as Map<String, dynamic>;
      print(_boundingBoxes);
      getBoundingBoxesPerPage();
      notifyListeners();
    }
  }

  void getBoundingBoxesPerPage() {
    pageBoundingBoxes = _boundingBoxes[_curPage];
    if (pageBoundingBoxes == null) {
      logger.d("이 페이지에 bounding box 없음.");
    }
    notifyListeners();
  }

  void updateCurrentPage(String curPage) {
    _curPage = curPage;
    notifyListeners();
  }

  bool hitTest(Offset position) => true;
  get semanticsBuilder => null;
  bool shouldRebuildSemantics(covariant CustomPainter oldDelegate) => false;

  void startStroke(
      Offset position, BuildContext context, double width, double height) {
    print("Start stroke!");

    double px = position.dx / width;
    double py = position.dy / height;

    // Bounding Box 범위에 들어가는지 확인.
    bool didFound = false;
    var touchedWord = "";
    print(pageBoundingBoxes);
    if (pageBoundingBoxes != null) {
      // logger.d(pageBoundingBoxes);
      for (var i = 0; i < pageBoundingBoxes!.length; i++) {
        // logger.d(pageBoundingBoxes[i]);
        if (didFound) {
          break;
        }
        (pageBoundingBoxes![i] as Map).forEach((key, value) {
          // boundingBox: [x_start, y_start, x_end, y_end]
          List boundingBox = json.decode(value);
          if ((px > boundingBox[0] && px < boundingBox[2]) &&
              (py > boundingBox[1] && py < boundingBox[3])) {
            didFound = true;
            touchedWord = key;
          }
        });
      }
    }

    print(px);
    print(py);

    if (didFound) {
      logger.d("터치 인풋이 bounding box 에 들어왔음!!");
      logger.d(touchedWord);
    } else {
      logger.d("터치 인풋이 bounding box 에 안들어왔음!!");
    }

    strokes.add([Offset(px, py)]);

    // print(position.dx / width);
    // print(position.dy / height);

    notifyListeners();
  }

  void appendStroke(
      Offset position, BuildContext context, double width, double height) {
    // print("append stroke!");
    var stroke = strokes.last;
    stroke.add(Offset(position.dx / width, position.dy / height));
    notifyListeners();
  }

  void endStroke() {
    print("end stroke!");
    strokes.last = [strokes.last.first, strokes.last.last];

    var dist = pow((strokes.last.first.dx - strokes.last.last.dx), 2) +
        pow((strokes.last.first.dy - strokes.last.last.dy), 2);
    dist = sqrt(dist);

    if (dist >= 0.1) {
      if (strokes.last.first.dx < strokes.last.last.dx) {
        logger.d("오른쪽 드래그!");
      } else {
        logger.d("왼쪽 드래그!");
      }
    } else {
      logger.d("충분히 드래그 하지 않음");
    }

    // print(strokes);
    notifyListeners();
  }

  @override
  void paint(Canvas canvas, Size size) {
    var rect = Offset.zero & size;
    Paint fillPaint = new Paint();
    fillPaint.color = Color.fromRGBO(255, 255, 255, 0.0);
    fillPaint.style = PaintingStyle.fill;
    canvas.drawRect(rect, fillPaint);

    Paint initPaint = new Paint();
    initPaint.color = initialColor;
    initPaint.style = PaintingStyle.fill;

    if (pageBoundingBoxes != null) {
      for (var i = 0; i < pageBoundingBoxes!.length; i++) {
        (pageBoundingBoxes![i] as Map).forEach((key, value) {
          // boundingBox: [x_start, y_start, x_end, y_end]
          List boundingBox = json.decode(value);
          canvas.drawRect(
              Offset(boundingBox[0] * width, boundingBox[1] * height) &
                  Size((boundingBox[2] - boundingBox[0]) * width,
                      (boundingBox[3] - boundingBox[1]) * height),
              initPaint);
        });
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
