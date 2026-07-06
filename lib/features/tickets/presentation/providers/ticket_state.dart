import '../../domain/entities/ticket.dart';

abstract class TicketState {}

class TicketInitial extends TicketState {}

class TicketLoading extends TicketState {}

class TicketSuccess extends TicketState {
  final Ticket ticket;

  TicketSuccess(this.ticket);
}

class TicketError extends TicketState {
  final String message;

  TicketError(this.message);
}
