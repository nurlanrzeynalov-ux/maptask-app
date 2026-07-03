// Kopyalamaq üçün bura klikləyin:
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() => runApp(const MaterialApp(home: MapScreen()));

enum TaskCategory { repair, delivery, photo, other }

class TaskItem {
  final String title, description, budget;
  final LatLng location;
  final TaskCategory category;
  final double radius;

  TaskItem({required this.title, required this.description, required this.budget, 
            required this.location, required this.category, required this.radius});

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

  // Tapşırıq yaratma funksiyası
  void _createNewTask(LatLng point) async {
    final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTaskScreen()));
    if (res != null && res is Map<String, dynamic>) {
      setState(() {
        tasks.add(TaskItem(
          title: res['title'], description: res['desc'], budget: res['budget'],
          location: point, // Kliklənən nöqtəni bura ötürürük
          category: res['cat'], radius: res['rad']
        ));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MapTask Radar')),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: const LatLng(40.4093, 49.8671), 
          initialZoom: 13,
          onTap: (_, point) => _createNewTask(point), // XƏRİTƏYƏ KLİK ETMƏK
        ),
        children: [
          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
          CircleLayer(circles: tasks.map((t) => CircleMarker(
            point: t.location, radius: t.radius * 1000, useRadiusInMeter: true,
            color: t.color.withOpacity(0.2), borderColor: t.color, borderStrokeWidth: 2,
          )).toList()),
          MarkerLayer(markers: tasks.map((t) => Marker(
            point: t.location,
            child: GestureDetector(
              onTap: () => showModalBottomSheet(context: context, builder: (_) => Padding(
                padding: const EdgeInsets.all(20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(t.icon, size: 50, color: t.color),
                  Text(t.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text("Büdcə: ${t.budget} AZN", style: const TextStyle(color: Colors.green)),
                  Text(t.description)
                ]),
              )),
              child: Icon(t.icon, color: t.color, size: 40),
            ),
          )).toList()),
        ],
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
  TaskCategory _cat = TaskCategory.repair;
  double _rad = 5.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni İş Yarat')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
        DropdownButtonFormField<TaskCategory>(value: _cat, items: TaskCategory.values.map((c) => 
          DropdownMenuItem(value: c, child: Text(c.name.toUpperCase()))).toList(), onChanged: (v) => setState(() => _cat = v!)),
        TextField(controller: _t, decoration: const InputDecoration(labelText: 'Başlıq')),
        TextField(controller: _d, decoration: const InputDecoration(labelText: 'Detallar')),
        TextField(controller: _b, decoration: const InputDecoration(labelText: 'Məbləğ (AZN)')),
        const SizedBox(height: 20),
        Text("Görünmə sahəsi: ${_rad.toInt()} km"),
        Slider(value: _rad, min: 1, max: 20, divisions: 19, onChanged: (v) => setState(() => _rad = v)),
        ElevatedButton(onPressed: () => Navigator.pop(context, {
          'title': _t.text, 'desc': _d.text, 'budget': _b.text, 'cat': _cat, 'rad': _rad
        }), child: const Text("Təsdiqlə"))
      ])),
    );
  }
}