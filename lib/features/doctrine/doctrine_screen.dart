import 'package:flutter/material.dart';
import '../../config/app_strings.dart';
import '../../config/theme.dart';
import '../doctrine/doctrine_data.dart';
import 'doctrine_detail_screen.dart';

class DoctrineScreen extends StatelessWidget {
  const DoctrineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t('doctrine_tile')),
      ),
      body: ListView.builder(
        itemCount: doctrineTopics.length,
        itemBuilder: (context, index) {
          final topic = doctrineTopics[index];
          return ListTile(
            leading: Icon(topic.icon),
            title: Text(topic.titleFor(AppStrings.locale)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DoctrineDetailScreen(topic: topic),
              ),
            ),
          );
        },
      ),
    );
  }
}