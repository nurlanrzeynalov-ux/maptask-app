import 'package:flutter/material.dart';
import 'chat_screen.dart'; // YENİ: Çat ekranı bura əlavə edildi

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('Sifarişlərim', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.black, 
            labelColor: Colors.black, 
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [Tab(text: "Aktiv Sifarişlər"), Tab(text: "Tamamlanmışlar")],
          ),
        ),
        body: TabBarView(children: [_buildActiveOrders(context), _buildCompletedOrders()]),
      ),
    );
  }

  // --- AKTİV SİFARİŞLƏR SİYAHISI ---
  Widget _buildActiveOrders(BuildContext context) {
    final List<Map<String, dynamic>> orders = [
      {
        "title": "Ofis əşyalarının daşınması", 
        "category": "Daşınma / Fiziki İş",
        "budget": "40", 
        "date": "Bu gün, 14:30", 
        "color": Colors.brown,
        "icon": Icons.fitness_center,
        "bids": [
          {"name": "Samir Həsənov", "price": "35", "time": "1 saata", "rating": "4.9", "msg": "Maşınım boşdur, dərhal yaxınlaşa bilərəm. Özümlə fəhlə də gətirə bilərəm."},
          {"name": "Rəşad Ə.", "price": "40", "time": "2 saata", "rating": "4.7", "msg": "Səliqəli şəkildə daşıyarıq."}
        ]
      },
      {
        "title": "Kondisioner qazının vurulması", 
        "category": "Usta / Təmir",
        "budget": "50", 
        "date": "Sabah, 10:00", 
        "color": Colors.orange,
        "icon": Icons.plumbing,
        "bids": [
          {"name": "Əli Usta", "price": "45", "time": "Sabah səhər", "rating": "5.0", "msg": "Qaz vurulması və yoxlanış daxil 45 AZN-ə edərəm."}
        ]
      }
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20), 
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final bids = order['bids'] as List;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))]
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showBidsModal(context, order),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: (order['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              Icon(order['icon'], size: 14, color: order['color']),
                              const SizedBox(width: 6),
                              Text(order['category'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: order['color'])),
                            ],
                          ),
                        ),
                        Text("${order['budget']} AZN", style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(order['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8), 
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: Colors.black54),
                        const SizedBox(width: 6),
                        Text(order['date'], style: const TextStyle(color: Colors.black54, fontSize: 13)),
                      ],
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                              child: Text("${bids.length}", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            const Text("Təklif gəlib", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                          ],
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey)
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- TAMAMLANMIŞLAR SİYAHISI ---
  Widget _buildCompletedOrders() => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle_outline, size: 60, color: Colors.grey),
        SizedBox(height: 16),
        Text("Tamamlanmış işiniz yoxdur.", style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.bold))
      ],
    )
  );

  // --- TƏKLİFLƏR PƏNCƏRƏSİ ---
  void _showBidsModal(BuildContext context, Map<String, dynamic> order) {
    final bids = order['bids'] as List;
    showModalBottomSheet(
      context: context, 
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75, 
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            Text("${order['title']} üçün təkliflər", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            Expanded(
              child: ListView.builder(
                itemCount: bids.length,
                itemBuilder: (context, index) {
                  final bid = bids[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(backgroundColor: Colors.blue.shade100, child: Text(bid['name'].toString().substring(0, 1), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(bid['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Row(children: [const Icon(Icons.star, color: Colors.orange, size: 14), const SizedBox(width: 4), Text(bid['rating'], style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.bold))])
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("${bid['price']} AZN", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                                Text(bid['time'], style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              ],
                            )
                          ],
                        ),
                        
                        if (bid['msg'] != null && bid['msg'].toString().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [const Icon(Icons.format_quote, color: Colors.grey, size: 16), const SizedBox(width: 8), Expanded(child: Text(bid['msg'], style: const TextStyle(fontSize: 13, color: Colors.black87, fontStyle: FontStyle.italic)))],
                            ),
                          )
                        ],
                        
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 12)),
                            onPressed: () {
                              // Təklif qəbul edildikdə aşağıdakı pəncərəni bağla
                              Navigator.pop(ctx); 
                              
                              // YENİ: Dərhal Çat ekranına keç
                              Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(userName: bid['name'])));
                              
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ ${bid['name']} ilə söhbət başladıldı!"), backgroundColor: Colors.green));
                            }, 
                            child: const Text("Təklifi Qəbul Et", style: TextStyle(fontWeight: FontWeight.bold))
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            )
          ],
        ),
      )
    );
  }
}