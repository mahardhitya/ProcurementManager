class MonthlyBudgetsModel {
  final String id;
  final String fiscal_year_id;
  final String month_name;
  final String month_index;
  final String total_revenue;
  final String total_expense;

  MonthlyBudgetsModel({
    required this.id,
    required this.fiscal_year_id,
    required this.month_name,
    required this.month_index,
    required this.total_revenue,
    required this.total_expense,
  });

  factory MonthlyBudgetsModel.fromJson(Map data) {
    return MonthlyBudgetsModel(
      id: data['id'] ?? data['_id'] ?? '',
      fiscal_year_id: data['fiscal_year_id'] ?? '',
      month_name: data['month_name'] ?? '',
      month_index: data['month_index'] ?? '0',
      total_revenue: data['total_revenue'] ?? '0',
      total_expense: data['total_expense'] ?? '0',
    );
  }
}
