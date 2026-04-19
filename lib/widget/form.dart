import 'dart:io';

import 'package:flutter/material.dart';

import 'tag_list.dart';

class AddPointForm extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController noteController;
  final double? latitude;
  final double? longitude;
  final String? imagePath;
  final List<String> selectedTags;
  final VoidCallback onTakePhoto;
  final VoidCallback onPickFromGallery;
  final ValueChanged<List<String>> onTagsChanged;

  const AddPointForm({
    super.key,
    required this.titleController,
    required this.noteController,
    required this.latitude,
    required this.longitude,
    required this.imagePath,
    required this.selectedTags,
    required this.onTakePhoto,
    required this.onPickFromGallery,
    required this.onTagsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: titleController,
          decoration: InputDecoration(
            labelText: 'Title',
            hintText: 'e.g. British Museum',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: noteController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Note',
            hintText: 'Write something about this place...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current Location',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                latitude == null || longitude == null
                    ? 'Location not ready'
                    : 'Lat: ${latitude!.toStringAsFixed(6)}\nLng: ${longitude!.toStringAsFixed(6)}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Tags',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 10),
        TagList(
          selectedTags: selectedTags,
          onChanged: onTagsChanged,
        ),
        const SizedBox(height: 20),
        const Text(
          'Photo',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            children: [
              if (imagePath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(imagePath!),
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_camera_back_rounded, size: 44),
                      SizedBox(height: 8),
                      Text('No photo selected'),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onTakePhoto,
                      icon: const Icon(Icons.photo_camera_rounded),
                      label: const Text('Camera'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onPickFromGallery,
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('Gallery'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}