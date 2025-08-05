class NutrientAnalysisHelper {
  static const Map<String, Map<String, Map<String, double>>> optimalValues = {
    'Establishment/Seedling': {
      'pH': {'low': 5.0, 'optimal': 5.5, 'high': 6.0},
      'nitrogen': {'low': 30.0, 'optimal': 40.0, 'high': 50.0, 'per_plant_low': 20.0, 'per_plant_optimal': 26.7, 'per_plant_high': 33.3},
      'phosphorus': {'low': 8.0, 'optimal': 10.0, 'high': 12.0, 'per_plant_low': 5.3, 'per_plant_optimal': 6.7, 'per_plant_high': 8.0},
      'potassium': {'low': 25.0, 'optimal': 30.0, 'high': 35.0, 'per_plant_low': 16.7, 'per_plant_optimal': 20.0, 'per_plant_high': 23.3},
      'magnesium': {'low': 4.0, 'optimal': 5.5, 'high': 7.0, 'per_plant_low': 2.7, 'per_plant_optimal': 3.7, 'per_plant_high': 4.7},
      'calcium': {'low': 8.0, 'optimal': 10.0, 'high': 12.0, 'per_plant_low': 5.3, 'per_plant_optimal': 6.7, 'per_plant_high': 8.0},
      'zinc': {'low': 0.02, 'optimal': 0.03, 'high': 0.04, 'per_plant_low': 0.013, 'per_plant_optimal': 0.02, 'per_plant_high': 0.027},
      'boron': {'low': 0.015, 'optimal': 0.02, 'high': 0.025, 'per_plant_low': 0.01, 'per_plant_optimal': 0.013, 'per_plant_high': 0.017}
    },
    'Vegetative Growth': {
      'pH': {'low': 5.0, 'optimal': 5.5, 'high': 6.0},
      'nitrogen': {'low': 50.0, 'optimal': 60.0, 'high': 70.0, 'per_plant_low': 33.3, 'per_plant_optimal': 40.0, 'per_plant_high': 46.7},
      'phosphorus': {'low': 15.0, 'optimal': 17.5, 'high': 20.0, 'per_plant_low': 10.0, 'per_plant_optimal': 11.7, 'per_plant_high': 13.3},
      'potassium': {'low': 50.0, 'optimal': 55.0, 'high': 60.0, 'per_plant_low': 33.3, 'per_plant_optimal': 36.7, 'per_plant_high': 40.0},
      'magnesium': {'low': 10.0, 'optimal': 12.5, 'high': 15.0, 'per_plant_low': 6.7, 'per_plant_optimal': 8.3, 'per_plant_high': 10.0},
      'calcium': {'low': 15.0, 'optimal': 17.5, 'high': 20.0, 'per_plant_low': 10.0, 'per_plant_optimal': 11.7, 'per_plant_high': 13.3},
      'zinc': {'low': 0.04, 'optimal': 0.05, 'high': 0.06, 'per_plant_low': 0.027, 'per_plant_optimal': 0.033, 'per_plant_high': 0.04},
      'boron': {'low': 0.025, 'optimal': 0.03, 'high': 0.035, 'per_plant_low': 0.017, 'per_plant_optimal': 0.02, 'per_plant_high': 0.023}
    },
    'Flowering and Fruiting': {
      'pH': {'low': 5.0, 'optimal': 5.5, 'high': 6.0},
      'nitrogen': {'low': 50.0, 'optimal': 55.0, 'high': 60.0, 'per_plant_low': 33.3, 'per_plant_optimal': 36.7, 'per_plant_high': 40.0},
      'phosphorus': {'low': 20.0, 'optimal': 22.5, 'high': 25.0, 'per_plant_low': 13.3, 'per_plant_optimal': 15.0, 'per_plant_high': 16.7},
      'potassium': {'low': 60.0, 'optimal': 70.0, 'high': 80.0, 'per_plant_low': 40.0, 'per_plant_optimal': 46.7, 'per_plant_high': 53.3},
      'magnesium': {'low': 15.0, 'optimal': 17.5, 'high': 20.0, 'per_plant_low': 10.0, 'per_plant_optimal': 11.7, 'per_plant_high': 13.3},
      'calcium': {'low': 15.0, 'optimal': 17.5, 'high': 20.0, 'per_plant_low': 10.0, 'per_plant_optimal': 11.7, 'per_plant_high': 13.3},
      'zinc': {'low': 0.05, 'optimal': 0.06, 'high': 0.07, 'per_plant_low': 0.033, 'per_plant_optimal': 0.04, 'per_plant_high': 0.047},
      'boron': {'low': 0.03, 'optimal': 0.035, 'high': 0.04, 'per_plant_low': 0.02, 'per_plant_optimal': 0.023, 'per_plant_high': 0.027}
    },
    'Maturation and Harvesting': {
      'pH': {'low': 5.0, 'optimal': 5.5, 'high': 6.0},
      'nitrogen': {'low': 25.0, 'optimal': 32.5, 'high': 40.0, 'per_plant_low': 16.7, 'per_plant_optimal': 21.7, 'per_plant_high': 26.7},
      'phosphorus': {'low': 12.0, 'optimal': 15.0, 'high': 18.0, 'per_plant_low': 8.0, 'per_plant_optimal': 10.0, 'per_plant_high': 12.0},
      'potassium': {'low': 50.0, 'optimal': 55.0, 'high': 60.0, 'per_plant_low': 33.3, 'per_plant_optimal': 36.7, 'per_plant_high': 40.0},
      'magnesium': {'low': 8.0, 'optimal': 10.0, 'high': 12.0, 'per_plant_low': 5.3, 'per_plant_optimal': 6.7, 'per_plant_high': 8.0},
      'calcium': {'low': 10.0, 'optimal': 12.5, 'high': 15.0, 'per_plant_low': 6.7, 'per_plant_optimal': 8.3, 'per_plant_high': 10.0},
      'zinc': {'low': 0.03, 'optimal': 0.04, 'high': 0.05, 'per_plant_low': 0.02, 'per_plant_optimal': 0.027, 'per_plant_high': 0.033},
      'boron': {'low': 0.02, 'optimal': 0.025, 'high': 0.03, 'per_plant_low': 0.013, 'per_plant_optimal': 0.017, 'per_plant_high': 0.02}
    },
  };

  static Map<String, String> getRecommendations(String nutrient, String status, String stage) {
    final recommendations = <String, String>{};
    
    switch (nutrient.toLowerCase()) {
      case 'ph':
        if (status == 'Low') {
          recommendations['natural'] = 'Apply calcitic or dolomitic lime (1–2 tons/acre, depending on soil test).';
          recommendations['biological'] = 'Introduce acid-tolerant microbes (e.g., Azospirillum) to enhance nutrient uptake.';
          recommendations['artificial'] = 'Use calcium carbonate (500–1,000 kg/acre) to raise pH gradually.';
          recommendations['application'] = 'Apply lime 30–50 cm from plant stem, incorporate lightly into topsoil. Apply 2–3 months before planting.';
        } else if (status == 'High') {
          recommendations['natural'] = 'Apply elemental sulfur or composted organic matter (e.g., pine needles) to lower pH.';
          recommendations['biological'] = 'Use sulfur-oxidizing bacteria (e.g., Thiobacillus) to acidify soil.';
          recommendations['artificial'] = 'Apply ammonium-based fertilizers (e.g., ammonium sulfate) to lower pH.';
          recommendations['application'] = 'Apply sulfur 30–50 cm from stem, avoid direct contact with roots.';
        } else {
          recommendations['maintain'] = 'Monitor pH annually with handheld pH meter. Add organic mulch (e.g., coffee pulp) to stabilize pH.';
          recommendations['avoid'] = 'Avoid excessive lime or sulfur applications; avoid raw spent coffee grounds.';
        }
        break;

      case 'nitrogen':
        if (status == 'Low') {
          recommendations['natural'] = 'Apply composted manure (5–10 tons/acre) or green manure (e.g., legumes).';
          recommendations['biological'] = 'Inoculate with nitrogen-fixing bacteria (e.g., Rhizobium).';
          recommendations['artificial'] = 'Apply urea (100–150 kg/acre, split applications).';
          recommendations['application'] = 'Apply in ring 30–50 cm from stem or via fertigation. Split applications 2–3 times/year during vegetative growth.';
        } else if (status == 'High') {
          recommendations['natural'] = 'Increase organic matter (e.g., cover crops) to bind excess N.';
          recommendations['biological'] = 'Use denitrifying bacteria to reduce excess N.';
          recommendations['artificial'] = 'Reduce N fertilizer; apply potassium to balance ratios.';
          recommendations['application'] = 'Avoid further N application; leach with water if possible.';
        } else {
          recommendations['maintain'] = 'Split N applications (2–3 times/year); use cover crops.';
          recommendations['avoid'] = 'Avoid over-fertilization; excessive irrigation post-application.';
        }
        break;

      case 'phosphorus':
        if (status == 'Low') {
          recommendations['natural'] = 'Apply rock phosphate (200–300 kg/acre) or bone meal.';
          recommendations['biological'] = 'Use phosphate-solubilizing bacteria (e.g., Pseudomonas).';
          recommendations['artificial'] = 'Apply triple superphosphate (50–100 kg/acre).';
          recommendations['application'] = 'Apply in planting holes or as band 30 cm from stem. Incorporate into soil at planting and early vegetative stages.';
        } else if (status == 'High') {
          recommendations['natural'] = 'Add organic matter to reduce P fixation.';
          recommendations['biological'] = 'Introduce mycorrhizal fungi to regulate P uptake.';
          recommendations['artificial'] = 'Avoid P fertilizers; apply Ca to balance ratios.';
          recommendations['application'] = 'No direct reduction; avoid further P application.';
        } else {
          recommendations['maintain'] = 'Apply P in planting holes; monitor soil tests.';
          recommendations['avoid'] = 'Avoid over-application; alkaline soils that fix P.';
        }
        break;

      case 'potassium':
        if (status == 'Low') {
          recommendations['natural'] = 'Apply wood ash (500–1,000 kg/acre) or composted banana peels.';
          recommendations['biological'] = 'Use potassium-solubilizing bacteria (e.g., Bacillus).';
          recommendations['artificial'] = 'Apply potassium sulfate (100–150 kg/acre).';
          recommendations['application'] = 'Apply in ring 30–50 cm from stem or via fertigation during flowering and fruiting.';
        } else if (status == 'High') {
          recommendations['natural'] = 'Increase organic matter to buffer excess K.';
          recommendations['biological'] = 'Use microbes to enhance nutrient cycling.';
          recommendations['artificial'] = 'Reduce K fertilizers; apply Mg to balance ratios.';
          recommendations['application'] = 'Avoid further K application; ensure good drainage.';
        } else {
          recommendations['maintain'] = 'Apply K during flowering; use fertigation for precision.';
          recommendations['avoid'] = 'Avoid over-application; poor drainage.';
        }
        break;

      case 'magnesium':
        if (status == 'Low') {
          recommendations['natural'] = 'Apply dolomitic lime (500–1,000 kg/acre).';
          recommendations['biological'] = 'Use Mg-solubilizing microbes.';
          recommendations['artificial'] = 'Apply magnesium sulfate (50–100 kg/acre).';
          recommendations['application'] = 'Apply as soil drench or foliar spray (1–2% solution) 30 cm from stem during vegetative growth.';
        } else if (status == 'High') {
          recommendations['natural'] = 'Add organic matter to balance Mg:Ca ratios.';
          recommendations['biological'] = 'Introduce fungi to regulate Mg uptake.';
          recommendations['artificial'] = 'Reduce Mg fertilizers; apply Ca.';
          recommendations['application'] = 'Avoid Mg-rich fertilizers; monitor Mg:Ca ratios.';
        } else {
          recommendations['maintain'] = 'Use foliar sprays; monitor Mg:Ca ratios.';
          recommendations['avoid'] = 'Avoid excessive Mg application; high pH soils.';
        }
        break;

      case 'calcium':
        if (status == 'Low') {
          recommendations['natural'] = 'Apply gypsum (500–1,000 kg/acre).';
          recommendations['biological'] = 'Use Ca-solubilizing microbes.';
          recommendations['artificial'] = 'Apply calcium nitrate (50–100 kg/acre).';
          recommendations['application'] = 'Apply in ring 30–50 cm from stem during establishment and vegetative growth. Avoid direct root contact.';
        } else if (status == 'High') {
          recommendations['natural'] = 'Add organic matter to buffer excess Ca.';
          recommendations['biological'] = 'Use microbes to enhance nutrient cycling.';
          recommendations['artificial'] = 'Reduce Ca fertilizers; apply Mg.';
          recommendations['application'] = 'Avoid further Ca application; monitor Ca:Mg ratios.';
        } else {
          recommendations['maintain'] = 'Apply Ca in planting holes; monitor soil tests.';
          recommendations['avoid'] = 'Avoid over-liming; high pH soils.';
        }
        break;

      case 'zinc':
        if (status == 'Low') {
          recommendations['natural'] = 'Apply composted manure with Zn content.';
          recommendations['biological'] = 'Use Zn-solubilizing bacteria (e.g., Bacillus).';
          recommendations['artificial'] = 'Apply zinc sulfate (5–10 kg/acre).';
          recommendations['application'] = 'Apply as foliar spray (0.5–1% solution) or soil drench 30 cm from stem during vegetative growth.';
        } else if (status == 'High') {
          recommendations['natural'] = 'Increase organic matter to bind excess Zn.';
          recommendations['biological'] = 'Use fungi to regulate Zn uptake.';
          recommendations['artificial'] = 'Avoid Zn fertilizers; apply P to balance.';
          recommendations['application'] = 'Avoid further Zn application; monitor soil pH.';
        } else {
          recommendations['maintain'] = 'Use foliar sprays; monitor soil tests.';
          recommendations['avoid'] = 'Avoid over-application; high pH soils.';
        }
        break;

      case 'boron':
        if (status == 'Low') {
          recommendations['natural'] = 'Apply composted organic matter with B content.';
          recommendations['biological'] = 'Use B-solubilizing microbes.';
          recommendations['artificial'] = 'Apply borax (2–5 kg/acre).';
          recommendations['application'] = 'Apply as foliar spray (0.1–0.3% solution) or soil application 30 cm from stem during flowering.';
        } else if (status == 'High') {
          recommendations['natural'] = 'Increase organic matter to buffer excess B.';
          recommendations['biological'] = 'Use fungi to regulate B uptake.';
          recommendations['artificial'] = 'Avoid B fertilizers; apply Ca.';
          recommendations['application'] = 'Avoid further B application; ensure good drainage.';
        } else {
          recommendations['maintain'] = 'Use foliar sprays; monitor soil tests.';
          recommendations['avoid'] = 'Avoid over-application; sandy soils with leaching risk.';
        }
        break;
    }

    return recommendations;
  }

  static String getNutrientStatus(String nutrient, double value, String stage) {
    final ranges = optimalValues[stage]?[nutrient];
    if (ranges == null) return 'Unknown';

    final low = ranges['low'] ?? 0;
    final high = ranges['high'] ?? 0;

    if (value < low) return 'Low';
    if (value > high) return 'High';
    return 'Optimal';
  }

  static String getNutrientUnit(String nutrient, bool isPerPlant) {
    if (nutrient == 'pH') return '';
    
    if (['zinc', 'boron'].contains(nutrient)) {
      return isPerPlant ? 'mg/plant' : 'g/acre';
    } else {
      return isPerPlant ? 'g/plant' : 'kg/acre';
    }
  }

  static double convertToPerPlant(String nutrient, double value, int plantDensity) {
    if (nutrient == 'pH') return value;
    
    if (['zinc', 'boron'].contains(nutrient)) {
      // Convert g/acre to mg/plant
      return (value * 1000) / plantDensity;
    } else {
      // Convert kg/acre to g/plant
      return (value * 1000) / plantDensity;
    }
  }

  static double convertToPerAcre(String nutrient, double value, int plantDensity) {
    if (nutrient == 'pH') return value;
    
    if (['zinc', 'boron'].contains(nutrient)) {
      // Convert mg/plant to g/acre
      return (value * plantDensity) / 1000;
    } else {
      // Convert g/plant to kg/acre
      return (value * plantDensity) / 1000;
    }
  }
}