import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'models.dart';
import 'task_screens.dart';

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
      setState(() => tasks.add(TaskItem(title: res['title'], description: res['desc'], budget: res['budget'], location: point, category: res['cat'], radius: res['rad'], imagePath: res['image'])));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ İş xəritəyə əlavə edildi!'), backgroundColor: Colors.green));
    }
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          bool isAllSelected = _selectedCategories.length == TaskCategory.values.length;
          return SingleChildScrollView(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 20, left: 20, right: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Filtr", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                CheckboxListTile(title: const Text("Hamısını seç", style: TextStyle(color: Colors.blue)), value: isAllSelected, onChanged: (v) { setModalState(() => v == true ? _selectedCategories.addAll(TaskCategory.values) : _selectedCategories.clear()); setState(() {}); }),
                const Divider(),
                ...TaskCategory.values.map((cat) => CheckboxListTile(title: Text(getCategoryName(cat)), value: _selectedCategories.contains(cat), onChanged: (v) { setModalState(() => v == true ? _selectedCategories.add(cat) : _selectedCategories.remove(cat)); setState(() {}); })),
                ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)), onPressed: () => Navigator.pop(ctx), child: const Text("Tətbiq Et"))
              ],
            ),
          );
        },
      ),
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
            mapController: _mapController, options: MapOptions(initialCenter: _defaultLocation, initialZoom: 13),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
              CircleLayer(circles: displayedTasks.map((t) => CircleMarker(point: t.location, radius: t.radius * 1000, useRadiusInMeter: true, color: t.color.withOpacity(0.2), borderColor: t.color, borderStrokeWidth: 2)).toList()),
              MarkerLayer(markers: displayedTasks.map((t) => Marker(
                point: t.location, width: 50, height: 50,
                child: GestureDetector(
                  onTap: () => showModalBottomSheet(
                    context: context, builder: (_) => Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(t.icon, size: 50, color: t.color), Text(t.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), Text("Büdcə: ${t.budget} AZN", style: const TextStyle(color: Colors.green, fontSize: 16)), const SizedBox(height: 10), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)), onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => BiddingScreen(task: t))); }, child: const Text('Təklif Göndər'))])),
                  ),
                  child: Container(decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]), child: Icon(t.icon, color: t.color, size: 30)),
                ),
              )).toList()),
            ],
          ),
          const Center(child: Padding(padding: EdgeInsets.only(bottom: 40.0), child: Icon(Icons.location_on, size: 50, color: Colors.black87))),
          Positioned(top: 16, left: 16, child: FloatingActionButton.extended(backgroundColor: Colors.white, foregroundColor: Colors.black, icon: const Icon(Icons.filter_list), label: Text("Filtr (${_selectedCategories.length})"), onPressed: _showFilterModal)),
          Positioned(bottom: 20, left: 20, right: 20, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () => _createNewTask(_mapController.camera.center), child: const Text('Ünvanı Təsdiqlə', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)))),
        ],
      ),
    );
  }
}