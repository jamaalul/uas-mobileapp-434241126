import 'package:go_router/go_router.dart';
import '../pages/home/home.dart';
import '../pages/auth/login.dart';
import '../pages/auth/register.dart';
import '../pages/dashboard/user_dashboard.dart';
import '../pages/dashboard/admin_dashboard.dart';
import '../pages/dashboard/manage_users.dart';
import '../pages/dashboard/helpdesk_dashboard.dart';
import '../pages/dashboard/helpdesk_ticket_detail.dart';
import '../pages/dashboard/user_ticket_detail.dart';
import '../pages/create_tickets/user_create_ticket.dart';
import '../../../features/tickets/domain/entities/ticket.dart';

class AppRoutes {
  static const home = 'home';
  static const login = 'auth';
  static const register = 'register';
  static const userDashboard = 'userDashboard';
  static const adminDashboard = 'adminDashboard';
  static const helpdeskDashboard = 'helpdeskDashboard';
  static const userCreateTicket = 'userCreateTicket';
  static const userTicketDetail = 'userTicketDetail';
  static const helpdeskTicketDetail = 'helpdeskTicketDetail';
  static const manageUsers = 'manageUsers';
}

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      name: AppRoutes.home,
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      name: AppRoutes.login,
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      name: AppRoutes.register,
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      name: AppRoutes.userDashboard,
      path: '/user-dashboard',
      builder: (context, state) => const UserDashboard(),
    ),
    GoRoute(
      name: AppRoutes.adminDashboard,
      path: '/admin-dashboard',
      builder: (context, state) => const AdminDashboard(),
    ),
    GoRoute(
      name: AppRoutes.manageUsers,
      path: '/manage-users',
      builder: (context, state) => const ManageUsersPage(),
    ),
    GoRoute(
      name: AppRoutes.helpdeskDashboard,
      path: '/helpdesk-dashboard',
      builder: (context, state) => const HelpdeskDashboard(),
    ),
    GoRoute(
      name: AppRoutes.userCreateTicket,
      path: '/user-create-ticket',
      builder: (context, state) => const CreateTicketPage(),
    ),
    GoRoute(
      name: AppRoutes.userTicketDetail,
      path: '/user-ticket-detail',
      builder: (context, state) {
        final ticket = state.extra as Ticket;
        return UserTicketDetailPage(ticket: ticket);
      },
    ),
    GoRoute(
      name: AppRoutes.helpdeskTicketDetail,
      path: '/helpdesk-ticket-detail',
      builder: (context, state) {
        final ticket = state.extra as Ticket;
        return HelpdeskTicketDetailPage(ticket: ticket);
      },
    ),
  ],
);
