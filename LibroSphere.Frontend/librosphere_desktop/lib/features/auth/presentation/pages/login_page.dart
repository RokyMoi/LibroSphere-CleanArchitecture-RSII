import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/localization/admin_language_scope.dart';
import '../../../session/presentation/viewmodels/admin_session_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/login_form.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.session});

  final AdminSessionViewModel session;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthViewModel _viewModel = AuthViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF7FAFF), Color(0xFFEFF4FB)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 900;
              final horizontalPadding = compact ? 20.0 : 36.0;
              final verticalPadding = compact ? 20.0 : 32.0;

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: compact ? 560 : 1160,
                      minHeight: compact
                          ? 0
                          : constraints.maxHeight - (verticalPadding * 2),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(compact ? 28 : 36),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x11000000),
                            blurRadius: 30,
                            offset: Offset(0, 14),
                          ),
                        ],
                      ),
                      child: compact
                          ? _CompactLoginLayout(
                              viewModel: _viewModel,
                              session: widget.session,
                            )
                          : _WideLoginLayout(
                              viewModel: _viewModel,
                              session: widget.session,
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WideLoginLayout extends StatelessWidget {
  const _WideLoginLayout({required this.viewModel, required this.session});

  final AuthViewModel viewModel;
  final AdminSessionViewModel session;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: _BrandPanel(
            padding: EdgeInsets.fromLTRB(42, 42, 34, 42),
            alignStart: true,
          ),
        ),
        Container(
          width: 430,
          padding: const EdgeInsets.fromLTRB(36, 42, 36, 36),
          decoration: const BoxDecoration(
            color: desktopPrimary,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(36),
              bottomRight: Radius.circular(36),
            ),
          ),
          child: ListenableBuilder(
            listenable: viewModel,
            builder: (context, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: _FormLogoBadge(compact: false)),
                  const SizedBox(height: 18),
                  const _LoginHeader(),
                  const SizedBox(height: 14),
                  Text(
                    context.tr(
                      english:
                          'Sign in with your administrator account to manage the catalog, users, orders, and reporting.',
                      bosnian:
                          'Prijavite se administratorskim nalogom da upravljate katalogom, korisnicima, narudzbama i izvjestajima.',
                    ),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  LoginForm(
                    emailController: viewModel.emailController,
                    passwordController: viewModel.passwordController,
                    isSubmitting: viewModel.isSubmitting,
                    errorMessage: viewModel.failure?.message,
                    onSubmit: () => viewModel.submit(session),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CompactLoginLayout extends StatelessWidget {
  const _CompactLoginLayout({required this.viewModel, required this.session});

  final AuthViewModel viewModel;
  final AdminSessionViewModel session;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _BrandPanel(
              padding: EdgeInsets.fromLTRB(24, 28, 24, 22),
              alignStart: false,
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: const BoxDecoration(
                color: desktopPrimary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: _FormLogoBadge(compact: true)),
                  const SizedBox(height: 16),
                  const _LoginHeader(compact: true),
                  const SizedBox(height: 12),
                  Text(
                    context.tr(
                      english:
                          'Sign in with your administrator account to continue.',
                      bosnian:
                          'Prijavite se administratorskim nalogom za nastavak.',
                    ),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  LoginForm(
                    emailController: viewModel.emailController,
                    passwordController: viewModel.passwordController,
                    isSubmitting: viewModel.isSubmitting,
                    errorMessage: viewModel.failure?.message,
                    onSubmit: () => viewModel.submit(session),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.padding, required this.alignStart});

  final EdgeInsets padding;
  final bool alignStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(36),
          bottomLeft: Radius.circular(36),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FBFF), Color(0xFFE9F1FB)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: alignStart
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  'assets/librosphere_logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.tr(
              english: 'LibroSphere Admin Portal',
              bosnian: 'LibroSphere Admin Portal',
            ),
            textAlign: alignStart ? TextAlign.left : TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF143A6B),
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Text(
              context.tr(
                english:
                    'Manage books, genres, users, orders, and dashboard activity from one admin workspace.',
                bosnian:
                    'Upravljajte knjigama, zanrovima, korisnicima, narudzbama i dashboard aktivnostima iz jednog admin prostora.',
              ),
              textAlign: alignStart ? TextAlign.left : TextAlign.center,
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.66),
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 26),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: alignStart ? WrapAlignment.start : WrapAlignment.center,
            children: const [
              _InfoChip(
                englishLabel: 'Catalog Management',
                bosnianLabel: 'Upravljanje katalogom',
              ),
              _InfoChip(
                englishLabel: 'Order Monitoring',
                bosnianLabel: 'Praćenje narudzbi',
              ),
              _InfoChip(
                englishLabel: 'Role-Based Access',
                bosnianLabel: 'Pristup po ulogama',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormLogoBadge extends StatelessWidget {
  const _FormLogoBadge({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 96.0 : 118.0;
    final radius = compact ? 28.0 : 34.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 18),
        child: ColorFiltered(
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          child: Image.asset(
            'assets/librosphere_logo.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.englishLabel,
    required this.bosnianLabel,
  });

  final String englishLabel;
  final String bosnianLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        context.tr(english: englishLabel, bosnian: bosnianLabel),
        style: const TextStyle(
          color: Color(0xFF143A6B),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final titleSize = compact ? 24.0 : 30.0;

    return Text(
      context.tr(english: 'ADMIN LOGIN', bosnian: 'ADMIN PRIJAVA'),
      style: TextStyle(
        color: Colors.white,
        fontSize: titleSize,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
