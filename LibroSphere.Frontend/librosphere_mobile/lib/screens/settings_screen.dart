import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../core/ui/app_feedback.dart';
import '../data/models/order_status.dart';
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
                  backgroundColor: Colors.transparent,
                  child: NetworkAvatar(
                    imageUrl: profileUrl,
                    radius: 28,
                    backgroundColor: brandBlueDark,
                    fallback: Text(
                      _initials(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
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
  late Future<List<_OrderViewData>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadOrders();
  }

  Future<List<_OrderViewData>> _loadOrders({bool forceRefresh = false}) async {
    final orders = await widget.session.getOrders(forceRefresh: forceRefresh);
    return orders.map(_OrderViewData.fromMap).toList(growable: false);
  }

  Future<void> _refresh() async {
    final next = _loadOrders(forceRefresh: true);
    setState(() {
      _future = next;
    });
    await next;
  }

  Future<bool> _refund(String orderId) async {
    if (orderId.isEmpty) return false;
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

    if (confirmed != true || !mounted) return false;

    try {
      await widget.session.refundOrder(orderId);
      if (!mounted) return false;
      showSuccessSnackBar(context, 'Refund requested successfully.');
      await _refresh();
      return true;
    } catch (error) {
      if (!mounted) return false;
      showDestructiveSnackBar(context, formatErrorMessage(error));
      return false;
    }
  }

  Future<void> _openOrderDetails(_OrderViewData order) async {
    final didRefund = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _OrderDetailsScreen(
          order: order,
          onRefund: order.isRefundable
              ? () => _refund(order.id)
              : null,
        ),
      ),
    );

    if (didRefund == true && mounted) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<List<_OrderViewData>>(
            future: _future,
            builder: (context, snapshot) {
              final orders = snapshot.data ?? const <_OrderViewData>[];
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
                    onTap: () => _openOrderDetails(order),
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
  const _OrderCard({required this.order, required this.onTap});

  final _OrderViewData order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0B000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.shortId}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.itemSummary,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _StatusChip(status: order.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.formattedTotal,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAF2FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: brandBlueDark,
                  ),
                ),
              ],
            ),
            if (order.orderDateLabel != null) ...[
              const SizedBox(height: 8),
              Text(
                order.orderDateLabel!,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ],
            if (order.items.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...order.items.take(2).map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.book_outlined,
                        size: 16,
                        color: brandBlueDark,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (order.items.length > 2)
                Text(
                  '+ ${order.items.length - 2} more item${order.items.length - 2 == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrderDetailsScreen extends StatelessWidget {
  const _OrderDetailsScreen({
    required this.order,
    required this.onRefund,
  });

  final _OrderViewData order;
  final Future<bool> Function()? onRefund;

  Future<void> _handleRefund(BuildContext context) async {
    final refundAction = onRefund;
    if (refundAction == null) {
      return;
    }

    final didRefund = await refundAction();
    if (didRefund && context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          children: [
            const _BackHeader(title: 'Order Details'),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0B000000),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: brandBlue,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order #${order.shortId}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                order.itemSummary,
                                style: const TextStyle(
                                  color: Color(0xD9FFFFFF),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _StatusChip(status: order.status, inverse: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _OrderMetaRow(
                    label: 'Total',
                    value: order.formattedTotal,
                    emphasize: true,
                  ),
                  if (order.orderDateLabel != null)
                    _OrderMetaRow(
                      label: 'Order date',
                      value: order.orderDateLabel!,
                    ),
                  if (order.buyerEmail.isNotEmpty)
                    _OrderMetaRow(
                      label: 'Email',
                      value: order.buyerEmail,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Purchased Items',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            if (order.items.isEmpty)
              const _OrdersMessage(
                message: 'No item details are available for this order yet.',
                icon: Icons.inventory_2_outlined,
              )
            else
              ...order.items.map((item) => _OrderItemTile(item: item)),
            if (order.isRefundable) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handleRefund(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB42318),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Request Refund',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({required this.item});

  final _OrderLineItemViewData item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: brandBlueDark,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    'Quantity: ${item.quantity}',
                    style: const TextStyle(
                      color: brandBlueDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  item.formattedTotal,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, this.inverse = false});

  final OrderStatus status;
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (status) {
      case OrderStatus.paymentReceived:
        bg = const Color(0xFFE7F6EC);
        fg = const Color(0xFF027A48);
      case OrderStatus.refunded:
        bg = const Color(0xFFFFF4ED);
        fg = const Color(0xFFB54708);
      case OrderStatus.pending:
        bg = const Color(0xFFFFF8E1);
        fg = const Color(0xFF92400E);
      case OrderStatus.paymentFailed:
        bg = const Color(0xFFFFF4ED);
        fg = const Color(0xFFB54708);
      default:
        bg = const Color(0xFFF2F4F7);
        fg = const Color(0xFF344054);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: inverse ? Colors.white.withValues(alpha: 0.2) : bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        _displayStatus(status),
        style: TextStyle(
          color: inverse ? Colors.white : fg,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static String _displayStatus(OrderStatus status) {
    return switch (status) {
      OrderStatus.pending => 'Pending',
      OrderStatus.paymentReceived => 'Paid',
      OrderStatus.paymentFailed => 'Payment Failed',
      OrderStatus.refunded => 'Refunded',
      OrderStatus.unknown => 'Unknown',
    };
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
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0B000000),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
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
      ),
    );
  }
}

class _OrderMetaRow extends StatelessWidget {
  const _OrderMetaRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final valueStyle = emphasize
        ? const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)
        : const TextStyle(fontSize: 14, fontWeight: FontWeight.w700);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderViewData {
  _OrderViewData({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.currencyCode,
    required this.items,
    required this.buyerEmail,
    required this.orderDate,
  });

  final String id;
  final OrderStatus status;
  final double totalAmount;
  final String currencyCode;
  final List<_OrderLineItemViewData> items;
  final String buyerEmail;
  final DateTime? orderDate;

  bool get isRefundable => status == OrderStatus.paymentReceived;

  String get shortId => id.length > 8 ? id.substring(0, 8) : id;

  String get formattedTotal => _formatMoney(totalAmount, currencyCode);

  String get itemSummary {
    final quantity = items.fold<int>(0, (sum, item) => sum + item.quantity);
    final count = quantity == 0 ? items.length : quantity;
    return '$count item${count == 1 ? '' : 's'}';
  }

  String? get orderDateLabel {
    final date = orderDate;
    if (date == null) {
      return null;
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  factory _OrderViewData.fromMap(Map<String, dynamic> json) {
    final totalValue = _readAny(json, const ['totalAmount', 'TotalAmount']);
    final rawItems = _readAny(json, const ['items', 'Items']);
    final itemMaps = rawItems is List
        ? rawItems.whereType<Map>().map((item) {
            return Map<String, dynamic>.from(item);
          }).toList()
        : <Map<String, dynamic>>[];
    final items = itemMaps.map(_OrderLineItemViewData.fromMap).toList();
    final fallbackCurrency = items.isNotEmpty ? items.first.currencyCode : 'USD';

    return _OrderViewData(
      id: (_readAny(json, const ['id', 'Id']) ?? '').toString(),
      status: parseOrderStatus(_readAny(json, const ['status', 'Status'])),
      totalAmount: _parseMoneyAmount(totalValue),
      currencyCode: _parseMoneyCurrency(totalValue, fallbackCode: fallbackCurrency),
      items: items,
      buyerEmail: (_readAny(json, const ['buyerEmail', 'BuyerEmail']) ?? '')
          .toString(),
      orderDate: _parseDate(
        _readAny(
          json,
          const ['orderDate', 'OrderDate', 'createdOnUtc', 'CreatedOnUtc'],
        ),
      ),
    );
  }
}

class _OrderLineItemViewData {
  _OrderLineItemViewData({
    required this.title,
    required this.quantity,
    required this.price,
    required this.currencyCode,
  });

  final String title;
  final int quantity;
  final double price;
  final String currencyCode;

  String get formattedTotal => _formatMoney(price * quantity, currencyCode);

  factory _OrderLineItemViewData.fromMap(Map<String, dynamic> json) {
    final priceValue = _readAny(
      json,
      const ['price', 'Price', 'priceAtPurchase', 'PriceAtPurchase'],
    );

    return _OrderLineItemViewData(
      title: (_readAny(json, const ['title', 'Title', 'bookTitle', 'BookTitle']) ??
              'Book')
          .toString(),
      quantity: _parseInt(
        _readAny(json, const ['quantity', 'Quantity']),
        fallback: 1,
      ),
      price: _parseMoneyAmount(priceValue),
      currencyCode: _parseMoneyCurrency(priceValue),
    );
  }
}

dynamic _readAny(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key) && json[key] != null) {
      return json[key];
    }
  }
  return null;
}

double _parseMoneyAmount(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value) ?? 0;
  }

  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    final amount = _readAny(map, const ['amount', 'Amount']);
    return _parseMoneyAmount(amount);
  }

  return 0;
}

String _parseMoneyCurrency(dynamic value, {String fallbackCode = 'USD'}) {
  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    final directCode = _readAny(map, const ['code', 'Code']);
    if (directCode != null) {
      return directCode.toString();
    }

    final currency = _readAny(map, const ['currency', 'Currency']);
    if (currency is Map) {
      final currencyMap = Map<String, dynamic>.from(currency);
      final nestedCode = _readAny(currencyMap, const ['code', 'Code']);
      if (nestedCode != null) {
        return nestedCode.toString();
      }
    }
  }

  return fallbackCode;
}

DateTime? _parseDate(dynamic value) {
  if (value is DateTime) {
    return value.toLocal();
  }

  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value)?.toLocal();
  }

  return null;
}

int _parseInt(dynamic value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }

  return fallback;
}

String _formatMoney(double amount, String currencyCode) {
  final normalizedCurrency = currencyCode.trim().toUpperCase();
  if (normalizedCurrency == 'USD') {
    return '\$${amount.toStringAsFixed(2)}';
  }

  return '${amount.toStringAsFixed(2)} $normalizedCurrency';
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
