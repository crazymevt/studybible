import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_state.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showDashboardOnStart = ref.watch(showDashboardOnStartProvider);
    final fontFamily = ref.watch(appFontFamilyProvider);
    final fontSizeDelta = ref.watch(appFontSizeDeltaProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('General', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: const Text('Show Dashboard on Startup'),
            subtitle: const Text('Launch directly to the dashboard instead of the reader'),
            value: showDashboardOnStart,
            onChanged: (value) {
              ref.read(showDashboardOnStartProvider.notifier).set(value);
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Appearance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            title: const Text('Font Family'),
            subtitle: const Text('Choose the font style for the application'),
            trailing: DropdownButton<String>(
              value: fontFamily,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  ref.read(appFontFamilyProvider.notifier).set(newValue);
                }
              },
              items: <String>[
                'System Default',
                'Roboto',
                'Lora',
                'Open Sans',
                'Lato',
                'Source Code Pro',
                'Merriweather',
                'Playfair Display'
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          ListTile(
            title: const Text('Text Size'),
            subtitle: const Text('Adjust the size of text throughout the app'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.text_fields, size: 16),
                Expanded(
                  child: Slider(
                    value: fontSizeDelta,
                    min: -4.0,
                    max: 8.0,
                    divisions: 12,
                    label: fontSizeDelta == 0.0 ? 'Default' : '${fontSizeDelta > 0 ? '+' : ''}${fontSizeDelta.toInt()}',
                    onChanged: (double value) {
                      ref.read(appFontSizeDeltaProvider.notifier).set(value);
                    },
                  ),
                ),
                const Icon(Icons.text_fields, size: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
