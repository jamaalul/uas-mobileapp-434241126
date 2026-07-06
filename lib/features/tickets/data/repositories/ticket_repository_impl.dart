import '../../domain/entities/ticket.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../datasources/ticket_remote_datasource.dart';

class TicketRepositoryImpl implements TicketRepository {
  final TicketRemoteDataSource remoteDataSource;

  TicketRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Ticket> createTicket({
    required String issue,
    required String description,
    String? attachmentUrl,
  }) async {
    return await remoteDataSource.createTicket(
      issue: issue,
      description: description,
      attachmentUrl: attachmentUrl,
    );
  }

  @override
  Future<void> updateTicket({
    required String ticketId,
    String? helpdesk,
    String? status,
  }) async {
    await remoteDataSource.updateTicket(
      ticketId: ticketId,
      helpdesk: helpdesk,
      status: status,
    );
  }
}
