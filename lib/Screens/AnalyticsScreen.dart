import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );
  String _selectedOrderType = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        // Switched to a case statement for better readability
        switch (_tabController.index) {
          case 0:
            _selectedOrderType = 'all';
            break;
          case 1:
            _selectedOrderType = 'delivery';
            break;
          case 2:
            _selectedOrderType = 'take_away';
            break;
          case 3: // New case for Pickup
            _selectedOrderType = 'pickup';
            break;
          case 4:
            _selectedOrderType = 'dine_in';
            break;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Analytics & Reports',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
            fontSize: 24,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: _buildOrderTypeTabs(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateRangeSelector(),
            const SizedBox(height: 32),

            // Analytics Overview Cards
            _buildAnalyticsOverviewCards(),
            const SizedBox(height: 32),

            buildSectionHeader('Sales Trend', Icons.trending_up),
            const SizedBox(height: 16),
            _buildSalesChart(),
            const SizedBox(height: 32),

            buildSectionHeader('Performance', Icons.star_border),
            const SizedBox(height: 16),
            _buildTopItemsList(),
            const SizedBox(height: 32),

            buildSectionHeader('Distribution', Icons.pie_chart_outline),
            const SizedBox(height: 16),
            _buildOrderTypeDistributionChart(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTypeTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: Colors.deepPurple,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.deepPurple,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(
            icon: Icon(Icons.dashboard_outlined, size: 18),
            text: 'All',
          ),
          Tab(
            icon: Icon(Icons.delivery_dining_outlined, size: 18),
            text: 'Delivery',
          ),
          Tab(
            icon: Icon(Icons.shopping_bag_outlined, size: 18),
            text: 'Takeaway',
          ),
          // --- NEW TAB ADDED ---
          Tab(
            icon: Icon(Icons.storefront_outlined, size: 18),
            text: 'Pickup',
          ),
          // --- END NEW TAB ---
          Tab(
            icon: Icon(Icons.table_bar_outlined, size: 18),
            text: 'Dine In',
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () async {
                final newRange = await showDateRangePicker(
                  context: context,
                  initialDateRange: _dateRange,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Colors.deepPurple,
                          onPrimary: Colors.white,
                          onSurface: Colors.black87,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (newRange != null) {
                  setState(() {
                    _dateRange = DateTimeRange(
                      start: newRange.start,
                      end: DateTime(newRange.end.year, newRange.end.month,
                          newRange.end.day, 23, 59, 59),
                    );
                  });
                }
              },
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Date Range',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormat('MMM dd, yyyy').format(_dateRange.start)} - ${DateFormat('MMM dd, yyyy').format(_dateRange.end)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  _dateRange = DateTimeRange(
                    start: DateTime.now().subtract(const Duration(days: 7)),
                    end: DateTime.now(),
                  );
                });
              },
              child: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsOverviewCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getOrdersQuery().snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data?.docs ?? [];
        final totalOrders = orders.length;
        final totalRevenue = orders.fold<double>(
          0,
              (sum, doc) {
            final data = doc.data() as Map<String, dynamic>;
            return sum + ((data['totalAmount'] as num?)?.toDouble() ?? 0);
          },
        );
        final avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0;

        return Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Orders',
                totalOrders.toString(),
                Icons.receipt_long_outlined,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Revenue',
                'QAR ${totalRevenue.toStringAsFixed(0)}',
                Icons.attach_money_outlined,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Avg Order',
                'QAR ${avgOrderValue.toStringAsFixed(0)}',
                Icons.trending_up_outlined,
                Colors.orange,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),

          // Center and scale long values
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              textAlign: TextAlign.center,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),

          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.deepPurple, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
      ],
    );
  }

  Widget _buildSalesChart() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          height: 300,
          child: StreamBuilder<QuerySnapshot>(
            stream: _getOrdersQuery().snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.bar_chart_outlined,
                  message: 'No sales data available for this range.',
                );
              }

              // Aggregate sales by day
              final ordersByDay = snapshot.data!.docs.fold<Map<DateTime, double>>(
                {},
                    (map, doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final timestamp = data['timestamp'] as Timestamp;
                  final date = timestamp.toDate();
                  final day = DateTime(date.year, date.month, date.day);
                  final total = (data['totalAmount'] as num?)?.toDouble() ?? 0;
                  map[day] = (map[day] ?? 0) + total;
                  return map;
                },
              );

              // Generate all days in the range
              final List<DateTime> allDays = [];
              DateTime current = DateTime(
                  _dateRange.start.year, _dateRange.start.month, _dateRange.start.day);
              final end = DateTime(_dateRange.end.year, _dateRange.end.month,
                  _dateRange.end.day)
                  .add(const Duration(days: 1));

              while (current.isBefore(end)) {
                allDays.add(current);
                current = current.add(const Duration(days: 1));
              }

              // Prepare chart data
              final chartData = allDays.map((day) {
                return SalesData(
                  day,
                  ordersByDay[day] ?? 0,
                  DateFormat('MMM dd').format(day),
                );
              }).toList();

              return SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  majorGridLines: const MajorGridLines(width: 0),
                  axisLine: const AxisLine(width: 0),
                  labelStyle: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(
                    text: 'Sales Amount (QAR)',
                    textStyle: TextStyle(color: Colors.grey[700]),
                  ),
                  majorGridLines: const MajorGridLines(width: 0.5, color: Colors.grey),
                  axisLine: const AxisLine(width: 0),
                  labelStyle: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  header: '',
                  canShowMarker: false,
                  animationDuration: 0,
                  color: Colors.deepPurpleAccent,
                  textStyle: const TextStyle(color: Colors.white, fontSize: 14),
                  format: 'QAR point.y',
                ),
                series: <CartesianSeries<SalesData, String>>[
                  ColumnSeries<SalesData, String>(
                    dataSource: chartData,
                    xValueMapper: (SalesData sales, _) => sales.label,
                    yValueMapper: (SalesData sales, _) => sales.amount,
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple.shade300,
                        Colors.deepPurple.shade600,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    width: 0.7,
                    animationDuration: 1000,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopItemsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<QuerySnapshot>(
          stream: _getOrdersQuery().snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState(
                icon: Icons.restaurant_menu_outlined,
                message: 'No items sold in selected range.',
              );
            }

            final itemCounts = <String, int>{};
            final itemRevenue = <String, double>{};

            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final items = List<Map<String, dynamic>>.from(data['items'] ?? []);

              for (var item in items) {
                final itemName = item['name'] ?? 'Unknown Item';
                final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
                final price = (item['price'] as num?)?.toDouble() ?? 0;

                itemCounts.update(itemName, (value) => value + quantity,
                    ifAbsent: () => quantity);
                itemRevenue.update(
                  itemName,
                      (value) => value + (price * quantity),
                  ifAbsent: () => price * quantity,
                );
              }
            }

            if (itemCounts.isEmpty) {
              return _buildEmptyState(
                icon: Icons.restaurant_menu_outlined,
                message: 'No items sold in selected range.',
              );
            }

            final sortedItems = itemCounts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            final topItems = sortedItems.take(5).toList();

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topItems.length,
              itemBuilder: (context, index) {
                final item = topItems[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.deepPurple.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.deepPurple.shade300,
                              Colors.deepPurple.shade500,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '#${index + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Revenue: QAR ${itemRevenue[item.key]?.toStringAsFixed(2) ?? '0.00'}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${item.value}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            'sold',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderTypeDistributionChart() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          height: 300,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Orders')
                .where('timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(_dateRange.start))
                .where('timestamp',
                isLessThanOrEqualTo: Timestamp.fromDate(_dateRange.end))
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.pie_chart_outline,
                  message: 'No order type data for the selected range.',
                );
              }

              final orderTypeCounts = <String, int>{
                'delivery': 0,
                'take_away': 0,
                'pickup': 0,
                'dine_in': 0,
              };
              int totalOrders = 0;

              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                String rawOrderType = (data['Order_type'] as String?) ?? 'unknown';
                String cleanedRaw = rawOrderType.trim().toLowerCase();
                String normalizedKey;

                if (cleanedRaw == 'delivery') {
                  normalizedKey = 'delivery';
                } else if (cleanedRaw == 'take_away') {
                  normalizedKey = 'take_away';
                } else if (cleanedRaw == 'pickup') { // Add check for pickup
                  normalizedKey = 'pickup';
                } else if (cleanedRaw == 'dine_in') {
                  normalizedKey = 'dine_in';
                } else {
                  normalizedKey = 'unknown';
                }

                if (orderTypeCounts.containsKey(normalizedKey)) {
                  orderTypeCounts[normalizedKey] = orderTypeCounts[normalizedKey]! + 1;
                  totalOrders++;
                }
              }

              final chartData = orderTypeCounts.entries
                  .where((entry) => entry.value > 0)
                  .map((entry) => OrderTypeData(
                entry.key,
                entry.value,
                _getOrderTypeColor(entry.key),
              ))
                  .toList();

              if (chartData.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.pie_chart_outline,
                  message: 'No order type data for the selected range.',
                );
              }

              return SfCircularChart(
                legend: Legend(
                  isVisible: true,
                  overflowMode: LegendItemOverflowMode.wrap,
                  position: LegendPosition.bottom,
                  textStyle: TextStyle(color: Colors.grey[700]),
                ),
                series: <PieSeries<OrderTypeData, String>>[
                  PieSeries<OrderTypeData, String>(
                    dataSource: chartData,
                    xValueMapper: (OrderTypeData data, _) => data.orderType,
                    yValueMapper: (OrderTypeData data, _) => data.count,
                    pointColorMapper: (OrderTypeData data, _) => data.color,
                    dataLabelMapper: (OrderTypeData data, _) {
                      final percentage = (data.count / totalOrders * 100).toStringAsFixed(1);
                      return '${_formatOrderTypeForPieLabel(data.orderType)}\n$percentage%';
                    },
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.inside,
                      textStyle: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    explode: true,
                    explodeIndex: 0,
                    radius: '80%',
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Query<Map<String, dynamic>> _getOrdersQuery() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('Orders')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(_dateRange.start))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(_dateRange.end))
        .orderBy('timestamp', descending: true);

    if (_selectedOrderType != 'all') {
      query = query.where('Order_type', isEqualTo: _selectedOrderType);
    }
    return query;
  }

  Color _getOrderTypeColor(String orderType) {
    switch (orderType.toLowerCase()) {
      case 'delivery':
        return Colors.blue.shade600;
      case 'take_away':
        return Colors.orange.shade600;
      case 'pickup': // Add color for pickup
        return Colors.purple.shade600;
      case 'dine_in':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade400;
    }
  }

  String _formatOrderTypeForPieLabel(String normalizedKey) {
    switch (normalizedKey) {
      case 'delivery':
        return 'Delivery';
      case 'take_away':
        return 'Take Away';
      case 'pickup': // Add label for pickup
        return 'Pick Up';
      case 'dine_in':
        return 'Dine In';
      default:
        return 'Other';
    }
  }
}

class SalesData {
  final DateTime date;
  final double amount;
  final String label;
  SalesData(this.date, this.amount, this.label);
}

class OrderTypeData {
  final String orderType;
  final int count;
  final Color color;
  OrderTypeData(this.orderType, this.count, this.color);
}
