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
      appBar: AppBar(title: const Text("Təklif Göndər"), backgroundColor: Colors.white, elevation: 0, foregroundColor: Colors.black),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Təklifiniz (AZN)")),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎉 Təklifiniz göndərildi!'), backgroundColor: Colors.blueAccent));
              },
              child: const Text("Təsdiqlə", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
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

  IconData _getIcon(TaskCategory c) => switch(c) {
    TaskCategory.delivery => Icons.local_shipping, TaskCategory.repair => Icons.plumbing,
    TaskCategory.auto => Icons.car_crash, TaskCategory.autoParts => Icons.settings_suggest,
    TaskCategory.cleaning => Icons.cleaning_services, TaskCategory.helper => Icons.fitness_center,
    TaskCategory.tech => Icons.computer, TaskCategory.photoDrone => Icons.camera_alt,
    TaskCategory.shopping => Icons.shopping_cart, TaskCategory.office => Icons.business_center,
    TaskCategory.petCare => Icons.pets, TaskCategory.beauty => Icons.face_retouching_natural,
    // Yeni İkonlar
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
    // Yeni Rənglər
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
              spacing: 8, 
              runSpacing: 10, 
              children: TaskCategory.values.map((category) {
                final isSelected = _cat == category;
                final color = _getColor(category);
                
                return GestureDetector(
                  onTap: () => setState(() => _cat = category),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? color : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? color : Colors.grey.shade300),
                      boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))] : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getIcon(category), size: 16, color: isSelected ? Colors.white : color),
                        const SizedBox(width: 6),
                        Text(
                          getCategoryName(category).split(" / ").first,
                          style: TextStyle(
                            fontSize: 13, 
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, 
                            color: isSelected ? Colors.white : Colors.black87
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 30),
            const Text("İşin Detalları", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 12),
            TextField(controller: _t, decoration: InputDecoration(labelText: 'Başlıq', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
            const SizedBox(height: 12),
            TextField(controller: _d, maxLines: 3, decoration: InputDecoration(labelText: 'Məlumat', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
            const SizedBox(height: 12),
            TextField(controller: _b, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Büdcə (AZN)', prefixIcon: const Icon(Icons.account_balance_wallet, color: Colors.green), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
            
            const SizedBox(height: 25), 
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Görünmə sahəsi:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("${_rad.toInt()} km", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),
            Slider(value: _rad, min: 1, max: 20, divisions: 19, activeColor: Colors.black, inactiveColor: Colors.grey.shade300, onChanged: (v) => setState(() => _rad = v)),
            
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55), backgroundColor: Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () => Navigator.pop(context, {'title': _t.text, 'desc': _d.text, 'budget': _b.text, 'cat': _cat, 'rad': _rad, 'image': null}),
              child: const Text("Təsdiqlə", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
            )
          ]
        )
      ),
    );
  }
}