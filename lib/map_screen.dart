import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(40.4093, 49.8671), // Bakı
    zoom: 14.0,
  );

  int _selectedCategoryIndex = 0;
  final List<String> _categories = ["Hamısı", "Kuryer", "Təmizlik", "Təmir", "Daşınma"];
  
  final Set<Marker> _markers = {};
  
  // XƏRİTƏNİN MƏRKƏZ KOORDİNATI (Müştəri xəritəni sürüşdürdükcə bu yenilənəcək)
  LatLng _currentCenter = _initialPosition.target;

  @override
  void initState() {
    super.initState();
    _listenToTasks(); 
  }

  void _listenToTasks() {
    FirebaseFirestore.instance.collection('tasks').snapshots().listen((snapshot) {
      final Set<Marker> newMarkers = {};
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final double lat = (data['lat'] as num).toDouble();
          final double lng = (data['lng'] as num).toDouble();
          final String title = data['title']?.toString() ?? 'Sifariş';
          final String desc = data['desc']?.toString() ?? 'Məlumat yoxdur';
          final String price = data['price']?.toString() ?? '0 ₼';

          newMarkers.add(
            Marker(
              markerId: MarkerId(doc.id),
              position: LatLng(lat, lng),
              onTap: () => _showTaskDetails(title, desc, price),
            ),
          );
        } catch (e) {
          debugPrint("XƏTA: Pin oxunmadı - $e");
        }
      }
      
      if (mounted) {
        setState(() {
          _markers.clear();
          _markers.addAll(newMarkers);
        });
      }
    });
  }

  Future<void> _addNewTask(String title, String desc, String price, LatLng location) async {
    await FirebaseFirestore.instance.collection('tasks').add({
      'title': title,
      'desc': desc,
      'price': price,
      'lat': location.latitude,
      'lng': location.longitude,
      'createdAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sifariş uğurla bazaya yazıldı!'), backgroundColor: Colors.green),
    );
  }

  void _showCreateTaskDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Yeni Sifariş", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Başlıq (məs: Kuryer)")),
            TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Qiymət (₼)")),
            TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Məlumat")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Ləğv et", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () {
              if (titleCtrl.text.isNotEmpty) {
                // Sifarişi birbaşa ekranın mərkəz koordinatına göndəririk
                _addNewTask(titleCtrl.text, descCtrl.text, "${priceCtrl.text} ₼", _currentCenter);
                Navigator.pop(context);
              }
            },
            child: const Text("Yarat", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showTaskDetails(String title, String desc, String price) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
                    child: Text(price, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(desc, style: TextStyle(color: Colors.grey.shade700, fontSize: 15, height: 1.4)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sifariş qəbul edildi!"), backgroundColor: Colors.black));
                  },
                  child: const Text("Qəbul Et", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            markers: _markers,
            
            // XƏRİTƏNİ SÜRÜŞDÜRDÜKCƏ MƏRKƏZ KOORDİNATI YENİLƏNİR
            onCameraMove: (CameraPosition position) {
              _currentCenter = position.target;
            },
          ),
          
          // EKRANIN TƏN ORTASINDA DAYANAN SABİT MAVİ PİN
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40.0), // Pinin ucu tam mərkəzə düşsün deyə yuxarı qaldırırıq
              child: Icon(Icons.location_on, size: 55, color: Colors.blueAccent),
            ),
          ),
          
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedCategoryIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategoryIndex = index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Text(
                        _categories[index],
                        style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.black,
        elevation: 10,
        onPressed: _showCreateTaskDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Yeni Sifariş", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}