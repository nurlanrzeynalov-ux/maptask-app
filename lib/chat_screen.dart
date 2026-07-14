import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart'; // YENİ: Kamera və Qalereya
import 'package:firebase_storage/firebase_storage.dart'; // YENİ: Şəkli bazaya yükləmək
import 'dart:typed_data'; // YENİ: Şəkli byte kimi oxumaq üçün (Web dəstəyi)

class ChatScreen extends StatefulWidget {
  final String taskId;
  final String userName; 
  final String offerPrice; 
  final String initialMessage; 

  const ChatScreen({
    super.key, 
    required this.taskId, 
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
  bool _isUploading = false; // YENİ: Yüklənmə animasiyası üçün

  // MESAJI FİREBASE-Ə GÖNDƏRMƏK
  Future<void> _sendMessage() async {
    if (_msgController.text.trim().isEmpty || _currentUserId == null) return;
    
    final text = _msgController.text.trim();
    _msgController.clear(); 
    
    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(widget.taskId)
        .collection('messages')
        .add({
      'text': text,
      'senderId': _currentUserId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // YENİ FUNKSİYA: ŞƏKLİ ÇƏKİB HESABAT GÖNDƏRMƏK
  Future<void> _uploadReportAndComplete() async {
    final ImagePicker picker = ImagePicker();
    
    // 1. Şəkli seçirik və ya çəkirik
    final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    
    if (image == null) return; // Şəkil çəkməkdən imtina etsə, dayanır

    setState(() => _isUploading = true); // Yüklənir ikonunu aktiv edirik

    try {
      // 2. Şəkli byte formatında oxuyuruq (Chrome/Web-də işləməsi üçün ən yaxşı yol)
      Uint8List imageData = await image.readAsBytes();

      // 3. Firebase Storage-də yer ayırırıq
      String fileName = "reports/${widget.taskId}_${DateTime.now().millisecondsSinceEpoch}.jpg";
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);

      // 4. Şəkli yükləyirik və URL-ni alırıq
      UploadTask uploadTask = storageRef.putData(imageData, SettableMetadata(contentType: 'image/jpeg'));
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // 5. İşin statusunu "Təsdiq Gözləyir" edirik
      await FirebaseFirestore.instance.collection('tasks').doc(widget.taskId).update({
        'status': 'pending_verification', 
      });

      // 6. Şəkli Çata göndəririk
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .collection('messages')
          .add({
        'text': '📸 İcraçı işi bitirdi və hesabat göndərdi!', // Mətn
        'imageUrl': downloadUrl, // Şəkil URL-i əlavə olunur!
        'senderId': _currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hesabat uğurla göndərildi!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Xəta baş verdi: $e"), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _isUploading = false);
    }
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
      ),
      body: Column(
        children: [
          // STATUS DİNLƏYİCİ BLOKU (Ağıllı Düymələr)
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('tasks').doc(widget.taskId).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox();
              
              var taskData = snapshot.data!.data() as Map<String, dynamic>;
              String status = taskData['status'] ?? 'active';
              String creatorId = taskData['creatorId'] ?? '';
              String acceptedCourierId = taskData['acceptedCourierId'] ?? '';

              // 1. KURYER ÜÇÜN "İŞİ TAMAMLA" DÜYMƏSİ
              if (status == 'in_progress' && _currentUserId == acceptedCourierId) {
                return Container(
                  color: Colors.blue.shade50,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text("İşi bitirdikdə hesabat göndərin", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        onPressed: _isUploading ? null : _uploadReportAndComplete, // Kamera funksiyasına bağlandı!
                        icon: _isUploading 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                            : const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        label: const Text("Təhvil Ver", style: TextStyle(color: Colors.white)),
                      )
                    ],
                  ),
                );
              }

              // 2. MÜŞTƏRİ ÜÇÜN "TƏSDİQLƏ" DÜYMƏSİ 
              if (status == 'pending_verification' && _currentUserId == creatorId) {
                return Container(
                  color: Colors.orange.shade50,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text("Kuryer işi bitirdi.\nTəsdiqləyirsiniz?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: () {
                          FirebaseFirestore.instance.collection('tasks').doc(widget.taskId).update({
                            'status': 'completed', 
                          });
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sifariş tamamlandı və arxivləndi!"), backgroundColor: Colors.green));
                        },
                        child: const Text("Təsdiqlə və Bağla", style: TextStyle(color: Colors.white)),
                      )
                    ],
                  ),
                );
              }

              // 3. İŞ BİTİBSƏ
              if (status == 'completed') {
                return Container(
                  width: double.infinity,
                  color: Colors.green.shade100,
                  padding: const EdgeInsets.all(12),
                  child: const Center(
                    child: Text("✅ Bu sifariş uğurla tamamlanmışdır.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ),
                );
              }
              return const SizedBox();
            },
          ),

          // İLK TƏKLİF QUTUSU
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Təklif: ${widget.offerPrice}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue.shade900)),
                if(widget.initialMessage.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(widget.initialMessage, style: TextStyle(fontSize: 14, color: Colors.blue.shade800)),
                ]
              ],
            ),
          ),

          // REAL-TIME ÇAT VƏ ŞƏKİLLƏRİN GÖSTƏRİLMƏSİ
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tasks')
                  .doc(widget.taskId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true) 
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Hələ mesaj yoxdur.", style: TextStyle(color: Colors.grey)));
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, 
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == _currentUserId; 
                    final text = msg['text'] ?? '';
                    final imageUrl = msg['imageUrl']; // YENİ: Şəkil varmı yoxlayırıq
                    
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
                          boxShadow: [if (!isMe) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            // ƏGƏR ŞƏKİL VARSA, ÇATDA GÖSTƏRİRİK
                            if (imageUrl != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(imageUrl, width: 200, fit: BoxFit.cover),
                                ),
                              ),
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
          
          // MESAJ YAZMA PANELİ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
            child: SafeArea(
              child: Row(
                children: [
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
                    onTap: _sendMessage, 
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