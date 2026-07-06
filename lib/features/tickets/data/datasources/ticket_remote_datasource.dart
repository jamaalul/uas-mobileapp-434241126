import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ticket_model.dart';
import '../models/status_log_model.dart';

abstract class TicketRemoteDataSource {
  Future<TicketModel> createTicket({
    required String issue,
    required String description,
    String? attachmentUrl,
  });

  Future<void> updateTicket({
    required String ticketId,
    String? helpdesk,
    String? status,
  });
}

class TicketRemoteDataSourceImpl implements TicketRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;

  TicketRemoteDataSourceImpl({
    required this.firestore,
    required this.firebaseAuth,
  });

  @override
  Future<TicketModel> createTicket({
    required String issue,
    required String description,
    String? attachmentUrl,
  }) async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated');
    }

    final ticketRef = firestore.collection('tickets').doc();
    final now = DateTime.now();

    final ticketModel = TicketModel(
      id: ticketRef.id,
      userId: user.uid,
      issue: issue,
      description: description,
      attachmentUrl: attachmentUrl,
      helpdesk: null,
      status: 'open',
      createdAt: now,
      statusLogs: [
        StatusLogModel(
          status: 'open',
          timestamp: now,
          updatedBy: user.uid,
        ),
      ],
    );

    await ticketRef.set(ticketModel.toJson());

    return ticketModel;
  }

  @override
  Future<void> updateTicket({
    required String ticketId,
    String? helpdesk,
    String? status,
  }) async {
    final data = <String, dynamic>{};
    if (helpdesk != null) data['helpdesk'] = helpdesk;
    if (status != null) {
      data['status'] = status;
      
      final user = firebaseAuth.currentUser;
      if (user != null) {
        final log = StatusLogModel(
          status: status,
          timestamp: DateTime.now(),
          updatedBy: user.uid,
        ).toMap();
        data['statusLogs'] = FieldValue.arrayUnion([log]);
      }
    }

    if (data.isEmpty) return;

    await firestore.collection('tickets').doc(ticketId).update(data);
  }
}
