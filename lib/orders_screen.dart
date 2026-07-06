import 'package:flutter/material.dart';

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
            indicatorColor: Colors.black, labelColor: Colors.black, unselectedLabelColor: Colors.grey,
            tabs: [Tab(text: "Aktiv Sifarişlər"), Tab(text: "Tamamlanmışlar")],
          ),
        ),
        body: TabBarView(children: [_buildActiveOrders(context), _buildCompletedOrders()]),
      ),
    );
  }

  Widget _buildActiveOrders(BuildContext context) {
    final List<Map<String, dynamic>> orders = [
      {"title": "Ofis əşyalarının daşınması", "budget": "40", "date": "Bu gün, 14:30", "bids": [{"name": "Samir (Kuryer)", "price": "35", "time": "1 saata", "rating": "4.9", "msg": "Maşınım boşdur, dərhal yaxınlaşa bilərəm."}]},
      {"title": "Kondisioner təmiri", "budget": "50", "date": "Sabah, 10:00", "bids": [{"name": "Əli Usta", "price": "45", "time": "Sabah səhər", "rating": "4.8", "msg": "Qaz vurulması daxil 45 AZN-ə edərəm."}]}
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(16), itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final bids = order['bids'] as List;
        return Card(
          elevation: 3, margin: const EdgeInsets.only(bottom: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: InkWell(
            onTap: () => _showBidsModal(context, order),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(order['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text("${order['budget']} AZN", style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 8), Text(order['date'], style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 15), Text("${bids.length} Təklif Gəlib", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletedOrders() => const Center(child: Text("Hələ ki, tamamlanmış işiniz yoxdur.", style: TextStyle(fontSize: 18, color: Colors.black54)));

  void _showBidsModal(BuildContext context, Map<String, dynamic> order) {
    final bids = order['bids'] as List;
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7, padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("${order['title']} - Təkliflər", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: bids.length,
                itemBuilder: (context, index) {
                  final bid = bids[index];
                  return Card(
                    child: ListTile(
                      title: Text(bid['name']), subtitle: Text('${bid['price']} AZN - ${bid['time']}'),
                      trailing: ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text("Qəbul Et")),
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