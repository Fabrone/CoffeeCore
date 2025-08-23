import 'dart:developer' as developer;

class NutrientAnalysisHelper {
  static const Map<String, Map<String, Map<String, double>>> optimalValues = {
    'Establishment/Seedling': {
      'pH': {'low': 5.0, 'optimal': 6.0, 'high': 7.0},
      'nitrogen': {'low': 100.0, 'optimal': 150.0, 'high': 200.0},
      'phosphorus': {'low': 20.0, 'optimal': 40.0, 'high': 60.0},
      'potassium': {'low': 150.0, 'optimal': 200.0, 'high': 250.0},
      'magnesium': {'low': 50.0, 'optimal': 100.0, 'high': 150.0},
      'calcium': {'low': 1000.0, 'optimal': 1500.0, 'high': 2000.0},
      'zinc': {'low': 2.0, 'optimal': 5.0, 'high': 10.0},
      'boron': {'low': 0.5, 'optimal': 1.0, 'high': 2.0},
    },
    'Vegetative Growth': {
      'pH': {'low': 5.0, 'optimal': 6.0, 'high': 7.0},
      'nitrogen': {'low': 120.0, 'optimal': 180.0, 'high': 240.0},
      'phosphorus': {'low': 25.0, 'optimal': 50.0, 'high': 75.0},
      'potassium': {'low': 180.0, 'optimal': 240.0, 'high': 300.0},
      'magnesium': {'low': 60.0, 'optimal': 120.0, 'high': 180.0},
      'calcium': {'low': 1200.0, 'optimal': 1800.0, 'high': 2400.0},
      'zinc': {'low': 2.5, 'optimal': 6.0, 'high': 12.0},
      'boron': {'low': 0.6, 'optimal': 1.2, 'high': 2.4},
    },
    'Flowering and Fruiting': {
      'pH': {'low': 5.0, 'optimal': 6.0, 'high': 7.0},
      'nitrogen': {'low': 80.0, 'optimal': 120.0, 'high': 160.0},
      'phosphorus': {'low': 30.0, 'optimal': 60.0, 'high': 90.0},
      'potassium': {'low': 200.0, 'optimal': 300.0, 'high': 400.0},
      'magnesium': {'low': 70.0, 'optimal': 140.0, 'high': 210.0},
      'calcium': {'low': 1400.0, 'optimal': 2000.0, 'high': 2600.0},
      'zinc': {'low': 3.0, 'optimal': 7.0, 'high': 14.0},
      'boron': {'low': 0.7, 'optimal': 1.5, 'high': 3.0},
    },
    'Maturation and Harvesting': {
      'pH': {'low': 5.0, 'optimal': 6.0, 'high': 7.0},
      'nitrogen': {'low': 60.0, 'optimal': 100.0, 'high': 140.0},
      'phosphorus': {'low': 20.0, 'optimal': 40.0, 'high': 60.0},
      'potassium': {'low': 150.0, 'optimal': 200.0, 'high': 250.0},
      'magnesium': {'low': 50.0, 'optimal': 100.0, 'high': 150.0},
      'calcium': {'low': 1000.0, 'optimal': 1500.0, 'high': 2000.0},
      'zinc': {'low': 2.0, 'optimal': 5.0, 'high': 10.0},
      'boron': {'low': 0.5, 'optimal': 1.0, 'high': 2.0},
    },
  };

  static String getNutrientStatus(String nutrient, double value, String stage) {
    try {
      final ranges = optimalValues[stage]?[nutrient];
      if (ranges == null) {
        developer.log('No ranges found for $nutrient in stage $stage', name: 'NutrientAnalysisHelper');
        return 'Unknown';
      }

      if (value < ranges['low']!) {
        return 'Low';
      } else if (value > ranges['high']!) {
        return 'High';
      } else {
        return 'Optimal';
      }
    } catch (e) {
      developer.log('Error determining status for $nutrient: $e', name: 'NutrientAnalysisHelper', error: e);
      return 'Unknown';
    }
  }

  static String getNutrientUnit(String nutrient, bool isPerPlant) {
    if (nutrient == 'pH') return '';
    return isPerPlant ? 'mg/plant' : 'kg/acre';
  }

  static double convertToPerPlant(String nutrient, double value, int plantDensity) {
    if (nutrient == 'pH') return value;
    return value / plantDensity * 1000; // kg/acre to mg/plant
  }

  static double convertToPerAcre(String nutrient, double value, int plantDensity) {
    if (nutrient == 'pH') return value;
    return value * plantDensity / 1000; // mg/plant to kg/acre
  }

