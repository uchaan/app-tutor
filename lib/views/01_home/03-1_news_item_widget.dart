import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NewsItemWidget extends StatefulWidget {
  final String type;
  const NewsItemWidget({Key? key, required this.type}) : super(key: key);

  @override
  _NewsItemWidgetState createState() => _NewsItemWidgetState();
}

class _NewsItemWidgetState extends State<NewsItemWidget> {
  Widget detailedItem() {
    if (this.widget.type == 'news') {
      return Container();
    } else if (this.widget.type == 'message') {
      return Container();
    } else if (this.widget.type == 'alarm') {
      return Container();
    } else
      return Container();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
      child: Padding(
          padding: EdgeInsets.fromLTRB(4.w, 6.w, 4.w, 4.w),
          child: detailedItem()),
    );
  }
}
