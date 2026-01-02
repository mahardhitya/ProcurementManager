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

   ProcurementRequestsModel({
      required this.id,
      required this.monthly_budget_id,
      required this.user_id,
      required this.item_name,
      required this.quantity,
      required this.price,
      required this.total_price,
      required this.status,
      required this.division_name
   });

   factory ProcurementRequestsModel.fromJson(Map data) {
      return ProcurementRequestsModel(
         id: data['_id'],
         monthly_budget_id: data['monthly_budget_id'],
         user_id: data['user_id'],
         item_name: data['item_name'],
         quantity: data['quantity'],
         price: data['price'],
         total_price: data['total_price'],
         status: data['status'],
         division_name: data['division_name']
      );
   }
}