import 'package:cake_bliss/constants/app_colors.dart';
import 'package:cake_bliss/types/type_details.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Viewpage extends StatelessWidget {
  final String categoryName;

  const Viewpage({
    Key? key,
    required this.categoryName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 200,
        title: const SizedBox.shrink(),
        flexibleSpace: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'asset/chocolate-liqueurs-alcohol-content-varies-in-the-candy-version-1703220515.jpg',
              fit: BoxFit.cover,
            ),
            Container(),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16, right: 16),
                child: Text(
                  categoryName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: _firestore
            .collection('types')
            .where('category', isEqualTo: categoryName)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('No types available in this category.'));
          }

          final types = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: types.length,
            itemBuilder: (context, index) {
              var type = types[index].data() as Map<String, dynamic>;

              return Card(
                color: AppColors().subcolor,
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      type['image'],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.image_not_supported,
                        size: 40,
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const CircularProgressIndicator();
                      },
                    ),
                  ),
                  title: Text(
                    type['name'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Rate: ₹${type['rate']}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => TypeDetailsPage(
                              typeId: types[index].id,
                              categoryName: categoryName,
                              typeData: type)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
