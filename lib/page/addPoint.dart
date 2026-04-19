import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../model/record.dart';
import '../store/store.dart';
import '../widget/form.dart';

class AddPointPage extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const AddPointPage({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<AddPointPage> createState() => _AddPointPageState();
}

class _AddPointPageState extends State<AddPointPage> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _picker = ImagePicker();

  double? _latitude;
  double? _longitude;
  String? _imagePath;
  List<String> _selectedTags = [];
  bool _isSaving = false;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;

    if (_latitude == null || _longitude == null) {
      _loadCurrentLocation();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition();

      if (!mounted) return;

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<String> _persistImage(XFile file) async {
    final appDir = await getApplicationDocumentsDirectory();
    final folder = Directory('${appDir.path}/checkin_images');

    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    final ext = file.path.split('.').last;
    final target = File(
      '${folder.path}/${DateTime.now().millisecondsSinceEpoch}.$ext',
    );

    final copied = await File(file.path).copy(target.path);
    return copied.path;
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (file == null) return;

    final savedPath = await _persistImage(file);

    if (!mounted) return;

    setState(() {
      _imagePath = savedPath;
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final note = _noteController.text.trim();

    if (title.isEmpty) {
      _showMessage('Please enter a title.');
      return;
    }

    if (_latitude == null || _longitude == null) {
      _showMessage('Current location is not ready.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final record = CheckInRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      note: note,
      latitude: _latitude!,
      longitude: _longitude!,
      createdAt: DateTime.now(),
      imagePath: _imagePath,
      tags: _selectedTags,
    );

    await CheckInStore.instance.addRecord(record);

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Check-in'),
        actions: [
          IconButton(
            onPressed: _isLoadingLocation ? null : _loadCurrentLocation,
            icon: const Icon(Icons.my_location_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: AddPointForm(
                  titleController: _titleController,
                  noteController: _noteController,
                  latitude: _latitude,
                  longitude: _longitude,
                  imagePath: _imagePath,
                  selectedTags: _selectedTags,
                  onTakePhoto: () => _pickImage(ImageSource.camera),
                  onPickFromGallery: () => _pickImage(ImageSource.gallery),
                  onTagsChanged: (value) {
                    setState(() {
                      _selectedTags = value;
                    });
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: const Icon(Icons.bookmark_add_rounded),
                  label: Text(_isSaving ? 'Saving...' : 'Save Check-in'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}