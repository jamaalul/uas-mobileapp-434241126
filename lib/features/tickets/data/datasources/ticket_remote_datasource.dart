import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ticket_model.dart';

abstract class TicketRemoteDataSource {
  Future<TicketModel> createTicket({
    required String issue,
    required String description,
    String? attachmentUrl,
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
      createdAt: now,
    );

    await ticketRef.set(ticketModel.toJson());

    return ticketModel;
  }
}
