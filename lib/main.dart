// baraja_kitchen.dart - Bootstrap-style with Elegant Green Theme
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

void main() => runApp(BarajaKitchenApp());

class BarajaKitchenApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baraja Kitchen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF004225),
        scaffoldBackgroundColor: Color(0xFFF8F9FA),
        fontFamily: 'Helvetica',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF004225),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          fillColor: Colors.white,
          filled: true,
          hintStyle: TextStyle(color: Colors.grey[600]),
        ),
      ),
      home: KitchenDashboard(),
    );
  }
}

class KitchenDashboard extends StatefulWidget {
  @override
  State<KitchenDashboard> createState() => _KitchenDashboardState();
}

class _KitchenDashboardState extends State<KitchenDashboard> {
  List<Order> queue = [];
  List<Order> preparing = [];
  List<Order> done = [];
  String search = '';
  late Timer _uiTimer;
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();
  final player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    queue = sampleOrders();
    _uiTimer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {});
      for (var o in queue) {
        if (o.isLate && !o.alertPlayed) {
          o.alertPlayed = true;
          player.play(AssetSource('audio/alert.mp3'));
        }
      }
    });
    _clockTimer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _uiTimer.cancel();
    _clockTimer.cancel();
    super.dispose();
  }

  List<Order> sampleOrders() => [
    Order('Andi', 'C022', 'Dine-in', [
      Item('Flat White', 2),
      Item('Americano', 1),
    ]),
    Order('Andi', 'J003', 'Delivery', [
      Item('Coffee Late (iced)', 1),
      Item('Hellbraun', 1),
    ], start: DateTime.now().subtract(Duration(seconds: 35))),
    Order('Citra', 'A033', 'Dine-in', [
      Item('Flat White', 1),
      Item('Mocha', 1),
    ]),
  ];

  void confirm(Order o) async {
    setState(() {
      queue.remove(o);
      o.startTimer();
      preparing.add(o);
    });
    await player.play(AssetSource('audio/login.mp3'));
  }

  void complete(Order o) async {
    setState(() {
      preparing.remove(o);
      o.stopTimer();
      done.add(o);
    });
    await player.play(AssetSource('audio/ding.mp3'));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Pesanan Selesai'),
        content: Text('${o.name} (Meja ${o.table}) selesai dalam ${o.totalCookTime()}'),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget buildCardColumn(String title, List<Order> list, Function(Order) onAction, {bool timer = false, bool finish = false}) {
    List<Order> filtered = list.where((o) => o.name.toLowerCase().contains(search) || o.items.any((i) => i.name.toLowerCase().contains(search))).toList();

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Color(0xFF004225),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: filtered.map((o) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${o.name} - (Table ${o.table})', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(o.service, style: TextStyle(color: Colors.grey[600]))
                            ],
                          ),
                          Divider(),
                          ...o.items.map((i) => Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Text('${i.name} x${i.qty}'),
                          )),
                          SizedBox(height: 6),
                          if (!finish)
                            Text(
                              timer ? 'Sisa waktu: ${o.remainingText()}' : 'Konfirmasi: ${o.confirmationText()}',
                              style: TextStyle(color: o.isLate ? Colors.red : Colors.green, fontWeight: FontWeight.bold),
                            ),
                          if (timer && !finish)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [5, 10, 15].map((m) => Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: OutlinedButton.icon(
                                  onPressed: () => setState(() => o.remaining += Duration(minutes: m)),
                                  icon: Icon(FontAwesomeIcons.clock, size: 14),
                                  label: Text('+${m}m'),
                                ),
                              )).toList(),
                            ),
                          SizedBox(height: 8),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () => onAction(o),
                              icon: Icon(finish ? FontAwesomeIcons.eye : FontAwesomeIcons.check),
                              label: Text(finish ? 'LIHAT DETAIL' : (timer ? 'SELESAIKAN' : 'KONFIRMASI')),
                            ),
                          ),
                          if (finish)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text('Waktu Memasak: ${o.totalCookTime()}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              ),
                            )
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        titleSpacing: 16,
        backgroundColor: Color(0xFF004225),
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 36),
            SizedBox(width: 12),
            Text('Baraja Kitchen', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Spacer(),
            Text(
              DateFormat('HH:mm:ss').format(_currentTime),
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            )
          ],
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: EdgeInsets.all(8),
            child: TextField(
              onChanged: (v) => setState(() => search = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Cari nama pelanggan atau produk...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 1000) {
            return Row(
              children: [
                buildCardColumn('Antrian', queue, confirm),
                buildCardColumn('Penyiapan', preparing, complete, timer: true),
                buildCardColumn('Selesai', done, (_) {}, finish: true),
              ],
            );
          } else {
            return DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  Container(
                    color: Color(0xFF004225),
                    child: TabBar(
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      tabs: [
                        Tab(text: 'Antrian'),
                        Tab(text: 'Penyiapan'),
                        Tab(text: 'Selesai'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        buildCardColumn('Antrian', queue, confirm),
                        buildCardColumn('Penyiapan', preparing, complete, timer: true),
                        buildCardColumn('Selesai', done, (_) {}, finish: true),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

class Order {
  final String name;
  final String table;
  final String service;
  final List<Item> items;
  final DateTime start;
  Duration remaining = Duration(minutes: 3);
  Timer? _timer;
  bool alertPlayed = false;

  Order(this.name, this.table, this.service, this.items, {DateTime? start}) : start = start ?? DateTime.now();

  void startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      remaining -= Duration(seconds: 1);
    });
  }

  void stopTimer() => _timer?.cancel();

  bool get isLate => DateTime.now().difference(start).inSeconds > 30;

  String confirmationText() {
    final diff = DateTime.now().difference(start);
    return '${diff.inMinutes}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  String remainingText() {
    if (remaining.inSeconds >= 0) {
      return '${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';
    } else {
      return '-${remaining.inSeconds.abs()}s';
    }
  }

  String totalCookTime() {
    final cookedDuration = Duration(minutes: 3) - remaining;
    return '${cookedDuration.inMinutes}:${(cookedDuration.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}

class Item {
  final String name;
  final int qty;
  Item(this.name, this.qty);
}