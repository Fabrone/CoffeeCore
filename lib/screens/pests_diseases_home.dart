import 'package:coffeecore/screens/Disease%20Management/coffee_disease_management.dart';
import 'package:coffeecore/screens/Pest%20Management/coffee_pest_management_page.dart';
import 'package:coffeecore/screens/Symptom%20Analysis/coffee_symptom_checker_page.dart';
import 'package:flutter/material.dart';

class PestDiseaseHomePage extends StatelessWidget {
  const PestDiseaseHomePage({super.key});

  static final Color coffeeBrown = Colors.brown[700]!; 

  @override
  Widget build(BuildContext context) {
    ScaffoldMessenger.of(context); 

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Coffee Pest & Disease Management',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: coffeeBrown,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.brown[50],
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Choose the item to manage on your coffee farm:', 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _buildOptionCard(
              context,
              'Manage Coffee Pests', 
              Icons.bug_report,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CoffeePestManagementPage()),
              ),
            ),
            const SizedBox(height: 20),
            _buildOptionCard(
              context,
              'Manage Coffee Diseases', 
              Icons.local_hospital,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CoffeeDiseaseManagementPage()),
              ),
            ),
            const SizedBox(height: 20),
            _buildOptionCard(
              context,
              'Identify Issue by Symptoms',
              Icons.search,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CoffeeSymptomCheckerPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: MediaQuery.of(context).size.width * 0.8,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: coffeeBrown), // Updated color
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}