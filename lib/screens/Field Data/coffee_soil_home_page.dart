import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'coffee_soil_input_page.dart';
import 'coffee_soil_summary_page.dart';

class CoffeeSoilHomePage extends StatelessWidget {
  const CoffeeSoilHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3C2F2F),
        title: const Text(
          'Soil Management',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFFF5E8C7),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select Coffee Farming Structure',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4A2C2A)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildCard(context, 'Single Crop', 'Manage soil data for a single coffee plot.', () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CoffeeSoilInputPage(structureType: 'single')),
            )),
            _buildCard(context, 'Intercrop', 'Manage soil data for coffee with intercrops.', () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CoffeeSoilInputPage(structureType: 'intercrop')),
            )),
            _buildCard(context, 'Multiple Plots', 'Manage soil data for multiple coffee plots.', () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CoffeeSoilInputPage(structureType: 'multiple')),
            )),
            _buildCard(context, 'Soil History', 'View saved soil data and interventions.', () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CoffeeSoilSummaryPage(userId: userId)),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, String description, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A2C2A)),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(fontSize: 14, color: Color(0xFF3A5F0B)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}