import 'package:web/web.dart' as web;

/// Strips query parameters from the browser address bar so outlet_id and table_id
/// are not visible to the customer after the page loads.
void cleanTableOrderUrl() {
  final hasHash = web.window.location.hash.isNotEmpty;
  final cleanPath = hasHash ? '/#/table-order' : '/table-order';
  web.window.history.replaceState(null, '', cleanPath);
}
