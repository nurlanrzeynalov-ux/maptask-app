import 'package:flutter/material.dart';
import 'models.dart';

class BiddingScreen extends StatefulWidget {
  final TaskItem task;
  const BiddingScreen({super.key, required this.task});
  @override
  State<BiddingScreen> createState() => _BiddingScreenState();
}

class _BiddingScreenState extends State<BiddingScreen> {
  final _priceController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Təklif Göndər")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Təklifiniz (AZN)")),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 55)),
              onPressed: () {
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎉 Təklifiniz göndərildi!'), backgroundColor: Colors.blueAccent));
              },
              child: const Text("Təsdiqlə")
            )
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
  TaskCategory _cat = TaskCategory.delivery;
  double _rad = 5.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni İş Yarat')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<TaskCategory>(value: _cat, items: TaskCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(getCategoryName(c)))).toList(), onChanged: (v) => setState(() => _cat = v!)),
            TextField(controller: _t, decoration: const InputDecoration(labelText: 'Başlıq')),
            TextField(controller: _d, decoration: const InputDecoration(labelText: 'Detallar')),
            TextField(controller: _b, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Məbləğ (AZN)')),
            const SizedBox(height: 20), Text("Görünmə sahəsi: ${_rad.toInt()} km"),
            Slider(value: _rad, min: 1, max: 20, divisions: 19, onChanged: (v) => setState(() => _rad = v)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.black, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context, {'title': _t.text, 'desc': _d.text, 'budget': _b.text, 'cat': _cat, 'rad': _rad, 'image': null}),
              child: const Text("Təsdiqlə")
            )
          ]
        )
      ),
    );
  }
}