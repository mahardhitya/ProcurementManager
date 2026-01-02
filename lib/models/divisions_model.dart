class DivisionsModel {
   final String id;
   final String name;
   final String code;

   DivisionsModel({
      required this.id,
      required this.name,
      required this.code
   });

   factory DivisionsModel.fromJson(Map data) {
      return DivisionsModel(
         id: data['_id'],
         name: data['name'],
         code: data['code']
      );
   }
}