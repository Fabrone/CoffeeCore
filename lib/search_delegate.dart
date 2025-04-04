import 'package:coffeecore/screens/Farm%20Management/coffee_management_screen.dart';
import 'package:coffeecore/screens/Field%20Data/coffee_soil_home_page.dart';
import 'package:coffeecore/screens/learn_coffee_farming.dart';
import 'package:coffeecore/screens/manuals_screen.dart';
import 'package:coffeecore/screens/pests_diseases_home.dart';
import 'package:coffeecore/screens/user_profile.dart';
import 'package:coffeecore/screens/weather_screen.dart';
import 'package:coffeecore/screens/market_prices.dart';
import 'package:coffeecore/settings/notifications_settings_screen.dart';
import 'package:coffeecore/settings/settings_screen.dart';
import 'package:flutter/material.dart';

// Define a class for searchable items
class SearchItem {
  final String name;
  final IconData? icon;
  final VoidCallback onTap;

  SearchItem({required this.name, this.icon, required this.onTap});
}

// Custom Search Delegate
class CoffeeCoreSearchDelegate extends SearchDelegate {
  final List<SearchItem> searchableItems;

  CoffeeCoreSearchDelegate(this.searchableItems);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context, query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context, query);
  }

  Widget _buildSearchResults(BuildContext context, String query) {
    if (query.isEmpty) {
      return const Center(child: Text('Start typing to search...'));
    }

    // Filter items based on query
    List<SearchItem> exactMatches = searchableItems
        .where((item) => item.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    // Find close matches for "Did you mean..."
    List<SearchItem> closeMatches = searchableItems
        .where((item) => !_isExactMatch(item.name, query) && _isCloseMatch(item.name, query))
        .toList();

    if (exactMatches.isEmpty && closeMatches.isEmpty) {
      return const Center(child: Text('No results found'));
    }

    return ListView(
      children: [
        // "Did you mean..." section
        if (exactMatches.isEmpty && closeMatches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Did you mean...?',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600]),
            ),
          ),
          ...closeMatches.map((item) => _buildSearchItemTile(context, item)),
          const Divider(),
        ],
        // Exact matches
        ...exactMatches.map((item) => _buildSearchItemTile(context, item)),
      ],
    );
  }

  Widget _buildSearchItemTile(BuildContext context, SearchItem item) {
    return ListTile(
      leading: item.icon != null ? Icon(item.icon, color: Colors.brown[700]) : null,
      title: Text(item.name),
      onTap: () {
        item.onTap();
        close(context, null); // Close search after navigation
      },
    );
  }

  bool _isExactMatch(String name, String query) {
    return name.toLowerCase().contains(query.toLowerCase());
  }

  bool _isCloseMatch(String name, String query) {
    String nameLower = name.toLowerCase();
    String queryLower = query.toLowerCase();
    return nameLower.startsWith(queryLower.substring(0, queryLower.length > 2 ? 2 : queryLower.length)) ||
        nameLower.contains(queryLower.substring(0, queryLower.length > 3 ? 3 : queryLower.length));
  }
}

// Define the searchable items (could also be passed from HomePage)
List<SearchItem> getSearchableItems(BuildContext context) {
  return [
    SearchItem(
      name: 'Weather',
      icon: Icons.cloud,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeatherScreen())),
    ),
    SearchItem(
      name: 'Field Data (Soil)',
      icon: Icons.input,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CoffeeSoilHomePage())),
    ),
    SearchItem(name: 'Single Crop', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CoffeeSoilHomePage()))),
    SearchItem(name: 'Multiple Plots', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CoffeeSoilHomePage()))),
    SearchItem(name: 'Soil History', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CoffeeSoilHomePage()))),
    SearchItem(
      name: 'Pests & Diseases',
      icon: Icons.pest_control,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PestDiseaseHomePage())),
    ),
    SearchItem(name: 'Manage Coffee Pests', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PestDiseaseHomePage()))),
    SearchItem(name: 'Manage Coffee Diseases', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PestDiseaseHomePage()))),
    SearchItem(name: 'Identify Issues by Symptoms', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PestDiseaseHomePage()))),
    SearchItem(
      name: 'Farm Management',
      icon: Icons.supervisor_account,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CoffeeManagementScreen())),
    ),
    SearchItem(name: 'Costs', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CoffeeManagementScreen()))),
    SearchItem(name: 'Revenue', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CoffeeManagementScreen()))),
    SearchItem(name: 'Profits/Loss', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CoffeeManagementScreen()))),
    SearchItem(name: 'Loans', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CoffeeManagementScreen()))),
    SearchItem(
      name: 'Manuals',
      icon: Icons.book,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManualsScreen())),
    ),
    SearchItem(
      name: 'Settings',
      icon: Icons.settings,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen())),
    ),
    SearchItem(name: 'User Profile', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen()))),
    SearchItem(name: 'Contact Us', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen()))),
    SearchItem(name: 'FAQ/Knowledge base', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen()))),
    SearchItem(name: 'Terms and Conditions', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen()))),
    SearchItem(name: 'Privacy Policy', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen()))),
    SearchItem(name: 'About CoffeeCore', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen()))),
    SearchItem(name: 'Account', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen()))),
    SearchItem(
      name: 'Notifications',
      icon: Icons.notifications,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsSettingsScreen())),
    ),
    SearchItem(
      name: 'Tips',
      icon: Icons.lightbulb,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LearnCoffeeFarming())),
    ),
    SearchItem(name: 'Planning Your Coffee Farm', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LearnCoffeeFarming()))),
    SearchItem(name: 'Preparation & Tools', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LearnCoffeeFarming()))),
    SearchItem(name: 'Coffee Varieties and Growth Periods', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LearnCoffeeFarming()))),
    SearchItem(name: 'How to Cultivate Coffee', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LearnCoffeeFarming()))),
    SearchItem(name: 'Common Coffee Pests', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LearnCoffeeFarming()))),
    SearchItem(name: 'Common Coffee Diseases', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LearnCoffeeFarming()))),
    SearchItem(name: 'Common Cultivation Challenges', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LearnCoffeeFarming()))),
    SearchItem(name: 'How to Manage Pests', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LearnCoffeeFarming()))),
    SearchItem(
      name: 'Market Prices',
      icon: Icons.shopping_cart,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MarketPricesWidget())),
    ),
  ];
}