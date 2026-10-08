import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBannerner: false,
      title: 'تطبيق مؤذن',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      home: const PrayerTimesScreen(),
    );
  }
}

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  String locationStatus = "جاري تحديد الموقع...";
  Map<String, String> prayerTimesMap = {};

  @override
  void initState() {
    super.initState();
    _determinePositionAndCalculateTimes();
  }

  // دالة لتحديد الموقع وحساب أوقات الصلاة تلقائياً
  Future<void> _determinePositionAndCalculateTimes() async {
    bool serviceEnabled;
    LocationPermission permission;

    // التأكد من تفعيل خدمة الموقع في الهاتف
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        locationStatus = "خدمات الموقع غير مفعلة. يرجى تفعيل GPS.";
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          locationStatus = "تم رفض صلاحية الوصول إلى الموقع.";
        });
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        locationStatus = "صلاحيات الموقع مرفوضة بشكل دائم من الإعدادات.";
      });
      return;
    }

    // جلب الإحداثيات الحالية للمستخدم
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    
    setState(() {
      locationStatus = "خط العرض: ${position.latitude.toStringAsFixed(2)} | خط الطول: ${position.longitude.toStringAsFixed(2)}";
    });

    // حساب أوقات الصلاة بناءً على الإحداثيات الحالية
    final myCoordinates = Coordinates(position.latitude, position.longitude);
    final params = CalculationMethod.muslim_world_league.getParameters();
    params.madhab = Madhab.shafi; 
    
    final date = DateComponents.from(DateTime.now());
    final prayerTimes = PrayerTimes(myCoordinates, date, params);

    // تنسيق الوقت للعرض بشكل جميل
    final dateFormat = DateFormat.jm();
    setState(() {
      prayerTimesMap = {
        'الفجر': dateFormat.format(prayerTimes.fajr),
        'الشروق': dateFormat.format(prayerTimes.sunrise),
        'الظهر': dateFormat.format(prayerTimes.dhuhr),
        'العصر': dateFormat.format(prayerTimes.asr),
        'المغرب': dateFormat.format(prayerTimes.maghrib),
        'العشاء': dateFormat.format(prayerTimes.isha),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مواقيت الصلاة'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                locationStatus, 
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: prayerTimesMap.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      children: prayerTimesMap.entries.map((entry) {
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          child: ListTile(
                            leading: const Icon(Icons.access_time_filled, color: Colors.teal),
                            title: Text(entry.key, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            trailing: Text(entry.value, style: const TextStyle(fontSize: 18, color: Colors.teal, fontWeight: FontWeight.bold)),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
