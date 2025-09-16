import 'package:json_annotation/json_annotation.dart';

part 'recording.g.dart';

@JsonSerializable()
class Recording {
  @JsonKey(name: '_id')
  final String id;
  final String userId;
  final String filename;
  final String? originalName;
  final String? filePath;
  final String? transcription;
  final bool isEmergency;
  final String? emergencyType;
  final double? confidence;
  final List<String>? keywords;
  final String status;
  final RecordingMetadata? metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Recording({
    required this.id,
    required this.userId,
    required this.filename,
    this.originalName,
    this.filePath,
    this.transcription,
    required this.isEmergency,
    this.emergencyType,
    this.confidence,
    this.keywords,
    required this.status,
    this.metadata,
    required this.createdAt,
    this.updatedAt,
  });

  factory Recording.fromJson(Map<String, dynamic> json) =>
      _$RecordingFromJson(json);
  Map<String, dynamic> toJson() => _$RecordingToJson(this);
}

@JsonSerializable()
class RecordingMetadata {
  final int? fileSize;
  final String? mimeType;
  final int? duration;
  final int? sampleRate;

  RecordingMetadata({
    this.fileSize,
    this.mimeType,
    this.duration,
    this.sampleRate,
  });

  factory RecordingMetadata.fromJson(Map<String, dynamic> json) =>
      _$RecordingMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$RecordingMetadataToJson(this);
}

@JsonSerializable()
class EmergencyAnalysis {
  final List<String> matchedKeywords;
  final String emergencyType;
  final double confidenceScore;
  final String riskLevel;

  EmergencyAnalysis({
    required this.matchedKeywords,
    required this.emergencyType,
    required this.confidenceScore,
    required this.riskLevel,
  });

  factory EmergencyAnalysis.fromJson(Map<String, dynamic> json) =>
      _$EmergencyAnalysisFromJson(json);
  Map<String, dynamic> toJson() => _$EmergencyAnalysisToJson(this);
}