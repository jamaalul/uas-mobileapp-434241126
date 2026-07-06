import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../../domain/usecases/create_ticket_usecase.dart';
import '../../data/datasources/ticket_remote_datasource.dart';
import '../../data/models/ticket_model.dart';
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

// Notifier for admin ticket update actions (assign helpdesk, reject, etc.)
class TicketUpdateNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> updateTicket({
    required String ticketId,
    String? helpdesk,
    String? status,
  }) async {
    state = const AsyncLoading();
    try {
      await ref.read(ticketRepositoryProvider).updateTicket(
            ticketId: ticketId,
            helpdesk: helpdesk,
            status: status,
          );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final ticketUpdateProvider =
    NotifierProvider<TicketUpdateNotifier, AsyncValue<void>>(
  TicketUpdateNotifier.new,
);

/// Streams a map of { status -> count } for the current user's tickets.
final ticketCountsProvider = StreamProvider<Map<String, int>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final user = auth.currentUser;

  if (user == null) {
    return Stream.value({'open': 0, 'diproses': 0, 'selesai': 0, 'ditolak': 0});
  }

  return firestore
      .collection('tickets')
      .where('userId', isEqualTo: user.uid)
      .snapshots()
      .map((snapshot) {
    final counts = <String, int>{
      'open': 0,
      'diproses': 0,
      'selesai': 0,
      'ditolak': 0,
    };
    for (final doc in snapshot.docs) {
      final status = (doc.data()['status'] as String?) ?? 'open';
      if (counts.containsKey(status)) {
        counts[status] = counts[status]! + 1;
      }
    }
    return counts;
  });
});

/// Streams the full list of the current user's tickets, ordered by createdAt desc.
final userTicketsProvider = StreamProvider<List<Ticket>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final user = auth.currentUser;

  if (user == null) return Stream.value([]);

  return firestore
      .collection('tickets')
      .where('userId', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => TicketModel.fromFirestore(doc)).toList());
});

/// Streams a map of { status -> count } for ALL tickets (admin use).
final allTicketCountsProvider = StreamProvider<Map<String, int>>((ref) {
  final firestore = ref.watch(firestoreProvider);

  return firestore
      .collection('tickets')
      .snapshots()
      .map((snapshot) {
    final counts = <String, int>{
      'open': 0,
      'diproses': 0,
      'selesai': 0,
      'ditolak': 0,
    };
    for (final doc in snapshot.docs) {
      final status = (doc.data()['status'] as String?) ?? 'open';
      if (counts.containsKey(status)) {
        counts[status] = counts[status]! + 1;
      }
    }
    return counts;
  });
});

/// Streams the full list of ALL tickets, ordered by createdAt desc (admin use).
final allTicketsProvider = StreamProvider<List<Ticket>>((ref) {
  final firestore = ref.watch(firestoreProvider);

  return firestore
      .collection('tickets')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => TicketModel.fromFirestore(doc)).toList());
});

/// Fetches users with role == 'helpdesk'
final helpdeskUsersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final firestore = ref.watch(firestoreProvider);
  
  final snapshot = await firestore
      .collection('users')
      .where('role', isEqualTo: 'helpdesk')
      .get();
      
  return snapshot.docs.map((doc) => {
    'id': doc.id,
    'name': doc.data()['name'] ?? 'Unknown',
  }).toList();
});

/// Fetches user details by userId
final ticketUserProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
  final firestore = ref.watch(firestoreProvider);
  final doc = await firestore.collection('users').doc(userId).get();
  
  if (doc.exists) {
    return {
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    };
  }
  return null;
});
