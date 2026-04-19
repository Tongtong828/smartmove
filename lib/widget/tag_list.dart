import 'package:flutter/material.dart';

import '../model/tag.dart';

class TagList extends StatelessWidget {
  final List<String> selectedTags;
  final ValueChanged<List<String>> onChanged;

  const TagList({
    super.key,
    required this.selectedTags,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableTags.map((tag) {
        final isSelected = selectedTags.contains(tag.key);

        return FilterChip(
          selected: isSelected,
          label: Text(tag.label),
          avatar: Icon(
            tag.icon,
            size: 18,
            color: isSelected ? Colors.white : tag.color,
          ),
          selectedColor: tag.color,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          onSelected: (value) {
            final next = List<String>.from(selectedTags);
            if (value) {
              next.add(tag.key);
            } else {
              next.remove(tag.key);
            }
            onChanged(next);
          },
        );
      }).toList(),
    );
  }
}