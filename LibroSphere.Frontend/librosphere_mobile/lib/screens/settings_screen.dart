import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../core/app_constants.dart';
import '../core/ui/app_feedback.dart';
import '../features/session/presentation/session_scope.dart';
import '../features/session/presentation/viewmodels/session_viewmodel.dart';
import '../widgets/common_widgets.dart';
import 'package:image_picker/image_picker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final session = SessionScope.read(context);

    return ValueListenableBuilder(
      valueListenable: session.profileState,
      builder: (context, _, child) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          children: [
            const Text(
              'Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            _ProfileCard(session: session),
            const SizedBox(height: 14),
            _SettingsTile(
              icon: Icons.person_outline_rounded,
              label: 'Edit Profile',
              onTap: () => _openEditProfile(session),
            ),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.lock_outline_rounded,
              label: 'Change Password',
              onTap: () => _openChangePassword(session),
            ),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.receipt_long_outlined,
              label: 'My Orders',
              onTap: () => _openMyOrders(session),
            ),
            const SizedBox(height: 24),
            PrimaryPillButton(
              label: 'Logout',
              onPressed: () async => session.logout(),
            ),
          ],
        );
      },
    );
  }

  void _openEditProfile(SessionViewModel session) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _EditProfileScreen(session: session)),
    );
  }

  void _openChangePassword(SessionViewModel session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ChangePasswordScreen(session: session),
      ),
    );
  }

  void _openMyOrders(SessionViewModel session) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _MyOrdersScreen(session: session)),
    );
  }
}

class _ProfileCard extends StatefulWidget {
  const _ProfileCard({required this.session});

