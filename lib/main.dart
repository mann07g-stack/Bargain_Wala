import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';

// --- Main App Entry Point ---

void main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras.first;

  runApp(
    // Use Provider to make the Cart and Camera available to all widgets.
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartModel()),
        // Provide the camera description to the ScanPage
        Provider<CameraDescription>.value(value: firstCamera),
      ],
      child: const MyApp(),
    ),
  );
}

// --- App State Management (The Cart) ---

// Represents a single item the user is bargaining for.
class BargainItem {
  final String id;
  final String productName;
  final double retailPrice;
  double userQuotedPrice;
  double serverCounterPrice; // This would be updated by your backend
  NegotiationStatus status;

  BargainItem({
    required this.id,
    required this.productName,
    required this.retailPrice,
    required this.userQuotedPrice,
    required this.serverCounterPrice,
    this.status = NegotiationStatus.pending,
  });
}

// Represents a mock item found during a "scan".
class ScannableItem {
  final String name;
  final double retailPrice;
  ScannableItem({required this.name, required this.retailPrice});
}

enum NegotiationStatus { pending, negotiating, agreed, failed }

// ManAGES THE STATE of the shopping cart and negotiations.
class CartModel extends ChangeNotifier {
  final List<BargainItem> _items = [];
  double _coinsEarned = 0;

  List<BargainItem> get items => _items;
  double get coinsEarned => _coinsEarned;

  double get bestQuotedPriceTotal {
    return _items.fold(0.0, (sum, item) {
      // If agreed, use the agreed price, otherwise use the user's last quote
      final price = (item.status == NegotiationStatus.agreed)
          ? item.userQuotedPrice
          : item.userQuotedPrice;
      return sum + price;
    });
  }

  void addItem(BargainItem item) {
    // Check if item is already in cart to avoid duplicates
    if (!_items.any((i) => i.productName == item.productName)) {
      _items.add(item);
      // This will notify any widgets listening to this model to rebuild.
      notifyListeners();
      // In a real app, you would also call your backend here to start negotiation
      startNegotiation(item);
    }
  }

  // This is a mock function. In a real app, this would involve
  // API calls to your server.
  void startNegotiation(BargainItem item) {
    print("Starting negotiation for ${item.productName}...");
    item.status = NegotiationStatus.negotiating;
    notifyListeners();

    // Simulate a server response after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      // Simulate server accepting the price
      if (item.userQuotedPrice > item.retailPrice * 0.8) {
        item.status = NegotiationStatus.agreed;
        item.serverCounterPrice = item.userQuotedPrice;

        // *** NEW: Add saved amount to coins ***
        double savings = item.retailPrice - item.userQuotedPrice;
        if (savings > 0) {
          _coinsEarned += savings;
        }

        print("Server AGREED to price for ${item.productName}");
      } else {
        // Simulate server counter-offer
        item.serverCounterPrice = item.retailPrice * 0.85;
        item.status = NegotiationStatus.pending; // User needs to re-quote
        print("Server COUNTERED for ${item.productName}");
      }
      // Notify listeners to update the UI with negotiation status
      notifyListeners();
    });
  }
}

// --- Root Application Widget ---

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bargain Wala',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Colors.white),
          titleLarge: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Colors.white),
          bodyMedium: TextStyle(fontSize: 16.0, color: Colors.white70),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white30),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white30),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.teal),
          ),
          labelStyle: const TextStyle(color: Colors.white70),
        ),
      ),
      debugShowCheckedModeBanner: false,
      // Define the routes for navigation
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/scan': (context) => const ScanPage(),
        '/slots': (context) => const SlotsPage(),
        '/recommend': (context) => const RecommendPage(),
        '/cart': (context) => const CartPage(),
        // *** NEW ROUTES ***
        '/productDetail': (context) => const ProductDetailPage(),
        '/premiumStore': (context) => const PremiumStorePage(),
      },
    );
  }
}

