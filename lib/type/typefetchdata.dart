// import 'package:cake_bliss/constants/app_colors.dart';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';

// class UserTypesPage extends StatelessWidget {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   UserTypesPage({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         toolbarHeight: 100,
//         backgroundColor: AppColors().mainColor,
//         title: Center(
//             child: Text(
//           'Types',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         )),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore
//             .collection('types')
//             .orderBy('createdAt', descending: true)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           }

//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return Center(child: Text('No types available'));
//           }

//           return GridView.builder(
//             padding: EdgeInsets.all(16),
//             gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 2,
//               childAspectRatio: 0.75,
//               crossAxisSpacing: 16,
//               mainAxisSpacing: 16,
//             ),
//             itemCount: snapshot.data!.docs.length,
//             itemBuilder: (context, index) {
//               final doc = snapshot.data!.docs[index];
//               final data = doc.data() as Map<String, dynamic>;

//               return GestureDetector(
//                   // onTap: () {
//                   //   Navigator.push(
//                   //       context,
//                   //       MaterialPageRoute(
//                   //           builder: (context) => TypeDetailsPage(
//                   //                 typeData: data,
//                   //               )));
//                   // },
//                   child: Card(
//                 clipBehavior: Clip.antiAlias,
//                 elevation: 2,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Main image
//                     Expanded(
//                       child: Container(
//                         width: double.infinity,
//                         child: Image.network(
//                           data['image'],
//                           fit: BoxFit.cover,
//                           errorBuilder: (context, error, stackTrace) =>
//                               Container(
//                             color: Colors.grey[300],
//                             child: Icon(Icons.error),
//                           ),
//                         ),
//                       ),
//                     ),
//                     // Name and rate
//                     Padding(
//                       padding: EdgeInsets.all(8),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             data['name'],
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                             ),
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           SizedBox(height: 4),
//                           Text(
//                             '₹${data['rate']}',
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: Colors.green[700],
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ));
//             },
//           );
//         },
//       ),
//     );
//   }
// }
