import 'package:flutter/material.dart';

import '../../../../core/localization/admin_language_controller.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/analytics_activity_model.dart';

class RecentActivityList extends StatelessWidget {
  const RecentActivityList({
    super.key,
    required this.items,
    required this.language,
  });

  final List<AnalyticsActivityModel> items;
  final AdminLanguage language;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        language.isEnglish ? 'No recent activity.' : 'Nema nedavne aktivnosti.',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.take(6).map((activity) {
        final headline = _buildHeadline(activity);
        final details = _buildDetails(activity);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    details,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  formatAdminDateTime(
                    activity.occurredOnUtc,
                    language: language,
                  ),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _buildHeadline(AnalyticsActivityModel activity) {
    final adminEmail = _extractAdminEmail(activity.description);
    final entity = activity.entityName.trim().toLowerCase();
    final action = activity.action.trim().toLowerCase();

    return switch ('$entity:$action') {
      'book:created' => _adminMessage(
          adminEmail,
          language.isEnglish ? 'added a book' : 'je dodao knjigu',
          language.isEnglish ? 'A book was added' : 'Dodana je knjiga',
        ),
      'book:updated' => _adminMessage(
          adminEmail,
          language.isEnglish ? 'updated a book' : 'je azurirao knjigu',
          language.isEnglish ? 'A book was updated' : 'Azurirana je knjiga',
        ),
      'book:deleted' => _adminMessage(
          adminEmail,
          language.isEnglish ? 'deleted a book' : 'je obrisao knjigu',
          language.isEnglish ? 'A book was deleted' : 'Obrisana je knjiga',
        ),
      'author:created' => _adminMessage(
          adminEmail,
          language.isEnglish ? 'added an author' : 'je dodao autora',
          language.isEnglish ? 'An author was added' : 'Dodan je autor',
        ),
      'author:updated' => _adminMessage(
          adminEmail,
          language.isEnglish ? 'updated an author' : 'je azurirao autora',
          language.isEnglish ? 'An author was updated' : 'Azuriran je autor',
        ),
      'author:deleted' => _adminMessage(
          adminEmail,
          language.isEnglish ? 'deleted an author' : 'je obrisao autora',
          language.isEnglish ? 'An author was deleted' : 'Obrisan je autor',
        ),
      'genre:created' => _adminMessage(
          adminEmail,
          language.isEnglish ? 'added a genre' : 'je dodao zanr',
          language.isEnglish ? 'A genre was added' : 'Dodan je zanr',
        ),
      'genre:updated' => _adminMessage(
          adminEmail,
          language.isEnglish ? 'updated a genre' : 'je azurirao zanr',
          language.isEnglish ? 'A genre was updated' : 'Azuriran je zanr',
        ),
      'genre:deleted' => _adminMessage(
          adminEmail,
          language.isEnglish ? 'deleted a genre' : 'je obrisao zanr',
          language.isEnglish ? 'A genre was deleted' : 'Obrisan je zanr',
        ),
      'order:created' => language.isEnglish
          ? 'A new order was created'
          : 'Kreirana je nova narudzba',
      'order:statuschanged' => language.isEnglish
          ? 'An order status was changed'
          : 'Promijenjen je status narudzbe',
      'review:created' =>
          language.isEnglish ? 'A new review was added' : 'Dodana je nova recenzija',
      'review:updated' =>
          language.isEnglish ? 'A review was updated' : 'Azurirana je recenzija',
      'review:deleted' =>
          language.isEnglish ? 'A review was deleted' : 'Obrisana je recenzija',
      'wishlist:created' =>
          language.isEnglish ? 'A wishlist was created' : 'Kreirana je wishlist lista',
      'wishlist:itemadded' => language.isEnglish
          ? 'An item was added to the wishlist'
          : 'Dodana je stavka u wishlist',
      'wishlist:itemremoved' => language.isEnglish
          ? 'An item was removed from the wishlist'
          : 'Uklonjena je stavka iz wishlist-e',
      'user:loggedin' =>
          language.isEnglish ? 'A user logged in' : 'Korisnik se prijavio',
      'user:deactivated' => language.isEnglish
          ? 'A user was deactivated'
          : 'Korisnik je deaktiviran',
      'cart:updated' =>
          language.isEnglish ? 'A cart was updated' : 'Korpa je azurirana',
      'cart:deleted' =>
          language.isEnglish ? 'A cart was deleted' : 'Korpa je obrisana',
      'library:granted' => language.isEnglish
          ? 'A book was added to the library'
          : 'Knjiga je dodana u biblioteku',
      _ => _buildFallbackHeadline(activity, adminEmail),
    };
  }

  String _buildFallbackHeadline(
    AnalyticsActivityModel activity,
    String? adminEmail,
  ) {
    final cleanedEntity = activity.entityName.trim();
    final cleanedAction = activity.action.trim().toLowerCase();
    if (cleanedEntity.isEmpty && cleanedAction.isEmpty) {
      return language.isEnglish ? 'New activity' : 'Nova aktivnost';
    }

    if (adminEmail != null && adminEmail.isNotEmpty) {
      return language.isEnglish
          ? 'Admin: $adminEmail made a change'
          : 'Admin: $adminEmail je napravio izmjenu';
    }

    return [cleanedEntity, cleanedAction]
        .where((part) => part.isNotEmpty)
        .join(' - ');
  }

  String _adminMessage(
    String? adminEmail,
    String adminText,
    String fallbackText,
  ) {
    if (adminEmail == null || adminEmail.isEmpty) {
      return fallbackText;
    }

    return 'Admin: $adminEmail $adminText';
  }

  String _buildDetails(AnalyticsActivityModel activity) {
    final sanitized = _sanitizeDescription(activity.description);
    final headline = _buildHeadline(activity).trim().toLowerCase();
    final normalized = sanitized.trim();

    if (normalized.isEmpty || normalized.toLowerCase() == headline) {
      return '';
    }

    return _localizeDescription(normalized);
  }

  String? _extractAdminEmail(String description) {
    final match = RegExp(
      r'(?:Edited By Admin|Admin):\s*([^\s.]+@[^\s.]+\.[^\s.]+)',
      caseSensitive: false,
    ).firstMatch(description);
    return match?.group(1);
  }

  String _sanitizeDescription(String description) {
    var value = description.trim();

    value = value.replaceAll(
      RegExp(
        r'\s*(?:Edited By Admin|Admin):\s*([^\s.]+@[^\s.]+\.[^\s.]+)\.?',
        caseSensitive: false,
      ),
      '',
    );

    value = value.replaceAll(
      RegExp(
        r'\s*[A-Za-z]+(?:\s+[A-Za-z]+)*\s+ID:\s*[^.]+\.?',
        caseSensitive: false,
      ),
      '',
    );

    value = value.replaceAll(
      RegExp(r'\s*ID:\s*[^.]+\.?', caseSensitive: false),
      '',
    );

    value = value.replaceAll(
      RegExp(r'Narudzba\s+[A-Za-z0-9-]{6,}\s+za', caseSensitive: false),
      'Narudzba za',
    );

    value = value.replaceAll(RegExp(r'\s{2,}'), ' ');
    value = value.replaceAll(RegExp(r'\.\s*\.'), '.');
    value = value.replaceAll(RegExp(r'\s+\.'), '.');

    return value.trim();
  }

  String _localizeDescription(String value) {
    return language.isEnglish
        ? _toEnglish(value)
        : _toBosnian(value);
  }

  String _toEnglish(String value) {
    return value
        .replaceAll('Autor "', 'Author "')
        .replaceAll('Knjiga "', 'Book "')
        .replaceAll('Zanr "', 'Genre "')
        .replaceAll('Cijena:', 'Price:')
        .replaceAll('Iznos:', 'Amount:')
        .replaceAll('Stavki:', 'Items:')
        .replaceAll('Ukupno:', 'Total:')
        .replaceAll('Nova ocjena:', 'New rating:')
        .replaceAll('Ocjena:', 'Rating:')
        .replaceAll('Korisnik ', 'User ')
        .replaceAll('Korpa je azurirana.', 'The cart was updated.')
        .replaceAll('Korpa je obrisana.', 'The cart was deleted.')
        .replaceAll('Wishlist je kreirana.', 'The wishlist was created.')
        .replaceAll(
          'Knjiga je dodana u wishlist.',
          'A book was added to the wishlist.',
        )
        .replaceAll(
          'Knjiga je uklonjena iz wishlist-e.',
          'A book was removed from the wishlist.',
        )
        .replaceAll(
          'Kupovina je prebacena u biblioteku za ',
          'The purchase was moved to the library for ',
        )
        .replaceAll('Recenzija je azurirana.', 'The review was updated.')
        .replaceAll('Recenzija je obrisana.', 'The review was deleted.')
        .replaceAll('Nova recenzija je dodana.', 'A new review was added.')
        .replaceAll('Narudzba je kreirana za ', 'The order was created for ')
        .replaceAll('Narudzba za ', 'The order for ')
        .replaceAll(' je presla u status ', ' changed to status ')
        .replaceAll(' se prijavio.', ' logged in.')
        .replaceAll(' je deaktiviran.', ' was deactivated.')
        .replaceAll(' je dodan u katalog.', ' was added to the catalog.')
        .replaceAll(' je dodana.', ' was added.')
        .replaceAll(' je azuriran.', ' was updated.')
        .replaceAll(' je azurirana.', ' was updated.')
        .replaceAll(' je obrisan.', ' was deleted.')
        .replaceAll(' je obrisana.', ' was deleted.')
        .replaceAll(' je obrisana iz kataloga.', ' was deleted from the catalog.')
        .replaceAll(' je kreiran.', ' was created.');
  }

  String _toBosnian(String value) {
    return value
        .replaceAll('Author "', 'Autor "')
        .replaceAll('Book "', 'Knjiga "')
        .replaceAll('Genre "', 'Zanr "')
        .replaceAll('Price:', 'Cijena:')
        .replaceAll('Amount:', 'Iznos:')
        .replaceAll('Items:', 'Stavki:')
        .replaceAll('Total:', 'Ukupno:')
        .replaceAll('New rating:', 'Nova ocjena:')
        .replaceAll('Rating:', 'Ocjena:')
        .replaceAll('User ', 'Korisnik ')
        .replaceAll('The cart was updated.', 'Korpa je azurirana.')
        .replaceAll('The cart was deleted.', 'Korpa je obrisana.')
        .replaceAll('The wishlist was created.', 'Wishlist je kreirana.')
        .replaceAll(
          'A book was added to the wishlist.',
          'Knjiga je dodana u wishlist.',
        )
        .replaceAll(
          'A book was removed from the wishlist.',
          'Knjiga je uklonjena iz wishlist-e.',
        )
        .replaceAll(
          'The purchase was moved to the library for ',
          'Kupovina je prebacena u biblioteku za ',
        )
        .replaceAll('The review was updated.', 'Recenzija je azurirana.')
        .replaceAll('The review was deleted.', 'Recenzija je obrisana.')
        .replaceAll('A new review was added.', 'Nova recenzija je dodana.')
        .replaceAll('The order was created for ', 'Narudzba je kreirana za ')
        .replaceAll('The order for ', 'Narudzba za ')
        .replaceAll(' changed to status ', ' je presla u status ')
        .replaceAll(' logged in.', ' se prijavio.')
        .replaceAll(' was deactivated.', ' je deaktiviran.')
        .replaceAll(' was added to the catalog.', ' je dodan u katalog.')
        .replaceAll(' was added.', ' je dodana.')
        .replaceAll(' was updated.', ' je azurirana.')
        .replaceAll(' was deleted from the catalog.', ' je obrisana iz kataloga.')
        .replaceAll(' was deleted.', ' je obrisana.')
        .replaceAll(' was created.', ' je kreiran.');
  }
}
