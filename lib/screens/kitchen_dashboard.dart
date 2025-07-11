// screens/kitchen_dashboard.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../models/order.dart';
import '../services/order_service.dart';
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
  bool _isLoading = false;
  String? _errorMessage;

  late Timer _uiTimer;
  late Timer _clockTimer;
  late Timer _refreshTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadOrders();
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

    // Refresh orders every 30 seconds
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (_) {
      _refreshOrders();
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
    _refreshTimer.cancel();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ordersMap = await OrderService.refreshOrders();
      setState(() {
        queue = ordersMap['pending'] ?? [];
        preparing = ordersMap['preparing'] ?? [];
        done = ordersMap['completed'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshOrders() async {
    try {
      final ordersMap = await OrderService.refreshOrders();
      setState(() {
        queue = ordersMap['pending'] ?? [];
        preparing = ordersMap['preparing'] ?? [];
        done = ordersMap['completed'] ?? [];
      });
    } catch (e) {
      print('Error refreshing orders: $e');
    }
  }

  void _confirmOrder(Order order) async {
    setState(() {
      queue.remove(order);
      order.startTimer();
      preparing.add(order);
    });

    // Update order status in database from 'Waiting' to 'OnProcess'
    if (order.orderId != null) {
      await OrderService.updateOrderStatus(order.orderId!, 'OnProcess');
    }
    await AudioService.playLogin();
  }

  void _completeOrder(Order order) async {
    setState(() {
      preparing.remove(order);
      order.stopTimer();
      done.add(order);
    });

    // Update order status in database from 'OnProcess' to 'Completed'
    if (order.orderId != null) {
      await OrderService.updateOrderStatus(order.orderId!, 'Completed');
    }
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

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          SizedBox(height: 16),
          Text(
            'Error loading orders',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error occurred',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadOrders,
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading orders...'),
        ],
      ),
    );
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
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: _isLoading ? null : _loadOrders,
            ),
            SizedBox(width: 8),
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
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? _buildLoadingWidget()
          : _errorMessage != null
          ? _buildErrorWidget()
          : LayoutBuilder(
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