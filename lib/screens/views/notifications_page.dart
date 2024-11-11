// notifications_page.dart
import 'package:flutter/material.dart';
import '../controllers/notification_controller.dart';
import '../models/notification_model.dart';

class NotificationsPage extends StatefulWidget {
  final String userId;

  const NotificationsPage({
    Key? key, 
    required this.userId,
  }) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool isLoading = true;
  String errorMessage = '';
  LocationModel? userLocation;
  late NotificationController controller;

  @override
  void initState() {
    super.initState();
    controller = NotificationController(userId: widget.userId);
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      await controller.fetchUserRole();
      final location = await controller.fetchLocationData();
      
      setState(() {
        userLocation = location;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load data. Please try again.';
      });
    }
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final Color backgroundColor;
    final Color iconColor;
    final IconData iconData;

    switch (notification.level) {
      case 3:
        backgroundColor = Colors.red[100]!;
        iconColor = Colors.red;
        iconData = Icons.warning;
        break;
      case 2:
        backgroundColor = Colors.orange[100]!;
        iconColor = Colors.orange;
        iconData = Icons.warning_amber;
        break;
      default:
        backgroundColor = Colors.white;
        iconColor = Colors.brown;
        iconData = Icons.notifications;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: backgroundColor,
      child: ListTile(
        leading: Icon(
          iconData,
          color: iconColor,
          size: 28,
        ),
        title: Text(
          notification.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              notification.timestamp,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.brown[300],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : userLocation == null
                  ? const Center(child: Text('No access to any location'))
                  : ListView.builder(
                      itemCount: controller.buildNotificationsList(userLocation!).length,
                      itemBuilder: (context, index) {
                        final notifications = controller.buildNotificationsList(userLocation!);
                        return _buildNotificationCard(notifications[index]);
                      },
                    ),
    );
  }
}