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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
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
    ),
    Order(
      "Latte Caramel",
      "latte_caramel",
      Duration(minutes: 4),
      "Budi",
      "3",
      2,
    ),
    Order("Cappuccino", "capucino", Duration(minutes: 3), "Citra", "2", 1),
  ];

  List<Order> orders = [];
  List<Order> inProgressOrders = [];
  List<Order> completedOrders = [];

  @override
  void initState() {
    super.initState();
    _resetOrders();
    _uiTimer = Timer.periodic(Duration(seconds: 1), (_) async {
      for (var order in orders) {
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
      order.startCountdown();
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

  void _addExtraTime(Order order, int minutes) {
    setState(() {
      order.remaining += Duration(minutes: minutes);
    });
  }

  void _removeOrder(Order order) {
    setState(() {
      completedOrders.remove(order);
    });
  }

  Widget _buildOrderCard(
    Order order, {
    required VoidCallback onTap,
    bool showTimer = false,
    bool isDone = false,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        elevation: 10,
        margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/products/${order.imageName}.jpg',
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'x${order.quantity}',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Text('👤 ${order.customerName}', style: TextStyle(fontSize: 20)),
              Text(
                '📍 Meja: ${order.tableNumber}',
                style: TextStyle(fontSize: 20),
              ),
              if (!isDone) ...[
                SizedBox(height: 14),
                Text(
                  showTimer
                      ? order.remainingTimeText
                      : order.timeSinceOrderText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: showTimer
                        ? (order.remaining.inSeconds < 0
                              ? Colors.red
                              : Colors.orangeAccent)
                        : (order.waitingTooLong
                              ? Colors.redAccent
                              : Color(0xFF005429)),
                  ),
                ),
                if (!showTimer && order.waitingTooLong)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      '⚠️ Menunggu lebih dari 30 detik!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
              if (showTimer && !isDone)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (int m in [5, 10, 15])
                        TextButton(
                          onPressed: () => _addExtraTime(order, m),
                          child: Text(
                            '+${m}m',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 18),
                ),
                child: Text(
                  isDone
                      ? 'Cek Pesanan'
                      : showTimer
                      ? 'Selesaikan'
                      : 'Konfirmasi',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColumn(
    String title,
    List<Order> list,
    Function(Order) onTap, {
    bool showTimer = false,
    bool isDone = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              style: TextStyle(
                color: Color(0xFF005429),
                fontWeight: FontWeight.bold,
                fontSize: 30,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 8),
              children: list
                  .map(
                    (order) => _buildOrderCard(
                      order,
                      onTap: () => onTap(order),
                      showTimer: showTimer,
                      isDone: isDone,
                    ),
                  )
                  .toList(),
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
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Reset Pesanan',
              onPressed: _resetOrders,
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 1000) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildColumn("Antrian", orders, _confirmOrder),
                _buildColumn(
                  "Penyiapan",
                  inProgressOrders,
                  _completeOrder,
                  showTimer: true,
                ),
                _buildColumn(
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
                        Tab(text: "Antrian"),
                        Tab(text: "Penyiapan"),
                        Tab(text: "Selesai"),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildColumn("Antrian", orders, _confirmOrder),
                        _buildColumn(
                          "Penyiapan",
                          inProgressOrders,
                          _completeOrder,
                          showTimer: true,
                        ),
                        _buildColumn(
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
  ) : remaining = duration;

  Order copy() {
    return Order(
      name,
      imageName,
      duration,
      customerName,
      tableNumber,
      quantity,
    );
  }

  void startCountdown() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      remaining -= Duration(seconds: 1);
    });
  }

  bool get waitingTooLong =>
      DateTime.now().difference(createdAt).inSeconds > 30;

  String get timeSinceOrderText {
    final seconds = DateTime.now().difference(createdAt).inSeconds;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return "Konfirmasi: ${minutes}:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  String get remainingTimeText {
    if (remaining.inSeconds >= 0) {
      return "Sisa waktu: ${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}";
    } else {
      return "Lewat ${-remaining.inSeconds}s";
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}
