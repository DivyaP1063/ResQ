// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recording.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Recording _$RecordingFromJson(Map<String, dynamic> json) => Recording(
      id: json['_id'] as String,
      userId: json['userId'] as String,
      filename: json['filename'] as String,
      originalName: json['originalName'] as String?,
      filePath: json['filePath'] as String?,
      transcription: json['transcription'] as String?,
      isEmergency: json['isEmergency'] as bool,
      emergencyType: json['emergencyType'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      keywords: (json['keywords'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      status: json['status'] as String,
      metadata: json['metadata'] == null
          ? null
          : RecordingMetadata.fromJson(
              json['metadata'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$RecordingToJson(Recording instance) => <String, dynamic>{
      '_id': instance.id,
      'userId': instance.userId,
      'filename': instance.filename,
      'originalName': instance.originalName,
      'filePath': instance.filePath,
      'transcription': instance.transcription,
      'isEmergency': instance.isEmergency,
      'emergencyType': instance.emergencyType,
      'confidence': instance.confidence,
      'keywords': instance.keywords,
      'status': instance.status,
      'metadata': instance.metadata,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

RecordingMetadata _$RecordingMetadataFromJson(Map<String, dynamic> json) =>
    RecordingMetadata(
      fileSize: (json['fileSize'] as num?)?.toInt(),
      mimeType: json['mimeType'] as String?,
      duration: (json['duration'] as num?)?.toInt(),
      sampleRate: (json['sampleRate'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RecordingMetadataToJson(RecordingMetadata instance) =>
    <String, dynamic>{
      'fileSize': instance.fileSize,
      'mimeType': instance.mimeType,
      'duration': instance.duration,
      'sampleRate': instance.sampleRate,
    };

EmergencyAnalysis _$EmergencyAnalysisFromJson(Map<String, dynamic> json) =>
    EmergencyAnalysis(
      matchedKeywords: (json['matchedKeywords'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      emergencyType: json['emergencyType'] as String,
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      riskLevel: json['riskLevel'] as String,
    );

Map<String, dynamic> _$EmergencyAnalysisToJson(EmergencyAnalysis instance) =>
    <String, dynamic>{
      'matchedKeywords': instance.matchedKeywords,
      'emergencyType': instance.emergencyType,
      'confidenceScore': instance.confidenceScore,
      'riskLevel': instance.riskLevel,
    };
