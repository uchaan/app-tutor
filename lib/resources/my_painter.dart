import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class MyPainter extends ChangeNotifier implements CustomPainter {
  Color strokeColor;
  // var strokes = <List<Offset>>[];
  Map<String, dynamic> _highlights = {};
  double height;
  List<List<Offset>> strokes = [];
  // var height = MediaQuery.of(context).size.height;
  // var width = MediaQuery.of(context).size.width;
  // ratio = MediaQuery.of(context).devicePixelRatio;

  MyPainter(this.strokeColor, this.height);

  bool hitTest(Offset position) => true;
  get semanticsBuilder => null;
  bool shouldRebuildSemantics(covariant CustomPainter oldDelegate) => false;

  void startStroke(
      Offset position, BuildContext context, double width, double height) {
    // print("startStroke");
    // double width = MediaQuery.of(context).size.width;
    // double height = MediaQuery.of(context).size.height;
    // Offset(position.dx/width, position.dy/height)
    // print(width);
    // print(height);
    // print('핸드폰 크기 가로: $width, 세로: $height');
    // print('위치 $position');
    strokes.add([Offset(position.dx / width, position.dy / height)]);
    //strokes.add([position]);
    notifyListeners();
  }

  void appendStroke(
      Offset position, BuildContext context, double width, double height) {
    // print("appendStroke");
    var stroke = strokes.last;
    // double width = MediaQuery.of(context).size.width;
    // double height = MediaQuery.of(context).size.height;
    stroke.add(Offset(position.dx / width, position.dy / height));
    // stroke.add(position);
    notifyListeners();
  }

  void endStroke() {
    // print('endStroke');
    strokes.last = [strokes.last.first, strokes.last.last];
    print(strokes);
    notifyListeners();
  }

  void delete() {
    // print('delete');
    // print(strokes);
    // print(pastStrokes);
    strokes.removeLast();
    // print('after');
    // print(strokes);
    // print(pastStrokes);
  }

  void deleteAll() {
    strokes.clear();
  }

  Future<void> getHighlights(
      String childUid, String title, int currPage) async {
    // print('gethighlights');

    DocumentReference bookDocReference =
        FirebaseFirestore.instance.collection('books').doc(childUid);

    DocumentSnapshot documentSnapshot =
        await bookDocReference.collection('words').doc(title).get();

    if (documentSnapshot.exists) {
      Map highlightMap = documentSnapshot.data() as Map;
      // print(highlightMap);

      highlightMap.forEach((key, value) {
        List<List<Offset>> temp = [];
        List highlightPerPage = json.decode(value);

        highlightPerPage.forEach((element) {
          List<Offset> _offset = [];
          element.forEach((e) => _offset.add(Offset(e[0], e[1])));
          temp.add(_offset);
        });
        _highlights[key] = temp;
      });

      if (_highlights.isNotEmpty && _highlights[currPage.toString()] != null) {
        // print(_highlights);
        strokes = _highlights[currPage.toString()];
        notifyListeners();
      }
    }

    print("HIGHLIGHT: $_highlights");

    print("STROKES: $strokes");
  }

  void saveHighlightPerPage(String currPage) {
    // print("SAVE HIGHLIGHT");

    if (_highlights[currPage] != null) {
      _highlights[currPage] = strokes;
    } else {
      if (strokes.isEmpty) {
        return;
      } else {
        _highlights[currPage] = strokes;
      }
    }
    // print(_highlights);
  }

  void getHighlightPerPage(String currPage) {
    // print("GET HIGHLIGHT");

    if (_highlights[currPage] != null)
      strokes = _highlights[currPage];
    else
      strokes = [];
    notifyListeners();
  }

  Future<void> saveHighlights(String childUid, String title) async {
    //save strokes to firebase
    // print('save highlights');
    Map<String, String> highlights = {};

    // print(_highlights);

    _highlights.forEach((key, values) {
      List<List<List<double>>> temp = [];
      for (var stroke in values) {
        List<List<double>> temp2 = [];
        stroke.forEach((e) => (temp2.add([e.dx, e.dy])));
        temp.add(temp2);
      }
      // print(temp);
      highlights[key] = temp.toString();
    });

    DocumentReference bookDocReference =
        FirebaseFirestore.instance.collection('books').doc(childUid);

    bookDocReference.collection('words').doc(title).set(highlights);
    return;
  }

  List<Offset> cal(List<Offset> a, Size size) {
    List<Offset> temp = [];
    a.forEach((e) => (temp.add(Offset(e.dx * size.width, e.dy * size.height))));
    return temp;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // print("paint!");
    // print(strokes);
    // print(pastStrokes);

    var rect = Offset.zero & size;
    Paint fillPaint = new Paint();
    fillPaint.color = Color.fromRGBO(255, 255, 255, 0.0);
    fillPaint.style = PaintingStyle.fill;
    canvas.drawRect(rect, fillPaint);

    Paint strokePaint = new Paint();
    strokePaint.color = strokeColor;
    strokePaint.style = PaintingStyle.stroke;
    strokePaint.strokeWidth = 30.0 * height / 390;

    Path strokePath = new Path();
    for (var stroke in strokes) {
      strokePath.addPolygon(cal(stroke, size), false);
    }
    canvas.drawPath(strokePath, strokePaint);
  }

  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
