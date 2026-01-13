class ProcurementRequestsModel {
  final String id;
  final String monthly_budget_id;
  final String user_id;
  final String item_name;
  final String quantity;
  final String price;
  final String total_price;
  final String status;
  final String division_name;
  final String date;
  final String month_name;
  final String rejection_reason; // Alasan penolakan
  final String imange_path; // Path gambar

  ProcurementRequestsModel({
    required this.id,
    required this.monthly_budget_id,
    required this.user_id,
    required this.item_name,
    required this.quantity,
    required this.price,
    required this.total_price,
    required this.status,
    required this.division_name,
    this.date = '',
    this.month_name = '',
    this.rejection_reason = '',
    this.imange_path = '',
  });

  factory ProcurementRequestsModel.fromJson(Map data) {
    return ProcurementRequestsModel(
      id: data['id'] ?? data['_id'] ?? '', // Support both 'id' and '_id'
      monthly_budget_id: data['monthly_budget_id'] ?? '',
      user_id: data['user_id'] ?? '',
      item_name: data['item_name'] ?? '',
      quantity: data['quantity'] ?? '0',
      price: data['price'] ?? '0',
      total_price: data['total_price'] ?? '0',
      status: data['status'] ?? 'Pending',
      division_name: data['division_name'] ?? '',
      date: data['date'] ?? '',
      month_name: data['month_name'] ?? '',
      rejection_reason: data['rejection_reason'] ?? '',
      imange_path: data['imange_path'] ?? '',
    );
  }
}
