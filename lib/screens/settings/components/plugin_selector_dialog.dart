import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/screens/settings/components/plugin_card.dart';

class PluginSelectionWidget extends StatelessWidget {
  final List<Plugin> plugins;
  final ValueChanged<Plugin>? onPluginSelected;
  final VoidCallback? onCloseButtonPressed;

  const PluginSelectionWidget({
    Key? key,
    required this.plugins,
    this.onPluginSelected,
    this.onCloseButtonPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
            child: ListView.builder(
          key: const PageStorageKey('ListOfPlugins'),
          itemCount: plugins.length,
          shrinkWrap: true,
          itemBuilder: (context, index) => PluginCard(
            plugin: plugins[index],
            onTap: (onPluginSelected == null)
                ? null
                : () => onPluginSelected!(plugins[index]),
          ),
        )),
        ElevatedButton(
          child: const Text('Close'),
          onPressed: onCloseButtonPressed,
        ),
      ],
    );
  }
}

class PluginSelectorDialog extends StatelessWidget {
  final ValueChanged<Plugin>? onPluginSelected;
  final List<Plugin> plugins;

  const PluginSelectorDialog({
    Key? key,
    required this.plugins,
    this.onPluginSelected,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select a plugin'),
      content: SizedBox(
        width: 300,
        child: PluginSelectionWidget(
          plugins: plugins,
          onPluginSelected: (Plugin selectedPlugin) {
            onPluginSelected!(selectedPlugin);
            Navigator.of(context).pop();
          },
          onCloseButtonPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}
