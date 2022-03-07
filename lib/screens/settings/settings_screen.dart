import 'package:fleeting_notes_flutter/constants.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String exportOption = 'Markdown';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(kDefaultPadding / 3),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ]),
            ),
            const Divider(
              thickness: 1,
              height: 1,
            ),
            SingleChildScrollView(
                controller: ScrollController(),
                padding: const EdgeInsets.all(kDefaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Export Notes", style: TextStyle(fontSize: 12)),
                    const Divider(thickness: 1, height: 1),
                    Padding(
                      padding: const EdgeInsets.all(kDefaultPadding / 2),
                      child: Row(children: [
                        DropdownButton(
                          underline: SizedBox(),
                          value: exportOption,
                          onChanged: (String? newValue) {
                            setState(() {
                              exportOption = newValue!;
                            });
                          },
                          items: const [
                            DropdownMenuItem(
                              child: Text('Markdown'),
                              value: 'Markdown',
                            ),
                            DropdownMenuItem(
                              child: Text('JSON'),
                              value: 'JSON',
                            ),
                          ],
                        ),
                        const Spacer(),
                        ElevatedButton(onPressed: () {}, child: Text('Export')),
                      ]),
                    ),
                  ],
                ))
          ],
        ),
      ),
    );
  }
}
