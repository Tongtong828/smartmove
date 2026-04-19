import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../model/record.dart';
import '../model/tag.dart';
import '../store/store.dart';
import 'address_detail.dart';
import 'point_pick.dart';

class AddPointPage extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;

  const AddPointPage({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
  });

  @override
  State<AddPointPage> createState() => _AddPointPageState();
}

class _AddPointPageState extends State<AddPointPage> {
  static const String amapWebKey = '25e1c7867cf33ba2b1bcc57919b2f093';

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  late final AMapRegeoService _regeoService;

  double? _latitude;
  double? _longitude;
  String? _imagePath;
  List<String> _selectedTags = [];

  String? _locationSource;
  bool _isSaving = false;
  bool _isResolvingAddress = false;

  @override
  void initState() {
    super.initState();

    _regeoService = AMapRegeoService(
      webKey: amapWebKey,
    );

    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;

    if (widget.initialAddress != null &&
        widget.initialAddress!.trim().isNotEmpty) {
      _addressController.text = widget.initialAddress!;
    }

    if (_latitude != null && _longitude != null) {
      _locationSource = 'current';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _useInitialCurrentLocation() async {
    if (widget.initialLatitude == null || widget.initialLongitude == null) {
      _showMessage('Current location is not ready yet.');
      return;
    }

    setState(() {
      _latitude = widget.initialLatitude;
      _longitude = widget.initialLongitude;
      _locationSource = 'current';
    });

    if (widget.initialAddress != null &&
        widget.initialAddress!.trim().isNotEmpty) {
      _addressController.text = widget.initialAddress!;
    } else {
      _addressController.text = 'Please edit the detailed address';
    }

    _showMessage('Using current location.');
  }

  Future<void> _resolvePickedLocationAddress({
    required double latitude,
    required double longitude,
  }) async {
    setState(() {
      _isResolvingAddress = true;
      _addressController.text = 'Finding address...';
    });

    try {
      final address = await _regeoService.reverseGeocode(
        latitude: latitude,
        longitude: longitude,
      );

      if (!mounted) return;

      if (address != null && address.trim().isNotEmpty) {
        _addressController.text = address;
      } else {
        _addressController.text = 'The address could not be obtained automatically. Please fill it in manually';
      }
    } catch (_) {
      if (!mounted) return;
      _addressController.text = 'Address resolution failed. Please fill it in manually';
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingAddress = false;
        });
      }
    }
  }

  Future<void> _pickOnMap() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => PickLocationPage(
          initialLatitude: _latitude ?? widget.initialLatitude,
          initialLongitude: _longitude ?? widget.initialLongitude,
        ),
      ),
    );

    if (result == null) return;

    final latitude = (result['latitude'] as num).toDouble();
    final longitude = (result['longitude'] as num).toDouble();

    setState(() {
      _latitude = latitude;
      _longitude = longitude;
      _locationSource = 'manual';
      _addressController.clear();
    });

    await _resolvePickedLocationAddress(
      latitude: latitude,
      longitude: longitude,
    );

    _showMessage('Map location selected.');
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

  void _toggleTag(String key) {
    final next = List<String>.from(_selectedTags);

    if (next.contains(key)) {
      next.remove(key);
    } else {
      next.add(key);
    }

    setState(() {
      _selectedTags = next;
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final note = _noteController.text.trim();
    final address = _addressController.text.trim();

    if (title.isEmpty) {
      _showMessage('Please enter a title.');
      return;
    }

    if (_latitude == null || _longitude == null || _locationSource == null) {
      _showMessage('Please choose a location first.');
      return;
    }

    if (_selectedTags.isEmpty) {
      _showMessage('Please select at least one tag.');
      return;
    }

    if (address.isEmpty || address == 'Loading...') {
      _showMessage('Please wait for the address or enter it manually.');
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
      address: address,
      locationSource: _locationSource!,
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

  String _locationStatusText() {
    if (_locationSource == null) {
      return 'No location selected';
    }
    if (_locationSource == 'manual') {
      return 'Picked on map';
    }
    return 'Using current location';
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = _latitude != null && _longitude != null;
    final latText = _latitude == null ? '--' : _latitude!.toStringAsFixed(6);
    final lngText = _longitude == null ? '--' : _longitude!.toStringAsFixed(6);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Check-in'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Location',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Default: current location. Pick on Map is optional if you want to correct or add a missed check-in.',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _useInitialCurrentLocation,
                                  icon: const Icon(Icons.my_location_rounded),
                                  label: const Text('Use Current Location'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickOnMap,
                                  icon: const Icon(Icons.place_rounded),
                                  label: const Text('Pick on Map'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FB),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _locationStatusText(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  hasLocation
                                      ? 'Location selected successfully.'
                                      : 'Current location is not ready yet.',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Lat: $latText\nLng: $lngText',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _addressController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Detailed Address',
                              hintText:
                                  'Address will auto-fill. You can still edit it.',
                              suffixIcon: _isResolvingAddress
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextField(
                            controller: _titleController,
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
                            controller: _noteController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: 'Note',
                              hintText: 'Write something about this place...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tags',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Select at least one tag.',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: availableTags.map((tag) {
                              final isSelected = _selectedTags.contains(tag.key);

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
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.w700,
                                ),
                                onSelected: (_) {
                                  _toggleTag(tag.key);
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Photo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_imagePath != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                File(_imagePath!),
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
                                  Icon(
                                    Icons.photo_camera_back_rounded,
                                    size: 44,
                                  ),
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
                                  onPressed: () =>
                                      _pickImage(ImageSource.camera),
                                  icon: const Icon(Icons.photo_camera_rounded),
                                  label: const Text('Camera'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _pickImage(ImageSource.gallery),
                                  icon: const Icon(Icons.photo_library_rounded),
                                  label: const Text('Gallery'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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