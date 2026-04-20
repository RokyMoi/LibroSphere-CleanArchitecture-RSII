import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../core/app_constants.dart';
import '../core/ui/app_feedback.dart';
import '../core/utils/validators.dart';
import '../data/models/book_model.dart';
import '../data/models/order_status.dart';
import '../features/session/presentation/session_scope.dart';
import '../features/session/presentation/viewmodels/session_viewmodel.dart';
import '../widgets/common_widgets.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  SessionViewModel? _session;
  late Future<List<BookModel>> _future = _load();

  Future<List<BookModel>> _load() async {
    final session = SessionScope.read(context);
    final cart = await session.refreshCart();
    if (cart == null) {
      return <BookModel>[];
    }

    return Future.wait(cart.items.map((item) => session.getBook(item.bookId)));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final nextSession = SessionScope.read(context);
    if (_session == nextSession) {
      return;
    }

    _session?.removeListener(_handleSessionChanged);
    _session = nextSession;
    _session!.addListener(_handleSessionChanged);
  }

  @override
  void dispose() {
    _session?.removeListener(_handleSessionChanged);
    super.dispose();
  }

  void _handleSessionChanged() {
    if (!mounted) {
      return;
    }

    setState(() {
      _future = _load();
    });
  }

  Future<void> _removeFromCart(String bookId) async {
    try {
      await context.session.removeFromCart(bookId);
      if (!mounted) {
        return;
      }

      showDestructiveSnackBar(context, 'The book was removed from your shopping cart.');
      setState(() {
        _future = _load();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      showDestructiveSnackBar(context, formatErrorMessage(error));
    }
  }

  Future<void> _openCheckout() async {
    final session = SessionScope.read(context);
    final result = await Navigator.of(context).push<CheckoutResult>(
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(session: session),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    if (result.success) {
      showSuccessSnackBar(context, result.message);
    } else {
      showDestructiveSnackBar(context, result.message);
    }

    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BookModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return InfoStateView(
            title: 'Shopping Cart',
            message: formatErrorMessage(snapshot.error!),
            icon: Icons.shopping_cart_outlined,
          );
        }

        if (!snapshot.hasData) {
          return const CenteredLoadingIndicator();
        }

        final books = snapshot.data!;
        final session = context.session;
        final total = session.cart?.total ?? 0;

        if (books.isEmpty) {
          return const InfoStateView(
            title: 'Shopping Cart',
            message: 'Your shopping cart is empty.',
            icon: Icons.shopping_cart_outlined,
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          children: [
            SectionHeader(title: 'Shopping Cart', count: books.length),
            const SizedBox(height: 26),
            ...books.map(
              (book) => Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BookCover(imageUrl: book.imageLink, width: 88, height: 130, radius: 0),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(book.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(
                            session.authorNameForBook(book),
                            style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 96,
                            child: PrimaryPillButton(
                              label: 'Remove',
                              compact: true,
                              onPressed: () => _removeFromCart(book.id),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text('\$${book.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total Price:',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            PrimaryPillButton(
              label: 'CHECKOUT',
              onPressed: books.isEmpty ? null : _openCheckout,
            ),
          ],
        );
      },
    );
  }
}

class CheckoutResult {
  const CheckoutResult({
    required this.success,
    required this.message,
  });

  final bool success;
  final String message;
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.session,
  });

  final SessionViewModel session;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  CardFieldInputDetails? _cardDetails;
  bool _processing = false;
  String? _nameError;
  String? _emailError;
  String? _cardError;
  String? _formError;

  bool get _supportsStripeCardField {
    if (kIsWeb) {
      return true;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.session.currentUser?.fullName ?? '';
    _emailController.text = widget.session.currentUser?.email ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (!_supportsStripeCardField) {
      setState(() {
        _formError =
            'Checkout with card entry is available on Android and iOS. Windows build can open the screen, but card payment is not supported here.';
      });
      showDestructiveSnackBar(context, _formError!);
      return;
    }

    final stripeKey = resolveStripePublishableKey();
    if (stripeKey == null) {
      setState(() {
        _formError = 'Stripe is not configured for this build. Set LIBROSPHERE_STRIPE_PUBLISHABLE_KEY.';
      });
      showDestructiveSnackBar(context, _formError!);
      return;
    }

    if (!_validate()) {
      return;
    }

    setState(() => _processing = true);
    try {
      final order = await widget.session.checkout(
        BillingDetails(
          email: _emailController.text.trim(),
          name: _nameController.text.trim(),
        ),
      );

      if (!mounted) {
        return;
      }

      final isPaid = order.status != OrderStatus.paymentFailed;
      Navigator.of(context).pop(
        CheckoutResult(
          success: isPaid,
          message: isPaid
              ? 'Payment completed successfully. Your book should appear in My Library shortly.'
              : 'Payment failed. Please check your card details and try again.',
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _formError = formatErrorMessage(error));
      showDestructiveSnackBar(context, _formError!);
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  bool _validate() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final cardComplete = !_supportsStripeCardField || (_cardDetails?.complete ?? false);

    setState(() {
      _nameError = name.isEmpty ? 'Cardholder name is required.' : null;
      _emailError = email.isEmpty
          ? 'Email is required.'
          : (isValidEmail(email) ? null : 'Enter a valid email address.');
      _cardError = _supportsStripeCardField
          ? (cardComplete ? null : 'Please complete your card details.')
          : null;
      _formError = null;
    });

    return _nameError == null && _emailError == null && _cardError == null;
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.session.cart?.total ?? 0;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          children: [
            InkWell(
              onTap: () => Navigator.of(context).pop(),
              child: const Row(
                children: [
                  Icon(Icons.chevron_left_rounded, color: brandBlue, size: 28),
                  SizedBox(width: 8),
                  Text('Checkout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: brandBlue, borderRadius: BorderRadius.circular(30)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment details', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 18),
                  const Text('Cardholder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  RoundedInput(
                    controller: _nameController,
                    hint: 'Full name',
                    dense: true,
                    errorText: _nameError,
                    onChanged: (_) {
                      if (_nameError != null || _formError != null) {
                        setState(() {
                          _nameError = null;
                          _formError = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Email', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  RoundedInput(
                    controller: _emailController,
                    hint: 'Email address',
                    dense: true,
                    keyboardType: TextInputType.emailAddress,
                    errorText: _emailError,
                    onChanged: (_) {
                      if (_emailError != null || _formError != null) {
                        setState(() {
                          _emailError = null;
                          _formError = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Card', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  _supportsStripeCardField
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                          child: CardField(
                            onCardChanged: (details) => setState(() {
                              _cardDetails = details;
                              _cardError = null;
                              _formError = null;
                            }),
                            countryCode: resolveStripeMerchantCountryCode(),
                            style: const TextStyle(fontSize: 16, color: Colors.black87),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                          child: const Text(
                            'Card input is not supported on Windows. Use Android or iOS to complete payment.',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                  FormMessage(message: _cardError, color: Colors.white),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Total:',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            '\$${total.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  PrimaryPillButton(
                    label: _processing ? 'Processing...' : 'Pay Now',
                    rectangular: true,
                    onPressed: _processing || !_supportsStripeCardField ? null : _pay,
                  ),
                  FormMessage(message: _formError, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
