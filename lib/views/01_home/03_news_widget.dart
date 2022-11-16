import 'package:carousel_slider/carousel_slider.dart';
import 'package:crayon/views/01_home/03-1_news_item_widget.dart';
import 'package:flutter/material.dart';

class NewsWidget extends StatefulWidget {
  const NewsWidget({Key? key}) : super(key: key);

  @override
  _NewsWidgetState createState() => _NewsWidgetState();
}

List<Widget> _newsItemList() {
  List<NewsItemWidget> _items = [];
  // 보여지는 순서. (1) 새로운 뉴스, (2)
  _items.add(NewsItemWidget(type: 'news'));
  _items.add(NewsItemWidget(type: 'alarm'));
  _items.add(NewsItemWidget(type: 'reservation'));

  return [];
}

class _NewsWidgetState extends State<NewsWidget> {
  final CarouselController _caroController = CarouselController();
  int _caroCurrIndex = 0;

  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      items: _newsItemList(),
      carouselController: _caroController,
      options: CarouselOptions(
          enlargeCenterPage: true,
          viewportFraction: 0.95,
          aspectRatio: 2,
          onPageChanged: (index, reason) {
            print('index: $index');
            setState(() {
              _caroCurrIndex = index;
            });
          }),
    );
  }
}
