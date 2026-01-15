import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert'; // Untuk jsonDecode
import 'package:intl/intl.dart'; // Untuk format tanggal
import 'package:shared_preferences/shared_preferences.dart'; // Untuk session user
import '../../../core/restapi.dart'; // Import DataService
import '../../../core/config.dart'; // Import AppConfig

class AddRequestPage extends StatefulWidget {
  final String monthName; // Kita butuh ini untuk menandai data masuk bulan apa
  final String userDivision; // Divisi user yang login

  const AddRequestPage({
    super.key,
    required this.monthName,
    required this.userDivision,
  });

  @override
  State<AddRequestPage> createState() => _AddRequestPageState();
}

class _AddRequestPageState extends State<AddRequestPage> {
  // Global Key untuk Validasi Form
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  int _totalPrice = 0;
  bool _isLoading = false;
  int _selectedQuantity = 1;
  File? _imageFile;
  XFile? _pickedImage; // Untuk web compatibility
  final ImagePicker _picker = ImagePicker();

  // Dropdown options untuk quantity
  final List<int> _quantityOptions = List.generate(50, (index) => index + 1);

  // Real-time calculation
  void _calculateTotal() {
    int price = int.tryParse(_priceController.text.replaceAll('.', '')) ?? 0;
    setState(() {
      _totalPrice = _selectedQuantity * price;
    });
  }

