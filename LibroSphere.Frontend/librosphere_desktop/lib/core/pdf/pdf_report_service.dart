import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../features/books/data/models/admin_author_model.dart';
import '../../features/books/data/models/admin_book_model.dart';
import '../../features/dashboard/data/models/dashboard_stats_model.dart';
import '../../features/genres/data/models/admin_genre_model.dart';

/// Generates structured PDF reports for LibroSphere admin.
class PdfReportService {
  // ─── colours ──────────────────────────────────────────────────────────────
  static const _brandBlue = PdfColor.fromInt(0xFF1B4F9B);
  static const _brandBlueDark = PdfColor.fromInt(0xFF0D2E5E);
  static const _accent = PdfColor.fromInt(0xFFE8F0FE);
  static const _mutedText = PdfColor.fromInt(0xFF6B7280);
  static const _divider = PdfColor.fromInt(0xFFE5E7EB);
  static const _white = PdfColors.white;

  // ─── Report 1: Platform Overview (Dashboard stats) ────────────────────────

  Future<Uint8List> generatePlatformReport(DashboardStatsModel stats) async {
    final pdf = pw.Document(
      title: 'LibroSphere Platform Report',
      author: 'LibroSphere Admin',
    );

    final now = DateTime.now();
    final dateStr = _formatDate(now);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          _buildHeader('Platform Overview Report', dateStr),
          pw.SizedBox(height: 20),
          _buildSectionTitle('Key Metrics'),
          pw.SizedBox(height: 10),
          _buildStatsGrid(stats),
          pw.SizedBox(height: 24),
          _buildSectionTitle('Commerce Summary'),
          pw.SizedBox(height: 10),
          _buildCommerceTable(stats),
          pw.SizedBox(height: 24),
          _buildSectionTitle('Catalog Summary'),
          pw.SizedBox(height: 10),
          _buildCatalogTable(stats),
          if (stats.recentActivity.isNotEmpty) ...[
            pw.SizedBox(height: 24),
            _buildSectionTitle('Recent Activity'),
            pw.SizedBox(height: 10),
            _buildActivityTable(stats),
          ],
          pw.SizedBox(height: 32),
          _buildFooter(),
        ],
      ),
    );

    return pdf.save();
  }

  // ─── Report 2: Book Catalogue ─────────────────────────────────────────────

  Future<Uint8List> generateBookCatalogueReport({
    required List<AdminBookModel> books,
    required List<AdminAuthorModel> authors,
    required List<AdminGenreModel> genres,
  }) async {
    final pdf = pw.Document(
      title: 'LibroSphere Book Catalogue',
      author: 'LibroSphere Admin',
    );

    final now = DateTime.now();
    final dateStr = _formatDate(now);

    final authorMap = {for (final a in authors) a.id: a.name};
    final genreMap = {for (final g in genres) g.id: g.name};

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          _buildHeader('Book Catalogue', dateStr),
          pw.SizedBox(height: 6),
          pw.Text(
            'Total books: ${books.length}',
            style: pw.TextStyle(
              color: _mutedText,
              fontSize: 11,
            ),
          ),
          pw.SizedBox(height: 20),
          _buildBookTable(books, authorMap, genreMap),
          pw.SizedBox(height: 32),
          _buildFooter(),
        ],
      ),
    );

    return pdf.save();
  }

  // ─── Shared header / footer ───────────────────────────────────────────────

  pw.Widget _buildHeader(String title, String date) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: const pw.BoxDecoration(
        color: _brandBlue,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'LibroSphere',
                style: pw.TextStyle(
                  color: _white,
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                title,
                style: const pw.TextStyle(color: _white, fontSize: 14),
              ),
            ],
          ),
          pw.Text(
            'Generated: $date',
            style: const pw.TextStyle(color: _white, fontSize: 10),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: _divider, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'LibroSphere Admin System — Confidential',
            style: const pw.TextStyle(color: _mutedText, fontSize: 9),
          ),
          pw.Text(
            '© ${DateTime.now().year} LibroSphere',
            style: const pw.TextStyle(color: _mutedText, fontSize: 9),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSectionTitle(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const pw.BoxDecoration(
        color: _accent,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: _brandBlueDark,
          fontWeight: pw.FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // ─── Stats grid ───────────────────────────────────────────────────────────

  pw.Widget _buildStatsGrid(DashboardStatsModel stats) {
    return pw.GridView(
      crossAxisCount: 3,
      childAspectRatio: 2.4,
      children: [
        _statCard('Total Users', stats.totalUsers.toString()),
        _statCard('Active Users', stats.activeUsers.toString()),
        _statCard('Total Books', stats.totalBooks.toString()),
        _statCard('Total Authors', stats.totalAuthors.toString()),
        _statCard('Total Reviews', stats.totalReviews.toString()),
        _statCard('Wishlist Items', stats.totalWishlistItems.toString()),
      ],
    );
  }

  pw.Widget _statCard(String label, String value) {
    return pw.Container(
      margin: const pw.EdgeInsets.all(4),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _divider),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: _brandBlue,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 9, color: _mutedText),
          ),
        ],
      ),
    );
  }

  // ─── Commerce table ───────────────────────────────────────────────────────

  pw.Widget _buildCommerceTable(DashboardStatsModel stats) {
    return _buildSimpleTable(
      headers: const ['Metric', 'Value'],
      rows: [
        ['Total Sales (paid orders)', stats.totalSales.toString()],
        [
          'Total Revenue',
          '\$${stats.totalProfit.toStringAsFixed(2)}',
        ],
        [
          'Revenue Last 30 Days',
          '\$${stats.revenueLast30Days.toStringAsFixed(2)}',
        ],
        [
          'Average Book Price',
          '\$${stats.averageBookPrice.toStringAsFixed(2)}',
        ],
      ],
    );
  }

  // ─── Catalog table ────────────────────────────────────────────────────────

  pw.Widget _buildCatalogTable(DashboardStatsModel stats) {
    return _buildSimpleTable(
      headers: const ['Metric', 'Value'],
      rows: [
        ['Total Books', stats.totalBooks.toString()],
        ['Total Authors', stats.totalAuthors.toString()],
        [
          'Average Book Price',
          '\$${stats.averageBookPrice.toStringAsFixed(2)}',
        ],
      ],
    );
  }

  // ─── Activity table ───────────────────────────────────────────────────────

  pw.Widget _buildActivityTable(DashboardStatsModel stats) {
    return _buildSimpleTable(
      headers: const ['Entity', 'Action', 'Description', 'Time'],
      rows: stats.recentActivity
          .take(15)
          .map(
            (a) => [
              a.entityName,
              a.action,
              a.description,
              a.occurredOnUtc != null ? _formatDate(a.occurredOnUtc!) : '—',
            ],
          )
          .toList(),
    );
  }

  // ─── Book catalogue table ─────────────────────────────────────────────────

  pw.Widget _buildBookTable(
    List<AdminBookModel> books,
    Map<String, String> authorMap,
    Map<String, String> genreMap,
  ) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: _divider, width: 0.5),
      headerDecoration: const pw.BoxDecoration(color: _brandBlue),
      headerStyle: pw.TextStyle(
        color: _white,
        fontWeight: pw.FontWeight.bold,
        fontSize: 10,
      ),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignments: const {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerRight,
      },
      headers: const ['Title', 'Author', 'Genres', 'Price'],
      data: books.map((book) {
        final author = authorMap[book.authorId] ?? '—';
        final bookGenres = book.genreIds
            .map((id) => genreMap[id] ?? '—')
            .take(3)
            .join(', ');
        final price = '\$${book.amount.toStringAsFixed(2)}';
        return [book.title, author, bookGenres, price];
      }).toList(),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(1),
      },
      oddRowDecoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF9FAFB),
      ),
    );
  }

  // ─── Generic simple table ─────────────────────────────────────────────────

  pw.Widget _buildSimpleTable({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: _divider, width: 0.5),
      headerDecoration: const pw.BoxDecoration(color: _brandBlue),
      headerStyle: pw.TextStyle(
        color: _white,
        fontWeight: pw.FontWeight.bold,
        fontSize: 10,
      ),
      cellStyle: const pw.TextStyle(fontSize: 10),
      headers: headers,
      data: rows,
      oddRowDecoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF9FAFB),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final hour = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$day.$month.${d.year} $hour:$min';
  }
}