// --- 1. Home Page (The 4 Quadrants) ---

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  // ... (This widget is unchanged) ...
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Bargain Wala',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          // GridView for the 4-quadrant layout
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildQuadrant(
                context,
                icon: Icons.qr_code_scanner,
                title: 'Scan',
                color: Colors.teal,
                onTap: () => Navigator.pushNamed(context, '/scan'),
              ),
              _buildQuadrant(
                context,
                icon: Icons.calendar_today,
                title: 'Book Visit',
                color: Colors.lightBlue,
                onTap: () => Navigator.pushNamed(context, '/slots'),
              ),
              _buildQuadrant(
                context,
                icon: Icons.recommend,
                title: 'Recommend',
                color: Colors.orange,
                onTap: () => Navigator.pushNamed(context, '/recommend'),
              ),
              _buildQuadrant(
                context,
                icon: Icons.shopping_cart,
                title: 'Saved Cart',
                color: Colors.pink,
                onTap: () => Navigator.pushNamed(context, '/cart'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to build each quadrant
  Widget _buildQuadrant(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.7), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// --- 2. Scan Page (Quadrant 1) ---
// *** MODIFIED: Now stateful, shows list of scanned items ***

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<ScannableItem> _scannedItems = [];
  bool _isScanned = false;

  @override
  void initState() {
    super.initState();
    // Get the camera from the Provider
    final camera = Provider.of<CameraDescription>(context, listen: false);

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _controller!.initialize();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onScanButtonPressed() {
    // This is a mock scan. In a real app, you'd use a QR/barcode
    // scanning library or image recognition here.
    print("Scan complete!");

    // *** NEW: Populate a MOCK list of items from the "bag" ***
    setState(() {
      _scannedItems = [
        ScannableItem(name: 'Fresh Milk', retailPrice: 3.50),
        ScannableItem(name: 'Loaf of Bread', retailPrice: 2.75),
        ScannableItem(name: 'Dozen Eggs', retailPrice: 4.20),
      ];
      _isScanned = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scan complete! Found 3 items.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Your Bag')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return Column(
              children: [
                // Camera Preview
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      CameraPreview(_controller!),
                      // Mock scan button
                      Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.camera),
                          label: const Text("Scan Bag"),
                          onPressed: _onScanButtonPressed,
                        ),
                      ),
                    ],
                  ),
                ),
                // *** NEW: List of scanned items ***
                Expanded(
                  child: _isScanned
                      ? ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _scannedItems.length,
                          itemBuilder: (context, index) {
                            return _ScannableItemTile(
                                item: _scannedItems[index]);
                          },
                        )
                      : const Center(
                          child: Text(
                            'Scan a bag to see items here.',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                ),
              ],
            );
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

// *** NEW: Helper widget for each item in the scanned list ***
class _ScannableItemTile extends StatefulWidget {
  final ScannableItem item;

  const _ScannableItemTile({required this.item});

  @override
  State<_ScannableItemTile> createState() => _ScannableItemTileState();
}

class _ScannableItemTileState extends State<_ScannableItemTile> {
  final _priceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isQuoted = false;

