import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../../domain/usecases/create_ticket_usecase.dart';
import '../../data/datasources/ticket_remote_datasource.dart';
import '../../data/repositories/ticket_repository_impl.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import 'ticket_state.dart';

// Dependencies
final ticketRemoteDataSourceProvider = Provider<TicketRemoteDataSource>((ref) {
  return TicketRemoteDataSourceImpl(
    firestore: ref.watch(firestoreProvider),
    firebaseAuth: ref.watch(firebaseAuthProvider),
  );
});

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  return TicketRepositoryImpl(
    remoteDataSource: ref.watch(ticketRemoteDataSourceProvider),
  );
});

final createTicketUseCaseProvider = Provider<CreateTicketUseCase>((ref) {
  return CreateTicketUseCase(ref.watch(ticketRepositoryProvider));
});

// Notifier
class TicketNotifier extends Notifier<TicketState> {
  @override
  TicketState build() {
    return TicketInitial();
  }

  Future<void> createTicket({
    required String issue,
    required String description,
    String? attachmentUrl,
  }) async {
    state = TicketLoading();
    try {
      final ticket = await ref.read(createTicketUseCaseProvider).execute(
        issue: issue,
        description: description,
        attachmentUrl: attachmentUrl,
      );
      state = TicketSuccess(ticket);
    } catch (e) {
      state = TicketError(e.toString());
    }
  }
}

final ticketProvider = NotifierProvider<TicketNotifier, TicketState>(() {
  return TicketNotifier();
});
