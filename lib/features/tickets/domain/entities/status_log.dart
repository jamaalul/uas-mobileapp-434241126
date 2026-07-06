class StatusLog {
  final String status;
  final DateTime timestamp;
  final String updatedBy;
  final String? note;

  StatusLog({
    required this.status,
    required this.timestamp,
    required this.updatedBy,
    this.note,
  });
}
