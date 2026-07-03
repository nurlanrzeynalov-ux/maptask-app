// Kopyalamaq üçün sağ yuxarıdakı "Copy" düyməsinə bas:
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const MaterialApp(home: MapScreen(), debugShowCheckedModeBanner: false));

enum TaskCategory { repair, delivery, photo, other }

String getCategoryName(TaskCategory cat) {
  switch(cat) {
    case TaskCategory.repair: return "Təmir";
    case TaskCategory.delivery: return "Çatdırılma";
    case TaskCategory.photo: return "Foto";
    case TaskCategory.other: return "Digər";
  }
}

class TaskItem {
  final String title, description, budget;
  final LatLng location;
  final TaskCategory category;
  final double radius;
  final String? imagePath;

  TaskItem({required this.title, required this.description, required this.budget, 
            required this.location, required this.category, required this.radius, this.imagePath});

  Color get color => switch(category) {
        TaskCategory.repair => Colors.orange,
        TaskCategory.delivery => Colors.blue,
        TaskCategory.photo => Colors.purple,
        TaskCategory.other => Colors.grey,
      };

  IconData get icon => switch(category) {
        TaskCategory.repair => Icons.plumbing,
        TaskCategory.delivery => Icons.local_shipping,
        TaskCategory.photo => Icons.camera_alt,
        TaskCategory.other => Icons.work,
      };
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<TaskItem> tasks = [];
  final MapController _mapController = MapController();
  final LatLng _defaultLocation = const LatLng(40.4093, 49.8671);

  Set<TaskCategory> _selectedCategories = TaskCategory.values.toSet();

