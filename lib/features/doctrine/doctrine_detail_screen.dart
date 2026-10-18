import 'package:flutter/material.dart';
import '../../config/app_strings.dart';
import '../doctrine/doctrine_data.dart';

class DoctrineDetailScreen extends StatelessWidget {
  final DoctrineTopic topic;

  const DoctrineDetailScreen({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(topic.titleFor(AppStrings.locale)),
      ),
      body: ListView.builder(
        itemCount: topic.itemsFor(AppStrings.locale).length,
        itemBuilder: (context, index) {
          final item = topic.itemsFor(AppStrings.locale)[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              item,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        },
      ),
    );
  }
}