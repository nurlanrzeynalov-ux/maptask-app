import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'models.dart';

class BiddingScreen extends StatefulWidget {
  final TaskItem task;
  const BiddingScreen({super.key, required this.task});
  @override
  State<BiddingScreen> createState() => _BiddingScreenState();
}

class _BiddingScreenState extends State<BiddingScreen> {
  final _priceController = TextEditingController();
  final _timeController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(title: const Text("Təklif Göndər", style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.white, elevation: 0, foregroundColor: Colors.black),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [Icon(widget.task.icon, color: widget.task.color, size: 20), const SizedBox(width: 8), Text(getCategoryName(widget.task.category), style: TextStyle(color: widget.task.color, fontWeight: FontWeight.bold, fontSize: 13))]),
                  const SizedBox(height: 12),
                  Text(widget.task.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                  Row(children: [const Icon(Icons.account_balance_wallet, size: 18, color: Colors.green), const SizedBox(width: 8), Text("Büdcə: ${widget.task.budget} AZN", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15))]),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text("Sizin Təklifiniz", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 15),
            TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Məbləğ (AZN)", prefixIcon: const Icon(Icons.payments_outlined, color: Colors.black54), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            const SizedBox(height: 15),
            TextField(controller: _timeController, decoration: InputDecoration(labelText: "İcra müddəti (məs: 2 saata)", prefixIcon: const Icon(Icons.access_time, color: Colors.black54), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            const SizedBox(height: 15),
            TextField(controller: _noteController, maxLines: 3, decoration: InputDecoration(labelText: "Müştəriyə qeydiniz (istəyə bağlı)", alignLabelWithHint: true, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            const SizedBox(height: 30),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () { Navigator.pop(context, true); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎉 Təklifiniz uğurla göndərildi!'), backgroundColor: Colors.green)); }, child: const Text("Təklifi Göndər", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))
          ],
        ),
      ),
    );
  }
}

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});
  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _t = TextEditingController(), _d = TextEditingController(), _b = TextEditingController();
  final _dropoffController = TextEditingController(); 
  final _roomsController = TextEditingController(); 
  final _areaController = TextEditingController(); 
  
  LatLng? _dropoffLatLng;
  TaskCategory _cat = TaskCategory.delivery;
  double _rad = 5.0;

  // YENİ: Seçilmiş faylları (şəkil/video) tutan siyahı
  final List<String> _selectedMedia = [];

  void _pickDropoffLocation() async {
    final LatLng? picked = await Navigator.push(context, MaterialPageRoute(builder: (_) => const LocationPickerScreen()));
    if (picked != null) {
      setState(() {
        _dropoffLatLng = picked;
        _dropoffController.text = "${picked.latitude.toStringAsFixed(4)}, ${picked.longitude.toStringAsFixed(4)}";
      });
    }
  }

  // YENİ: Telefonun qalereyasından şəkil/video seçilməsini simulyasiya edir
  void _pickMedia() {
    setState(() {
      _selectedMedia.add('https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/200'); // Test üçün saxta şəkil
    });
  }

  IconData _getIcon(TaskCategory c) => switch(c) {
    TaskCategory.delivery => Icons.local_shipping, TaskCategory.repair => Icons.plumbing,
    TaskCategory.auto => Icons.car_crash, TaskCategory.autoParts => Icons.settings_suggest,
    TaskCategory.cleaning => Icons.cleaning_services, TaskCategory.helper => Icons.fitness_center,
    TaskCategory.tech => Icons.computer, TaskCategory.photoDrone => Icons.camera_alt,
    TaskCategory.shopping => Icons.shopping_cart, TaskCategory.office => Icons.business_center,
    TaskCategory.petCare => Icons.pets, TaskCategory.beauty => Icons.face_retouching_natural,
    TaskCategory.realEstate => Icons.apartment, TaskCategory.sales => Icons.sell,
    TaskCategory.needs => Icons.volunteer_activism, TaskCategory.other => Icons.work,
  };

  Color _getColor(TaskCategory c) => switch(c) {
    TaskCategory.delivery => Colors.blue, TaskCategory.repair => Colors.orange,
    TaskCategory.auto => Colors.red, TaskCategory.autoParts => Colors.redAccent,
    TaskCategory.cleaning => Colors.teal, TaskCategory.helper => Colors.brown,
    TaskCategory.tech => Colors.deepPurple, TaskCategory.photoDrone => Colors.indigo,
    TaskCategory.shopping => Colors.green, TaskCategory.office => Colors.blueGrey,
    TaskCategory.petCare => Colors.amber, TaskCategory.beauty => Colors.pink,
    TaskCategory.realEstate => Colors.cyan, TaskCategory.sales => Colors.deepOrange,
    TaskCategory.needs => Colors.pinkAccent, TaskCategory.other => Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(title: const Text('Yeni İş Yarat', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Kateqoriya Seçin", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 10, 
              children: TaskCategory.values.map((category) {
                final isSelected = _cat == category;
                final color = _getColor(category);
                return GestureDetector(
                  onTap: () => setState(() => _cat = category),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: isSelected ? color : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? color : Colors.grey.shade300), boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))] : []),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(_getIcon(category), size: 16, color: isSelected ? Colors.white : color), const SizedBox(width: 6), Text(getCategoryName(category).split(" / ").first, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? Colors.white : Colors.black87))]),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 30),
            const Text("İşin Detalları", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 12),
            TextField(controller: _t, decoration: InputDecoration(labelText: 'Başlıq', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
            const SizedBox(height: 12),

            if (_cat == TaskCategory.delivery) ...[
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)), child: const Row(children: [Icon(Icons.my_location, color: Colors.blue), SizedBox(width: 10), Expanded(child: Text("📍 Haradan: İşin xəritədə qoyulduğu ünvan", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 13)))])),
              const SizedBox(height: 12),
              TextField(controller: _dropoffController, readOnly: true, onTap: _pickDropoffLocation, decoration: InputDecoration(labelText: '🎯 Hara çatdırılacaq? (Xəritədən seç)', filled: true, fillColor: Colors.white, suffixIcon: const Icon(Icons.map, color: Colors.blue), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
              const SizedBox(height: 12),
              TextField(controller: _d, maxLines: 2, decoration: InputDecoration(labelText: 'Əlavə qeyd', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
            ] else if (_cat == TaskCategory.realEstate) ...[
               Row(
                 children: [
                   Expanded(child: TextField(controller: _roomsController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Otaq sayı', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)))),
                   const SizedBox(width: 12),
                   Expanded(child: TextField(controller: _areaController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Sahəsi (m²)', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)))),
                 ],
               ),
               const SizedBox(height: 12),
               TextField(controller: _d, maxLines: 2, decoration: InputDecoration(labelText: 'Əlavə məlumat', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
            ] else ...[
              TextField(controller: _d, maxLines: 3, decoration: InputDecoration(labelText: 'Məlumat', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
            ],

            const SizedBox(height: 12),
            TextField(controller: _b, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Büdcə (AZN)', prefixIcon: const Icon(Icons.account_balance_wallet, color: Colors.green), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
            
            // --- YENİ BÖLMƏ: Media (Şəkil/Video) Əlavə Et ---
            const SizedBox(height: 20),
            const Text("Media (Şəkil və ya Video)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Əlavə et düyməsi
                  GestureDetector(
                    onTap: _pickMedia,
                    child: Container(
                      width: 80, height: 80,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid, width: 2)),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate, color: Colors.grey.shade600), const SizedBox(height: 4), Text("Əlavə et", style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold))]),
                    ),
                  ),
                  // Seçilmiş şəkillər/videolar
                  ..._selectedMedia.map((url) => Stack(
                    children: [
                      Container(
                        width: 80, height: 80,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)),
                      ),
                      Positioned(
                        top: 4, right: 16,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedMedia.remove(url)),
                          child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle), child: const Icon(Icons.close, size: 14, color: Colors.white)),
                        ),
                      )
                    ],
                  )).toList(),
                ],
              ),
            ),
            // ------------------------------------------------

            const SizedBox(height: 25), 
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Görünmə sahəsi:", style: TextStyle(fontWeight: FontWeight.bold)), Text("${_rad.toInt()} km", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))]),
            Slider(value: _rad, min: 1, max: 20, divisions: 19, activeColor: Colors.black, inactiveColor: Colors.grey.shade300, onChanged: (v) => setState(() => _rad = v)),
            
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55), backgroundColor: Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                Map<String, String>? extras;
                if (_cat == TaskCategory.realEstate) {
                  extras = {'Otaq': _roomsController.text, 'Sahə': '${_areaController.text} m²'};
                }
                Navigator.pop(context, {
                  'title': _t.text, 'desc': _d.text, 'budget': _b.text, 'cat': _cat, 'rad': _rad, 
                  'media': _selectedMedia.isEmpty ? null : _selectedMedia, // Mediaları göndəririk
                  'dropoff': _dropoffLatLng, 'extras': extras
                });
              },
              child: const Text("Təsdiqlə", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
            )
          ]
        )
      ),
    );
  }
}

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});
  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  final LatLng _initialCenter = const LatLng(40.4093, 49.8671); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Çatdırılma Ünvanını Seç', style: TextStyle(color: Colors.black, fontSize: 16)), backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
      body: Stack(
        children: [
          FlutterMap(mapController: _mapController, options: MapOptions(initialCenter: _initialCenter, initialZoom: 14), children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png')]),
          const Center(child: Padding(padding: EdgeInsets.only(bottom: 40.0), child: Icon(Icons.location_on, size: 50, color: Colors.blue))),
          Positioned(bottom: 20, left: 20, right: 20, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.black, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () => Navigator.pop(context, _mapController.camera.center), child: const Text('Bu Ünvanı Təsdiqlə', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold))))
        ],
      ),
    );
  }
}