  final SessionViewModel session;

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final profileUrl = session.currentUser?.profilePictureUrl;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _isUploading ? null : _pickAndUploadImage,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: brandBlueDark,
                  backgroundImage: profileUrl != null && profileUrl.isNotEmpty
                      ? CachedNetworkImageProvider(profileUrl)
                      : null,
                  child: profileUrl == null || profileUrl.isEmpty
                      ? Text(
                          _initials(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : null,
                ),
                if (_isUploading)
                  Positioned.fill(
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.black.withValues(alpha: 0.5),
                      child: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: brandBlueDark,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.currentUser?.fullName ?? 'Unknown User',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  session.currentUser?.email ?? '',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials() {
    final first = widget.session.currentUser?.firstName ?? '';
    final last = widget.session.currentUser?.lastName ?? '';
    final buffer = StringBuffer();
    if (first.isNotEmpty) buffer.write(first[0].toUpperCase());
    if (last.isNotEmpty) buffer.write(last[0].toUpperCase());
    return buffer.isEmpty ? '?' : buffer.toString();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (xFile == null) return;
    if (!mounted) return;

    setState(() => _isUploading = true);

    try {
      final bytes = await xFile.readAsBytes();
      final mimeType = xFile.mimeType ?? 'image/jpeg';
      final fileName = xFile.name.isEmpty ? 'profile.jpg' : xFile.name;

      await widget.session.updateProfilePicture(
        imageBytes: bytes,
        filename: fileName,
        contentType: mimeType,
      );

      if (!mounted) return;
      showSuccessSnackBar(context, 'Profile picture updated successfully.');
    } catch (error) {
      if (!mounted) return;
      showDestructiveSnackBar(context, formatErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: brandBlueDark, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Edit Profile Screen
// ---------------------------------------------------------------------------
class _EditProfileScreen extends StatefulWidget {
  const _EditProfileScreen({required this.session});

  final SessionViewModel session;

  @override
  State<_EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<_EditProfileScreen> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  String? _firstNameError;
  String? _lastNameError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.session.currentUser?.firstName ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.session.currentUser?.lastName ?? '',
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  bool _validate() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    setState(() {
      _firstNameError = firstName.isEmpty || firstName.length > 100
          ? 'First name is required (max 100 characters).'
          : null;
      _lastNameError = lastName.isEmpty || lastName.length > 100
          ? 'Last name is required (max 100 characters).'
          : null;
    });

    return _firstNameError == null && _lastNameError == null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_validate() || _submitting) return;

    setState(() => _submitting = true);

    try {
      await widget.session.updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      );
      if (!mounted) return;
      showSuccessSnackBar(context, 'Profile updated successfully.');
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      showDestructiveSnackBar(context, formatErrorMessage(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          children: [
            _BackHeader(title: 'Edit Profile'),
            const SizedBox(height: 24),
            RoundedInput(
              controller: _firstNameController,
              hint: 'First Name',
              textInputAction: TextInputAction.next,
              errorText: _firstNameError,
              onChanged: (_) {
                if (_firstNameError != null) {
                  setState(() => _firstNameError = null);
                }
              },
            ),
            const SizedBox(height: 16),
            RoundedInput(
              controller: _lastNameController,
              hint: 'Last Name',
              textInputAction: TextInputAction.done,
              errorText: _lastNameError,
              onChanged: (_) {
                if (_lastNameError != null) {
                  setState(() => _lastNameError = null);
                }
              },
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            PrimaryPillButton(
              label: _submitting ? 'Saving...' : 'Save Changes',
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Change Password Screen
// ---------------------------------------------------------------------------
class _ChangePasswordScreen extends StatefulWidget {
  const _ChangePasswordScreen({required this.session});

  final SessionViewModel session;

  @override
  State<_ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<_ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;
  bool _submitting = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validate() {
    final current = _currentPasswordController.text;
    final newPwd = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    setState(() {
      _currentPasswordError =
          current.isEmpty ? 'Current password is required.' : null;
      _newPasswordError = newPwd.isEmpty
          ? 'New password is required.'
          : newPwd.length < 8
              ? 'New password must be at least 8 characters.'
              : null;
      _confirmPasswordError = confirm != newPwd
          ? 'Password confirmation does not match.'
          : null;
    });

    return _currentPasswordError == null &&
        _newPasswordError == null &&
        _confirmPasswordError == null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_validate() || _submitting) return;

    setState(() => _submitting = true);

    try {
      await widget.session.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmNewPassword: _confirmPasswordController.text,
      );
      if (!mounted) return;
      showSuccessSnackBar(context, 'Password changed successfully.');
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      showDestructiveSnackBar(context, formatErrorMessage(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          children: [
            _BackHeader(title: 'Change Password'),
            const SizedBox(height: 24),
            RoundedInput(
              controller: _currentPasswordController,
              hint: 'Current Password',
              obscureText: true,
              textInputAction: TextInputAction.next,
              errorText: _currentPasswordError,
              onChanged: (_) {
                if (_currentPasswordError != null) {
                  setState(() => _currentPasswordError = null);
                }
              },
            ),
            const SizedBox(height: 16),
            RoundedInput(
              controller: _newPasswordController,
              hint: 'New Password',
              obscureText: true,
              textInputAction: TextInputAction.next,
              errorText: _newPasswordError,
              onChanged: (_) {
                if (_newPasswordError != null) {
                  setState(() => _newPasswordError = null);
                }
              },
            ),
            const SizedBox(height: 16),
            RoundedInput(
              controller: _confirmPasswordController,
              hint: 'Confirm New Password',
              obscureText: true,
              textInputAction: TextInputAction.done,
              errorText: _confirmPasswordError,
              onChanged: (_) {
                if (_confirmPasswordError != null) {
                  setState(() => _confirmPasswordError = null);
                }
              },
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            PrimaryPillButton(
              label: _submitting ? 'Updating...' : 'Change Password',
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// My Orders Screen
// ---------------------------------------------------------------------------
class _MyOrdersScreen extends StatefulWidget {
  const _MyOrdersScreen({required this.session});

  final SessionViewModel session;

  @override
  State<_MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<_MyOrdersScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.session.getOrders();
  }

  Future<void> _refresh() async {
    final next = widget.session.getOrders();
    setState(() {
      _future = next;
    });
    await next;
  }

  Future<void> _refund(Map<String, dynamic> order) async {
    final orderId = (order['id'] ?? order['Id'] ?? '').toString();
    if (orderId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refund Order'),
        content: const Text('Are you sure you want to request a refund for this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Refund'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await widget.session.refundOrder(orderId);
      if (!mounted) return;
      showSuccessSnackBar(context, 'Refund requested successfully.');
      _refresh();
    } catch (error) {
      if (!mounted) return;
      showDestructiveSnackBar(context, formatErrorMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _future,
            builder: (context, snapshot) {
              final orders = snapshot.data ?? const <Map<String, dynamic>>[];
              final itemCount = orders.isEmpty ? 3 : orders.length + 2;

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const _BackHeader(title: 'My Orders');
                  }
                  if (index == 1) {
                    return const SizedBox(height: 18);
                  }
                  if (snapshot.hasError) {
                    return _OrdersMessage(
                      message: formatErrorMessage(snapshot.error!),
                      icon: Icons.error_outline,
                    );
                  }
                  if (!snapshot.hasData) {
                    return const LoadingSkeleton(
                      child: Column(
                        children: [
                          SkeletonBox(height: 110, radius: 18),
                          SizedBox(height: 14),
                          SkeletonBox(height: 110, radius: 18),
                          SizedBox(height: 14),
                          SkeletonBox(height: 110, radius: 18),
                        ],
                      ),
                    );
                  }
                  if (orders.isEmpty) {
                    return const _OrdersMessage(
                      message: 'You have no orders yet.',
                      icon: Icons.receipt_long_outlined,
                    );
                  }

                  final order = orders[index - 2];
                  return _OrderCard(
                    order: order,
                    onRefund: () => _refund(order),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onRefund});

  final Map<String, dynamic> order;
  final VoidCallback onRefund;

  @override
  Widget build(BuildContext context) {
    final orderId = (order['id'] ?? order['Id'] ?? '').toString();
    final status = (order['status'] ?? order['Status'] ?? '').toString();
    final totalAmount = order['totalAmount'] ?? order['TotalAmount'];
    final createdAt = order['createdOnUtc'] ?? order['CreatedOnUtc'] ?? '';
    final items = order['items'] ?? order['Items'];
    final itemCount = items is List ? items.length : 0;
    final isRefundable = status.toLowerCase() == 'paymentreceived' ||
        status.toLowerCase() == 'payment_received';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order #${orderId.length > 8 ? orderId.substring(0, 8) : orderId}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusChip(status: status),
            ],
          ),
          const SizedBox(height: 8),
          if (createdAt.toString().isNotEmpty)
            Text(
              'Date: ${_formatDate(createdAt.toString())}',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          if (itemCount > 0)
            Text(
              '$itemCount item${itemCount == 1 ? '' : 's'}',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          if (totalAmount != null) ...[
            const SizedBox(height: 6),
            Text(
              '\$${_formatAmount(totalAmount)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          if (items is List && items.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...items.take(3).map((item) {
              final title = item['bookTitle'] ?? item['BookTitle'] ?? 'Book';
              final price = item['priceAtPurchase'] ?? item['PriceAtPurchase'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.book_outlined, size: 16, color: brandBlueDark),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title.toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    if (price != null)
                      Text(
                        '\$${_formatAmount(price)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              );
            }),
            if (items.length > 3)
              Text(
                '+ ${items.length - 3} more',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
          if (isRefundable) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onRefund,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB42318),
                  side: const BorderSide(color: Color(0xFFB42318)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Request Refund',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatDate(String raw) {
    try {
      final date = DateTime.parse(raw).toLocal();
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return raw;
    }
  }

  static String _formatAmount(dynamic amount) {
    if (amount is num) return amount.toStringAsFixed(2);
    return amount.toString();
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase().replaceAll('_', '');
    Color bg;
    Color fg;

    switch (normalized) {
      case 'paymentreceived':
        bg = const Color(0xFFE7F6EC);
        fg = const Color(0xFF027A48);
      case 'refunded':
        bg = const Color(0xFFFFF4ED);
        fg = const Color(0xFFB54708);
      case 'pending':
      case 'created':
        bg = const Color(0xFFFFF8E1);
        fg = const Color(0xFF92400E);
      default:
        bg = const Color(0xFFF2F4F7);
        fg = const Color(0xFF344054);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        _displayStatus(status),
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static String _displayStatus(String raw) {
    final clean = raw.replaceAll('_', ' ').replaceAll(RegExp(r'([a-z])([A-Z])'), r'$1 $2');
    if (clean.isEmpty) return 'Unknown';
    return '${clean[0].toUpperCase()}${clean.substring(1)}';
  }
}

class _OrdersMessage extends StatelessWidget {
  const _OrdersMessage({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Icon(icon, size: 48, color: brandBlueDark),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackHeader extends StatelessWidget {
  const _BackHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(),
      child: Row(
        children: [
          const Icon(
            Icons.chevron_left_rounded,
            color: brandBlue,
            size: 28,
          ),
          const SizedBox(width: 4),
          Text(
            title,
            style: const TextStyle(
              color: brandBlueDark,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
