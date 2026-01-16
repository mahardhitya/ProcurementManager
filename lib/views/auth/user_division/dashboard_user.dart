import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_page.dart';
import 'notification_page.dart';
import 'add_request_page.dart';
import '../../../core/restapi.dart';
import '../../../core/config.dart';

class DashboardUser extends StatefulWidget {
  const DashboardUser({super.key});

  @override
  State<DashboardUser> createState() => _DashboardUserState();
}

class _DashboardUserState extends State<DashboardUser> {
  int _currentIndex = 0;
  String? userDivision;
  String? userId;
  bool _isLoading = true;

  // Keys untuk refresh child widgets
  final GlobalKey<_HomeTabState> _homeKey = GlobalKey<_HomeTabState>();
  final GlobalKey<_StatusTabState> _statusKey = GlobalKey<_StatusTabState>();

  final List<String> months = const [
    "Januari",
    "Februari",
    "Maret",
    "April",
    "Mei",
    "Juni",
    "Juli",
    "Agustus",
    "September",
    "Oktober",
    "November",
    "Desember",
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userDivision = prefs.getString('division_name') ?? 'IT';
      userId = prefs.getString('user_id') ?? '';
      _isLoading = false;
    });
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Logout'),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  // Method untuk refresh semua tabs setelah pengajuan baru
  void _refreshAllTabs() {
    _homeKey.currentState?._loadData();
    _statusKey.currentState?._loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || userDivision == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTab(
            key: _homeKey,
            userDivision: userDivision!,
            months: months,
            onShowLogout: _showLogoutDialog,
          ),
          _StatusTab(
            key: _statusKey,
            userDivision: userDivision!,
            months: months,
          ),
          _PengajuanTab(
            userDivision: userDivision!,
            months: months,
            onSubmitSuccess: _refreshAllTabs,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
            // Refresh data saat pindah tab
            if (index == 0) {
              _homeKey.currentState?._loadData();
            } else if (index == 1) {
              _statusKey.currentState?._loadData();
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF1565C0),
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_outlined),
              activeIcon: Icon(Icons.list_alt),
              label: 'Status',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              activeIcon: Icon(Icons.add_circle),
              label: 'Pengajuan',
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== HOME TAB ====================
class _HomeTab extends StatefulWidget {
  final String userDivision;
  final List<String> months;
  final VoidCallback onShowLogout;

  const _HomeTab({
    super.key,
    required this.userDivision,
    required this.months,
    required this.onShowLogout,
  });

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  String _selectedMonth = "";
  List<Map<String, dynamic>> _allRequests = [];
  bool _isLoading = true;
  final DataService _dataService = DataService();
  int _divisionBudget = 0; // Budget yang diberikan admin untuk divisi ini

  @override
  void initState() {
    super.initState();
    // Default ke bulan saat ini
    int currentMonthIndex = DateTime.now().month - 1;
    _selectedMonth = widget.months[currentMonthIndex];
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load division budget from API
      await _loadDivisionBudget();

      String response = await _dataService.selectAll(
        AppConfig.token,
        'procumon',
        'procurement_requests',
        AppConfig.appid,
      );

      List requestData = [];

      if (response.isNotEmpty && response != '[]') {
        try {
          var jsonResponse = json.decode(response);
          if (jsonResponse is Map && jsonResponse['data'] != null) {
            requestData = jsonResponse['data'] as List;
          } else if (jsonResponse is List) {
            requestData = jsonResponse;
          }
        } catch (e) {
          print('Error parsing JSON: $e');
          requestData = [];
        }
      }

      // Collect processed item keys
      Set<String> processedItemKeys = {};
      for (var item in requestData) {
        if (item == null) continue;
        String status = (item['status'] ?? '').toString().toLowerCase();
        if (status == 'approved' || status == 'rejected') {
          String key =
              '${item['item_name'] ?? ''}|${item['division_name'] ?? ''}|${item['month_name'] ?? ''}|${item['date'] ?? ''}';
          processedItemKeys.add(key);
        }
      }

      List<Map<String, dynamic>> filteredRequests = [];
      for (var item in requestData) {
        if (item == null) continue;
        String itemDivision = (item['division_name'] ?? '').toString();
        String itemStatus = (item['status'] ?? 'Pending').toString();
        bool isDeleted = itemStatus.toLowerCase() == 'deleted';

        String itemKey =
            '${item['item_name'] ?? ''}|$itemDivision|${item['month_name'] ?? ''}|${item['date'] ?? ''}';
        bool isPendingWithProcessedVersion =
            itemStatus.toLowerCase() == 'pending' &&
            processedItemKeys.contains(itemKey);

        if (itemDivision == widget.userDivision &&
            !isDeleted &&
            !isPendingWithProcessedVersion) {
          filteredRequests.add({
            'id': (item['id'] ?? item['_id'] ?? '').toString(),
            'item_name': (item['item_name'] ?? 'Unknown').toString(),
            'quantity': int.tryParse((item['quantity'] ?? '0').toString()) ?? 0,
            'price': int.tryParse((item['price'] ?? '0').toString()) ?? 0,
            'total_price':
                int.tryParse((item['total_price'] ?? '0').toString()) ?? 0,
            'status': itemStatus,
            'date': (item['date'] ?? '').toString(),
            'division': itemDivision,
            'month_name': (item['month_name'] ?? '').toString(),
          });
        }
      }

      setState(() {
        _allRequests = filteredRequests;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _allRequests = [];
        _isLoading = false;
      });
    }
  }

  // Load budget yang dialokasikan admin untuk divisi ini (dummy data)
  Future<void> _loadDivisionBudget() async {
    // Dummy data budget per divisi
    Map<String, int> divisionBudgets = {
      'IT': 40000000,
      'Marketing': 35000000,
      'Operations': 25000000,
      'Finance': 15000000,
      'HR': 10000000,
    };

    _divisionBudget = divisionBudgets[widget.userDivision] ?? 0;
  }

  // Get requests filtered by selected month
  List<Map<String, dynamic>> get _filteredRequests {
    return _allRequests
        .where((item) => item['month_name'] == _selectedMonth)
        .toList();
  }

  // Calculate totals for selected month
  Map<String, int> _calculateMonthlyTotal() {
    int totalItems = 0;
    int totalBudget = 0;

    for (var item in _filteredRequests) {
      totalItems += item['quantity'] as int;
      totalBudget += (item['quantity'] as int) * (item['price'] as int);
    }

    return {'totalItems': totalItems, 'totalBudget': totalBudget};
  }

  // Get notification count
  int _getNotificationCount() {
    return _allRequests
        .where(
          (item) => item['status'] == 'Pending' || item['status'] == 'Rejected',
        )
        .length;
  }

  String _formatCurrency(int amount) {
    if (amount >= 1000000000) {
      return "${(amount / 1000000000).toStringAsFixed(1)}M";
    } else if (amount >= 1000000) {
      return "${(amount / 1000000).toStringAsFixed(0)}Jt";
    } else if (amount >= 1000) {
      return "${(amount / 1000).toStringAsFixed(0)}K";
    }
    return amount.toString();
  }

  // Format currency with full number and thousand separators
  String _formatCurrencyFull(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthlyTotal = _calculateMonthlyTotal();
    final totalItems = monthlyTotal['totalItems']!;
    final totalBudget = monthlyTotal['totalBudget']!;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Header with gradient
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Halo, Divisi ${widget.userDivision}",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                "ProcuMon",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              // Notification Icon
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              NotificationPage(
                                                userDivision:
                                                    widget.userDivision,
                                              ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.notifications_outlined,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  if (_getNotificationCount() > 0)
                                    Positioned(
                                      top: -2,
                                      right: -2,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 18,
                                          minHeight: 18,
                                        ),
                                        child: Center(
                                          child: Text(
                                            _getNotificationCount().toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              // Profile Icon
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProfilePage(
                                        userDivision: widget.userDivision,
                                      ),
                                    ),
                                  );
                                },
                                child: const CircleAvatar(
                                  backgroundColor: Colors.white24,
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Logout Icon
                              GestureDetector(
                                onTap: widget.onShowLogout,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.logout,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Summary Cards (Floating) - Shopee Style Layout
                Positioned(
                  bottom: -85,
                  left: 16,
                  right: 16,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Card - Budget dari Admin
                      Expanded(
                        flex: 1,
                        child: Container(
                          height: 140,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE3F2FD),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_wallet,
                                      color: Color(0xFF1565C0),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Expanded(
                                    child: Text(
                                      "Budget Divisi",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Rp ${_formatCurrencyFull(_divisionBudget)}",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1565C0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Right Column - 2 Cards
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            // Top Right Card - Total Barang Diajukan
                            Container(
                              height: 62,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.shopping_bag_outlined,
                                      color: Colors.orange.shade600,
                                      size: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Total Barang",
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        Text(
                                          "$totalItems Item",
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Bottom Right Card - Total Budget Pengajuan
                            Container(
                              height: 62,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.receipt_long_outlined,
                                      color: Colors.green.shade600,
                                      size: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Total Pengajuan",
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        Text(
                                          "Rp ${_formatCurrency(totalBudget)}",
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 115),

            // Month Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Pilih Bulan",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.months.length,
                      itemBuilder: (context, index) {
                        final month = widget.months[index];
                        final isSelected = month == _selectedMonth;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedMonth = month);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF1565C0)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF1565C0)
                                      : Colors.grey.shade300,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF1565C0,
                                          ).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                month,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Achievement section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ringkasan $_selectedMonth",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredRequests.isEmpty
                      ? _buildEmptyState()
                      : _buildAchievementCards(),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryInfo(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.2), width: 1.5),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "Belum ada pengajuan di bulan $_selectedMonth",
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCards() {
    // Group by status
    int approved = _filteredRequests
        .where((r) => r['status'] == 'Approved')
        .length;
    int pending = _filteredRequests
        .where((r) => r['status'] == 'Pending')
        .length;
    int rejected = _filteredRequests
        .where((r) => r['status'] == 'Rejected')
        .length;

    return Column(
      children: [
        _buildStatusCard(
          "Disetujui",
          approved,
          Colors.green,
          Icons.check_circle_outline,
        ),
        const SizedBox(height: 12),
        _buildStatusCard("Menunggu", pending, Colors.orange, Icons.access_time),
        const SizedBox(height: 12),
        _buildStatusCard(
          "Ditolak",
          rejected,
          Colors.red,
          Icons.cancel_outlined,
        ),
      ],
    );
  }

  Widget _buildStatusCard(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== STATUS TAB ====================
class _StatusTab extends StatefulWidget {
  final String userDivision;
  final List<String> months;

  const _StatusTab({
    super.key,
    required this.userDivision,
    required this.months,
  });

  @override
  State<_StatusTab> createState() => _StatusTabState();
}

class _StatusTabState extends State<_StatusTab> {
  String _selectedMonth = "";
  List<Map<String, dynamic>> _allRequests = [];
  bool _isLoading = true;
  final DataService _dataService = DataService();

  @override
  void initState() {
    super.initState();
    int currentMonthIndex = DateTime.now().month - 1;
    _selectedMonth = widget.months[currentMonthIndex];
    _loadData();
  }

  Future<void> _loadData() async {
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

      // Collect processed item keys
      Set<String> processedItemKeys = {};
      for (var item in requestData) {
        String status = item['status']?.toLowerCase() ?? '';
        if (status == 'approved' || status == 'rejected') {
          String key =
              '${item['item_name']}|${item['division_name']}|${item['month_name']}|${item['date']}';
          processedItemKeys.add(key);
        }
      }

      List<Map<String, dynamic>> filteredRequests = [];
      for (var item in requestData) {
        String itemDivision = item['division_name'] ?? '';
        String itemStatus = item['status'] ?? 'Pending';
        bool isDeleted = itemStatus.toLowerCase() == 'deleted';

        String itemKey =
            '${item['item_name']}|$itemDivision|${item['month_name']}|${item['date']}';
        bool isPendingWithProcessedVersion =
            itemStatus.toLowerCase() == 'pending' &&
            processedItemKeys.contains(itemKey);

        if (itemDivision == widget.userDivision &&
            !isDeleted &&
            !isPendingWithProcessedVersion) {
          filteredRequests.add({
            'id': item['id'] ?? item['_id'] ?? '',
            'item_name': item['item_name'] ?? 'Unknown',
            'quantity': int.tryParse(item['quantity']?.toString() ?? '0') ?? 0,
            'price': int.tryParse(item['price']?.toString() ?? '0') ?? 0,
            'total_price':
                int.tryParse(item['total_price']?.toString() ?? '0') ?? 0,
            'status': itemStatus,
            'date': item['date'] ?? '',
            'division': itemDivision,
            'month_name': item['month_name'] ?? '',
            'rejection_reason': item['rejection_reason'] ?? '',
          });
        }
      }

      setState(() {
        _allRequests = filteredRequests;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredRequests {
    return _allRequests
        .where((item) => item['month_name'] == _selectedMonth)
        .toList();
  }

  Map<String, int> _calculateMonthlyTotal() {
    int totalItems = 0;
    int totalBudget = 0;
    for (var item in _filteredRequests) {
      totalItems += item['quantity'] as int;
      totalBudget += (item['quantity'] as int) * (item['price'] as int);
    }
    return {'totalItems': totalItems, 'totalBudget': totalBudget};
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  String _formatCurrency(int amount) {
    if (amount >= 1000000000) {
      return "${(amount / 1000000000).toStringAsFixed(1)}M";
    } else if (amount >= 1000000) {
      return "${(amount / 1000000).toStringAsFixed(0)}Jt";
    } else if (amount >= 1000) {
      return "${(amount / 1000).toStringAsFixed(0)}K";
    }
    return amount.toString();
  }

  @override
  Widget build(BuildContext context) {
    final monthlyTotal = _calculateMonthlyTotal();
    final totalItems = monthlyTotal['totalItems']!;
    final totalBudget = monthlyTotal['totalBudget']!;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Status Pengajuan",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Divisi ${widget.userDivision}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Summary Card - Diperbesar
          // Summary Card - Diperbesar
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildSummaryCard(
                  "Total Item",
                  "$totalItems Pcs",
                  Icons.shopping_bag_outlined,
                  Colors.orange,
                ),
                Container(width: 1, height: 50, color: Colors.grey.shade200),
                _buildSummaryCard(
                  "Total Biaya",
                  "${_formatCurrency(totalBudget)}",
                  Icons.attach_money,
                  Colors.green,
                ),
              ],
            ),
          ),

          // Month Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 45,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.months.length,
                itemBuilder: (context, index) {
                  final month = widget.months[index];
                  final isSelected = month == _selectedMonth;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedMonth = month),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1565C0)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF1565C0)
                                : Colors.grey.shade300,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF1565C0,
                                    ).withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          month,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // List of requests
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRequests.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredRequests.length,
                    itemBuilder: (context, index) {
                      return _buildRequestCard(_filteredRequests[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.2), width: 1.5),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "Belum ada pengajuan di bulan $_selectedMonth",
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> item) {
    Color statusColor = Colors.orange;
    if (item['status'] == 'Approved') statusColor = Colors.green;
    if (item['status'] == 'Rejected') statusColor = Colors.red;

    int totalPrice = (item['quantity'] as int) * (item['price'] as int);
    bool canEdit = item['status'] == 'Pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['item_name'] ?? 'No Name',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Tanggal: ${item['date']}",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    item['status'] ?? 'Pending',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (canEdit) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    color: Colors.blue,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showEditDialog(item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: Colors.red,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showDeleteConfirmation(item),
                  ),
                ],
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailColumn("Kuantitas", "${item['quantity']} pcs"),
                _buildDetailColumn(
                  "Harga Satuan",
                  "Rp ${_formatNumber(item['price'])}",
                ),
                _buildDetailColumn(
                  "Total",
                  "Rp ${_formatNumber(totalPrice)}",
                  isHighlight: true,
                ),
              ],
            ),
            // Show rejection reason
            if (item['status'] == 'Rejected' &&
                item['rejection_reason'] != null &&
                item['rejection_reason'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Alasan Penolakan:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['rejection_reason'].toString(),
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailColumn(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 15 : 14,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            color: isHighlight ? Colors.blue : Colors.black87,
          ),
        ),
      ],
    );
  }

  void _showEditDialog(Map<String, dynamic> item) {
    final TextEditingController nameController = TextEditingController(
      text: item['item_name'],
    );
    final TextEditingController quantityController = TextEditingController(
      text: item['quantity'].toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit, color: Colors.blue),
            SizedBox(width: 8),
            Text("Edit Pengajuan"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Nama Barang",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.inventory_2_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Quantity",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixText: "pcs",
                prefixIcon: const Icon(Icons.numbers),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              final newQuantity = int.tryParse(quantityController.text) ?? 0;

              if (newName.isEmpty || newQuantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Data tidak valid")),
                );
                return;
              }

              Navigator.pop(context);

              try {
                await _dataService.updateId(
                  'item_name',
                  newName,
                  AppConfig.token,
                  'procumon',
                  'procurement_requests',
                  AppConfig.appid,
                  item['id'],
                );
                await _dataService.updateId(
                  'quantity',
                  newQuantity.toString(),
                  AppConfig.token,
                  'procumon',
                  'procurement_requests',
                  AppConfig.appid,
                  item['id'],
                );

                int newTotalPrice = newQuantity * (item['price'] as int);
                await _dataService.updateId(
                  'total_price',
                  newTotalPrice.toString(),
                  AppConfig.token,
                  'procumon',
                  'procurement_requests',
                  AppConfig.appid,
                  item['id'],
                );

                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Pengajuan berhasil diperbarui"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Gagal memperbarui: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 8),
            Text("Konfirmasi Hapus"),
          ],
        ),
        content: Text(
          "Apakah Anda yakin ingin menghapus pengajuan \"${item['item_name']}\"?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _dataService.updateId(
                  'status',
                  'Deleted',
                  AppConfig.token,
                  'procumon',
                  'procurement_requests',
                  AppConfig.appid,
                  item['id'],
                );
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Pengajuan berhasil dihapus"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Gagal menghapus: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }
}

// ==================== PENGAJUAN TAB ====================
class _PengajuanTab extends StatefulWidget {
  final String userDivision;
  final List<String> months;
  final VoidCallback onSubmitSuccess;

  const _PengajuanTab({
    required this.userDivision,
    required this.months,
    required this.onSubmitSuccess,
  });

  @override
  State<_PengajuanTab> createState() => _PengajuanTabState();
}

class _PengajuanTabState extends State<_PengajuanTab> {
  String _selectedMonth = "";

  @override
  void initState() {
    super.initState();
    int currentMonthIndex = DateTime.now().month - 1;
    _selectedMonth = widget.months[currentMonthIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Ajukan Barang",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Divisi ${widget.userDivision}",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month selection
                const Text(
                  "Pilih Bulan Pengajuan",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedMonth,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFF1565C0),
                      ),
                      items: widget.months.map((month) {
                        return DropdownMenuItem<String>(
                          value: month,
                          child: Text(month),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedMonth = value);
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Info card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.add_shopping_cart,
                          size: 48,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Ajukan Pengadaan Barang",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Silakan ajukan barang yang dibutuhkan untuk divisi ${widget.userDivision}. Setelah pengajuan berhasil, Anda dapat melihat statusnya di menu Status.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          height: 1.6,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Tips
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.amber.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Pengajuan yang masih Pending dapat diedit di menu Status",
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddRequestPage(
                            monthName: _selectedMonth,
                            userDivision: widget.userDivision,
                          ),
                        ),
                      );

                      if (result == true && mounted) {
                        widget.onSubmitSuccess();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Pengajuan berhasil! Lihat di menu Status",
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 24),
                    label: const Text(
                      "Buat Pengajuan Baru",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                      shadowColor: const Color(0xFF1565C0).withOpacity(0.4),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
