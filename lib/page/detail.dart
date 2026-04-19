import 'dart:io';

import 'package:flutter/material.dart';

import '../model/record.dart';
import '../model/tag.dart';
import '../store/store.dart';

class DetailPage extends StatelessWidget {
  final CheckInRecord record;

  const DetailPage({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-in Detail'),
        actions: [
          IconButton(
            onPressed: () async {
              await CheckInStore.instance.deleteRecord(record.id);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: record.imagePath != null
                ? Image.file(
                    File(record.imagePath!),
                    height: 260,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 220,
                    color: const Color(0xFFEDEFF5),
                    child: const Center(
                      child: Icon(Icons.photo_rounded, size: 48),
                    ),
                  ),
          ),
          const SizedBox(height: 18),
          Text(
            record.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            record.dateTimeLabel,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: record.tags.map((key) {
              final tag = findTagByKey(key);
              if (tag == null) return const SizedBox.shrink();

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: tag.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tag.icon, size: 16, color: tag.color),
                    const SizedBox(width: 6),
                    Text(
                      tag.label,
                      style: TextStyle(
                        color: tag.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                record.note.isEmpty ? 'No note for this check-in.' : record.note,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _row(
                    'Latitude',
                    record.latitude.toStringAsFixed(6),
                  ),
                  const SizedBox(height: 12),
                  _row(
                    'Longitude',
                    record.longitude.toStringAsFixed(6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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