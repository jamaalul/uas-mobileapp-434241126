import '../entities/ticket.dart';
import '../repositories/ticket_repository.dart';

class CreateTicketUseCase {
  final TicketRepository repository;

  CreateTicketUseCase(this.repository);

  Future<Ticket> execute({
    required String issue,
    required String description,
    String? attachmentUrl,
  }) {
    return repository.createTicket(
      issue: issue,
      description: description,
      attachmentUrl: attachmentUrl,
    );
  }
}
