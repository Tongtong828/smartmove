class CheckInRecord {
  final String id;
  final String title;
  final String note;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final String? imagePath;
  final List<String> tags;

  CheckInRecord({
    required this.id,
    required this.title,
    required this.note,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.tags,
    this.imagePath,
  });

  factory CheckInRecord.fromJson(Map<String, dynamic> json) {
    return CheckInRecord(
      id: json['id'] as String,
      title: json['title'] as String,
      note: json['note'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      imagePath: json['imagePath'] as String?,
      tags: (json['tags'] as List<dynamic>).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
      'imagePath': imagePath,
      'tags': tags,
    };
  }

  String get dateLabel {
    final y = createdAt.year.toString();
    final m = createdAt.month.toString().padLeft(2, '0');
    final d = createdAt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String get timeLabel {
    final h = createdAt.hour.toString().padLeft(2, '0');
    final m = createdAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get dateTimeLabel => '$dateLabel  $timeLabel';
}