import 'package:cake_bliss/checkout/checkout_cart.dart';
import 'package:cake_bliss/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TypeDetailsPage extends StatefulWidget {
  final String typeId;
  final String categoryName;

  const TypeDetailsPage({
    Key? key,
    required this.typeId,
    required this.categoryName,
    required Map<String, dynamic> typeData,
  }) : super(key: key);

  @override
  State<TypeDetailsPage> createState() => _TypeDetailsPageState();
}

class _TypeDetailsPageState extends State<TypeDetailsPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _typeData;

  String? _selectedWeight;
  double _calculatedPrice = 0.0;
  double _baseRate = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchTypeData();
    _checkIfFavorite();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _isFavorite = false;

// Add these new methods
  Future<void> _checkIfFavorite() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final doc = await FirebaseFirestore.instance
            .collection('favorites')
            .doc(userId)
            .collection('items')
            .doc(widget.typeId)
            .get();

        setState(() {
          _isFavorite = doc.exists;
        });
      }
    } catch (e) {
      print('Error checking favorite status: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (!mounted) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add favorites')),
      );
      return;
    }

    try {
      final favoriteRef = FirebaseFirestore.instance
          .collection('favorites')
          .doc(userId)
          .collection('items')
          .doc(widget.typeId);

      final bool newFavoriteStatus = !_isFavorite;

      // Update UI immediately for better user experience
      setState(() {
        _isFavorite = newFavoriteStatus;
      });

      if (newFavoriteStatus) {
        // Add to favorites
        await favoriteRef.set({
          'typeId': widget.typeId,
          'name': _typeData!['name'],
          'image':
              _typeData!['images'].isNotEmpty ? _typeData!['images'][0] : '',
          'price': _typeData!['rate'],
          'categoryName': widget.categoryName,
          'addedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Added to favorites'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        // Remove from favorites
        await favoriteRef.delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from favorites'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      // Revert the state if operation failed
      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update favorites. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  int _quantity = 1;

  Future<void> _addToCart() async {
    if (_selectedWeight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a weight first')),
      );
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add items to cart')),
      );
      return;
    }

    try {
      // Reference to user's cart
      final cartRef = FirebaseFirestore.instance
          .collection('carts')
          .doc(userId)
          .collection('items');

      // Check if item already exists in cart
      final existingItem = await cartRef
          .where('typeId', isEqualTo: widget.typeId)
          .where('weight', isEqualTo: _selectedWeight)
          .get();

      if (existingItem.docs.isNotEmpty) {
        // Update quantity if item exists
        final doc = existingItem.docs.first;
        await cartRef.doc(doc.id).update({
          'quantity': FieldValue.increment(_quantity),
          'totalPrice': (_calculatedPrice * _quantity) +
              (doc.data()['totalPrice'] as num),
        });
      } else {
        // Add new item to cart
        await cartRef.add({
          'typeId': widget.typeId,
          'name': _typeData!['name'],
          'categoryName': widget.categoryName,
          'image': _typeData!['images'][0],
          'weight': _selectedWeight,
          'quantity': _quantity,
          'price': _calculatedPrice,
          'totalPrice': _calculatedPrice * _quantity,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to cart successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error adding to cart: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add to cart. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildQuantitySelector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.remove_circle_outline, color: AppColors().mainColor),
          onPressed: () {
            if (_quantity > 1) {
              setState(() {
                _quantity--;
                if (_selectedWeight != null) {
                  _calculatePrice(_selectedWeight!);
                }
              });
            }
          },
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors().mainColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _quantity.toString(),
            style: TextStyle(
              fontSize: 16,
              color: AppColors().mainColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.add_circle_outline, color: AppColors().mainColor),
          onPressed: () {
            setState(() {
              _quantity++;
              if (_selectedWeight != null) {
                _calculatePrice(_selectedWeight!);
              }
            });
          },
        ),
      ],
    );
  }

  Future<void> _fetchTypeData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('types')
          .doc(widget.typeId)
          .get();

      if (doc.exists) {
        setState(() {
          _typeData = doc.data() as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching type data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _calculatePrice(String weight) {
    // Remove 'kg' and safely parse the weight value
    double weightValue =
        double.tryParse(weight.replaceAll('kg', '').trim()) ?? 0.0;

    // Ensure base rate is correctly retrieved
    double baseRate = double.tryParse(_typeData!['rate'].toString()) ?? 0.0;

    setState(() {
      _selectedWeight = weight;
      // Multiply base rate by weight value
      _calculatedPrice = baseRate * weightValue;
    });

    print(
        'Base Rate: $baseRate, Weight: $weightValue, Calculated Price: $_calculatedPrice');
  }

  void _showCustomizationDialog() {
    if (_selectedWeight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a weight first'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Customize Your Cake',
            style: TextStyle(color: AppColors().mainColor),
          ),
          content: Text(
            'Would you like to create your own cake design for $_selectedWeight?',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('No', style: TextStyle(color: AppColors().mainColor)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/customization',
                  arguments: {
                    'typeId': widget.typeId,
                    'weight': _selectedWeight,
                    'basePrice': _typeData!['rate'],
                    'typeName': _typeData!['name'],
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors().mainColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Yes', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeightSelectionChips(List<dynamic> weights) {
    return Wrap(
      spacing: 10,
      children: weights.map((weight) {
        return ChoiceChip(
          label: Text(weight.toString()),
          selected: _selectedWeight == weight,
          onSelected: (bool selected) {
            if (selected) {
              _calculatePrice(weight.toString());
            }
          },
          backgroundColor: AppColors().mainColor,
          selectedColor: AppColors().subcolor.withOpacity(0.5),
        );
      }).toList(),
    );
  }

  Widget _buildImageCarousel(List<dynamic> images) {
    return Stack(
      children: [
        Card(
          color: AppColors().subcolor,
          elevation: 5,
          margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      images[index],
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.error_outline,
                              size: 40, color: Colors.red),
                        );
                      },
                    ),
                    // Semi-transparent overlay for better text visibility
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.3),
                            Colors.transparent,
                            Colors.white.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        // Image counter
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_currentPage + 1}/${images.length}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_typeData == null) {
      return const Scaffold(
        body: Center(child: Text('Type not found')),
      );
    }

    final List<dynamic> images = _typeData!['images'] ?? [];
    final List<dynamic> weights = _typeData!['weights'] ?? [];

    return Scaffold(
      backgroundColor: AppColors().subcolor,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors().mainColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Add to Cart',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedWeight == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please select a weight first')),
                    );
                    return;
                  }

                  // Create the item in the format expected by CheckoutPage
                  final directItem = {
                    'typeId': widget.typeId,
                    'name': _typeData!['name'],
                    'image': _typeData!['images'][0],
                    'weight': _selectedWeight,
                    'price': _calculatedPrice,
                    'quantity': _quantity,
                  };

                  // Use MaterialPageRoute instead of named route to pass the parameter correctly
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CheckoutPage(directCheckoutItem: directItem),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors().subcolor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Buy Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildImageCarousel(images),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _typeData!['name'],
                            style: TextStyle(
                              fontSize: 24,
                              color: AppColors().mainColor,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                              return ScaleTransition(
                                  scale: animation, child: child);
                            },
                            child: Icon(
                              _isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              key: ValueKey<bool>(_isFavorite),
                              color: _isFavorite
                                  ? Colors.red
                                  : AppColors().mainColor,
                              size: 24,
                            ),
                          ),
                          onPressed: _toggleFavorite,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Text(
                    //   'Category: ${widget.categoryName}',
                    //   style: TextStyle(
                    //     fontSize: 16,
                    //     color: Colors.grey[600],
                    //   ),
                    // ),
                    const SizedBox(height: 16),
                    Text(
                      '₹${_calculatedPrice > 0 ? _calculatedPrice.toStringAsFixed(2) : _baseRate.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_selectedWeight != null)
                      Text(
                        'for $_selectedWeight',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors().mainColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _typeData!['description'],
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Weights',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors().mainColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildWeightSelectionChips(weights),
                    Text(
                      'Quantity',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors().mainColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildQuantitySelector(),
                    const SizedBox(
                        height: 80), // Space at the bottom for better scrolling
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// class DirectCheckoutPage extends StatefulWidget {
//   const DirectCheckoutPage({Key? key}) : super(key: key);

//   @override
//   State<DirectCheckoutPage> createState() => _DirectCheckoutPageState();
// }

// class _DirectCheckoutPageState extends State<DirectCheckoutPage> {
//   List<Map<String, dynamic>> _addresses = [];
//   String? _selectedAddressId;
//   bool _isLoading = true;

//   // Order details
//   late String typeId;
//   late String typeName;
//   late String image;
//   late String weight;
//   late double price;
//   late int quantity;
//   late double totalAmount;
//   late String categoryName;

//   @override
//   void initState() {
//     super.initState();
//     _fetchAddresses();
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();

//     final args =
//         ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

//     typeId = args['typeId'];
//     typeName = args['typeName'];
//     image = args['image'];
//     weight = args['weight'];
//     price = args['price'];
//     quantity = args['quantity'];
//     totalAmount = price * quantity;
//     categoryName = args['categoryName'];
//   }

//   Future<void> _fetchAddresses() async {
//     try {
//       final userId = FirebaseAuth.instance.currentUser?.uid;
//       if (userId == null) {
//         setState(() => _isLoading = false);
//         return;
//       }

//       final snapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(userId)
//           .collection('addresses')
//           .get();

//       final addresses = snapshot.docs.map((doc) {
//         final data = doc.data();
//         data['id'] = doc.id;
//         return data;
//       }).toList();

//       setState(() {
//         _addresses = List<Map<String, dynamic>>.from(addresses);

//         if (_addresses.isNotEmpty) {
//           _selectedAddressId = _addresses[0]['id'];
//         }

//         _isLoading = false;
//       });
//     } catch (e) {
//       print('Error fetching addresses: $e');
//       setState(() => _isLoading = false);
//     }
//   }

//   void _showAddAddressDialog() {
//     Navigator.pushNamed(context, '/add-address').then((_) {
//       _fetchAddresses();
//     });
//   }

//   Future<void> _placeOrder() async {
//     if (_selectedAddressId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select an address')),
//       );
//       return;
//     }

//     setState(() => _isLoading = true);

//     try {
//       final userId = FirebaseAuth.instance.currentUser?.uid;
//       if (userId == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please login to place an order')),
//         );
//         setState(() => _isLoading = false);
//         return;
//       }

//       final selectedAddress = _addresses.firstWhere(
//         (address) => address['id'] == _selectedAddressId,
//       );

//       final orderRef = FirebaseFirestore.instance.collection('orders').doc();

//       await orderRef.set({
//         'userId': userId,
//         'orderId': orderRef.id,
//         'status': 'placed',
//         'totalAmount': totalAmount,
//         'items': [
//           {
//             'typeId': typeId,
//             'name': typeName,
//             'categoryName': categoryName,
//             'image': image,
//             'weight': weight,
//             'quantity': quantity,
//             'price': price,
//             'totalPrice': price * quantity,
//           }
//         ],
//         'shippingAddress': {
//           'name': selectedAddress['name'],
//           'phoneNumber': selectedAddress['phoneNumber'],
//           'address': selectedAddress['address'],
//           'city': selectedAddress['city'],
//           'state': selectedAddress['state'],
//           'pincode': selectedAddress['pincode'],
//         },
//         'paymentMethod': 'COD',
//         'createdAt': FieldValue.serverTimestamp(),
//       });

//       if (mounted) {
//         // Navigate to order success page
//         Navigator.pushReplacementNamed(context, '/order-success',
//             arguments: {'orderId': orderRef.id});
//       }
//     } catch (e) {
//       print('Error placing order: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Failed to place order. Please try again.'),
//             duration: Duration(seconds: 2),
//           ),
//         );
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Checkout'),
//         backgroundColor: AppColors().mainColor,
//         foregroundColor: Colors.white,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Order summary
//             Card(
//               elevation: 4,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Order Summary',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: AppColors().mainColor,
//                       ),
//                     ),
//                     const Divider(),
//                     Row(
//                       children: [
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(8),
//                           child: Image.network(
//                             image,
//                             width: 80,
//                             height: 80,
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 typeName,
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 16,
//                                 ),
//                               ),
//                               Text('Weight: $weight'),
//                               Text('Quantity: $quantity'),
//                               Text(
//                                 'Price: ₹${price.toStringAsFixed(2)}',
//                                 style: const TextStyle(
//                                     fontWeight: FontWeight.bold),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                     const Divider(),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Text(
//                           'Total Amount:',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 16,
//                           ),
//                         ),
//                         Text(
//                           '₹${totalAmount.toStringAsFixed(2)}',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 18,
//                             color: AppColors().mainColor,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 24),

//             // Delivery address section
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'Delivery Address',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: AppColors().mainColor,
//                   ),
//                 ),
//                 TextButton.icon(
//                   onPressed: _showAddAddressDialog,
//                   icon: Icon(Icons.add, color: AppColors().mainColor),
//                   label: Text(
//                     'Add New',
//                     style: TextStyle(color: AppColors().mainColor),
//                   ),
//                 ),
//               ],
//             ),

//             if (_addresses.isEmpty)
//               Card(
//                 elevation: 2,
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Center(
//                     child: Text(
//                       'No addresses found. Please add a delivery address.',
//                       style: TextStyle(color: Colors.grey[600]),
//                     ),
//                   ),
//                 ),
//               )
//             else
//               ListView.builder(
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 itemCount: _addresses.length,
//                 itemBuilder: (context, index) {
//                   final address = _addresses[index];
//                   final isSelected = address['id'] == _selectedAddressId;

//                   return Card(
//                     elevation: isSelected ? 4 : 2,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       side: BorderSide(
//                         color: isSelected
//                             ? AppColors().mainColor
//                             : Colors.transparent,
//                         width: 2,
//                       ),
//                     ),
//                     child: InkWell(
//                       onTap: () {
//                         setState(() {
//                           _selectedAddressId = address['id'];
//                         });
//                       },
//                       child: Padding(
//                         padding: const EdgeInsets.all(16.0),
//                         child: Row(
//                           children: [
//                             Radio(
//                               value: address['id'],
//                               groupValue: _selectedAddressId,
//                               activeColor: AppColors().mainColor,
//                               onChanged: (value) {
//                                 setState(() {
//                                   _selectedAddressId = value as String;
//                                 });
//                               },
//                             ),
//                             const SizedBox(width: 8),
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(address['name'] ?? 'No name provided'),
//                                   Text(address['phoneNumber'] ??
//                                       'No phone provided'),
//                                   Text(
//                                     '${address['address'] ?? 'No address'}, ${address['city'] ?? 'No city'}, ${address['state'] ?? 'No state'} - ${address['pincode'] ?? 'No pincode'}',
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),

//             const SizedBox(height: 24),

//             // Payment method section
//             Text(
//               'Payment Method',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: AppColors().mainColor,
//               ),
//             ),
//             Card(
//               elevation: 2,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Row(
//                   children: [
//                     Icon(Icons.money, color: AppColors().mainColor),
//                     const SizedBox(width: 16),
//                     const Expanded(
//                       child: Text(
//                         'Cash on Delivery',
//                         style: TextStyle(fontSize: 16),
//                       ),
//                     ),
//                     Radio(
//                       value: 'COD',
//                       groupValue: 'COD',
//                       activeColor: AppColors().mainColor,
//                       onChanged: (value) {
//                         // Only COD is available for now
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 32),

//             // Place order button
//             SizedBox(
//               width: double.infinity,
//               height: 50,
//               child: ElevatedButton(
//                 onPressed: _placeOrder,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppColors().mainColor,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: const Text(
//                   'Place Order',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
