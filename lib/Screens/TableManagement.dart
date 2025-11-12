// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
//
// class TableManagementScreen extends StatelessWidget {
//   const TableManagementScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         centerTitle: true,
//         title: const Text(
//           'Table Management',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: Colors.deepPurple,
//             fontSize: 24,
//           ),
//         ),
//         actions: [
//           Container(
//             margin: const EdgeInsets.only(right: 16),
//             decoration: BoxDecoration(
//               color: Colors.deepPurple,
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: IconButton(
//               icon: const Icon(Icons.add, color: Colors.white),
//               onPressed: () => _showAddTableDialog(context, null, null),
//               tooltip: 'Add New Table',
//             ),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Enhanced Search Section
//           Container(
//             margin: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.deepPurple.withOpacity(0.1),
//                   blurRadius: 10,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: TextField(
//               decoration: InputDecoration(
//                 hintText: 'Search tables by number or branch...',
//                 hintStyle: TextStyle(color: Colors.grey[400]),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(16),
//                   borderSide: BorderSide.none,
//                 ),
//                 filled: true,
//                 fillColor: Colors.white,
//                 prefixIcon: Icon(
//                   Icons.search_rounded,
//                   color: Colors.deepPurple.shade300,
//                   size: 24,
//                 ),
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 20,
//                   vertical: 16,
//                 ),
//               ),
//               onChanged: (query) {
//                 // TODO: Implement search filtering
//               },
//             ),
//           ),
//
//           // Enhanced Branch List
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance.collection('Branch').snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         CircularProgressIndicator(
//                           valueColor: AlwaysStoppedAnimation(
//                             Colors.deepPurple,
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//                         Text(
//                           'Loading branches...',
//                           style: TextStyle(
//                             color: Colors.grey[600],
//                             fontSize: 16,
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 }
//
//                 if (snapshot.hasError) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(
//                           Icons.error_outline,
//                           size: 64,
//                           color: Colors.red[300],
//                         ),
//                         const SizedBox(height: 16),
//                         Text(
//                           'Error: ${snapshot.error}',
//                           style: const TextStyle(color: Colors.red, fontSize: 16),
//                           textAlign: TextAlign.center,
//                         ),
//                       ],
//                     ),
//                   );
//                 }
//
//                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(
//                           Icons.business_outlined,
//                           size: 64,
//                           color: Colors.grey[400],
//                         ),
//                         const SizedBox(height: 16),
//                         Text(
//                           'No branches found.',
//                           style: TextStyle(
//                             color: Colors.grey[600],
//                             fontSize: 18,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           'Add a branch to get started.',
//                           style: TextStyle(
//                             color: Colors.grey[500],
//                             fontSize: 14,
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 }
//
//                 final branches = snapshot.data!.docs;
//                 return ListView.builder(
//                   padding: const EdgeInsets.symmetric(horizontal: 20),
//                   itemCount: branches.length,
//                   itemBuilder: (context, index) {
//                     final branchDoc = branches[index];
//                     final branchData = branchDoc.data() as Map<String, dynamic>;
//                     final name = branchData['name'] ?? 'Unnamed Branch';
//                     final Map<String, dynamic> tables =
//                     Map<String, dynamic>.from(branchData['Tables'] as Map<String, dynamic>? ?? {});
//
//                     return Container(
//                       margin: const EdgeInsets.only(bottom: 20),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(20),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.05),
//                             blurRadius: 10,
//                             offset: const Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       child: Theme(
//                         data: Theme.of(context).copyWith(
//                           dividerColor: Colors.transparent,
//                         ),
//                         child: ExpansionTile(
//                           tilePadding: const EdgeInsets.symmetric(
//                             horizontal: 24,
//                             vertical: 8,
//                           ),
//                           childrenPadding: const EdgeInsets.only(
//                             left: 16,
//                             right: 16,
//                             bottom: 16,
//                           ),
//                           title: Row(
//                             children: [
//                               Container(
//                                 padding: const EdgeInsets.all(12),
//                                 decoration: BoxDecoration(
//                                   color: Colors.deepPurple.withOpacity(0.1),
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: Icon(
//                                   Icons.business_rounded,
//                                   color: Colors.deepPurple,
//                                   size: 24,
//                                 ),
//                               ),
//                               const SizedBox(width: 16),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       name,
//                                       style: const TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         fontSize: 18,
//                                         color: Colors.black87,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 4),
//                                     Row(
//                                       children: [
//                                         Icon(
//                                           Icons.table_restaurant_rounded,
//                                           size: 16,
//                                           color: Colors.grey[600],
//                                         ),
//                                         const SizedBox(width: 4),
//                                         Text(
//                                           '${tables.length} tables',
//                                           style: TextStyle(
//                                             color: Colors.grey[600],
//                                             fontSize: 14,
//                                             fontWeight: FontWeight.w500,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                           initiallyExpanded: tables.isNotEmpty,
//                           trailing: Container(
//                             padding: const EdgeInsets.all(8),
//                             decoration: BoxDecoration(
//                               color: Colors.deepPurple,
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             child: IconButton(
//                               icon: const Icon(
//                                 Icons.add_rounded,
//                                 color: Colors.white,
//                                 size: 20,
//                               ),
//                               onPressed: () => _showAddTableDialog(
//                                 context,
//                                 branchDoc.id,
//                                 tables,
//                               ),
//                               padding: EdgeInsets.zero,
//                               constraints: const BoxConstraints(),
//                               tooltip: 'Add Table',
//                             ),
//                           ),
//                           children: tables.isEmpty
//                               ? [
//                             Container(
//                               padding: const EdgeInsets.all(24),
//                               child: Column(
//                                 children: [
//                                   Icon(
//                                     Icons.table_restaurant_outlined,
//                                     size: 48,
//                                     color: Colors.grey[400],
//                                   ),
//                                   const SizedBox(height: 12),
//                                   Text(
//                                     'No tables in this branch',
//                                     style: TextStyle(
//                                       color: Colors.grey[600],
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 8),
//                                   Text(
//                                     'Tap the + button to add your first table',
//                                     style: TextStyle(
//                                       color: Colors.grey[500],
//                                       fontSize: 14,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ]
//                               : tables.entries.map((entry) {
//                             final tableId = entry.key;
//                             final Map<String, dynamic> tableData =
//                             Map<String, dynamic>.from(entry.value as Map<String, dynamic>);
//                             final seats = tableData['seats'] ?? 0;
//                             final status = (tableData['status'] ?? 'available').toString();
//
//                             Color statusColor;
//                             Color statusBgColor;
//                             IconData statusIcon;
//
//                             switch (status) {
//                               case 'available':
//                                 statusColor = Colors.green;
//                                 statusBgColor = Colors.green.withOpacity(0.1);
//                                 statusIcon = Icons.check_circle_rounded;
//                                 break;
//                               case 'occupied':
//                                 statusColor = Colors.orange;
//                                 statusBgColor = Colors.orange.withOpacity(0.1);
//                                 statusIcon = Icons.people_rounded;
//                                 break;
//                               case 'reserved':
//                                 statusColor = Colors.blue;
//                                 statusBgColor = Colors.blue.withOpacity(0.1);
//                                 statusIcon = Icons.bookmark_rounded;
//                                 break;
//                               default:
//                                 statusColor = Colors.grey;
//                                 statusBgColor = Colors.grey.withOpacity(0.1);
//                                 statusIcon = Icons.help_rounded;
//                             }
//
//                             return Container(
//                               margin: const EdgeInsets.symmetric(
//                                 horizontal: 8,
//                                 vertical: 6,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: Colors.grey[50],
//                                 borderRadius: BorderRadius.circular(16),
//                                 border: Border.all(
//                                   color: Colors.grey[200]!,
//                                   width: 1,
//                                 ),
//                               ),
//                               child: ListTile(
//                                 contentPadding: const EdgeInsets.symmetric(
//                                   horizontal: 20,
//                                   vertical: 8,
//                                 ),
//                                 leading: Container(
//                                   padding: const EdgeInsets.all(12),
//                                   decoration: BoxDecoration(
//                                     color: statusBgColor,
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   child: Icon(
//                                     statusIcon,
//                                     color: statusColor,
//                                     size: 24,
//                                   ),
//                                 ),
//                                 title: Text(
//                                   'Table $tableId',
//                                   style: const TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 16,
//                                     color: Colors.black87,
//                                   ),
//                                 ),
//                                 subtitle: Padding(
//                                   padding: const EdgeInsets.only(top: 4),
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Row(
//                                         children: [
//                                           Icon(
//                                             Icons.chair_rounded,
//                                             size: 16,
//                                             color: Colors.grey[600],
//                                           ),
//                                           const SizedBox(width: 4),
//                                           Text(
//                                             '$seats seats',
//                                             style: TextStyle(
//                                               color: Colors.grey[600],
//                                               fontSize: 14,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                       const SizedBox(height: 4),
//                                       Container(
//                                         padding: const EdgeInsets.symmetric(
//                                           horizontal: 8,
//                                           vertical: 4,
//                                         ),
//                                         decoration: BoxDecoration(
//                                           color: statusBgColor,
//                                           borderRadius: BorderRadius.circular(8),
//                                         ),
//                                         child: Text(
//                                           status.toUpperCase(),
//                                           style: TextStyle(
//                                             color: statusColor,
//                                             fontSize: 12,
//                                             fontWeight: FontWeight.bold,
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 trailing: SizedBox(
//                                   width: 100,
//                                   child: Row(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                       Expanded(
//                                         child: Container(
//                                           margin: const EdgeInsets.only(right: 4),
//                                           decoration: BoxDecoration(
//                                             color: Colors.blue.withOpacity(0.1),
//                                             borderRadius: BorderRadius.circular(8),
//                                           ),
//                                           child: IconButton(
//                                             icon: const Icon(
//                                               Icons.edit_rounded,
//                                               color: Colors.blue,
//                                               size: 18,
//                                             ),
//                                             onPressed: () => _showEditTableDialog(
//                                               context,
//                                               branchDoc.id,
//                                               tableId,
//                                               tableData,
//                                             ),
//                                             tooltip: 'Edit Table',
//                                             padding: const EdgeInsets.all(6),
//                                           ),
//                                         ),
//                                       ),
//                                       Expanded(
//                                         child: Container(
//                                           decoration: BoxDecoration(
//                                             color: Colors.red.withOpacity(0.1),
//                                             borderRadius: BorderRadius.circular(8),
//                                           ),
//                                           child: IconButton(
//                                             icon: const Icon(
//                                               Icons.delete_rounded,
//                                               color: Colors.red,
//                                               size: 18,
//                                             ),
//                                             onPressed: () async {
//                                               final confirm = await _confirmDelete(context);
//                                               if (confirm) {
//                                                 final updatedTables = Map<String, dynamic>.from(tables);
//                                                 updatedTables.remove(tableId);
//                                                 await FirebaseFirestore.instance
//                                                     .collection('Branch')
//                                                     .doc(branchDoc.id)
//                                                     .update({'Tables': updatedTables});
//                                               }
//                                             },
//                                             tooltip: 'Delete Table',
//                                             padding: const EdgeInsets.all(6),
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             );
//                           }).toList(),
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _showAddTableDialog(
//       BuildContext context,
//       String? branchIds,
//       Map<String, dynamic>? currentTables,
//       ) async {
//     if (branchIds == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Branch not found')),
//       );
//       return;
//     }
//
//     await _showTableDialog(
//       context,
//       branchIds: branchIds,
//       existingTableData: const {},
//       isEdit: false,
//     );
//   }
//
//   Future<void> _showEditTableDialog(
//       BuildContext context,
//       String branchIds,
//       String tableId,
//       Map<String, dynamic> tableData,
//       ) async {
//     await _showTableDialog(
//       context,
//       branchIds: branchIds,
//       existingTableData: tableData,
//       isEdit: true,
//       existingTableId: tableId,
//     );
//   }
//
//   Future<void> _showTableDialog(
//       BuildContext context, {
//         required String branchIds,
//         required Map<String, dynamic> existingTableData,
//         required bool isEdit,
//         String? existingTableId,
//       }) async {
//     final _formKey = GlobalKey<FormState>();
//     final _idCtrl = TextEditingController(text: existingTableId ?? '');
//     final _seatsCtrl = TextEditingController(
//       text: (existingTableData['seats'] ?? '').toString(),
//     );
//
//     // Allowed statuses and labels (single source of truth)
//     const List<String> kStatusValues = ['available', 'occupied', 'reserved'];
//     const Map<String, String> kStatusLabels = {
//       'available': 'Available',
//       'occupied': 'Occupied',
//       'reserved': 'Reserved',
//     };
//
//     // Normalize any legacy/unknown value to an allowed value
//     String _normalizeStatus(String? raw) {
//       final s = (raw ?? '').trim().toLowerCase();
//       if (kStatusValues.contains(s)) return s;
//       switch (s) {
//         case 'ordered':
//         case 'booked':
//           return 'reserved';
//         case 'busy':
//           return 'occupied';
//         case 'free':
//           return 'available';
//         default:
//           return 'available';
//       }
//     }
//
//     // Ensure dropdown value is valid
//     String _status = _normalizeStatus(existingTableData['status']?.toString());
//
//     await showDialog<void>(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => StatefulBuilder(
//         builder: (context, setState) {
//           return Dialog(
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//             child: Container(
//               width: MediaQuery.of(context).size.width * 0.9,
//               padding: const EdgeInsets.all(24),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Header
//                   Row(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: Colors.deepPurple.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Icon(
//                           isEdit ? Icons.edit_rounded : Icons.add_rounded,
//                           color: Colors.deepPurple,
//                           size: 24,
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: Text(
//                           isEdit ? 'Edit Table' : 'Add New Table',
//                           style: const TextStyle(
//                             fontSize: 22,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.deepPurple,
//                           ),
//                         ),
//                       ),
//                       IconButton(
//                         onPressed: () => Navigator.pop(context),
//                         icon: const Icon(Icons.close_rounded),
//                         color: Colors.grey[600],
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 24),
//
//                   // Form
//                   Form(
//                     key: _formKey,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Table ID
//                         TextFormField(
//                           controller: _idCtrl,
//                           enabled: !isEdit,
//                           decoration: InputDecoration(
//                             labelText: 'Table ID',
//                             hintText: 'Enter table identifier',
//                             prefixIcon: Icon(
//                               Icons.tag_rounded,
//                               color: Colors.deepPurple.shade400,
//                             ),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: BorderSide(color: Colors.deepPurple, width: 2),
//                             ),
//                             filled: true,
//                             fillColor: isEdit ? Colors.grey[100] : Colors.white,
//                           ),
//                           validator: (v) => (v == null || v.trim().isEmpty) ? 'Table ID is required' : null,
//                         ),
//                         const SizedBox(height: 16),
//
//                         // Seats
//                         TextFormField(
//                           controller: _seatsCtrl,
//                           decoration: InputDecoration(
//                             labelText: 'Number of Seats',
//                             hintText: 'Enter seat capacity',
//                             prefixIcon: Icon(
//                               Icons.chair_rounded,
//                               color: Colors.deepPurple.shade400,
//                             ),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: BorderSide(color: Colors.deepPurple, width: 2),
//                             ),
//                             filled: true,
//                             fillColor: Colors.white,
//                           ),
//                           keyboardType: TextInputType.number,
//                           validator: (v) {
//                             if (v == null || v.trim().isEmpty) return 'Number of seats is required';
//                             final seats = int.tryParse(v);
//                             if (seats == null || seats <= 0) return 'Please enter a valid number greater than 0';
//                             return null;
//                           },
//                         ),
//                         const SizedBox(height: 16),
//
//                         // Status
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Table Status',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w500,
//                                 color: Colors.grey[700],
//                               ),
//                             ),
//                             const SizedBox(height: 8),
//                             Container(
//                               decoration: BoxDecoration(
//                                 border: Border.all(color: Colors.grey[300]!),
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: DropdownButtonFormField<String>(
//                                 value: kStatusValues.contains(_status) ? _status : 'available',
//                                 isExpanded: true,
//                                 decoration: InputDecoration(
//                                   border: InputBorder.none,
//                                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                                   prefixIcon: Icon(
//                                     Icons.info_outline_rounded,
//                                     color: Colors.deepPurple.shade400,
//                                   ),
//                                 ),
//                                 items: kStatusValues
//                                     .map(
//                                       (v) => DropdownMenuItem<String>(
//                                     value: v,
//                                     child: Row(
//                                       children: [
//                                         Container(
//                                           width: 12,
//                                           height: 12,
//                                           decoration: BoxDecoration(
//                                             shape: BoxShape.circle,
//                                             color: v == 'available'
//                                                 ? Colors.green
//                                                 : v == 'occupied'
//                                                 ? Colors.orange
//                                                 : Colors.blue,
//                                           ),
//                                         ),
//                                         const SizedBox(width: 8),
//                                         Text(kStatusLabels[v]!),
//                                       ],
//                                     ),
//                                   ),
//                                 )
//                                     .toList(),
//                                 onChanged: (val) => setState(() => _status = _normalizeStatus(val)),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 32),
//
//                   // Action buttons
//                   Row(
//                     children: [
//                       Expanded(
//                         child: OutlinedButton(
//                           onPressed: () => Navigator.pop(context),
//                           style: OutlinedButton.styleFrom(
//                             padding: const EdgeInsets.symmetric(vertical: 16),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             side: BorderSide(color: Colors.grey[400]!),
//                           ),
//                           child: Text(
//                             'Cancel',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.grey[700],
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: ElevatedButton(
//                           onPressed: () async {
//                             if (!_formKey.currentState!.validate()) return;
//
//                             final tableId = _idCtrl.text.trim();
//                             final seats = int.parse(_seatsCtrl.text.trim());
//
//                             final branchRef = FirebaseFirestore.instance.collection('Branch').doc(branchIds);
//                             final snap = await branchRef.get();
//                             final Map<String, dynamic> tables =
//                             Map<String, dynamic>.from(snap.data()?['Tables'] as Map<String, dynamic>? ?? {});
//
//                             if (!isEdit && tables.containsKey(tableId)) {
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(
//                                   content: Text('Table ID already exists in this branch'),
//                                   backgroundColor: Colors.red,
//                                 ),
//                               );
//                               return;
//                             }
//
//                             tables[tableId] = {
//                               'seats': seats,
//                               'status': _status, // normalized and valid
//                             };
//
//                             await branchRef.update({'Tables': tables});
//                             Navigator.pop(context);
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(
//                                 content: Text(
//                                   isEdit ? 'Table updated successfully' : 'Table "$tableId" added successfully',
//                                 ),
//                                 backgroundColor: Colors.green,
//                               ),
//                             );
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.deepPurple,
//                             padding: const EdgeInsets.symmetric(vertical: 16),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                           ),
//                           child: Text(
//                             isEdit ? 'Update Table' : 'Add Table',
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Future<bool> _confirmDelete(BuildContext context) async {
//     return await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Row(
//           children: [
//             Icon(Icons.warning_rounded, color: Colors.red, size: 28),
//             const SizedBox(width: 12),
//             const Text(
//               'Confirm Delete',
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//           ],
//         ),
//         content: const Text('Are you sure you want to delete this table? This action cannot be undone.'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             style: TextButton.styleFrom(
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//             ),
//             child: Text(
//               'Cancel',
//               style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600),
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//             ),
//             child: const Text(
//               'Delete',
//               style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
//             ),
//           ),
//         ],
//       ),
//     ) ??
//         false;
//   }
// }