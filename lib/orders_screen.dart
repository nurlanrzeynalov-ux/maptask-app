import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

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

  // --- AKTİV SİFARİŞLƏR SİYAHISI (FİREBASE CANLI BAĞLANTI) ---
  Widget _buildActiveOrders(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Sifarişləri görmək üçün daxil olun."));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('creatorId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.black));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("Hələ heç bir sifariş yaratmamısınız.", style: TextStyle(fontSize: 16, color: Colors.grey)),
          );
        }

        final orders = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(20), 
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final orderDoc = orders[index];
            final orderData = orderDoc.data() as Map<String, dynamic>;
            final orderId = orderDoc.id;

            final title = orderData['title'] ?? 'Adsız Sifariş';
            final budget = orderData['price'] ?? '0';
            
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('tasks').doc(orderId).collection('offers').snapshots(),
              builder: (context, offerSnapshot) {
                final offerCount = offerSnapshot.hasData ? offerSnapshot.data!.docs.length : 0;
                
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
                      onTap: () => _showBidsModal(context, orderId, title),
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
                                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.work_outline, size: 14, color: Colors.blue),
                                      SizedBox(width: 6),
                                      Text("Aktiv Sifariş", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                                    ],
                                  ),
                                ),
                                Text("$budget AZN", style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                                      child: Text("$offerCount", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
              }
            );
          },
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
  void _showBidsModal(BuildContext context, String orderId, String taskTitle) {
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
            Text("$taskTitle üçün təkliflər", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('tasks').doc(orderId).collection('offers').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("Hələ heç bir təklif gəlməyib."));
                  }

                  final bids = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: bids.length,
                    itemBuilder: (context, index) {
                      final bidData = bids[index].data() as Map<String, dynamic>;
                      final price = bidData['offerPrice'] ?? '';
                      final msg = bidData['message'] ?? '';
                      final courierName = "İcraçı"; 

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(backgroundColor: Colors.blue.shade100, child: Text(courierName.substring(0, 1), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(courierName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const Row(children: [Icon(Icons.star, color: Colors.orange, size: 14), SizedBox(width: 4), Text("5.0", style: TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.bold))])
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text("$price AZN", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                                  ],
                                )
                              ],
                            ),
                            
                            if (msg.toString().isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [const Icon(Icons.format_quote, color: Colors.grey, size: 16), const SizedBox(width: 8), Expanded(child: Text(msg, style: const TextStyle(fontSize: 13, color: Colors.black87, fontStyle: FontStyle.italic)))],
                                ),
                              )
                            ],
                            
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 12)),
                                onPressed: () async {
                                  try {
                                    // 1. BAZADA SİFARİŞİN STATUSUNU YENİLƏYİRİK
                                    await FirebaseFirestore.instance
                                        .collection('tasks')
                                        .doc(orderId)
                                        .update({
                                      'status': 'in_progress', // Status dəyişdi
                                      'acceptedCourierId': bidData['courierId'] ?? '', 
                                      'agreedPrice': price, 
                                    });

                                    if (context.mounted) {
                                      Navigator.pop(ctx); 
                                      
                                      Navigator.push(
                                        context, 
                                        MaterialPageRoute(
                                          builder: (_) => ChatScreen(
  taskId: orderId, // BAX BUNU DA BURA YAZDIQ
                                            userName: courierName,
                                            offerPrice: price.toString(),
                                            initialMessage: msg, 
                                          )
                                        )
                                      );
                                      
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("✅ Təklif qəbul edildi və xəritədən silindi!"), backgroundColor: Colors.green)
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Xəta baş verdi, yenidən cəhd edin."), backgroundColor: Colors.red)
                                    );
                                  }
                                }, 
                                child: const Text("Təklifi Qəbul Et", style: TextStyle(fontWeight: FontWeight.bold))
                              ),
                            )
                          ],
                        ),
                      );
                    },
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