  void _submitQuote(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final double quotedPrice = double.parse(_priceController.text);

      // Create a new bargain item
      final newItem = BargainItem(
        id: DateTime.now().millisecondsSinceEpoch.toString() +
            widget.item.name, // Mock ID
        productName: widget.item.name,
        retailPrice: widget.item.retailPrice,
        userQuotedPrice: quotedPrice,
        serverCounterPrice:
            widget.item.retailPrice, // Server hasn't countered yet
      );

      // Add item to cart using Provider
      Provider.of<CartModel>(context, listen: false).addItem(newItem);

      // Show a confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.item.name} added to cart!'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _isQuoted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                "Retail Price: \$${widget.item.retailPrice.toStringAsFixed(2)}",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      enabled: !_isQuoted,
                      decoration: InputDecoration(
                        labelText: 'Your Price (\$)',
                        prefixIcon: const Icon(Icons.attach_money),
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      backgroundColor: _isQuoted ? Colors.grey : Colors.teal,
                    ),
                    onPressed: _isQuoted
                        ? null
                        : () => _submitQuote(context),
                    child:
                        _isQuoted ? const Icon(Icons.check) : const Text('Quote'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- (REMOVED) Quote Price Page ---
// This widget is no longer needed as its functionality is merged into ScanPage.

// --- 3. Slots Page (Quadrant 2) ---
// *** MODIFIED: Now stateful, with Confirm/Reschedule logic ***

class SlotsPage extends StatefulWidget {
  const SlotsPage({super.key});

  @override
  State<SlotsPage> createState() => _SlotsPageState();
}

enum DeliveryStatus { pending, confirmed, rescheduled }

class _SlotsPageState extends State<SlotsPage> {
  // Mock data for time slots
  final List<TimeSlot> _timeSlots = [
    TimeSlot(time: '10:00 AM - 11:00 AM', isBooked: false),
    TimeSlot(time: '11:00 AM - 12:00 PM', isBooked: true),
    TimeSlot(time: '12:00 PM - 01:00 PM', isBooked: false),
    TimeSlot(time: '02:00 PM - 03:00 PM', isBooked: false),
    TimeSlot(time: '03:00 PM - 04:00 PM', isBooked: true),
    TimeSlot(time: '04:00 PM - 05:00 PM', isBooked: false),
  ];

  int? _selectedSlot;
  DeliveryStatus _deliveryStatus = DeliveryStatus.pending;
  String _deliveryTime = "Today, 2:00 PM - 3:00 PM"; // Mock delivery time

  Widget _buildDeliveryStatusCard(BuildContext context) {
    String statusText;
    Color statusColor;
    Widget actions;

    switch (_deliveryStatus) {
      case DeliveryStatus.confirmed:
        statusText = 'Delivery Confirmed!';
        statusColor = Colors.green;
        actions = Text('See you at $_deliveryTime',
            style: const TextStyle(color: Colors.white70));
        break;
      case DeliveryStatus.rescheduled:
        statusText = 'Delivery Rescheduled';
        statusColor = Colors.orange;
        actions = Text(
            'New time: ${_timeSlots[_selectedSlot!].time}', // Assumes _selectedSlot is set
            style: const TextStyle(color: Colors.white70));
        break;
      case DeliveryStatus.pending:
      statusText = 'Confirm Your Delivery';
        statusColor = Colors.blue;
        actions = Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // "CROSS" button (Reschedule)
            TextButton.icon(
              icon: const Icon(Icons.close, color: Colors.red),
              label:
                  const Text('Reschedule', style: TextStyle(color: Colors.red)),
              onPressed: () {
                // Logic to show reschedule options (e.g., enable the list below)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please select a new slot from the list below.')),
                );
              },
            ),
            const SizedBox(width: 8),
            // "TICK" button (Confirm)
            TextButton.icon(
              icon: const Icon(Icons.check, color: Colors.green),
              label: const Text('Confirm',
                  style: TextStyle(color: Colors.green)),
              onPressed: () {
                setState(() {
                  _deliveryStatus = DeliveryStatus.confirmed;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Delivery confirmed!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ],
        );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              statusText,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: statusColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Delivery Time: $_deliveryTime',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            actions,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book & Manage Visits')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // *** NEW: Delivery Status Card ***
          _buildDeliveryStatusCard(context),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Available Slots for Reschedule',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          // --- List of available slots ---
          Expanded(
            child: ListView.builder(
              itemCount: _timeSlots.length,
              itemBuilder: (context, index) {
                final slot = _timeSlots[index];
                final isAvailable = !slot.isBooked;
                final isSelected = _selectedSlot == index;

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Card(
                    color: isSelected
                        ? Colors.teal.withOpacity(0.5)
                        : Theme.of(context).cardColor,
                    child: ListTile(
                      leading: Icon(
                        isAvailable ? Icons.check_circle_outline : Icons.cancel,
                        color: isAvailable ? Colors.green : Colors.red,
                      ),
                      title: Text(slot.time,
                          style: TextStyle(
                            color: isAvailable ? Colors.white : Colors.white54,
                            decoration:
                                isAvailable ? null : TextDecoration.lineThrough,
                          )),
                      trailing: isAvailable
                          ? const Icon(Icons.arrow_forward_ios, size: 16)
                          : null,
                      onTap: isAvailable
                          ? () {
                              setState(() {
                                _selectedSlot = index;
                                // *** NEW: Set status to rescheduled ***
                                _deliveryStatus = DeliveryStatus.rescheduled;
                                _deliveryTime = slot.time;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Delivery rescheduled to: ${slot.time}'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TimeSlot {
  final String time;
  final bool isBooked;
  TimeSlot({required this.time, required this.isBooked});
}

// --- 4. Recommend Page (Quadrant 3) ---
// *** MODIFIED: Added Search Bar, "Request" box, and tappable cards ***

class RecommendPage extends StatefulWidget {
  const RecommendPage({super.key});

  @override
  State<RecommendPage> createState() => _RecommendPageState();
}

class _RecommendPageState extends State<RecommendPage> {
  final _searchController = TextEditingController();
  final _requestController = TextEditingController();

  // Mock data for products
  final List<Map<String, dynamic>> _products = List.generate(
    8,
    (index) => {
      'name': 'Recommended Product ${index + 1}',
      'price': (index + 1) * 35.50,
      'description':
          'This is a detailed description for Product ${index + 1}. It is of high quality and recommended just for you.'
    },
  );
  List<Map<String, dynamic>> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _filteredProducts = _products;
    _searchController.addListener(_filterProducts);
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _products;
      } else {
        _filteredProducts = _products
            .where((p) => p['name'].toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _requestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recommended For You')),
      body: Column(
        children: [
          // *** NEW: Search Bar ***
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search products...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          // --- Product Grid ---
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];
                return InkWell(
                  // *** NEW: Tappable Card ***
                  onTap: () {
                    Navigator.pushNamed(context, '/productDetail',
                        arguments: product);
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    clipBehavior: Clip.antiAlias, // Clips the image
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Container(
                            color: Colors.grey[800],
                            child: Center(
                                child: Icon(Icons.image,
                                    size: 50, color: Colors.grey[700])),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            product['name'],
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Text(
                            '\$${product['price'].toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.tealAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // *** NEW: Request Item Box ***
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _requestController,
              decoration: InputDecoration(
                labelText: 'Request an item for next time...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    // Logic to submit request
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Request Sent: ${_requestController.text}'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                    _requestController.clear();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// *** NEW: Product Detail Page ***
class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Receive the product data passed from the RecommendPage
    final product =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(title: Text(product['name'])),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.grey[800],
              child:
                  Center(child: Icon(Icons.image, size: 100, color: Colors.grey[700])),
            ),
            const SizedBox(height: 24),
            Text(
              product['name'],
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              '\$${product['price'].toStringAsFixed(2)}',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: Colors.tealAccent),
            ),
            const SizedBox(height: 24),
            Text(
              product['description'],
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // In a real app, you might navigate to a quote page
                  // or add to cart with a default price.
                   ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('This item must be scanned to be added to cart.'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                },
                child: const Text('Scan to Bargain'),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// --- 5. Cart Page (Quadrant 4) ---
// *** MODIFIED: Added Coin Counter and Premium Bag Button ***

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch for changes in the CartModel
    final cart = context.watch<CartModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Cart & Negotiations'),
      ),
      body: Column(
        children: [
          // *** NEW: Coin Counter ***
          Container(
            width: double.infinity,
            color: Colors.teal.withOpacity(0.2),
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.monetization_on,
                    color: Colors.amber, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Your Bargain Coins: ${cart.coinsEarned.toStringAsFixed(2)}',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.amber),
                ),
              ],
            ),
          ),
          // --- List of Cart Items ---
          Expanded(
            child: cart.items.isEmpty
                ? const Center(
                    child: Text(
                      'Your cart is empty.\nScan an item to start bargaining!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return _buildNegotiationTile(context, item);
                    },
                  ),
          ),
          // --- Total Price Footer ---
          if (cart.items.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Best Price:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        '\$${cart.bestQuotedPriceTotal.toStringAsFixed(2)}',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: Colors.tealAccent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // *** NEW: Premium Bag Button ***
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.star),
                      label: const Text('Browse Premium Bag (Use Coins)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/premiumStore');
                      },
                    ),
                  )
                ],
              ),
            )
        ],
      ),
    );
  }

  // Helper widget for each item in the cart
  Widget _buildNegotiationTile(BuildContext context, BargainItem item) {
    Icon statusIcon;
    Color statusColor;
    String statusText;
    Widget? savingsText;

    switch (item.status) {
      case NegotiationStatus.agreed:
        statusIcon = const Icon(Icons.check_circle);
        statusColor = Colors.green;
        statusText = 'Price Agreed!';
        double saved = item.retailPrice - item.userQuotedPrice;
        if (saved > 0) {
          savingsText = Text(
            'You saved \$${saved.toStringAsFixed(2)}!',
            style: const TextStyle(color: Colors.green),
          );
        }
        break;
      case NegotiationStatus.negotiating:
        statusIcon = const Icon(Icons.hourglass_top);
        statusColor = Colors.orange;
        statusText = 'Negotiating...';
        break;
      case NegotiationStatus.failed:
        statusIcon = const Icon(Icons.cancel);
        statusColor = Colors.red;
        statusText = 'Offer Rejected';
        break;
      case NegotiationStatus.pending:
      statusIcon = const Icon(Icons.info);
        statusColor = Colors.blue;
        statusText =
            'Server Countered: \$${item.serverCounterPrice.toStringAsFixed(2)}';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.productName,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Quote:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '\$${item.userQuotedPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Retail Price:',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white54),
                ),
                Text(
                  '\$${item.retailPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white54,
                      decoration: TextDecoration.lineThrough),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(statusIcon.icon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: TextStyle(
                      color: statusColor, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (savingsText != null) savingsText,
              ],
            )
          ],
        ),
      ),
    );
  }
}

// *** NEW: Premium Store Page (Placeholder) ***
class PremiumStorePage extends StatelessWidget {
  const PremiumStorePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the cart to show the user's coin balance
    final cart = context.watch<CartModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Premium Bag')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Your Coins: ${cart.coinsEarned.toStringAsFixed(2)}',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: Colors.amber),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.star, color: Colors.amber, size: 100),
            const SizedBox(height: 20),
            Text(
              'Expensive items will be shown here.',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'You can use your coins for discounts!',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}