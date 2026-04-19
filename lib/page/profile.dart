import 'package:flutter/material.dart';

import '../model/tag.dart';
import '../store/store.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CheckInStore.instance,
      builder: (context, _) {
        final records = CheckInStore.instance.records;
        final latest = records.isEmpty ? null : records.first;

        final usedTags = <String>{};
        for (final record in records) {
          usedTags.addAll(record.tags);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'City Explorer',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Collect places, moments and memories.',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _row('Total check-ins', records.length.toString()),
                      const SizedBox(height: 12),
                      _row('Used tags', usedTags.length.toString()),
                      const SizedBox(height: 12),
                      _row(
                        'Latest check-in',
                        latest == null ? '--' : latest.title,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableTags.map((tag) {
                      final count = CheckInStore.instance.countByTag(tag.key);

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: tag.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${tag.label} · $count',
                          style: TextStyle(
                            color: tag.color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _row(String title, String value) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        Text(value),
      ],
    );
  }
}
