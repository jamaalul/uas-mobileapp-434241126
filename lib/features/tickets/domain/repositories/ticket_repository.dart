import '../entities/ticket.dart';

abstract class TicketRepository {
  Future<Ticket> createTicket({
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
