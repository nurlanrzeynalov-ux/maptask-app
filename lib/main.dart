// Kopyalamaq üçün sağ yuxarıdakı "Copy" düyməsinə bas:
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const MaterialApp(home: MainScreen(), debugShowCheckedModeBanner: false));

// ==========================================
// KÖMƏKÇİ DƏYİŞƏNLƏR VƏ FUNKSİYALAR
// ==========================================
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

// ==========================================
// ƏSAS MENYU EKRANI (BOTTOM NAV BAR)
// ==========================================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MapScreen(),
    const OrdersScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Xəritə"),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Sifarişlər"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}

// ==========================================
// YENİ: SİFARİŞLƏR VƏ TƏKLİFLƏR EKRANI
// ==========================================
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sifarişlərim', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.black,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "Aktiv Sifarişlər"),
              Tab(text: "Tamamlanmışlar"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildActiveOrders(context),
            _buildCompletedOrders(),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOrders(BuildContext context) {
    // Vizualizasiya üçün xəyali məlumatlar (Gələcəkdə bunlar serverdən gələcək)
    final List<Map<String, dynamic>> orders = [
      {
        "title": "Ofis əşyalarının daşınması",
        "budget": "40",
        "date": "Bu gün, 14:30",
        "bids": [
          {"name": "Samir (Kuryer)", "price": "35", "time": "1 saata", "rating": "4.9", "msg": "Maşınım boşdur, dərhal yaxınlaşa bilərəm."},
          {"name": "Kənan Q.", "price": "40", "time": "2 saata", "rating": "4.7", "msg": "Özümlə köməkçi də gətirəcəyəm."}
        ]
      },
      {
        "title": "Kondisioner təmiri",
        "budget": "50",
        "date": "Sabah, 10:00",
        "bids": [
          {"name": "Əli Usta", "price": "45", "time": "Sabah səhər", "rating": "4.8", "msg": "Qaz vurulması daxil 45 AZN-ə edərəm."}
        ]
      }
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final bids = order['bids'] as List;
        
        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: InkWell(
            onTap: () => _showBidsModal(context, order),
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(order['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("${order['budget']} AZN", style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(order['date'], style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_offer, size: 18, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text("${bids.length} Təklif Gəlib", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletedOrders() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text("Hələ ki, tamamlanmış işiniz yoxdur.", style: TextStyle(fontSize: 18, color: Colors.black54)),
        ],
      ),
    );
  }

  // Təklifləri göstərən Bottom Sheet
  void _showBidsModal(BuildContext context, Map<String, dynamic> order) {
    final bids = order['bids'] as List;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 20),
              Text("${order['title']} - Təkliflər", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: bids.length,
                  itemBuilder: (context, index) {
                    final bid = bids[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                      elevation: 0,
                      color: Colors.grey.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(radius: 22, backgroundColor: Colors.blue.shade100, child: const Icon(Icons.person, color: Colors.blue)),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(bid['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        Row(
                                          children: [
                                            const Icon(Icons.star, size: 14, color: Colors.amber),
                                            Text(" ${bid['rating']}", style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
                                          ],
                                        )
                                      ],
                                    )
                                  ],
                                ),
                                Text("${bid['price']} AZN", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.timer, size: 16, color: Colors.grey),
                                const SizedBox(width: 5),
                                Text(bid['time'], style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('"${bid['msg']}"', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black54)),
                            const SizedBox(height: 15),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ ${bid['name']} adlı icraçının təklifi qəbul edildi!"), backgroundColor: Colors.green));
                                },
                                child: const Text("Təklifi Qəbul Et", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        );
      }
    );
  }
}

// ==========================================
// PROFİL EKRANI
// ==========================================
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double _balance = 15.50;

  void _addBalanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Balansı Artır"),
        content: const Text("Test məqsədi ilə hesabınıza 10 AZN əlavə olunsun?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Ləğv et", style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                _balance += 10.0;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("✅ Balansınız uğurla artırıldı!"), backgroundColor: Colors.green),
              );
            },
            child: const Text("Bəli, Artır"),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), 
        backgroundColor: Colors.white, 
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none, color: Colors.black), onPressed: (){}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, backgroundColor: Colors.blueAccent, child: Icon(Icons.person, size: 50, color: Colors.white)),
            const SizedBox(height: 15),
            const Text("Rəşad Əliyev", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text("+994 50 123 45 67", style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...List.generate(4, (index) => const Icon(Icons.star, color: Colors.amber, size: 24)),
                const Icon(Icons.star_half, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                const Text("4.8", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))]
              ),
              child: Column(
                children: [
                  const Text("Mövcud Balans", style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 10),
                  Text("${_balance.toStringAsFixed(2)} AZN", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                          onPressed: _addBalanceDialog,
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text("Mədaxil", style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white24, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Çıxarış üçün minimum balans 20 AZN olmalıdır.")));
                          },
                          icon: const Icon(Icons.account_balance_wallet),
                          label: const Text("Məxaric", style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Divider(),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle), child: const Icon(Icons.history, color: Colors.blue)),
              title: const Text("Əməliyyat Tarixçəsi", style: TextStyle(fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: (){},
            ),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle), child: const Icon(Icons.settings, color: Colors.orange)),
              title: const Text("Tənzimləmələr", style: TextStyle(fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: (){},
            ),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.purple.shade50, shape: BoxShape.circle), child: const Icon(Icons.help_outline, color: Colors.purple)),
              title: const Text("Dəstək və Qaydalar", style: TextStyle(fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: (){},
            ),
            const Divider(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, foregroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                onPressed: (){},
                child: const Text("Hesabdan Çıx", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// XƏRİTƏ EKRANI 
// ==========================================
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
// TƏKLİF GÖNDƏRMƏ (BIDDING) EKRANI
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
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () {
                  Navigator.pop(context, true); 
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