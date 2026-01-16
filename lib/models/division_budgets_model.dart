class DivisionBudgetsModel {
  final String id;
  final String divisionName;
  final String allocatedBudget;
  final String monthName;
  final String year;
  final String createdAt;

  DivisionBudgetsModel({
    required this.id,
    required this.divisionName,
    required this.allocatedBudget,
    this.monthName = '',
    this.year = '',
    this.createdAt = '',
  });

  factory DivisionBudgetsModel.fromJson(Map data) {
    return DivisionBudgetsModel(
      id: data['id'] ?? data['_id'] ?? '',
      divisionName: data['division_name'] ?? '',
      allocatedBudget: data['allocated_budget'] ?? '0',
      monthName: data['month_name'] ?? '',
      year: data['year'] ?? '',
      createdAt: data['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'division_name': divisionName,
      'allocated_budget': allocatedBudget,
      'month_name': monthName,
      'year': year,
      'created_at': createdAt,
    };
  }
}
