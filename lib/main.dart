import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_search_bar/flutter_search_bar.dart';
import 'package:carousel_slider/carousel_slider.dart';

import 'pane_carousel.dart';

void main() {
  runApp(const MyApp());
}

// https://docs.flutter.dev/release/breaking-changes/default-scroll-behavior-drag
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        // etc.
      };
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      scrollBehavior: MyCustomScrollBehavior(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          primarySwatch: Colors.blue,
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue)
              .copyWith(background: const Color(0xECECECEC))),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late SearchBar searchBar;
  CarouselController carouselController = CarouselController();
  TextEditingController searchController = TextEditingController();
  List<String> paneQueries = [''];
  int currPaneIndex = 0;

  _MyHomePageState() {
    searchBar = SearchBar(
        inBar: false,
        setState: setState,
        onChanged: _onSearchChanged,
        showClearButton: false,
        clearOnSubmit: false,
        controller: searchController,
        buildDefaultAppBar: buildAppBar);
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      title: Column(children: [
        const Text('Fleeting Notes', style: TextStyle(fontSize: 16)),
        Text(paneQueries[currPaneIndex], style: const TextStyle(fontSize: 12))
      ]),
      actions: <Widget>[
        searchBar.getSearchAction(context),
      ],
    );
  }

  void _addNewPane(query) {
    setState(() {
      currPaneIndex++;
      paneQueries = paneQueries.sublist(0, currPaneIndex);
      paneQueries.add(query);
    });
    carouselController.animateToPage(currPaneIndex);
  }

  void _onSearchChanged(query) {
    setState(() {
      paneQueries[currPaneIndex] = query;
    });
  }

  void _onPageChanged(int index, CarouselPageChangedReason reason) {
    setState(() {
      currPaneIndex = index;
    });
    searchController.text = paneQueries[currPaneIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: searchBar.build(context),
      body: PaneCarousel(
        paneQueries: paneQueries,
        currPaneIndex: currPaneIndex,
        onPageChanged: _onPageChanged,
        carouselController: carouselController,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNewPane(''),
        tooltip: 'Add New Pane',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
