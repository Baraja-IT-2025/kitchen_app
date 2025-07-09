// screens/kitchen_dashboard.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../models/order.dart';
import '../data/sample_data.dart';
import '../services/audio_service.dart';
import '../widgets/order_column.dart';
import '../config/app_theme.dart';

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

  @override
  void initState() {
    super.initState();
    queue = SampleData.getSampleOrders();
    _initializeTimers();
  }

  void _initializeTimers() {
    _uiTimer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {});
      _checkForLateOrders();
    });

    _clockTimer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  void _checkForLateOrders() {
    for (var order in queue) {
      if (order.isLate && !order.alertPlayed) {
        order.alertPlayed = true;
        AudioService.playAlert();
      }
    }
  }

  @override
  void dispose() {
    _uiTimer.cancel();
    _clockTimer.cancel();
    super.dispose();
  }

  void _confirmOrder(Order order) async {
    setState(() {
      queue.remove(order);
      order.startTimer();
      preparing.add(order);
    });
    await AudioService.playLogin();
  }

  void _completeOrder(Order order) async {
    setState(() {
      preparing.remove(order);
      order.stopTimer();
      done.add(order);
    });
    await AudioService.playDing();
    _showOrderCompleteDialog(order);
  }

  void _showOrderCompleteDialog(Order order) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Pesanan Selesai'),
        content: Text('${order.name} (Meja ${order.table}) selesai dalam ${order.totalCookTime()}'),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _addTimeToOrder(Order order, int minutes) {
    setState(() {
      order.remaining += Duration(minutes: minutes);
    });
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        OrderColumn(
          title: 'Antrian',
          orders: queue,
          onAction: _confirmOrder,
          searchQuery: search,
        ),
        OrderColumn(
          title: 'Penyiapan',
          orders: preparing,
          onAction: _completeOrder,
          searchQuery: search,
          showTimer: true,
          onAddTime: _addTimeToOrder,
        ),
        OrderColumn(
          title: 'Selesai',
          orders: done,
          onAction: (_) {},
          searchQuery: search,
          isFinished: true,
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: AppTheme.primaryColor,
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
                OrderColumn(
                  title: 'Antrian',
                  orders: queue,
                  onAction: _confirmOrder,
                  searchQuery: search,
                ),
                OrderColumn(
                  title: 'Penyiapan',
                  orders: preparing,
                  onAction: _completeOrder,
                  searchQuery: search,
                  showTimer: true,
                  onAddTime: _addTimeToOrder,
                ),
                OrderColumn(
                  title: 'Selesai',
                  orders: done,
                  onAction: (_) {},
                  searchQuery: search,
                  isFinished: true,
                ),
              ],
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
        elevation: 2,
        titleSpacing: 16,
        backgroundColor: AppTheme.primaryColor,
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 36),
            SizedBox(width: 12),
            Text(
              'Baraja Kitchen',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            Text(
              DateFormat('HH:mm:ss').format(_currentTime),
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: EdgeInsets.all(8),
            child: TextField(
              onChanged: (value) => setState(() => search = value.toLowerCase()),
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
            return _buildDesktopLayout();
          } else {
            return _buildMobileLayout();
          }
        },
      ),
    );
  }
}