import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

import 'pane.dart';

class PaneCarousel extends StatelessWidget {
  const PaneCarousel(
      {Key? key,
      required this.paneQueries,
      required this.currPaneIndex,
      required this.onPageChanged,
      required this.carouselController})
      : super(key: key);

  final List<String> paneQueries;
  final int currPaneIndex;
  final void Function(int, CarouselPageChangedReason) onPageChanged;
  final CarouselController carouselController;

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    return CarouselSlider.builder(
      itemCount: paneQueries.length,
      itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) =>
          Pane(
        query: paneQueries[itemIndex],
        visible: itemIndex == currPaneIndex,
      ),
      options: CarouselOptions(
        height: height,
        enableInfiniteScroll: false,
        onPageChanged: onPageChanged,
        viewportFraction: 0.95,
      ),
      carouselController: carouselController,
    );
  }
}
