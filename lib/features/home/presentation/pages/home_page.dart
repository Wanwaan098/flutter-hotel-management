import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bootstrap/flutter_bootstrap.dart';
import 'package:go_router/go_router.dart';
import 'package:ngoctran/core/routing/app_routes.dart';
import 'package:ngoctran/features/rooms/data/models/room_model.dart';
import 'package:ngoctran/features/rooms/data/datasources/room_remote_datasource.dart';
import 'package:ngoctran/core/presentation/widget/app_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final roomDataSource = RoomRemoteDataSource(FirebaseFirestore.instance);
  final user = FirebaseAuth.instance.currentUser;

  String searchQuery = '';
  String? selectedLoaiPhong;
  double? minPrice;
  double? maxPrice;

  @override
  Widget build(BuildContext context) {
    bootstrapGridParameters(gutterSize: 10);

    return Scaffold(
      backgroundColor: const Color(0xfffafafa),
      appBar: AppBar(
        title: const Text(
          'Trang chủ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFECA7E9),
        elevation: 0,
        centerTitle: true,
      ),

      // 🟣 Sử dụng Drawer mới (AppDrawer)
      drawer: AppDrawer(user: user),

      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm phòng...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.purple,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) =>
                        setState(() => searchQuery = value.toLowerCase()),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(
                    Icons.filter_list,
                    color: Colors.purple,
                    size: 30,
                  ),
                  onPressed: () => _showFilterDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Expanded(
              child: StreamBuilder<List<RoomModel>>(
                stream: roomDataSource.getRoomsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('Hiện chưa có phòng nào được đăng.'),
                    );
                  }

                  // 🔍 Lọc dữ liệu
                  final rooms = snapshot.data!.where((room) {
                    if (room.tinhTrang == 'Đã đặt')
                      return false; // 🔥 Ẩn phòng đã đặt
                    final matchSearch =
                        room.loaiPhong.toLowerCase().contains(searchQuery) ||
                        room.soPhong.toLowerCase().contains(searchQuery) ||
                        room.moTa.toLowerCase().contains(searchQuery);
                    final matchLoai =
                        selectedLoaiPhong == null ||
                        room.loaiPhong == selectedLoaiPhong;
                    final matchMin =
                        minPrice == null || room.giaDem >= minPrice!;
                    final matchMax =
                        maxPrice == null || room.giaDem <= maxPrice!;
                    return matchSearch && matchLoai && matchMin && matchMax;
                  }).toList();

                  if (rooms.isEmpty) {
                    return const Center(
                      child: Text('Không tìm thấy phòng phù hợp.'),
                    );
                  }

                  return SingleChildScrollView(
                    child: BootstrapContainer(
                      fluid: true,
                      children: [
                        BootstrapRow(
                          children: rooms
                              .map(
                                (room) => BootstrapCol(
                                  sizes: 'col-12 col-sm-6 col-md-4',
                                  child: _buildRoomCard(context, room),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(BuildContext context, RoomModel room) {
    return GestureDetector(
      onTap: () =>
          context.push('${AppRoutes.roomDetail}/${room.id}', extra: room),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 2,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    room.anhPhong,
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: InkWell(
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã thêm vào danh sách yêu thích 💖'),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.favorite_border,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phòng ${room.soPhong} - ${room.loaiPhong}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    room.moTa,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${room.giaDem.toStringAsFixed(0)} VNĐ/đêm',
                        style: const TextStyle(
                          color: Colors.purpleAccent,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_city,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Tầng ${room.tang}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
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

  // 🧩 Bộ lọc
  void _showFilterDialog(BuildContext context) {
    final loaiPhongOptions = ['Standard', 'Deluxe', 'VIP', 'Suite'];
    final minController = TextEditingController(
      text: minPrice?.toString() ?? '',
    );
    final maxController = TextEditingController(
      text: maxPrice?.toString() ?? '',
    );

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          runSpacing: 16,
          children: [
            const Center(
              child: Text(
                'Bộ lọc phòng',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Loại phòng',
                border: OutlineInputBorder(),
              ),
              initialValue: selectedLoaiPhong,
              items: [
                const DropdownMenuItem(value: null, child: Text('Tất cả')),
                ...loaiPhongOptions
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
              ],
              onChanged: (value) => setState(() => selectedLoaiPhong = value),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Giá tối thiểu',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: maxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Giá tối đa',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  minPrice = double.tryParse(minController.text);
                  maxPrice = double.tryParse(maxController.text);
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                minimumSize: const Size(double.infinity, 45),
              ),
              child: const Text(
                'Áp dụng',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