  static Map<String, String> getRecommendations(
      String nutrient, String status, String stage, String? soilType, bool isPerPlant, int plantDensity) {
    try {
      final recommendations = <String, String>{};

      // General recommendations for null soil type
      if (soilType == null) {
        if (nutrient == 'pH' && status == 'Low') {
          recommendations['artificial'] = isPerPlant
              ? 'Apply ${(500 / plantDensity).toStringAsFixed(2)}–${(1000 / plantDensity).toStringAsFixed(2)} g/plant of lime.'
              : 'Apply 500–1000 kg/acre of lime.';
          recommendations['natural'] = 'Add 2–3 tons/acre of organic compost annually.';
          recommendations['application'] = 'Incorporate into soil and retest after 3 months.';
        } else if (nutrient == 'pH' && status == 'High') {
          recommendations['artificial'] = isPerPlant
              ? 'Apply ${(200 / plantDensity).toStringAsFixed(2)}–${(400 / plantDensity).toStringAsFixed(2)} g/plant of sulfur.'
              : 'Apply 200–400 kg/acre of sulfur.';
          recommendations['natural'] = 'Add 2–3 tons/acre of organic compost to stabilize pH.';
          recommendations['application'] = 'Apply evenly and retest after 3 months.';
        } else if (status == 'Low') {
          recommendations['artificial'] = isPerPlant
              ? 'Apply ${(50 / plantDensity).toStringAsFixed(2)}–${(100 / plantDensity).toStringAsFixed(2)} g/plant of ${nutrient.toLowerCase()}-rich fertilizer.'
              : 'Apply 50–100 kg/acre of ${nutrient.toLowerCase()}-rich fertilizer.';
          recommendations['natural'] = 'Incorporate 2–3 tons/acre of organic compost or manure.';
          recommendations['application'] = 'Apply during early growth stages and monitor.';
        } else if (status == 'High') {
          recommendations['avoid'] = 'Reduce ${nutrient.toLowerCase()} inputs.';
          recommendations['natural'] = 'Use cover crops to absorb excess $nutrient.';
          recommendations['application'] = 'Retest after 2–3 months.';
        }
        recommendations['moisture'] = 'Maintain 500–700 mm/year of water for general coffee growth.';
        return recommendations;
      }

      // Soil type-specific recommendations
      switch (soilType) {
        case 'Volcanic':
          if (nutrient == 'pH' && status == 'Low') {
            recommendations['artificial'] = isPerPlant
                ? 'Apply ${(400 / plantDensity).toStringAsFixed(2)}–${(800 / plantDensity).toStringAsFixed(2)} g/plant of lime.'
                : 'Apply 400–800 kg/acre of lime.';
            recommendations['natural'] = 'Add 1–2 tons/acre of organic compost.';
            recommendations['application'] = 'Incorporate into soil and retest after 3 months.';
          } else if (nutrient == 'pH' && status == 'High') {
            recommendations['artificial'] = isPerPlant
                ? 'Apply ${(150 / plantDensity).toStringAsFixed(2)}–${(300 / plantDensity).toStringAsFixed(2)} g/plant of sulfur.'
                : 'Apply 150–300 kg/acre of sulfur.';
            recommendations['natural'] = 'Add 1–2 tons/acre of organic compost.';
            recommendations['application'] = 'Apply evenly and retest after 3 months.';
          } else if (status == 'Low') {
            recommendations['artificial'] = isPerPlant
                ? 'Apply ${(40 / plantDensity).toStringAsFixed(2)}–${(80 / plantDensity).toStringAsFixed(2)} g/plant of ${nutrient.toLowerCase()}-rich fertilizer.'
                : 'Apply 40–80 kg/acre of ${nutrient.toLowerCase()}-rich fertilizer.';
            recommendations['natural'] = 'Use 1–2 tons/acre of manure or compost.';
            recommendations['application'] = 'Apply during vegetative growth.';
          } else if (status == 'High') {
            recommendations['avoid'] = 'Avoid additional ${nutrient.toLowerCase()} inputs.';
            recommendations['natural'] = 'Use cover crops to balance $nutrient.';
            recommendations['application'] = 'Monitor levels after 2 months.';
          }
          recommendations['moisture'] = isPerPlant
              ? 'Apply ${(500 / plantDensity).toStringAsFixed(2)}–${(700 / plantDensity).toStringAsFixed(2)} mL/plant/year of water.'
              : 'Apply 500–700 mm/year of water.';
          break;

        case 'Red':
          if (nutrient == 'pH' && status == 'Low') {
            recommendations['artificial'] = isPerPlant
                ? 'Apply ${(600 / plantDensity).toStringAsFixed(2)}–${(1200 / plantDensity).toStringAsFixed(2)} g/plant of lime.'
                : 'Apply 600–1200 kg/acre of lime.';
            recommendations['natural'] = 'Add 5–10 tons/acre of organic compost or manure.';
            recommendations['application'] = 'Incorporate deeply and retest after 3 months.';
          } else if (nutrient == 'pH' && status == 'High') {
            recommendations['artificial'] = isPerPlant
                ? 'Apply ${(250 / plantDensity).toStringAsFixed(2)}–${(500 / plantDensity).toStringAsFixed(2)} g/plant of sulfur.'
                : 'Apply 250–500 kg/acre of sulfur.';
            recommendations['natural'] = 'Add 5–10 tons/acre of organic compost.';
            recommendations['application'] = 'Apply evenly and retest after 3 months.';
          } else if (status == 'Low') {
            recommendations['artificial'] = isPerPlant
                ? 'Apply ${(60 / plantDensity).toStringAsFixed(2)}–${(120 / plantDensity).toStringAsFixed(2)} g/plant of ${nutrient.toLowerCase()}-rich fertilizer.'
                : 'Apply 60–120 kg/acre of ${nutrient.toLowerCase()}-rich fertilizer.';
            recommendations['natural'] = 'Use 5–10 tons/acre of compost or manure to retain nutrients.';
            recommendations['application'] = 'Apply during early growth stages.';
          } else if (status == 'High') {
            recommendations['avoid'] = 'Reduce ${nutrient.toLowerCase()} inputs.';
            recommendations['natural'] = 'Use cover crops to absorb excess $nutrient.';
            recommendations['application'] = 'Retest after 2–3 months.';
          }
          recommendations['moisture'] = isPerPlant
              ? 'Apply ${(700 / plantDensity).toStringAsFixed(2)}–${(900 / plantDensity).toStringAsFixed(2)} mL/plant/year of water.'
              : 'Apply 700–900 mm/year of water.';
          break;

        case 'Alluvial':
          if (nutrient == 'pH' && status == 'Low') {
            recommendations['artificial'] = isPerPlant
                ? 'Apply ${(500 / plantDensity).toStringAsFixed(2)}–${(1000 / plantDensity).toStringAsFixed(2)} g/plant of lime.'
                : 'Apply 500–1000 kg/acre of lime.';
            recommendations['natural'] = 'Add 3–5 tons/acre of organic compost.';
            recommendations['application'] = 'Ensure good drainage before applying.';
          } else if (nutrient == 'pH' && status == 'High') {
            recommendations['artificial'] = isPerPlant
                ? 'Apply ${(200 / plantDensity).toStringAsFixed(2)}–${(400 / plantDensity).toStringAsFixed(2)} g/plant of sulfur.'
                : 'Apply 200–400 kg/acre of sulfur.';
            recommendations['natural'] = 'Add 3–5 tons/acre of organic compost.';
            recommendations['application'] = 'Apply evenly with drainage management.';
          } else if (status == 'Low') {
            recommendations['artificial'] = isPerPlant
                ? 'Apply ${(50 / plantDensity).toStringAsFixed(2)}–${(100 / plantDensity).toStringAsFixed(2)} g/plant of ${nutrient.toLowerCase()}-rich fertilizer.'
                : 'Apply 50–100 kg/acre of ${nutrient.toLowerCase()}-rich fertilizer.';
            recommendations['natural'] = 'Use 3–5 tons/acre of compost.';
            recommendations['application'] = 'Apply with drainage channels in place.';
          } else if (status == 'High') {
            recommendations['avoid'] = 'Avoid additional ${nutrient.toLowerCase()} inputs.';
            recommendations['natural'] = 'Use cover crops and ensure drainage.';
            recommendations['application'] = 'Monitor levels after 2 months.';
          }
          recommendations['moisture'] = isPerPlant
              ? 'Apply ${(600 / plantDensity).toStringAsFixed(2)}–${(800 / plantDensity).toStringAsFixed(2)} mL/plant/year of water.'
              : 'Apply 600–800 mm/year of water with proper drainage.';
          break;

        case 'Forest':
          if (nutrient == 'pH' && status == 'Low') {
            recommendations['artificial'] = isPerPlant
                ? 'Apply ${(300 / plantDensity).toStringAsFixed(2)}–${(600 / plantDensity).toStringAsFixed(2)} g/plant of lime.'
                : 'Apply 300–600 kg/acre of lime.';
            recommendations['natural'] = 'Add 1–2 tons/acre of organic compost and maintain shade trees.';
            recommendations['application'] = 'Incorporate lightly and retest after 3 months.';
          } else if (nutrient == 'pH' && status == 'High') {
            recommendations['artificial'] = isPerPlant
                ? 'Apply ${(100 / plantDensity).toStringAsFixed(2)}–${(200 / plantDensity).toStringAsFixed(2)} g/plant of sulfur.'
                : 'Apply 100–200 kg/acre of sulfur.';
            recommendations['natural'] = 'Add 1–2 tons/acre of organic compost under shade trees.';
            recommendations['application'] = 'Apply evenly and retest after 3 months.';
          } else if (status == 'Low') {
            recommendations['artificial'] = isPerPlant
                ? 'Apply ${(30 / plantDensity).toStringAsFixed(2)}–${(60 / plantDensity).toStringAsFixed(2)} g/plant of ${nutrient.toLowerCase()}-rich fertilizer.'
                : 'Apply 30–60 kg/acre of ${nutrient.toLowerCase()}-rich fertilizer.';
            recommendations['natural'] = 'Use 1–2 tons/acre of compost under shade trees.';
            recommendations['application'] = 'Apply during vegetative growth.';
          } else if (status == 'High') {
            recommendations['avoid'] = 'Avoid additional ${nutrient.toLowerCase()} inputs.';
            recommendations['natural'] = 'Use cover crops under shade trees.';
            recommendations['application'] = 'Monitor levels after 2 months.';
          }
          recommendations['moisture'] = isPerPlant
              ? 'Apply ${(400 / plantDensity).toStringAsFixed(2)}–${(600 / plantDensity).toStringAsFixed(2)} mL/plant/year of water.'
              : 'Apply 400–600 mm/year of water under shade trees.';
          break;

        case 'Laterite':
          if (nutrient == 'pH' && status == 'Low') {
            recommendations['artificial'] = isPerPlant
                ? 'Apply ${(700 / plantDensity).toStringAsFixed(2)}–${(1400 / plantDensity).toStringAsFixed(2)} g/plant of lime.'
                : 'Apply 700–1400 kg/acre of lime.';
            recommendations['natural'] = 'Add 5–10 tons/acre of manure or mulch with shade trees.';
            recommendations['application'] = 'Incorporate deeply and retest after 3 months.';
          } else if (nutrient == 'pH' && status == 'High') {
            recommendations['artificial'] = isPerPlant
                ? 'Apply ${(300 / plantDensity).toStringAsFixed(2)}–${(600 / plantDensity).toStringAsFixed(2)} g/plant of sulfur.'
                : 'Apply 300–600 kg/acre of sulfur.';
            recommendations['natural'] = 'Add 5–10 tons/acre of manure or mulch.';
            recommendations['application'] = 'Apply evenly and retest after 3 months.';
          } else if (status == 'Low') {
            recommendations['artificial'] = isPerPlant
                ? 'Apply ${(70 / plantDensity).toStringAsFixed(2)}–${(140 / plantDensity).toStringAsFixed(2)} g/plant of ${nutrient.toLowerCase()}-rich fertilizer.'
                : 'Apply 70–140 kg/acre of ${nutrient.toLowerCase()}-rich fertilizer.';
            recommendations['natural'] = 'Use 5–10 tons/acre of manure or mulch with shade trees.';
            recommendations['application'] = 'Apply during early growth stages.';
          } else if (status == 'High') {
            recommendations['avoid'] = 'Reduce ${nutrient.toLowerCase()} inputs.';
            recommendations['natural'] = 'Use cover crops and mulch to balance $nutrient.';
            recommendations['application'] = 'Retest after 2–3 months.';
          }
          recommendations['moisture'] = isPerPlant
              ? 'Apply ${(800 / plantDensity).toStringAsFixed(2)}–${(1000 / plantDensity).toStringAsFixed(2)} mL/plant/year of water.'
              : 'Apply 800–1000 mm/year of water.';
          break;
      }

      return recommendations;
    } catch (e) {
      developer.log('Error generating recommendations for $nutrient: $e',
          name: 'NutrientAnalysisHelper', error: e);
      return {};
    }
  }
}