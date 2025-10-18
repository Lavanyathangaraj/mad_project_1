// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotifyService().init(); // init notifications
  runApp(const SmartGroceryApp());
}

/* ---------------------------
  Local Notifications Helper
----------------------------*/
class LocalNotifyService {
  LocalNotifyService._private();
  static final LocalNotifyService _instance = LocalNotifyService._private();
  factory LocalNotifyService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);
  }

  Future<void> showInstant(int id, String title, String body) async {
    const android = AndroidNotificationDetails(
        'g1', 'Grocery', importance: Importance.max, priority: Priority.high);
    const details = NotificationDetails(android: android);
    await _plugin.show(id, title, body, details);
  }
}

/* ---------------------------
  Database helper & models
----------------------------*/
class GroceryItem {
  int? id;
  String name;
  String category;
  int qty;
  String notes;
  bool fav;
  int purchaseCount;
  String? lastPurchased;
  String schedule; // comma-separated Mon,Tue,...

  GroceryItem({
    this.id,
    required this.name,
    required this.category,
    this.qty = 1,
    this.notes = '',
    this.fav = false,
    this.purchaseCount = 0,
    this.lastPurchased,
    this.schedule = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'qty': qty,
        'notes': notes,
        'fav': fav ? 1 : 0,
        'purchaseCount': purchaseCount,
        'lastPurchased': lastPurchased,
        'schedule': schedule,
      };

  static GroceryItem fromMap(Map<String, dynamic> m) => GroceryItem(
        id: m['id'] as int?,
        name: m['name'] as String,
        category: m['category'] as String,
        qty: m['qty'] as int,
        notes: m['notes'] as String,
        fav: (m['fav'] as int) == 1,
        purchaseCount: m['purchaseCount'] as int,
        lastPurchased: m['lastPurchased'] as String?,
        schedule: (m['schedule'] as String?) ?? '',
      );
}

class DB {
  DB._private();
  static final DB instance = DB._private();
  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, 'smart_grocery.db');
    return openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          category TEXT,
          qty INTEGER,
          notes TEXT,
          fav INTEGER,
          purchaseCount INTEGER,
          lastPurchased TEXT,
          schedule TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE cart (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          itemId INTEGER,
          qty INTEGER
        )
      ''');
    });
  }

  Future<int> insertItem(GroceryItem it) async {
    final dbClient = await db;
    return dbClient.insert('items', it.toMap());
  }

  Future<int> updateItem(GroceryItem it) async {
    final dbClient = await db;
    return dbClient.update('items', it.toMap(), where: 'id = ?', whereArgs: [it.id]);
  }

  Future<int> deleteItem(int id) async {
    final dbClient = await db;
    return dbClient.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<GroceryItem>> allItems() async {
    final dbClient = await db;
    final rows = await dbClient.query('items', orderBy: 'fav DESC, name ASC');
    return rows.map((r) => GroceryItem.fromMap(r)).toList();
  }

  Future<void> addToCart(int itemId, int qty) async {
    final dbClient = await db;
    final rows = await dbClient.query('cart', where: 'itemId = ?', whereArgs: [itemId]);
    if (rows.isEmpty) {
      await dbClient.insert('cart', {'itemId': itemId, 'qty': qty});
    } else {
      final current = rows.first['qty'] as int;
      await dbClient.update('cart', {'qty': current + qty}, where: 'itemId = ?', whereArgs: [itemId]);
    }
  }

  Future<void> updateCart(int itemId, int qty) async {
    final dbClient = await db;
    if (qty <= 0) {
      await dbClient.delete('cart', where: 'itemId = ?', whereArgs: [itemId]);
    } else {
      await dbClient.update('cart', {'qty': qty}, where: 'itemId = ?', whereArgs: [itemId]);
    }
  }

  Future<List<Map<String, dynamic>>> getCartItems() async {
    final dbClient = await db;
    return dbClient.rawQuery('SELECT c.id AS cid, c.qty AS cqty, i.* FROM cart c JOIN items i ON c.itemId = i.id');
  }

  Future<void> clearCart() async {
    final dbClient = await db;
    await dbClient.delete('cart');
  }
}

/* ---------------------------
  Shared Preferences for Profile & Address
----------------------------*/
class ProfileStore {
  static const _kName = 'profile_name';
  static const _kEmail = 'profile_email';
  static const _kAddress = 'profile_address';
  static const _kPayment = 'profile_payment';

  static Future<void> saveProfile(String name, String email) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kName, name);
    await sp.setString(_kEmail, email);
  }

  static Future<void> saveAddress(String address) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kAddress, address);
  }

  static Future<void> savePaymentMock(String cardLast4) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kPayment, cardLast4);
  }

  static Future<Map<String, String?>> loadProfile() async {
    final sp = await SharedPreferences.getInstance();
    return {
      'name': sp.getString(_kName),
      'email': sp.getString(_kEmail),
      'address': sp.getString(_kAddress),
      'payment': sp.getString(_kPayment),
    };
  }
}

/* ---------------------------
  Main App UI
----------------------------*/
class SmartGroceryApp extends StatelessWidget {
  const SmartGroceryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Grocery',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/* ---------------------------
  HomeScreen
----------------------------*/
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String search = '';
  List<GroceryItem> items = [];
  Timer? suggestTimer;

  @override
  void initState() {
    super.initState();
    _refreshList();
    suggestTimer = Timer.periodic(const Duration(minutes: 1), (_) => _checkSuggestions());
  }

  @override
  void dispose() {
    suggestTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshList() async {
    items = await DB.instance.allItems();
    setState(() {});
  }

  Future<void> _checkSuggestions() async {
    final now = DateTime.now();
    for (var it in items) {
      if (it.purchaseCount >= 3 && it.lastPurchased != null) {
        final lp = DateTime.tryParse(it.lastPurchased!) ?? now;
        if (now.difference(lp).inDays >= 7) {
          await LocalNotifyService().showInstant(it.id ?? it.name.hashCode, 'Buy again?', 'You buy ${it.name} regularly. Order again?');
        }
      }
    }
  }

  void _openAddItem([GroceryItem? it]) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditScreen(item: it)));
    await _refreshList();
  }

  void _openCart() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
    await _refreshList();
  }

  void _openProfile() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
    await _refreshList();
  }

  List<GroceryItem> _filtered() {
    if (search.isEmpty) return items;
    return items.where((it) => it.name.toLowerCase().contains(search.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Grocery'),
        actions: [
          IconButton(onPressed: _openCart, icon: const Icon(Icons.shopping_cart)),
          IconButton(onPressed: _openProfile, icon: const Icon(Icons.person)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(labelText: 'Search', border: OutlineInputBorder()),
              onChanged: (v) => setState(() => search = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) {
                final it = list[i];
                return ListTile(
                  title: Text(it.name),
                  subtitle: Text('Qty: ${it.qty} | Category: ${it.category}'),
                  trailing: IconButton(
                    icon: Icon(it.fav ? Icons.star : Icons.star_border),
                    onPressed: () async {
                      it.fav = !it.fav;
                      await DB.instance.updateItem(it);
                      _refreshList();
                    },
                  ),
                  onTap: () => _openAddItem(it),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _openAddItem(),
      ),
    );
  }
}

/* ---------------------------
  Add/Edit Screen
----------------------------*/
class AddEditScreen extends StatefulWidget {
  final GroceryItem? item;
  const AddEditScreen({super.key, this.item});
  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameC, categoryC, qtyC, notesC;
  bool fav = false;

  @override
  void initState() {
    super.initState();
    final it = widget.item;
    nameC = TextEditingController(text: it?.name ?? '');
    categoryC = TextEditingController(text: it?.category ?? '');
    qtyC = TextEditingController(text: it?.qty.toString() ?? '1');
    notesC = TextEditingController(text: it?.notes ?? '');
    fav = it?.fav ?? false;
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    final it = GroceryItem(
      id: widget.item?.id,
      name: nameC.text,
      category: categoryC.text,
      qty: int.tryParse(qtyC.text) ?? 1,
      notes: notesC.text,
      fav: fav,
      purchaseCount: widget.item?.purchaseCount ?? 0,
      lastPurchased: widget.item?.lastPurchased,
    );
    if (widget.item == null) {
      await DB.instance.insertItem(it);
    } else {
      await DB.instance.updateItem(it);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.item == null ? 'Add Item' : 'Edit Item')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(controller: nameC, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 8),
              TextFormField(controller: categoryC, decoration: const InputDecoration(labelText: 'Category')),
              const SizedBox(height: 8),
              TextFormField(controller: qtyC, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              TextFormField(controller: notesC, decoration: const InputDecoration(labelText: 'Notes')),
              SwitchListTile(
                title: const Text('Favorite'),
                value: fav,
                onChanged: (v) => setState(() => fav = v),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _save, child: const Text('Save'))
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------------------------
  Cart Screen
----------------------------*/
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> cart = [];

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    cart = await DB.instance.getCartItems();
    setState(() {});
  }

  void _updateQty(int itemId, int qty) async {
    await DB.instance.updateCart(itemId, qty);
    _loadCart();
  }

  void _checkout() async {
    await DB.instance.clearCart();
    await _loadCart();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checkout done!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: ListView.builder(
        itemCount: cart.length,
        itemBuilder: (_, i) {
          final it = cart[i];
          return ListTile(
            title: Text(it['name']),
            subtitle: Text('Qty: ${it['cqty']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.remove), onPressed: () => _updateQty(it['id'], it['cqty'] - 1)),
                IconButton(icon: const Icon(Icons.add), onPressed: () => _updateQty(it['id'], it['cqty'] + 1)),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: ElevatedButton(
        onPressed: cart.isEmpty ? null : _checkout,
        child: const Text('Checkout'),
      ),
    );
  }
}

/* ---------------------------
  Profile Screen
----------------------------*/
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameC = TextEditingController();
  final emailC = TextEditingController();
  final addressC = TextEditingController();
  final cardC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await ProfileStore.loadProfile();
    nameC.text = data['name'] ?? '';
    emailC.text = data['email'] ?? '';
    addressC.text = data['address'] ?? '';
    cardC.text = data['payment'] ?? '';
    setState(() {});
  }

  void _save() async {
    await ProfileStore.saveProfile(nameC.text, emailC.text);
    await ProfileStore.saveAddress(addressC.text);
    await ProfileStore.savePaymentMock(cardC.text);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: emailC, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: addressC, decoration: const InputDecoration(labelText: 'Address')),
            TextField(controller: cardC, decoration: const InputDecoration(labelText: 'Card Last 4 digits')),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
