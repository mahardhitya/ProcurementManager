class FiscalYearsModel {
   final String id;
   final String year;
   final String status;

   FiscalYearsModel({
      required this.id,
      required this.year,
      required this.status
   });

   factory FiscalYearsModel.fromJson(Map data) {
      return FiscalYearsModel(
         id: data['id'] ?? data['_id'] ?? '',
         year: data['year'] ?? '',
         status: data['status'] ?? ''
      );
   }
}