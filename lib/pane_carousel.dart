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
    return CarouselSlider.builder(
      itemCount: paneQueries.length,
      itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) =>
          Pane(
        query: paneQueries[itemIndex],
        visible: itemIndex == currPaneIndex,
      ),
      options: CarouselOptions(
        enableInfiniteScroll: false,
        onPageChanged: onPageChanged,
      ),
      carouselController: carouselController,
    );
  }
}
