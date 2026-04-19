import 'dart:io';

import 'package:amap_map/amap_map.dart';
import 'package:flutter/material.dart';
import 'package:x_amap_base/x_amap_base.dart';

import '../model/record.dart';
import '../model/tag.dart';
import '../store/store.dart';

class DetailPage extends StatefulWidget {
  final CheckInRecord record;

  const DetailPage({
    super.key,
    required this.record,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  static const String _androidAmapKey = 'e26dbf722aba3a0197ae32bc699cc18f';
  static const String _iosAmapKey = '';

  bool _amapInited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initAmap(context);
  }

  void _initAmap(BuildContext context) {
    if (_amapInited) return;

    AMapInitializer.updatePrivacyAgree(
      const AMapPrivacyStatement(
        hasContains: true,
        hasShow: true,
        hasAgree: true,
      ),
    );

    AMapInitializer.init(
      context,
      apiKey: const AMapApiKey(
        androidKey: _androidAmapKey,
        iosKey: _iosAmapKey,
      ),
    );

    _amapInited = true;
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Place Details'),
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
              fontSize: 26,
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
          const SizedBox(height: 18),

          // Map preview with a fixed center pin overlay.
          _sectionCard(
            title: 'Map Preview',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 220,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AMapWidget(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(record.latitude, record.longitude),
                        zoom: 15,
                      ),
                      mapType: MapType.normal,
                      mapLanguage: MapLanguage.english,
                      onMapCreated: (_) {},
                    ),

                    // Center pin overlay to make the point always visible.
                    IgnorePointer(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.94),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              record.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Icon(
                            Icons.location_on_rounded,
                            size: 36,
                            color: Colors.redAccent,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          _sectionCard(
            title: 'Place / Address',
            child: Text(
              record.address.isEmpty ? 'No address' : record.address,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 14),

          _sectionCard(
            title: 'Notes',
            child: Text(
              record.note.isEmpty ? 'No notes for this place.' : record.note,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 14),

          _sectionCard(
            title: 'Location Details',
            child: Column(
              children: [
                _row('Location Source', record.locationSourceLabel),
                const SizedBox(height: 12),
                _row('Latitude', record.latitude.toStringAsFixed(6)),
                const SizedBox(height: 12),
                _row('Longitude', record.longitude.toStringAsFixed(6)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _row(String title, String value) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}