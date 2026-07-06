import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/ticket.dart';
import 'status_log_model.dart';

class TicketModel extends Ticket {
  TicketModel({
    required super.id,
    required super.userId,
    required super.issue,
    required super.description,
    super.attachmentUrl,
    super.helpdesk,
    super.status = 'open',
    required super.createdAt,
    super.statusLogs,
  });

  factory TicketModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final statusLogsList = data['statusLogs'] as List<dynamic>?;
    final statusLogs = statusLogsList
        ?.map((log) => StatusLogModel.fromMap(log as Map<String, dynamic>))
        .toList();
        
    return TicketModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      issue: data['issue'] ?? '',
      description: data['description'] ?? '',
      attachmentUrl: data['attachmentUrl'],
      helpdesk: data['helpdesk'],
      status: data['status'] ?? 'open',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      statusLogs: statusLogs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'issue': issue,
      'description': description,
      'attachmentUrl': attachmentUrl,
      'helpdesk': helpdesk,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'statusLogs': statusLogs?.map((log) {
        return StatusLogModel.fromEntity(log).toMap();
      }).toList(),
    };
  }

  factory TicketModel.fromEntity(Ticket entity) {
    return TicketModel(
      id: entity.id,
      userId: entity.userId,
      issue: entity.issue,
      description: entity.description,
      attachmentUrl: entity.attachmentUrl,
      helpdesk: entity.helpdesk,
      status: entity.status,
      createdAt: entity.createdAt,
      statusLogs: entity.statusLogs,
    );
  }
}
