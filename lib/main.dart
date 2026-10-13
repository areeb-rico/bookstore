import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'models/book.dart';
import 'screens/auth_gate.dart';
import 'screens/login.dart';
import 'screens/home.dart';
import 'screens/browser.dart';
import 'screens/liked.dart';
import 'screens/cart.dart';
import 'screens/profile.dart';
import 'screens/user_session.dart';
import 'screens/admin/dashboard_screen.dart';
import 'screens/admin/manage_books_screen.dart';
import 'screens/admin/manage_users_screen.dart';
import 'screens/admin/manage_orders_screen.dart';
import 'screens/admin/edit_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const BookStoreApp());
}

class BookStoreApp extends StatefulWidget {
  const BookStoreApp({super.key});

  @override
  State<BookStoreApp> createState() => _BookStoreAppState();
}

class _BookStoreAppState extends State<BookStoreApp> {
  // Shared state across the app
  final List<Book> allBooks = [
    Book(
      id: '1',
      title: 'The Silent Patient',
      author: 'Alex Michaelides',
      price: 12.99,
      rating: 4.8,
      category: 'Mystery',
      imageUrl:
          'https://images.unsplash.com/photo-1544947950-fa07a98d237f?q=80&w=300&auto=format&fit=crop',
      description:
          'Alicia Berenson’s life is seemingly perfect. One evening, she shoots her husband five times in the face, and then never speaks another word.',
    ),
    Book(
      id: '2',
      title: 'Project Hail Mary',
      author: 'Andy Weir',
      price: 16.00,
      rating: 4.8,
      category: 'Sci-Fi',
      imageUrl:
          'https://images.unsplash.com/photo-1512820790803-83ca734da794?q=80&w=300&auto=format&fit=crop',
      description:
          'Ryland Grace is the sole survivor on a desperate, last-chance mission—and if he fails, humanity and the earth itself will perish.',
    ),
    Book(
      id: '3',
      title: 'Atomic Habits',
      author: 'James Clear',
      price: 18.50,
      rating: 4.9,
      category: 'History',
      imageUrl:
          'https://images.unsplash.com/photo-1589829085413-56de8ae18c73?q=80&w=300&auto=format&fit=crop',
      description:
          'An easy & proven way to build good habits & break bad ones. Learn how tiny changes lead to remarkable results.',
    ),
    Book(
      id: '4',
      title: 'To Kill a Mockingbird',
      author: 'Harper Lee',
      price: 14.20,
      rating: 4.7,
      category: 'Fiction',
      imageUrl:
          'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?q=80&w=300&auto=format&fit=crop',
      description:
          'The unforgettable novel of a childhood in a sleepy Southern town and the crisis of conscience that rocked it.',
    ),
    Book(
      id: '5',
      title: 'The Design of Everyday Things',
      author: 'Don Norman',
      price: 21.00,
      rating: 4.6,
      category: 'History',
      imageUrl:
          'https://images.unsplash.com/photo-1532012197267-da84d127e765?q=80&w=300&auto=format&fit=crop',
      description:
          'Even the smartest among us can feel inept as we try to figure out which light switch or oven burner to turn on.',
    ),
    Book(
      id: '6',
      title: 'The Book of Art',
      author: 'E. H. Gombrich',
      price: 25.00,
      rating: 4.9,
      category: 'History',
      imageUrl:
          'https://images.unsplash.com/photo-1543002588-bfa74002ed7e?q=80&w=300&auto=format&fit=crop',
      description:
          'A classic introduction to art history, bringing the world of fine art and architecture to life.',
    ),
  ];

  final List<CartItem> cartItems = [];
  final List<Order> orders = [];
  final Set<String> savedBookIds = {'1'};

  void addToCart(Book book) {
    setState(() {
      final existingIndex = cartItems.indexWhere(
        (item) => item.book.id == book.id,
      );

      if (existingIndex >= 0) {
        cartItems[existingIndex].quantity++;
      } else {
        cartItems.add(CartItem(book: book));
      }
    });
  }

