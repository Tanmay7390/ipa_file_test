// import 'package:flutter/cupertino.dart';

// // Example main screen showing how to use the InvoiceBottomFixedArea
// class MainScreen extends StatelessWidget {
//   const MainScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return CupertinoPageScaffold(
//       navigationBar: const CupertinoNavigationBar(
//         middle: Text('Invoices'),
//       ),
//       child: Column(
//         children: [
//           // Your main content goes here
//           Expanded(
//             child: SafeArea(
//               child: CustomScrollView(
//                 slivers: [
//                   // Example content - replace with your actual content
//                   CupertinoSliverRefreshControl(
//                     onRefresh: () async {
//                       // Refresh logic
//                     },
//                   ),
//                   SliverToBoxAdapter(
//                     child: Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: Column(
//                         children: [
//                           // Sample invoice list items
//                           _buildInvoiceCard('INV-001', 'John Doe', '₹50,000', 'Paid'),
//                           const SizedBox(height: 12),
//                           _buildInvoiceCard('INV-002', 'Jane Smith', '₹75,000', 'Pending'),
//                           const SizedBox(height: 12),
//                           _buildInvoiceCard('INV-003', 'Bob Wilson', '₹30,000', 'Overdue'),
//                           const SizedBox(height: 12),
//                           _buildInvoiceCard('INV-004', 'Alice Brown', '₹120,000', 'Paid'),
//                           const SizedBox(height: 12),
//                           _buildInvoiceCard('INV-005', 'Mike Johnson', '₹85,000', 'Pending'),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           // Bottom fixed area for creating new invoice
//           const InvoiceBottomFixedArea(),
//         ],
//       ),
//     );
//   }

//   Widget _buildInvoiceCard(String invoiceNo, String clientName, String amount, String status) {
//     Color statusColor;
//     switch (status.toLowerCase()) {
//       case 'paid':
//         statusColor = CupertinoColors.systemGreen;
//         break;
//       case 'pending':
//         statusColor = CupertinoColors.systemOrange;
//         break;
//       case 'overdue':
//         statusColor = CupertinoColors.systemRed;
//         break;
//       default:
//         statusColor = CupertinoColors.systemGrey;
//     }

//     return Container(
//       padding: const EdgeInsets.all(16.0),
//       decoration: BoxDecoration(
//         color: CupertinoColors.systemBackground,
//         borderRadius: BorderRadius.circular(12.0),
//         border: Border.all(
//           color: CupertinoColors.separator,
//           width: 0.5,
//         ),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   invoiceNo,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   clientName,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     color: CupertinoColors.systemGrey,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   amount,
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//             decoration: BoxDecoration(
//               color: statusColor.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(16),
//             ),
//             child: Text(
//               status,
//               style: TextStyle(
//                 color: statusColor,
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Alternative approach using FloatingActionButton style
// class MainScreenWithFAB extends StatelessWidget {
//   const MainScreenWithFAB({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return CupertinoPageScaffold(
//       navigationBar: const CupertinoNavigationBar(
//         middle: Text('Invoices'),
//       ),
//       child: Stack(
//         children: [
//           // Main content
//           SafeArea(
//             child: CustomScrollView(
//               slivers: [
//                 // Your main content here
//                 SliverToBoxAdapter(
//                   child: Container(
//                     height: 600, // Example content height
//                     padding: const EdgeInsets.all(16.0),
//                     child: const Column(
//                       children: [
//                         Text('Your invoice list content goes here...'),
//                         // Add your actual content
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           // Floating action button style
//           Positioned(
//             right: 16,
//             bottom: 32,
//             child: GestureDetector(
//               onTap: () => showInvoiceFormSheet(context),
//               child: Container(
//                 width: 56,
//                 height: 56,
//                 decoration: BoxDecoration(
//                   color: CupertinoColors.activeBlue,
//                   borderRadius: BorderRadius.circular(28),
//                   boxShadow: [
//                     BoxShadow(
//                       color: CupertinoColors.black.withOpacity(0.2),
//                       offset: const Offset(0, 2),
//                       blurRadius: 8,
//                     ),
//                   ],
//                 ),
//                 child: const Icon(
//                   CupertinoIcons.add,
//                   color: CupertinoColors.white,
//                   size: 24,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
