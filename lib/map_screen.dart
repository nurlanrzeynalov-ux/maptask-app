import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart'; 
import 'dart:math' as math;
import 'chat_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController; 

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(40.4093, 49.8671),
    zoom: 14.0,
  );

  int _selectedCategoryIndex = 0;
  final List<String> _categories = ["Hamısı", "Kuryer", "Təmizlik", "Təmir", "Daşınma"];
  
  final Set<Marker> _markers = {};
  LatLng _currentCenter = _initialPosition.target;

  @override
  void initState() {
    super.initState();
    _getUserLocation(); 
    _listenToTasks(); 
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return; 

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    LatLng realLatLng = LatLng(position.latitude, position.longitude);

    if (mounted) {
      setState(() {
        _currentCenter = realLatLng; 
      });

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: realLatLng, zoom: 15.0),
        ),
      );
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; 
    final a = 0.5 - math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) *
        (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a)); 
  }

  void _listenToTasks() {
    // 1. HAZIRDA SİSTEMƏ GİRƏN İSTİFADƏÇİNİN ID-SİNİ ALIRIQ
    final currentUserId = FirebaseAuth.instance.currentUser?.uid; 

    FirebaseFirestore.instance
        .collection('tasks')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .listen((snapshot) {
      final Set<Marker> newMarkers = {};
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          
          // 2. SİFARİŞİ YARADANIN ID-SİNİ BAZADAN OXUYURUQ
          final String creatorId = data['creatorId']?.toString() ?? ''; 

          // 3. ƏSAS ŞƏRT: ƏGƏR SİFARİŞİ YARADAN MƏNƏMSƏ, ONU XƏRİTƏYƏ QOYMA VƏ NÖVBƏTİNƏ KEÇ!
          if (creatorId == currentUserId) {
            continue; 
          }

          final double lat = (data['lat'] as num).toDouble();
          final double lng = (data['lng'] as num).toDouble();
          final String title = data['title']?.toString() ?? 'Sifariş';
          final String desc = data['desc']?.toString() ?? 'Məlumat yoxdur';
          final String price = data['price']?.toString() ?? '0 ₼';
          
          final String taskId = doc.id; 

          final double distance = _calculateDistance(
            _currentCenter.latitude, 
            _currentCenter.longitude, 
            lat, 
            lng
          );

          if (distance <= 5.0) { 
            newMarkers.add(
              Marker(
                markerId: MarkerId(taskId),
                position: LatLng(lat, lng),
                onTap: () => _showTaskDetails(taskId, title, desc, price),
              ),
            );
          }
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('tasks').add({
      'title': title,
      'desc': desc,
      'price': price,
      'lat': location.latitude,
      'lng': location.longitude,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'active', 
      'creatorId': user.uid, 
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

  void _showOfferDialog(String taskId, String title, String originalPrice) {
    final priceCtrl = TextEditingController(text: originalPrice.replaceAll(RegExp(r'[^0-9]'), '')); 
    final msgCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Təklifini Göndər", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Sifariş: $title", style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 16),
            TextField(
              controller: priceCtrl, 
              keyboardType: TextInputType.number, 
              decoration: const InputDecoration(
                labelText: "Sənin Qiymətin (₼)", 
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payments_outlined),
              )
            ),
            const SizedBox(height: 12),
            TextField(
              controller: msgCtrl, 
              maxLines: 3, 
              decoration: const InputDecoration(
                labelText: "Müştəriyə mesajın...", 
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              )
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Ləğv et", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () async {
              if (priceCtrl.text.isNotEmpty && msgCtrl.text.isNotEmpty) {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                try {
                  await FirebaseFirestore.instance
                      .collection('tasks')
                      .doc(taskId)
                      .collection('offers')
                      .add({
                    'courierId': user.uid, 
                    'offerPrice': priceCtrl.text,
                    'message': msgCtrl.text,
                    'status': 'pending', 
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  if (mounted) {
                    Navigator.pop(context); 
                    Navigator.pop(context); 
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("✅ Təklifiniz göndərildi! Müştəri qəbul edənədək gözləyin."), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Xəta baş verdi, interneti yoxlayıb yenidən cəhd edin.")));
                }
              }
            },
            child: const Text("Təklif Göndər", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showTaskDetails(String taskId, String title, String desc, String price) {
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () => _showOfferDialog(taskId, title, price),
                  child: const Text("Təklif Göndər", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
            onMapCreated: (controller) {
              _mapController = controller; 
            },
            onCameraMove: (CameraPosition position) {
              _currentCenter = position.target;
              _listenToTasks(); 
            },
          ),
          
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40.0), 
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
          
          Positioned(
            bottom: 100, 
            right: 16,
            child: FloatingActionButton(
              heroTag: "myLocationBtn", 
              backgroundColor: Colors.white,
              elevation: 5,
              onPressed: () {
                _getUserLocation(); 
              },
              child: const Icon(Icons.my_location, color: Colors.black, size: 28),
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