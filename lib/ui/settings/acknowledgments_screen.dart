import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AcknowledgmentsScreen extends StatelessWidget {
  const AcknowledgmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acknowledgments'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              'This application is made possible thanks to the following projects, resources, and organizations:',
              style: TextStyle(fontSize: 16),
            ),
          ),
          _buildCredit(
            title: 'ph4.org',
            subtitle: 'Extensive catalog of Bible modules, commentaries, and dictionaries.',
            url: 'https://ph4.org/',
          ),
          _buildCredit(
            title: 'MyBible',
            subtitle: 'Excellent SQLite-based module format utilized by this app.',
            url: 'https://mybible.zone/',
          ),
          _buildCredit(
            title: 'OSIS',
            subtitle: 'Open Scriptural Information Standard XML schema for Bibles.',
            url: 'https://ebible.org/osis/',
          ),
          _buildCredit(
            title: 'BibleProject',
            subtitle: 'Incredible animated videos and resources for exploring the Bible.',
            url: 'https://bibleproject.com/',
          ),
          _buildCredit(
            title: 'Lumo Project',
            subtitle: 'Visual translations of the four Gospels.',
            url: 'https://lumoproject.com/',
          ),
          _buildCredit(
            title: 'Jesus Film Project',
            subtitle: 'Sharing the story of Jesus through film.',
            url: 'https://www.jesusfilm.org/',
          ),
          _buildCredit(
            title: 'OpenBible.info',
            subtitle: 'Crowdsourced cross-reference dataset (CC-BY).',
            url: 'https://www.openbible.info/',
          ),
          _buildCredit(
            title: "Nave's Topical Bible",
            subtitle:
                "Public-domain topical index, via the BradyStephenson/bible-data dataset (CC-BY 4.0).",
            url: 'https://github.com/BradyStephenson/bible-data',
          ),
          _buildCredit(
            title: 'Berean Study Bible',
            subtitle: 'Public domain Bible text and audio resources.',
            url: 'https://berean.bible/',
          ),
          _buildCredit(
            title: 'Clojure/JavaFX Study Bible',
            subtitle: 'The original desktop application that inspired this project.',
            url: null, // No URL known for this
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Note: Individual Bible modules, commentaries, and dictionaries downloaded or imported into this application are subject to their respective copyright holders and licenses. Please review the specific copyright information provided within each module.',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Open Source Licenses'),
            subtitle: const Text('View licenses for all open source libraries used in this app.'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: 'Study Bible',
                applicationIcon: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.menu_book, size: 64, color: Theme.of(context).colorScheme.primary),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCredit({
    required String title,
    required String subtitle,
    required String? url,
  }) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: url != null ? const Icon(Icons.open_in_new, size: 16) : null,
      onTap: url != null
          ? () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
          : null,
    );
  }
}
