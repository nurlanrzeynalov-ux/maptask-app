import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String taskId; // YENİ: Çatın hansı sifarişə aid olduğunu bilmək üçün
  final String userName; 
  final String offerPrice; 
  final String initialMessage; 

  const ChatScreen({
    super.key, 
    required this.taskId, // YENİ ƏLAVƏ
    required this.userName,
    required this.offerPrice,
    required this.initialMessage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  // MESAJI FİREBASE-Ə GÖNDƏRMƏK ÜÇÜN FUNKSİYA
  Future<void> _sendMessage() async {
    if (_msgController.text.trim().isEmpty || _currentUserId == null) return;
    
    final text = _msgController.text.trim();
    _msgController.clear(); // Ekranda dərhal silinsin
    
    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(widget.taskId)
        .collection('messages') // Hər sifarişin öz mesajlar qovluğu
        .add({
      'text': text,
      'senderId': _currentUserId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        foregroundColor: Colors.black,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(widget.userName.substring(0, 1), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.userName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Text("Aktiv", style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.call, color: Colors.black87), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // XƏRİTƏDƏN GƏLƏN İLK TƏKLİF QUTUSU (Həmişə ən üstdə qalır)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200)
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Təklif: ${widget.offerPrice} ₼", style:  TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue.shade900)),
                if(widget.initialMessage.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(widget.initialMessage, style: TextStyle(fontSize: 14, color: Colors.blue.shade800)),
                ]
              ],
            ),
          ),

          // REAL-TIME FİREBASE MESAJLARI (CANLI DİNLƏMƏ)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tasks')
                  .doc(widget.taskId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true) // WhatsApp kimi, ən yenilər aşağıda
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Hələ mesaj yoxdur. Söhbətə başlayın!", style: TextStyle(color: Colors.grey)));
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, // Ekranı aşağıdan yuxarı doldurur
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == _currentUserId; // Mesajın bizə aid olub olmadığını yoxlayır
                    final text = msg['text'] ?? '';
                    
                    // Vaxt formatı (serverdən gələn timestamp)
                    String timeString = "İndi";
                    if (msg['timestamp'] != null) {
                      final DateTime dt = (msg['timestamp'] as Timestamp).toDate();
                      timeString = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                    }

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.black : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 16),
                          ),
                          border: isMe ? null : Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            if (!isMe) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(text, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text(timeString, style: TextStyle(color: isMe ? Colors.white70 : Colors.grey, fontSize: 10)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
            ),
          ),
          
          // AŞAĞIDAKI MESAJ YAZMA PANELİ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {}, 
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                      child: Icon(Icons.add_photo_alternate_outlined, color: Colors.grey.shade700, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: InputDecoration(
                        hintText: "Mesajınızı yazın...",
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _sendMessage, // FİREBASE GÖNDƏRİM FUNKSİYASINA BAĞLANDI
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}