import 'package:crayon/models/review.dart';
import 'package:crayon/models/reviews.dart';
import 'package:crayon/views/99_session/review_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SessionHistoryWidget extends StatefulWidget {
  const SessionHistoryWidget({Key? key}) : super(key: key);

  @override
  _SessionHistoryWidgetState createState() => _SessionHistoryWidgetState();
}

class _SessionHistoryWidgetState extends State<SessionHistoryWidget> {
  List<Review> allReviewList = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      child: Consumer<ReviewLists>(
        builder: ((context, reviews, child) {
          if (reviews.initialized == false) {
            return Container(
                alignment: Alignment.center,
                child: CircularProgressIndicator());
          } else if (reviews.items.isEmpty) {
            return Center(
                child:
                    Text('진행된 세션이 아직 없습니다.', style: TextStyle(fontSize: 16.0)));
          } else {
            return ListView.builder(
              padding: const EdgeInsets.only(right: 8, left: 8, bottom: 8),
              shrinkWrap: true,
              physics: ClampingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemCount: reviews.items.length,
              itemBuilder: (BuildContext context, index) {
                return GestureDetector(
                  child: Card(
                    child: Column(
                      children: [
                        Expanded(
                            flex: 4,
                            child: Container(
                                width: 360.w / 3 - 13.w,
                                child: Image.network(
                                  '${reviews.items[index].img}',
                                  fit: BoxFit.cover,
                                ))),
                        SizedBox(height: 8),
                        Expanded(
                          flex: 1,
                          child: Text('${reviews.items[index].name}',
                              style: TextStyle(
                                  fontSize: 14.0, color: Colors.black87)),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                              '${DateFormat('MM월 dd일').format(reviews.items[index].date)}',
                              style: TextStyle(
                                  fontSize: 13.0,
                                  // fontWeight: FontWeight.bold,
                                  color: Colors.black87)),
                        ),
                        Expanded(
                            flex: 2,
                            child: reviews.items[index].done == 1
                                ? Row(
                                    children: [
                                      Text(
                                        '리뷰 완료 ',
                                        style: TextStyle(
                                          fontSize: 12.0,
                                        ),
                                      ),
                                      Icon(
                                        Icons.check,
                                        size: 17.0,
                                      )
                                    ],
                                  )
                                : TextButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ReviewView(
                                                review: reviews.items[index]),
                                          ));
                                    },
                                    icon: Icon(
                                      Icons.article,
                                      size: 17.0,
                                    ),
                                    label: Text(
                                      '리뷰하기',
                                      style: TextStyle(
                                        fontSize: 12.0,
                                      ),
                                    ),
                                  ))
                      ],
                    ),
                  ),
                  onTap: () => {print("아이 정보 보여주기")},
                );
              },
            );
          }
        }),
      ),
    );
  }
}
