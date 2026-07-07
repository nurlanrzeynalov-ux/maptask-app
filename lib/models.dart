import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum TaskCategory { delivery, repair, auto, autoParts, cleaning, helper, tech, photoDrone, shopping, office, petCare, beauty, realEstate, sales, needs, other }

String getCategoryName(TaskCategory cat) {
  switch(cat) {
    case TaskCategory.delivery: return "Kuryer / Çatdırılma";
    case TaskCategory.repair: return "Usta / Təmir";
    case TaskCategory.auto: return "Yol Yardımı";
    case TaskCategory.autoParts: return "Avto Detal / Diaqnostika";
    case TaskCategory.cleaning: return "Təmizlik";
    case TaskCategory.helper: return "Daşınma / Fiziki İş";
    case TaskCategory.tech: return "İT / Texniki Dəstək";
    case TaskCategory.photoDrone: return "Foto / Dron Çəkilişi";
    case TaskCategory.shopping: return "Alış-veriş / Köməkçi";
    case TaskCategory.office: return "Ofis / İnzibati İşlər";
    case TaskCategory.petCare: return "Heyvanlara Baxım";
    case TaskCategory.beauty: return "Gözəllik / Baxım";
    case TaskCategory.realEstate: return "Daşınmaz Əmlak";
    case TaskCategory.sales: return "Satış";
    case TaskCategory.needs: return "Ehtiyacım Var";
    case TaskCategory.other: return "Digər";
  }
}

class TaskItem {
  final String title, description, budget;
  final LatLng location;
  final TaskCategory category;
  final double radius;
  final String? imagePath;

  TaskItem({
    required this.title, 
    required this.description, 
    required this.budget, 
    required this.location, 
    required this.category, 
    required this.radius, 
    this.imagePath
  });

  Color get color => switch(category) {
        TaskCategory.delivery => Colors.blue,
        TaskCategory.repair => Colors.orange,
        TaskCategory.auto => Colors.red,
        TaskCategory.autoParts => Colors.redAccent,
        TaskCategory.cleaning => Colors.teal,
        TaskCategory.helper => Colors.brown,
        TaskCategory.tech => Colors.deepPurple,
        TaskCategory.photoDrone => Colors.indigo,
        TaskCategory.shopping => Colors.green,
        TaskCategory.office => Colors.blueGrey,
        TaskCategory.petCare => Colors.amber,
        TaskCategory.beauty => Colors.pink,
        TaskCategory.realEstate => Colors.cyan,
        TaskCategory.sales => Colors.deepOrange,
        TaskCategory.needs => Colors.pinkAccent,
        TaskCategory.other => Colors.grey,
      };

  IconData get icon => switch(category) {
        TaskCategory.delivery => Icons.local_shipping,
        TaskCategory.repair => Icons.plumbing,
        TaskCategory.auto => Icons.car_crash,
        TaskCategory.autoParts => Icons.settings_suggest,
        TaskCategory.cleaning => Icons.cleaning_services,
        TaskCategory.helper => Icons.fitness_center,
        TaskCategory.tech => Icons.computer,
        TaskCategory.photoDrone => Icons.camera_alt,
        TaskCategory.shopping => Icons.shopping_cart,
        TaskCategory.office => Icons.business_center,
        TaskCategory.petCare => Icons.pets,
        TaskCategory.beauty => Icons.face_retouching_natural,
        TaskCategory.realEstate => Icons.apartment,
        TaskCategory.sales => Icons.sell,
        TaskCategory.needs => Icons.volunteer_activism,
        TaskCategory.other => Icons.work,
      };
}