  // Fungsi untuk mengambil foto
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _pickedImage = pickedFile;
          if (!kIsWeb) {
            _imageFile = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // Langsung buka galeri untuk pilih foto
  void _showImageSourcePicker() {
    // Langsung buka galeri tanpa menampilkan dialog pilihan
    _pickImage(ImageSource.gallery);
  }

  // Format angka dengan pemisah ribuan
  String _formatNumber(String value) {
    if (value.isEmpty) return '';
    value = value.replaceAll('.', '');
    final number = int.tryParse(value);
    if (number == null) return value;
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  // CORE LOGIC: Save to GoCloud (API Mode)
  Future<void> _submitToCloud() async {
    if (!_formKey.currentState!.validate()) return;

    // Validasi foto wajib diupload
    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mohon upload foto barang terlebih dahulu"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Ambil data user dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      String userId = prefs.getString('user_id') ?? 'USER-GUEST';
      String divisionName =
          prefs.getString('division_name') ?? widget.userDivision;

      // Panggil API untuk insert procurement request
      final dataService = DataService();

      print('========== INSERT DEBUG ==========');
      print('AppID: ${AppConfig.appid}');
      print('Month Name: ${widget.monthName}');
      print('User ID: $userId');
      print('Division Name: $divisionName');

      String response = await dataService.insertProcurementRequests(
        AppConfig.appid, // App ID dari config
        widget.monthName, // monthly_budget_id (simpan nama bulan)
        userId, // User ID dari session
        _itemController.text, // item_name
        _selectedQuantity.toString(), // quantity
        _priceController.text.replaceAll(
          '.',
          '',
        ), // price (hapus pemisah ribuan)
        _totalPrice.toString(), // total_price
        'Pending', // Status default
        divisionName, // division_name dari session
        DateFormat('yyyy-MM-dd').format(DateTime.now()), // date
        widget.monthName, // month_name
        _pickedImage!.path, // image_path
      );

      print('Insert Response: $response');
      print('========== END INSERT DEBUG ==========');

      // Parsing response
      var decodedData = jsonDecode(response);

      // Handle response format: {"data": [...]} atau langsung [...]
      List insertedData = [];
      if (decodedData is Map && decodedData['data'] != null) {
        insertedData = decodedData['data'] as List;
      } else if (decodedData is List) {
        insertedData = decodedData;
      }

      if (mounted) {
        setState(() => _isLoading = false);

        // Validasi response dari GoCloud (Biasanya return List/Map yg berisi ID)
        if (insertedData.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Pengajuan berhasil dikirim!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Kembali & trigger refresh
        } else {
          throw Exception("Gagal menyimpan: $response");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _priceController.addListener(_calculateTotal);
  }

  @override
  void dispose() {
    _priceController.dispose();
    _itemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text("${widget.monthName}"),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1565C0),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.add_shopping_cart,
                    size: 60,
                    color: Colors.white70,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Pengajuan Baru",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Bulan ${widget.monthName} 2025",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            // Form Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama Barang Card
                    _buildSectionCard(
                      title: "Informasi Barang",
                      icon: Icons.inventory_2_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputLabel("Nama Barang", isRequired: true),
                          TextFormField(
                            controller: _itemController,
                            validator: (val) =>
                                val!.isEmpty ? "Nama barang wajib diisi" : null,
                            decoration: _inputDecor(
                              "Contoh: Laptop, Kertas A4, Mouse",
                              icon: Icons.shopping_bag_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quantity & Price Card
                    _buildSectionCard(
                      title: "Detail Harga",
                      icon: Icons.monetization_on_outlined,
                      child: Column(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel(
                                "Jumlah (Qty)",
                                isRequired: true,
                              ),
                              DropdownButtonFormField<int>(
                                value: _selectedQuantity,
                                isExpanded: true,
                                decoration: _inputDecor(
                                  "Pilih jumlah",
                                  icon: Icons.format_list_numbered,
                                ),
                                items: _quantityOptions.map((qty) {
                                  return DropdownMenuItem(
                                    value: qty,
                                    child: Text("$qty pcs"),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedQuantity = value!;
                                    _calculateTotal();
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel(
                                "Harga Satuan",
                                isRequired: true,
                              ),
                              TextFormField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (val) =>
                                    val!.isEmpty ? "Wajib isi" : null,
                                decoration: _inputDecor(
                                  "0",
                                  icon: Icons.attach_money,
                                  prefix: "Rp ",
                                ),
                                onChanged: (value) {
                                  final formatted = _formatNumber(value);
                                  if (formatted != value) {
                                    _priceController.value = TextEditingValue(
                                      text: formatted,
                                      selection: TextSelection.collapsed(
                                        offset: formatted.length,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Upload Foto Card
                    _buildSectionCard(
                      title: "Foto Barang",
                      icon: Icons.camera_alt_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputLabel(
                            "Upload Foto Validasi",
                            isRequired: true,
                          ),
                          const Text(
                            "Foto barang rusak atau yang akan diajukan",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _showImageSourcePicker,
                            child: Container(
                              height: 180,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _pickedImage == null
                                      ? Colors.grey.shade300
                                      : Colors.blue,
                                  width: 2,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: _pickedImage == null
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_a_photo,
                                          size: 50,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          "Tap untuk pilih foto",
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Dari Galeri",
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child: kIsWeb
                                              ? Image.network(
                                                  _pickedImage!.path,
                                                  width: double.infinity,
                                                  height: 180,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      width: double.infinity,
                                                      height: 180,
                                                      color:
                                                          Colors.grey.shade200,
                                                      child: const Center(
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .check_circle,
                                                              size: 50,
                                                              color:
                                                                  Colors.green,
                                                            ),
                                                            SizedBox(height: 8),
                                                            Text(
                                                              "Foto berhasil dipilih",
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .green,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                )
                                              : Image.file(
                                                  _imageFile!,
                                                  width: double.infinity,
                                                  height: 180,
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _imageFile = null;
                                                _pickedImage = null;
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Total Estimasi Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade50, Colors.blue.shade100],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calculate_outlined,
                                color: Colors.blue.shade700,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "Total Estimasi",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Rp ${_formatNumber(_totalPrice.toString())}",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "$_selectedQuantity pcs × Rp ${_formatNumber(_priceController.text)}",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitToCloud,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 3,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    "KIRIM PENGAJUAN",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widgets
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecor(String hint, {String? prefix, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefix,
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildInputLabel(String label, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          if (isRequired)
            const Text(" *", style: TextStyle(color: Colors.red, fontSize: 14)),
        ],
      ),
    );
  }
}
