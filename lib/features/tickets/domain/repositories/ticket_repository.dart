import '../entities/ticket.dart';

abstract class TicketRepository {
  Future<Ticket> createTicket({
    required String issue,
    required String description,
    String? attachmentUrl,
  });
}