  void _createNewTask(LatLng point) async {
    final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTaskScreen()));
    if (res != null && res is Map<String, dynamic>) {
      setState(() {
        tasks.add(TaskItem(
          title: res['title'], description: res['desc'], budget: res['budget'],
          location: point, category: res['cat'], radius: res['rad'], imagePath: res['image']
        ));
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ İş xəritəyə uğurla əlavə edildi! (Görmək üçün xəritəni sürüşdürün)'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            bool isAllSelected = _selectedCategories.length == TaskCategory.values.length;

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20, 
                  top: 20, left: 20, right: 20
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Hansı işləri görmək istəyirsiniz?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    const Divider(),
                    CheckboxListTile(
                      title: const Text("Hamısını seç", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                      activeColor: Colors.blue,
                      value: isAllSelected,
                      onChanged: (bool? value) {
                        setModalState(() {
                          if (value == true) {
                            _selectedCategories.addAll(TaskCategory.values);
                          } else {
                            _selectedCategories.clear();
                          }
                        });
                        setState(() {}); 
                      },
                    ),
                    const Divider(),
                    ...TaskCategory.values.map((cat) {
                      final isChecked = _selectedCategories.contains(cat);
                      return CheckboxListTile(
                        title: Text(getCategoryName(cat), style: const TextStyle(fontSize: 16)),
                        activeColor: Colors.black,
                        value: isChecked,
                        onChanged: (bool? value) {
                          setModalState(() {
                            if (value == true) {
                              _selectedCategories.add(cat);
                            } else {
                              _selectedCategories.remove(cat);
                            }
                          });
                          setState(() {}); 
                        },
                      );
                    }),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("Tətbiq Et", style: TextStyle(fontSize: 16)),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedTasks = tasks.where((t) => _selectedCategories.contains(t.category)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('MapTask Radar', style: TextStyle(color: Colors.black)), backgroundColor: Colors.white, elevation: 0),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultLocation, 
              initialZoom: 13,
            ),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
              CircleLayer(circles: displayedTasks.map((t) => CircleMarker(
                point: t.location, radius: t.radius * 1000, useRadiusInMeter: true,
                color: t.color.withOpacity(0.2), borderColor: t.color, borderStrokeWidth: 2,
              )).toList()),
              MarkerLayer(markers: displayedTasks.map((t) => Marker(
                point: t.location,
                width: 50, height: 50,
                child: GestureDetector(
                  onTap: () => showModalBottomSheet(
                    context: context, 
                    isScrollControlled: true, 
                    builder: (_) => SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom + 20, 
                          top: 20, left: 20, right: 20
                        ),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(t.icon, size: 50, color: t.color),
                          Text(t.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          Text("Sifarişçinin Büdcəsi: ${t.budget} AZN", style: const TextStyle(color: Colors.green, fontSize: 16)),
                          const SizedBox(height: 10),
                          Text(t.description),
                          const SizedBox(height: 15),
                          if (t.imagePath != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: kIsWeb 
                                  ? Image.network(t.imagePath!, height: 150, width: double.infinity, fit: BoxFit.cover)
                                  : Image.file(File(t.imagePath!), height: 150, width: double.infinity, fit: BoxFit.cover),
                            ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                              onPressed: () {
                                // YENİ: Alt paneli bağlayıb Təklif ekranına keçirik
                                Navigator.pop(context); 
                                Navigator.push(context, MaterialPageRoute(builder: (_) => BiddingScreen(task: t))).then((result) {
                                  if (result == true && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('🎉 Təklifiniz sifarişçiyə göndərildi!'),
                                        backgroundColor: Colors.blueAccent,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                });
                              }, 
                              icon: const Icon(Icons.handshake), 
                              label: const Text('Təklif Göndər', style: TextStyle(fontSize: 16))
                            ),
                          )
                        ]),
                      ),
                    ),
                  ),
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                    child: Icon(t.icon, color: t.color, size: 30),
                  ),
                ),
              )).toList()),
            ],
          ),

          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40.0),
              child: Icon(Icons.location_on, size: 50, color: Colors.black87),
            ),
          ),

          Positioned(
            top: 16, left: 16,
            child: FloatingActionButton.extended(
              heroTag: "btn_filter",
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              icon: const Icon(Icons.filter_list),
              label: Text(
                _selectedCategories.length == TaskCategory.values.length ? "Filtr" : "Filtr (${_selectedCategories.length})", 
                style: const TextStyle(fontWeight: FontWeight.bold)
              ),
              onPressed: _showFilterModal,
            ),
          ),

          Positioned(
            right: 16,
            bottom: 100, 
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: "btn_center", backgroundColor: Colors.white,
                  onPressed: () => _mapController.move(_defaultLocation, 13.0),
                  child: const Icon(Icons.my_location, color: Colors.blue),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: "btn_zoom_in", backgroundColor: Colors.white,
                  onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1),
                  child: const Icon(Icons.add, color: Colors.black87),
                ),
                const SizedBox(height: 5),
                FloatingActionButton.small(
                  heroTag: "btn_zoom_out", backgroundColor: Colors.white,
                  onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1),
                  child: const Icon(Icons.remove, color: Colors.black87),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 20, left: 20, right: 20,
            child: SizedBox(
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
                onPressed: () {
                  final currentCenter = _mapController.camera.center;
                  _createNewTask(currentCenter);
                },
                child: const Text('Ünvanı Təsdiqlə', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// YENİ: TƏKLİF GÖNDƏRMƏ (BIDDING) EKRANI
// ==========================================
class BiddingScreen extends StatefulWidget {
  final TaskItem task;
  const BiddingScreen({super.key, required this.task});

  @override
  State<BiddingScreen> createState() => _BiddingScreenState();
}

class _BiddingScreenState extends State<BiddingScreen> {
  final _priceController = TextEditingController();
  final _timeController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Başlanğıc olaraq sifarişçinin qoyduğu qiyməti yazırıq ki, icraçı ona uyğun rəqəm yazsın
    _priceController.text = widget.task.budget;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Təklif Göndər")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // İşin qısa xülasəsi
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Icon(widget.task.icon, size: 40, color: widget.task.color),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.task.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text("Müştərinin büdcəsi: ${widget.task.budget} AZN", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Form elementləri
            const Text("Sizin təklif etdiyiniz qiymət (AZN)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Məsələn: 45", prefixIcon: Icon(Icons.money)),
            ),
            const SizedBox(height: 20),

            const Text("İşi nə qədər vaxta edərsiniz?", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            TextField(
              controller: _timeController,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Məsələn: 2 saata, Yarım günə", prefixIcon: Icon(Icons.timer)),
            ),
            const SizedBox(height: 20),

            const Text("Müştəriyə əlavə mesajınız", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Məsələn: Detalı özüm alıb dərhal yaxınlaşa bilərəm...", prefixIcon: Icon(Icons.message)),
            ),
            const SizedBox(height: 30),

            // Göndər düyməsi
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () {
                  // Reallıqda burda məlumatlar serverə/database-ə gedəcək. İndi isə sadəcə təsdiqləyirik.
                  Navigator.pop(context, true); // "true" qaytarırıq ki, əvvəlki ekran uğurlu olduğunu bilsin.
                }, 
                icon: const Icon(Icons.send), 
                label: const Text("Təklifi Təsdiqlə", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// YENİ İŞ YARATMAQ EKRANI
// ==========================================
class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});
  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _t = TextEditingController(), _d = TextEditingController(), _b = TextEditingController();
  TaskCategory _cat = TaskCategory.repair;
  double _rad = 5.0;
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked != null) setState(() => _selectedImage = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni İş Yarat')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
        DropdownButtonFormField<TaskCategory>(value: _cat, items: TaskCategory.values.map((c) => 
          DropdownMenuItem(value: c, child: Text(getCategoryName(c)))).toList(), onChanged: (v) => setState(() => _cat = v!)),
        TextField(controller: _t, decoration: const InputDecoration(labelText: 'Başlıq')),
        TextField(controller: _d, decoration: const InputDecoration(labelText: 'Detallar')),
        TextField(controller: _b, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Məbləğ (AZN)')),
        const SizedBox(height: 20),
        Container(
          width: double.infinity, padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            _selectedImage == null ? const Text("İşin vəziyyətini göstərən şəkil əlavə edin") : const Text("Şəkil uğurla əlavə edildi!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              ElevatedButton.icon(onPressed: () => _pickImage(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: const Text("Kamera")),
              ElevatedButton.icon(onPressed: () => _pickImage(ImageSource.gallery), icon: const Icon(Icons.image), label: const Text("Qalereya")),
            ]),
          ]),
        ),
        const SizedBox(height: 20),
        Text("Görünmə sahəsi: ${_rad.toInt()} km"),
        Slider(value: _rad, min: 1, max: 20, divisions: 19, onChanged: (v) => setState(() => _rad = v)),
        ElevatedButton(
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.black, foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(context, {
          'title': _t.text, 'desc': _d.text, 'budget': _b.text, 'cat': _cat, 'rad': _rad, 'image': _selectedImage?.path
        }), child: const Text("Təsdiqlə", style: TextStyle(fontSize: 18),))
      ])),
    );
  }
}