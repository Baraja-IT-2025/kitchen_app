import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(BarajaKitchenApp());
}

class BarajaKitchenApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baraja Kitchen',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Color(0xFF005429),
        scaffoldBackgroundColor: Colors.grey[50],
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF005429),
            foregroundColor: Colors.white,
            textStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 32,
            color: Color(0xFF003d21),
          ),
          bodyMedium: TextStyle(fontSize: 22),
        ),
      ),
      home: KitchenDashboard(),
    );
  }
}

class KitchenDashboard extends StatefulWidget {
  @override
  _KitchenDashboardState createState() => _KitchenDashboardState();
}

class _KitchenDashboardState extends State<KitchenDashboard>
    with TickerProviderStateMixin {
  late Timer _uiTimer;
  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<Order> initialOrders = [
    Order(
      "Espresso Double",
      "espresso_double",
      Duration(minutes: 2),
      "Andi",
      "1",
      1,
      "Dine-in",
    ),
    Order(
      "Latte Caramel",
      "latte_caramel",
      Duration(minutes: 4),
      "Andi",
      "1",
      2,
      "Dine-in",
    ),
    Order(
      "Cappuccino",
      "capucino",
      Duration(minutes: 3),
      "Budi",
      "2",
      1,
      "Delivery",
    ),
    Order(
      "Americano",
      "americano",
      Duration(minutes: 3),
      "Budi",
      "2",
      1,
      "Delivery",
    ),
    Order(
      "Flat White",
      "flat_white",
      Duration(minutes: 3),
      "Citra",
      "3",
      1,
      "Dine-in",
    ),
    Order("Mocha", "mocha", Duration(minutes: 3), "Citra", "3", 1, "Dine-in"),
  ];

  List<Order> orders = [];
  List<Order> inProgressOrders = [];
  List<Order> completedOrders = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _resetOrders();
    _uiTimer = Timer.periodic(Duration(seconds: 1), (_) async {
      for (var order in [...orders, ...inProgressOrders]) {
        if (order.waitingTooLong && !order.alertPlayed) {
          order.alertPlayed = true;
          await _audioPlayer.play(AssetSource('audio/alert.mp3'));
        }
      }
      setState(() {});
    });
  }

  void _resetOrders() {
    setState(() {
      for (var order in inProgressOrders) {
        order.dispose();
      }
      inProgressOrders.clear();
      completedOrders.clear();
      orders = initialOrders.map((o) => o.copy()).toList();
    });
  }

  @override
  void dispose() {
    _uiTimer.cancel();
    _audioPlayer.dispose();
    for (var order in inProgressOrders) {
      order.dispose();
    }
    super.dispose();
  }

  void _confirmOrder(Order order) async {
    await _audioPlayer.play(AssetSource('audio/login.mp3'));
    setState(() {
      orders.remove(order);
      order.startCountdown(() {
        if (mounted) setState(() {});
      });
      inProgressOrders.add(order);
    });
  }

  void _completeOrder(Order order) async {
    setState(() {
      inProgressOrders.remove(order);
      order.dispose();
      completedOrders.add(order);
    });

    await _audioPlayer.play(AssetSource('audio/ding.mp3'));

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Pesanan Selesai'),
        content: Text('${order.name} untuk ${order.customerName} selesai.'),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _removeOrder(Order order) {
    setState(() {
      completedOrders.remove(order);
    });
  }

  Widget _buildGroupedOrdersColumn(
    String title,
    List<Order> list,
    void Function(Order) action, {
    bool showTimer = false,
    bool isDone = false,
  }) {
    final filtered = list.where((order) {
      return order.name.toLowerCase().contains(_searchQuery) ||
          order.customerName.toLowerCase().contains(_searchQuery);
    }).toList();

    final grouped = <String, List<Order>>{};
    for (var order in filtered) {
      grouped.putIfAbsent(order.tableNumber, () => []).add(order);
    }

    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 28,
                color: Color(0xFF005429),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: grouped.entries.map((entry) {
                final table = entry.key;
                final orders = entry.value;
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 10),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meja $table',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ...orders.map(
                          (order) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${order.name} x${order.quantity}',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text('👤 ${order.customerName}'),
                                      Text('🛎️ ${order.serviceType}'),
                                      if (!isDone)
                                        Text(
                                          showTimer
                                              ? order.remainingTimeText
                                              : order.timeSinceOrderText,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: showTimer
                                                ? (order.remaining.inSeconds < 0
                                                      ? Colors.red
                                                      : Colors.orangeAccent)
                                                : (order.waitingTooLong
                                                      ? Colors.red
                                                      : Colors.green),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (!isDone && showTimer)
                                  Row(
                                    children: [
                                      for (int m in [5, 10, 15])
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              order.remaining += Duration(
                                                minutes: m,
                                              );
                                            });
                                          },
                                          child: Text('+${m}m'),
                                        ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            for (var o in orders) action(o);
                          },
                          child: Text(
                            isDone
                                ? 'Cek Pesanan'
                                : showTimer
                                ? 'Selesaikan Semua'
                                : 'Konfirmasi Semua',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF005429),
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 42),
            SizedBox(width: 16),
            Text(
              'Baraja Kitchen',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: _resetOrders,
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                hintText: 'Cari nama pelanggan atau produk...',
                hintStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.search, color: Colors.white),
              ),
              onChanged: (query) {
                setState(() {
                  _searchQuery = query.toLowerCase();
                });
              },
            ),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 1000) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGroupedOrdersColumn("Antrian", orders, _confirmOrder),
                _buildGroupedOrdersColumn(
                  "Penyiapan",
                  inProgressOrders,
                  _completeOrder,
                  showTimer: true,
                ),
                _buildGroupedOrdersColumn(
                  "Selesai",
                  completedOrders,
                  _removeOrder,
                  isDone: true,
                ),
              ],
            );
          } else {
            return DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  Container(
                    color: Color(0xFF005429),
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
                        _buildGroupedOrdersColumn(
                          "Antrian",
                          orders,
                          _confirmOrder,
                        ),
                        _buildGroupedOrdersColumn(
                          "Penyiapan",
                          inProgressOrders,
                          _completeOrder,
                          showTimer: true,
                        ),
                        _buildGroupedOrdersColumn(
                          "Selesai",
                          completedOrders,
                          _removeOrder,
                          isDone: true,
                        ),
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
  final String imageName;
  final Duration duration;
  final String customerName;
  final String tableNumber;
  final int quantity;
  final String serviceType;
  Duration remaining;
  Timer? _timer;
  DateTime createdAt = DateTime.now();
  bool alertPlayed = false;

  Order(
    this.name,
    this.imageName,
    this.duration,
    this.customerName,
    this.tableNumber,
    this.quantity,
    this.serviceType,
  ) : remaining = duration;

  Order copy() {
    return Order(
      name,
      imageName,
      duration,
      customerName,
      tableNumber,
      quantity,
      serviceType,
    );
  }

  void startCountdown(VoidCallback tickCallback) {
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      remaining -= Duration(seconds: 1);
      tickCallback();
    });
  }

  bool get waitingTooLong =>
      DateTime.now().difference(createdAt).inSeconds > 30;

  String get timeSinceOrderText {
    final s = DateTime.now().difference(createdAt).inSeconds;
    return "Konfirmasi: \${s ~/ 60}:\${(s % 60).toString().padLeft(2, '0')}";
  }

  String get remainingTimeText {
    if (remaining.inSeconds >= 0) {
      return "Sisa: \${remaining.inMinutes}:\${(remaining.inSeconds % 60).toString().padLeft(2, '0')}";
    } else {
      return "Lewat \${-remaining.inSeconds}s";
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}
