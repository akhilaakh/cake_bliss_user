import 'package:cake_bliss/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CheckoutPage extends StatefulWidget {
  final Map<String, dynamic>? directCheckoutItem; // Add this parameter

  const CheckoutPage({Key? key, this.directCheckoutItem}) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _isLoading = true;
  bool _isDirectCheckout = false; // Flag for direct checkout
  List<Map<String, dynamic>> _cartItems = [];
  List<Map<String, dynamic>> _addresses = [];
  Map<String, dynamic>? _selectedAddress;
  double _subtotal = 0.0;
  final double _deliveryFee = 50.0;
  double _total = 0.0;

  @override
  void initState() {
    super.initState();

    // Check if this is a direct checkout
    if (widget.directCheckoutItem != null) {
      setState(() {
        _isDirectCheckout = true;
        // Create a list with just the single item
        _cartItems = [widget.directCheckoutItem!];
        _calculateTotals();
        _isLoading = false;
      });
    } else {
      // Regular cart checkout
      _fetchCartItems();
    }
    _fetchAddresses();
  }

  Future<void> _fetchCartItems() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('carts')
          .doc(userId)
          .collection('items')
          .get();

      final items = snapshot.docs
          .map((doc) => {
                ...doc.data(),
                'id': doc.id,
              })
          .toList();

      setState(() {
        _cartItems = items;
        _calculateTotals();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching cart items: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAddresses() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .get();

      final addresses = snapshot.docs
          .map((doc) => {
                ...doc.data(),
                'id': doc.id,
              })
          .toList();

      setState(() {
        _addresses = addresses;
        if (addresses.isNotEmpty) {
          // Select the default address if available
          _selectedAddress = addresses.firstWhere(
              (addr) => addr['isDefault'] == true,
              orElse: () => addresses.first);
        }
      });
    } catch (e) {
      print('Error fetching addresses: $e');
    }
  }

  void _calculateTotals() {
    double sum = 0.0;
    for (var item in _cartItems) {
      sum += (item['price'] * item['quantity']).toDouble();
    }
    setState(() {
      _subtotal = sum;
      _total = _subtotal + _deliveryFee;
    });
  }

  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity < 1) return;

    setState(() {
      _cartItems[index]['quantity'] = newQuantity;
      _cartItems[index]['totalPrice'] =
          _cartItems[index]['price'] * newQuantity;
      _calculateTotals();
    });

    // Update Firestore only if it's from the cart (not direct checkout)
    if (!_isDirectCheckout && _cartItems[index].containsKey('id')) {
      _updateCartItemInFirestore(_cartItems[index]['id'], newQuantity);
    }
  }

  Future<void> _updateCartItemInFirestore(String itemId, int quantity) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await FirebaseFirestore.instance
          .collection('carts')
          .doc(userId)
          .collection('items')
          .doc(itemId)
          .update({
        'quantity': quantity,
        'totalPrice': double.parse((quantity *
                _cartItems.firstWhere((item) => item['id'] == itemId)['price'])
            .toStringAsFixed(2)),
      });
    } catch (e) {
      print('Error updating cart item: $e');
    }
  }

  void _showAddressSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Select Delivery Address',
          style: TextStyle(color: AppColors().mainColor),
        ),
        content: _addresses.isEmpty
            ? const Text('No addresses found. Please add an address.')
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _addresses.map((address) {
                    return RadioListTile<Map<String, dynamic>>(
                      title: Text(address['name']),
                      subtitle: Text(
                          '${address['street']}, ${address['city']}, ${address['state']} - ${address['pincode']}'),
                      value: address,
                      groupValue: _selectedAddress,
                      onChanged: (value) {
                        setState(() {
                          _selectedAddress = value;
                          Navigator.pop(context);
                        });
                      },
                      activeColor: AppColors().mainColor,
                    );
                  }).toList(),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to add new address page
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddEditAddressPage()));
              Navigator.pushNamed(context, '/add-address').then((_) {
                _fetchAddresses();
              });
            },
            child: Text(
              'Add New Address',
              style: TextStyle(color: AppColors().mainColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a delivery address'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Create a new order
      final orderRef = FirebaseFirestore.instance.collection('orders').doc();

      await orderRef.set({
        'userId': userId,
        'orderNumber': 'ORD-${DateTime.now().millisecondsSinceEpoch}',
        'items': _cartItems
            .map((item) => {
                  'typeId': item['typeId'],
                  'name': item['name'],
                  'weight': item['weight'],
                  'quantity': item['quantity'],
                  'price': item['price'],
                  'totalPrice': item['price'] * item['quantity'],
                  'image': item['image'],
                })
            .toList(),
        'address': {
          'name': _selectedAddress!['name'],
          'phone': _selectedAddress!['phone'],
          'street': _selectedAddress!['street'],
          'city': _selectedAddress!['city'],
          'state': _selectedAddress!['state'],
          'pincode': _selectedAddress!['pincode'],
        },
        'subtotal': _subtotal,
        'deliveryFee': _deliveryFee,
        'total': _total,
        'status': 'pending',
        'paymentMethod': 'COD',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Clear cart if items were from cart (not direct checkout)
      if (!_isDirectCheckout) {
        await FirebaseFirestore.instance
            .collection('carts')
            .doc(userId)
            .collection('items')
            .get()
            .then((snapshot) {
          for (var doc in snapshot.docs) {
            doc.reference.delete();
          }
        });
      }

      if (mounted) {
        setState(() => _isLoading = false);

        // Navigate to order success page
        Navigator.pushReplacementNamed(context, '/order-success',
            arguments: {'orderId': orderRef.id});
      }
    } catch (e) {
      print('Error placing order: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to place order. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Checkout'),
          backgroundColor: AppColors().mainColor,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isDirectCheckout ? 'Buy Now' : 'Checkout'),
        backgroundColor: AppColors().mainColor,
      ),
      body: _cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 80),
                  const SizedBox(height: 16),
                  const Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors().mainColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      'Continue Shopping',
                      style: TextStyle(color: AppColors().white),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Items section
                        Text(
                          _isDirectCheckout ? 'Your Item' : 'Order Items',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors().mainColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(_cartItems.length, (index) {
                          final item = _cartItems[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      item['image'],
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.error),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Item details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text('Weight: ${item['weight']}'),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₹${item['price'].toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: AppColors().mainColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Quantity controls
                                  Column(
                                    children: [
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.remove_circle_outline,
                                              color: AppColors().mainColor,
                                            ),
                                            onPressed: () => _updateQuantity(
                                                index, item['quantity'] - 1),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 8),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: AppColors().mainColor),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              item['quantity'].toString(),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors().mainColor,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.add_circle_outline,
                                              color: AppColors().mainColor,
                                            ),
                                            onPressed: () => _updateQuantity(
                                                index, item['quantity'] + 1),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '₹${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 24),

                        // Delivery address section
                        Text(
                          'Delivery Address',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors().mainColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _showAddressSelectionDialog,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _selectedAddress == null
                                ? Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Select Delivery Address'),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: AppColors().mainColor,
                                      ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _selectedAddress!['name'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            'CHANGE',
                                            style: TextStyle(
                                              color: AppColors().mainColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(_selectedAddress!['phone']),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_selectedAddress!['street']}, ${_selectedAddress!['city']}, ${_selectedAddress!['state']} - ${_selectedAddress!['pincode']}',
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Order summary
                        Text(
                          'Order Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors().mainColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Subtotal'),
                                  Text('₹${_subtotal.toStringAsFixed(2)}'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Delivery Fee'),
                                  Text('₹${_deliveryFee.toStringAsFixed(2)}'),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '₹${_total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom action bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors().white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                '₹${_total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _placeOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors().mainColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Place Order',
                              style: TextStyle(
                                color: AppColors().white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// Address Model
class Address {
  final String? id;
  final String name;
  final String phone;
  final String street;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;

  Address({
    this.id,
    required this.name,
    required this.phone,
    required this.street,
    required this.city,
    required this.state,
    required this.pincode,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'street': street,
      'city': city,
      'state': state,
      'pincode': pincode,
      'isDefault': isDefault,
    };
  }

  factory Address.fromMap(Map<String, dynamic> map, String id) {
    return Address(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      street: map['street'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      pincode: map['pincode'] ?? '',
      isDefault: map['isDefault'] ?? false,
    );
  }
}

// Add/Edit Address Page

class AddEditAddressPage extends StatefulWidget {
  final Map<String, dynamic>? address; // Pass existing address for editing

  const AddEditAddressPage({Key? key, this.address}) : super(key: key);

  @override
  State<AddEditAddressPage> createState() => _AddEditAddressPageState();
}

class _AddEditAddressPageState extends State<AddEditAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.address != null) {
      _nameController.text = widget.address!['name'];
      _phoneController.text = widget.address!['phone'];
      _streetController.text = widget.address!['street'];
      _cityController.text = widget.address!['city'];
      _stateController.text = widget.address!['state'];
      _pincodeController.text = widget.address!['pincode'];
      _isDefault = widget.address!['isDefault'] ?? false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('You need to be logged in to save an address')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final addressesCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('addresses');

      // Check if this is the first address (to make it default)
      bool makeDefault = _isDefault;
      if (!makeDefault) {
        final addressesSnapshot = await addressesCollection.get();
        if (addressesSnapshot.docs.isEmpty) {
          makeDefault = true; // First address, make it default
        }
      }

      // If making this address default, update all other addresses
      if (makeDefault) {
        final batch = FirebaseFirestore.instance.batch();
        final existingAddresses =
            await addressesCollection.where('isDefault', isEqualTo: true).get();

        for (var doc in existingAddresses.docs) {
          batch.update(doc.reference, {'isDefault': false});
        }
        await batch.commit();
      }

      final addressData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'street': _streetController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'isDefault': makeDefault,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.address != null) {
        // Update existing address
        await addressesCollection
            .doc(widget.address!['id'])
            .update(addressData);
      } else {
        // Add new address
        addressData['createdAt'] = FieldValue.serverTimestamp();
        await addressesCollection.add(addressData);
      }

      if (mounted) {
        setState(() => _isLoading = false);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address saved successfully'),
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to address list page
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const AddressListPage()));
      }
    } catch (e) {
      print('Error saving address: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save address: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.address != null ? 'Edit Address' : 'Add New Address'),
        backgroundColor: AppColors().mainColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors().mainColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors().mainColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon:
                            Icon(Icons.person, color: AppColors().mainColor),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Phone field
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors().mainColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon:
                            Icon(Icons.phone, color: AppColors().mainColor),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (value.length < 10) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Address Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors().mainColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Street address field
                    TextFormField(
                      controller: _streetController,
                      decoration: InputDecoration(
                        labelText: 'Street Address',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors().mainColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon:
                            Icon(Icons.home, color: AppColors().mainColor),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your street address';
                        }
                        return null;
                      },
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // City field
                    TextFormField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors().mainColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.location_city,
                            color: AppColors().mainColor),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your city';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // State field
                    TextFormField(
                      controller: _stateController,
                      decoration: InputDecoration(
                        labelText: 'State',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors().mainColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon:
                            Icon(Icons.map, color: AppColors().mainColor),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your state';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Pincode field
                    TextFormField(
                      controller: _pincodeController,
                      decoration: InputDecoration(
                        labelText: 'Pincode',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors().mainColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon:
                            Icon(Icons.pin_drop, color: AppColors().mainColor),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your pincode';
                        }
                        if (value.length != 6) {
                          return 'Please enter a valid 6-digit pincode';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Default address checkbox
                    CheckboxListTile(
                      title: const Text('Make this my default address'),
                      value: _isDefault,
                      onChanged: (value) {
                        setState(() {
                          _isDefault = value ?? false;
                        });
                      },
                      activeColor: AppColors().mainColor,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 32),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors().mainColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          widget.address != null
                              ? 'Update Address'
                              : 'Save Address',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class AddressListPage extends StatefulWidget {
  const AddressListPage({Key? key}) : super(key: key);

  @override
  State<AddressListPage> createState() => _AddressListPageState();
}

class _AddressListPageState extends State<AddressListPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _addresses = [];

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .orderBy('isDefault', descending: true)
          .get();

      final addresses = snapshot.docs
          .map((doc) => {
                ...doc.data(),
                'id': doc.id,
              })
          .toList();

      setState(() {
        _addresses = addresses;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching addresses: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setDefaultAddress(String addressId) async {
    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      final addressesCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('addresses');

      // Set all addresses to non-default
      final allAddresses = await addressesCollection.get();
      for (var doc in allAddresses.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }

      // Set the selected address as default
      batch.update(addressesCollection.doc(addressId), {'isDefault': true});

      await batch.commit();

      // Refresh the addresses
      _fetchAddresses();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Default address updated'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error setting default address: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update default address: $e')),
      );
    }
  }

  Future<void> _deleteAddress(String addressId, bool isDefault) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .doc(addressId)
          .delete();

      // If deleted address was default and there are other addresses,
      // make another address the default
      if (isDefault && _addresses.length > 1) {
        final remainingAddresses =
            _addresses.where((addr) => addr['id'] != addressId).toList();
        if (remainingAddresses.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('addresses')
              .doc(remainingAddresses.first['id'])
              .update({'isDefault': true});
        }
      }

      // Refresh the addresses
      _fetchAddresses();

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address deleted'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error deleting address: $e');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete address: $e')),
      );
    }
  }

  void _showDeleteConfirmation(String addressId, bool isDefault) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Address',
          style: TextStyle(color: AppColors().mainColor),
        ),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAddress(addressId, isDefault);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
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
        title: const Text('My Addresses'),
        backgroundColor: AppColors().mainColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_off, size: 80),
                      const SizedBox(height: 16),
                      const Text(
                        'No addresses found',
                        style: TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const AddEditAddressPage())),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors().mainColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: const Text(
                          'Add New Address',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: _addresses.length,
                          itemBuilder: (context, index) {
                            final address = _addresses[index];
                            final isDefault = address['isDefault'] ?? false;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: isDefault
                                    ? BorderSide(
                                        color: AppColors().mainColor, width: 2)
                                    : BorderSide.none,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              address['name'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            if (isDefault) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors().mainColor,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'DEFAULT',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            // Edit button
                                            IconButton(
                                              icon: Icon(
                                                Icons.edit,
                                                color: AppColors().mainColor,
                                              ),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        AddEditAddressPage(
                                                      address: address,
                                                    ),
                                                  ),
                                                ).then(
                                                    (_) => _fetchAddresses());
                                              },
                                              constraints:
                                                  const BoxConstraints(),
                                              padding: const EdgeInsets.all(8),
                                            ),
                                            // Delete button
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              onPressed: () =>
                                                  _showDeleteConfirmation(
                                                      address['id'], isDefault),
                                              constraints:
                                                  const BoxConstraints(),
                                              padding: const EdgeInsets.all(8),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(address['phone']),
                                    const SizedBox(height: 4),
                                    Text(
                                        '${address['street']}, ${address['city']}, ${address['state']} - ${address['pincode']}'),
                                    if (!isDefault) ...[
                                      const SizedBox(height: 16),
                                      InkWell(
                                        onTap: () =>
                                            _setDefaultAddress(address['id']),
                                        child: Text(
                                          'Set as Default',
                                          style: TextStyle(
                                            color: AppColors().mainColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Add new address button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AddEditAddressPage(),
                              ),
                            ).then((_) => _fetchAddresses());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors().mainColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Add New Address',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors().white,
                            ),
                          ),
                        ),
                      ),
                      // If coming from checkout, add a button to return
                      if (ModalRoute.of(context)?.settings.arguments ==
                          'checkout') ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors().mainColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Return to Checkout',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors().mainColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
      // Add floating action button for empty state
      floatingActionButton: _addresses.isEmpty && !_isLoading
          ? null
          : FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEditAddressPage(),
                  ),
                ).then((_) => _fetchAddresses());
              },
              backgroundColor: AppColors().mainColor,
              child: const Icon(Icons.add),
            ),
    );
  }
}
