import 'package:cake_bliss/types/type_details.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cake_bliss/constants/app_colors.dart';

class FavouritePage extends StatelessWidget {
  const FavouritePage({Key? key}) : super(key: key);

  void navigateToTypeDetails(
      BuildContext context, Map<String, dynamic> cakeData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TypeDetailsPage(
          typeId: cakeData['typeId'],
          categoryName: cakeData['categoryName'],
          typeData: cakeData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorites'),
        backgroundColor: AppColors().mainColor,
      ),
      body: userId == null
          ? const Center(
              child: Text('Please login to view favorites'),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('favorites')
                  .doc(userId)
                  .collection('items')
                  .orderBy('addedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No favorites added yet'),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return GestureDetector(
                        onTap: () => navigateToTypeDetails(context, data),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Cake Image
                              Expanded(
                                flex: 3,
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                          top: Radius.circular(12),
                                        ),
                                        image: DecorationImage(
                                          image:
                                              NetworkImage(data['image'] ?? ''),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: CircleAvatar(
                                        backgroundColor: Colors.white,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.favorite,
                                            color: Colors.red,
                                          ),
                                          onPressed: () async {
                                            try {
                                              await FirebaseFirestore.instance
                                                  .collection('favorites')
                                                  .doc(userId)
                                                  .collection('items')
                                                  .doc(doc.id)
                                                  .delete();
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'Removed from favorites'),
                                                  duration:
                                                      Duration(seconds: 1),
                                                ),
                                              );
                                            } catch (e) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'Failed to remove from favorites'),
                                                  duration:
                                                      Duration(seconds: 2),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Cake Details
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data['name'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Category: ${data['categoryName'] ?? ''}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '₹${data['price']?.toString() ?? '0'}',
                                        style: TextStyle(
                                          color: AppColors().mainColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
