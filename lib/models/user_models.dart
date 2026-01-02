class UsersModel {
   final String? id; // Ubah jadi nullable (?) karena saat register belum punya ID
   final String name;
   final String email;
   final String password;
   final String role;
   final String division_id;

   UsersModel({
      this.id, // Hapus required karena ID bisa kosong
      required this.name,
      required this.email,
      required this.password,
      required this.role,
      required this.division_id
   });

   factory UsersModel.fromJson(Map data) {
      return UsersModel(
         id: data['_id'],
         name: data['name'],
         email: data['email'],
         password: data['password'],
         role: data['role'],
         division_id: data['division_id']
      );
   }

   Map<String, dynamic> toJson() {
     return {
       "name": name,
       "email": email,
       "password": password,
       "role": role,
       "division_id": division_id,
     };
   }
}