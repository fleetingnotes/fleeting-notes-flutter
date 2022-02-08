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
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

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
        onChanged: _onChanged,
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

  void _onChanged(query) {
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
