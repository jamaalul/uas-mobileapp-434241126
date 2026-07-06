import 'package:flutter/material.dart';

class HelpdeskDashboard extends StatefulWidget {
  const HelpdeskDashboard({super.key});

  @override
  State<HelpdeskDashboard> createState() => _HelpdeskDashboardState();
}

class _HelpdeskDashboardState extends State<HelpdeskDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(24.0),
        child: SafeArea(
          child: Text("Dashboard Helpdesk"),
        ),
      ),
    );
  }
}