  void toggleSaveBook(String bookId) {
    setState(() {
      if (savedBookIds.contains(bookId)) {
        savedBookIds.remove(bookId);
      } else {
        savedBookIds.add(bookId);
      }
    });
  }

  void clearCart() {
    setState(() {
      cartItems.clear();
    });
  }

  void placeOrder(String shippingAddress, double total) {
    setState(() {
      orders.insert(
        0,
        Order(
          id: '#ORD-${DateTime.now().millisecondsSinceEpoch}',
          items: List<CartItem>.from(cartItems),
          total: total,
          shippingAddress: shippingAddress,
          date: DateTime.now(),
        ),
      );

      cartItems.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: UserSession.darkMode,
      builder: (context, isDark, child) {
        return MaterialApp(
          title: 'Book Store',
          debugShowCheckedModeBanner: false,

          // Light theme
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF5F5F0),
            primaryColor: const Color(0xFF1E4D3B),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1E4D3B),
              primary: const Color(0xFF1E4D3B),
              surface: const Color(0xFFF5F5F0),
              brightness: Brightness.light,
            ),
            fontFamily: 'serif',
            useMaterial3: true,
          ),

          // Dark theme
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            primaryColor: const Color(0xFF1E4D3B),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1E4D3B),
              primary: const Color(0xFF5FAF91),
              surface: const Color(0xFF1E1E1E),
              brightness: Brightness.dark,
            ),
            fontFamily: 'serif',
            useMaterial3: true,
          ),

          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

          initialRoute: '/',
          routes: {
            '/': (context) => const AuthGate(),
            '/login': (context) => const LoginScreen(),
            '/main_shell': (context) => MainNavigationShell(
              allBooks: allBooks,
              cartItems: cartItems,
              orders: orders,
              savedBookIds: savedBookIds,
              onAddToCart: addToCart,
              onToggleSave: toggleSaveBook,
            ),
            '/cart': (context) => CartScreen(
              cartItems: cartItems,
              onPlaceOrder: placeOrder,
              onQuantityChanged: () => setState(() {}),
            ),

            // Admin panel
            '/admin-dashboard': (context) =>
                DashboardScreen(allBooks: allBooks, orders: orders),
            '/manage-books': (context) => ManageBooksScreen(allBooks: allBooks),
            '/manage-users': (context) => const ManageUsersScreen(),
            '/manage-orders': (context) => ManageOrdersScreen(orders: orders),
            '/edit-profile': (context) => const EditProfileScreen(),
          },
        );
      },
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  final List<Book> allBooks;
  final List<CartItem> cartItems;
  final List<Order> orders;
  final Set<String> savedBookIds;
  final Function(Book) onAddToCart;
  final Function(String) onToggleSave;

  const MainNavigationShell({
    super.key,
    required this.allBooks,
    required this.cartItems,
    required this.orders,
    required this.savedBookIds,
    required this.onAddToCart,
    required this.onToggleSave,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        allBooks: widget.allBooks,
        cartItems: widget.cartItems,
        savedBookIds: widget.savedBookIds,
        onAddToCart: widget.onAddToCart,
        onToggleSave: widget.onToggleSave,
      ),
      BrowserScreen(
        allBooks: widget.allBooks,
        cartItems: widget.cartItems,
        savedBookIds: widget.savedBookIds,
        onAddToCart: widget.onAddToCart,
        onToggleSave: widget.onToggleSave,
      ),
      LikedScreen(
        allBooks: widget.allBooks,
        cartItems: widget.cartItems,
        savedBookIds: widget.savedBookIds,
        onAddToCart: widget.onAddToCart,
        onToggleSave: widget.onToggleSave,
      ),
      ProfileScreen(orders: widget.orders),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).unselectedWidgetColor,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view),
              label: 'Browse',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: widget.savedBookIds.isNotEmpty,
                label: Text('${widget.savedBookIds.length}'),
                child: const Icon(Icons.favorite_outline),
              ),
              activeIcon: Badge(
                isLabelVisible: widget.savedBookIds.isNotEmpty,
                label: Text('${widget.savedBookIds.length}'),
                child: const Icon(Icons.favorite),
              ),
              label: 'Saved',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
