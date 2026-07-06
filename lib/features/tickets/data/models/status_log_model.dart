import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/status_log.dart';

class StatusLogModel extends StatusLog {
  StatusLogModel({
    required super.status,
    required super.timestamp,
    required super.updatedBy,
    super.note,
  });

  factory StatusLogModel.fromMap(Map<String, dynamic> map) {
    return StatusLogModel(
      status: map['status'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      updatedBy: map['updatedBy'] ?? '',
      note: map['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'updatedBy': updatedBy,
      'note': note,
    };
  }

  factory StatusLogModel.fromEntity(StatusLog entity) {
    return StatusLogModel(
      status: entity.status,
      timestamp: entity.timestamp,
      updatedBy: entity.updatedBy,
      note: entity.note,
    );
  }
}
