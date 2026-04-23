import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/localization/admin_language_scope.dart';
import '../../../../shared/widgets/admin/admin_panel.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../viewmodels/reports_viewmodel.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key, required this.viewModel});

  final ReportsViewModel viewModel;

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;

        if (vm.isLoading) {
          return const LoadingView();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
          child: AdminPanel(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  context.tr(english: 'Reports', bosnian: 'Izvjestaji'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr(
                    english:
                        'Generate and download PDF reports for platform analysis.',
                    bosnian:
                        'Generisite i preuzmite PDF izvjestaje za analizu platforme.',
                  ),
                  style: const TextStyle(
                    color: desktopMutedForeground,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),

                // Report cards
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                    childAspectRatio: 1.6,
                    children: [
                      _ReportCard(
                        icon: Icons.analytics_outlined,
                        title: context.tr(
                          english: 'Platform Overview',
                          bosnian: 'Pregled platforme',
                        ),
                        description: context.tr(
                          english:
                              'Key metrics: total users, active users, books, authors, sales, revenue, and recent activity.',
                          bosnian:
                              'Ključne metrike: ukupan broj korisnika, aktivni korisnici, knjige, autori, prodaja, prihod i nedavna aktivnost.',
                        ),
                        isGenerating: vm.isGeneratingPlatform,
                        error: vm.platformError,
                        onGenerate: () async {
                          final bytes = await vm.generatePlatformReport();
                          if (bytes != null && context.mounted) {
                            await Printing.layoutPdf(
                              onLayout: (_) => bytes,
                              name: 'LibroSphere_Platform_Report.pdf',
                            );
                          }
                        },
                      ),
                      _ReportCard(
                        icon: Icons.menu_book_outlined,
                        title: context.tr(
                          english: 'Book Catalogue',
                          bosnian: 'Katalog knjiga',
                        ),
                        description: context.tr(
                          english:
                              'Complete list of all books with authors, genres, and pricing information.',
                          bosnian:
                              'Kompletna lista svih knjiga sa autorima, zanrovima i cijenama.',
                        ),
                        isGenerating: vm.isGeneratingCatalogue,
                        error: vm.catalogueError,
                        onGenerate: () async {
                          final bytes = await vm.generateCatalogueReport();
                          if (bytes != null && context.mounted) {
                            await Printing.layoutPdf(
                              onLayout: (_) => bytes,
                              name: 'LibroSphere_Book_Catalogue.pdf',
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Report Card ──────────────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isGenerating,
    required this.onGenerate,
    this.error,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool isGenerating;
  final String? error;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: desktopPrimaryLight.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: desktopPrimaryLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                color: desktopMutedForeground,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error!,
              style: const TextStyle(
                color: Color(0xFFFC8181),
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              onPressed: isGenerating ? null : onGenerate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
                ),
              icon: isGenerating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download_rounded, size: 18),
              label: Text(
                isGenerating
                    ? context.tr(english: 'Generating...', bosnian: 'Generisanje...')
                    : context.tr(english: 'Generate PDF', bosnian: 'Generisi PDF'),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
