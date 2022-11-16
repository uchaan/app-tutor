import 'package:cached_network_image/cached_network_image.dart';
import 'package:crayon/constants/bookRatio.dart';
import 'package:crayon/providers/user_state.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crayon/models/book.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:crayon/configs/server.dart';

class BookListView extends StatefulWidget {
  final String childName;
  final String childUid;
  // BookListView({required this.child});
  BookListView({Key? key, required this.childName, required this.childUid})
      : super(key: key);

  @override
  _BookListViewState createState() => _BookListViewState();
}

class _BookListViewState extends State<BookListView> {
  Map _childListMap = {};
  late double width;
  late double height;
  int level = 1;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() async {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    super.didChangeDependencies();
  }

  //get list of selected child's books from firebase
  Stream<List<Book>> _getBooks() async* {
    List<Book> _allBooks = [];

    //get all collection, search for selected child's document
    await FirebaseFirestore.instance
        .collection('books')
        .doc(this.widget.childUid)
        .get()
        .then(((value) {
      Map _bookInfoMap = value.data() as Map; // name, uid, booklist

      if (_bookInfoMap.isNotEmpty) {
        List _bookList = _bookInfoMap['booklist'];

        _bookList.forEach((_bookInfo) {
          Book book = Book(_bookInfo['title'], _bookInfo['pages'],
              _bookInfo['level'], _bookInfo['iterationNum']);
          _allBooks.add(book);
          level = book.level;
        });
      }
    }));

    yield _allBooks;
  }

  //if _childList is empty, add all children in child list
  Future<Map> getChilds() async {
    QuerySnapshot<Map<String, dynamic>> creference =
        await FirebaseFirestore.instance.collection('books').get();
    int i = 0;
    creference.docs.forEach((doc) {
      Map childBookInfo = doc.data();
      setState(() {
        _childListMap[i.toString()] = {
          'name': childBookInfo['name'],
          'uid': childBookInfo['uid']
        };
      });
      i++;
    });

    return _childListMap;
  }

  //get image url from firebase storage
  Future<String> loadImage(String title, int page) async {
    if (page == 0) {
      return '';
    } else {
      var url = bookServerUrl + "/" + title + "/" + page.toString() + '.JPG';
      return url;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      // padding: const EdgeInsets.all(20.0),
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(0, 30, 0, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    Provider.of<UserState>(context, listen: false)
                        .changeStateTo(NAVIGATION);
                  },
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.black,
                  ),
                ),
                Expanded(
                  child: Text(
                    '${widget.childName}의 책장',
                    style: TextStyle(color: Colors.black, fontSize: 25.sp),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                  child: Icon(
                    Icons.auto_stories_rounded,
                    color: Colors.black,
                    size: 25.sp,
                  ),
                )
              ],
            ),
          ),
          Divider(
            thickness: 1.0,
          ),
          Expanded(
            child: StreamBuilder<List<Book>>(
                stream: _getBooks(),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.data == null || snapshot.data.isEmpty) {
                      return Center(child: Text('no data'));
                    } else {
                      return Container(
                        child: GridView.count(
                          crossAxisCount: 3,
                          childAspectRatio: level == 1
                              ? levelOneRatio * 0.9
                              : levelTwoRatio * 0.9,
                          mainAxisSpacing: 10,
                          children:
                              List.generate(snapshot.data.length, (index) {
                            return FutureBuilder(
                                future:
                                    loadImage(snapshot.data[index].title, 1),
                                builder: (BuildContext context,
                                    AsyncSnapshot<String> image) {
                                  if (image.hasData) {
                                    //print(_curPage);
                                    return GestureDetector(
                                      child: Column(
                                        children: [
                                          CachedNetworkImage(
                                            imageUrl: image.data.toString(),
                                            imageBuilder:
                                                (context, imageProvider) =>
                                                    Container(
                                              width: MediaQuery.of(context)
                                                          .size
                                                          .width /
                                                      3 -
                                                  10.w,
                                              height: level == 1
                                                  ? (MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              3 -
                                                          10.w) *
                                                      (1 / levelOneRatio)
                                                  : (MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              3 -
                                                          10.w) *
                                                      (1 / levelTwoRatio),
                                              decoration: BoxDecoration(
                                                  image: DecorationImage(
                                                image: imageProvider,
                                                fit: BoxFit.fitHeight,
                                              )),
                                            ),
                                            placeholder: (context, url) =>
                                                Container(),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Text('책 표지를 불러오지 못했습니다.'),
                                          ),
                                          Text(
                                            '반복횟수 ${snapshot.data[index].numOfrepeat}회',
                                            style: TextStyle(
                                                color: Colors.black87,
                                                fontSize: 13.w),
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        Provider.of<UserState>(context,
                                                listen: false)
                                            .setCoReadingView(
                                                this.widget.childName,
                                                this.widget.childUid,
                                                Book(
                                                    snapshot.data[index].title,
                                                    snapshot.data[index].pages,
                                                    snapshot.data[index].level,
                                                    snapshot.data[index]
                                                        .numOfrepeat));
                                        Provider.of<UserState>(context,
                                                listen: false)
                                            .changeStateTo(COREADING);
                                      },
                                    );
                                  } else {
                                    return Container();
                                  }
                                });
                          }),
                        ),
                      );
                    }
                  } else {
                    return Center(child: Container()); // loading
                  }
                }),
          ),
        ],
      ),
    ));
  }
}
