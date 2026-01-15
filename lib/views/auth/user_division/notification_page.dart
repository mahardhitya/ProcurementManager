import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/restapi.dart';
import '../../../core/config.dart';

class NotificationPage extends StatefulWidget {
  final String userDivision;

  const NotificationPage({super.key, required this.userDivision});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  final DataService _dataService = DataService();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      String response = await _dataService.selectAll(
        AppConfig.token,
        'procumon',
        'procurement_requests',
        AppConfig.appid,
      );

      var jsonResponse = json.decode(response);
      List requestData = [];
      if (jsonResponse is Map && jsonResponse['data'] != null) {
        requestData = jsonResponse['data'] as List;
      } else if (jsonResponse is List) {
        requestData = jsonResponse;
      }

      List<Map<String, dynamic>> allNotifications = [];
      for (var item in requestData) {
        String itemDivision = item['division_name'] ?? '';
        String itemStatus = item['status'] ?? 'Pending';

        // Filter only for user's division and not deleted
        if (itemDivision != widget.userDivision) continue;
        if (itemStatus.toLowerCase() == 'deleted') continue;

        String message = "";
        Color statusColor = Colors.orange;
        IconData icon = Icons.hourglass_empty;
        String monthName = item['month_name'] ?? '';

        if (itemStatus == 'Approved') {
          message =
              "Pengajuan ${item['item_name']} untuk bulan $monthName telah disetujui oleh Admin";
          statusColor = Colors.green;
          icon = Icons.check_circle;
        } else if (itemStatus == 'Rejected') {
          message =
              "Pengajuan ${item['item_name']} untuk bulan $monthName ditolak oleh Admin";
          statusColor = Colors.red;
          icon = Icons.cancel;
        } else if (itemStatus == 'Pending') {
          message =
              "Pengajuan ${item['item_name']} untuk bulan $monthName sedang menunggu persetujuan Admin";
          statusColor = Colors.orange;
          icon = Icons.pending;
        }

        allNotifications.add({
          'message': message,
          'status': itemStatus,
          'color': statusColor,
          'icon': icon,
          'date': item['date'] ?? '',
          'itemName': item['item_name'] ?? 'Unknown',
          'month': monthName,
          'isRead': itemStatus == 'Approved',
          'rejectionReason': item['rejection_reason'] ?? '',
        });
      }

      // Sort by date descending
      allNotifications.sort((a, b) => b['date'].compareTo(a['date']));

      setState(() {
        _notifications = allNotifications;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Notifikasi"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 80,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Tidak ada notifikasi",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        return _buildNotificationCard(_notifications[index]);
                      },
                    ),
            ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notif) {
    bool isRead = notif['isRead'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead ? Colors.grey.shade200 : Colors.blue.shade100,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Status
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (notif['color'] as Color).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                notif['icon'] as IconData,
                color: notif['color'] as Color,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif['itemName'],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isRead
                                ? FontWeight.w600
                                : FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notif['message'],
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        notif['date'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: (notif['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (notif['color'] as Color).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          notif['status'],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: notif['color'] as Color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
