import 'package:flutter/material.dart';
//import 'package:coffeecore/screens/pest_management/pest_management.dart'; // Updated import
//import 'package:coffeecore/screens/disease_management_page.dart'; // Updated import
//import 'package:coffeecore/screens/symptom_checker_page.dart'; // Updated import

class PestDiseaseHomePage extends StatelessWidget {
  const PestDiseaseHomePage({super.key});

  static final Color coffeeBrown = Colors.brown[700]!; // CoffeeCore theme color

  @override
  Widget build(BuildContext context) {
    ScaffoldMessenger.of(context); // Kept as is (though unused, likely a placeholder)

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Coffee Pest & Disease Management', // Updated title
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: coffeeBrown,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.brown[50], // Light coffee shade instead of grey
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Choose an option to manage your coffee farm:', // Updated text
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _buildOptionCard(
              context,
              'Manage Coffee Pests', // Updated title
              Icons.bug_report,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PestDiseaseHomePage()),
              ),
            ),
            const SizedBox(height: 20),
            _buildOptionCard(
              context,
              'Manage Coffee Diseases', // Updated title
              Icons.local_hospital,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PestDiseaseHomePage()),
              ),
            ),
            const SizedBox(height: 20),
            _buildOptionCard(
              context,
              'Identify Issue by Symptoms', // Kept as is, still relevant
              Icons.search,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PestDiseaseHomePage()),
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