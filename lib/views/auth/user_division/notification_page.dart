import 'package:flutter/material.dart';
import 'dashboard_user.dart';

class NotificationPage extends StatelessWidget {
  final String userDivision;

  const NotificationPage({super.key, required this.userDivision});

  @override
  Widget build(BuildContext context) {
    // Ambil semua notifikasi dari data dummy untuk divisi user
    List<Map<String, dynamic>> notifications = _generateNotifications();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Notifikasi"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          TextButton(
            onPressed: () {
              // Mark all as read
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Semua notifikasi ditandai sudah dibaca"),
                ),
              );
            },
            child: const Text("Tandai Semua", style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
      body: notifications.isEmpty
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
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return _buildNotificationCard(notifications[index]);
              },
            ),
    );
  }

  // Generate notifikasi dari data dummy untuk divisi user
  List<Map<String, dynamic>> _generateNotifications() {
    List<Map<String, dynamic>> allNotifications = [];
    final dummyData = DashboardUser.getDummyData();

    dummyData.forEach((month, items) {
      for (var item in items) {
        // Filter hanya untuk divisi user
        if (item['division'] != userDivision) continue;

        String message = "";
        Color statusColor = Colors.orange;
        IconData icon = Icons.hourglass_empty;

        if (item['status'] == 'Approved') {
          message =
              "Pengajuan ${item['item_name']} untuk bulan $month telah disetujui oleh Admin";
          statusColor = Colors.green;
          icon = Icons.check_circle;
        } else if (item['status'] == 'Rejected') {
          message =
              "Pengajuan ${item['item_name']} untuk bulan $month ditolak oleh Admin";
          statusColor = Colors.red;
          icon = Icons.cancel;
        } else if (item['status'] == 'Pending') {
          message =
              "Pengajuan ${item['item_name']} untuk bulan $month sedang menunggu persetujuan Admin";
          statusColor = Colors.orange;
          icon = Icons.pending;
        }

        allNotifications.add({
          'message': message,
          'status': item['status'],
          'color': statusColor,
          'icon': icon,
          'date': item['date'],
          'itemName': item['item_name'],
          'month': month,
          'isRead':
              item['status'] ==
              'Approved', // Approved sudah dibaca, pending/rejected belum
        });
      }
    });

    // Sort berdasarkan tanggal terbaru
    allNotifications.sort((a, b) => b['date'].compareTo(a['date']));

    return allNotifications;
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
