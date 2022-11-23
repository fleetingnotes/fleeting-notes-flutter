import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fleeting_notes_flutter/utils/theme_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SideMenu extends ConsumerWidget {
  const SideMenu({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    bool darkMode = settings.get('dark-mode', defaultValue: false);
    return Container(
      height: double.infinity,
      padding: EdgeInsets.only(
          top: kIsWeb ? Theme.of(context).custom.kDefaultPadding : 0),
      color: Theme.of(context).dialogBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: Theme.of(context).custom.kDefaultPadding),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Fleeting Notes",
                    ),
                  ),
                  IconButton(
                    icon: Icon(darkMode ? Icons.dark_mode : Icons.light_mode),
                    onPressed: () {
                      settings.set('dark-mode', !darkMode);
                    },
                    tooltip: 'Toggle Theme',
                  )
                ],
              ),
              const Spacer(),
              ListTile(
                title: const Text("Settings"),
                leading: const Icon(Icons.settings),
                onTap: () {
                  context.push('/settings');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
