import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LearnCoffeeFarming extends StatefulWidget {
  const LearnCoffeeFarming({super.key});

  @override
  LearnCoffeeFarmingState createState() => LearnCoffeeFarmingState();
}

class LearnCoffeeFarmingState extends State<LearnCoffeeFarming> {
  String? _selectedSection; 

  final Map<String, Map<String, dynamic>> _coffeeFarmingGuide = {
    'Planning Your Coffee Farm': {
      'icon': Icons.map,
      'content': '''
🌱 **Planning Your Coffee Farm**  
Successful coffee farming begins with careful planning. Here’s how to get started:

📍 **Choosing the Location**  
- **Altitude**: Arabica thrives at 1,200–2,200m, Robusta at 0–800m above sea level.  
- **Climate**: Ideal temperatures are 18–24°C for Arabica, 24–30°C for Robusta, with 1,200–2,000mm annual rainfall.  
- **Shade**: Use shade trees (e.g., banana, avocado) to protect young plants from intense sun.  

🌍 **Land Assessment**  
- Assess soil type (loamy, volcanic soils are best), drainage, and slope (gentle slopes prevent erosion).  
- Test soil pH: 5.2–6.2 for Arabica, 4.5–6.5 for Robusta.  

📅 **Timing**  
- Plan planting at the start of the rainy season (e.g., March-May or October-November in equatorial regions).  
- Allow 6–12 months for land preparation before planting.  

💡 **Key Tips**  
- Consult local agricultural officers for region-specific advice.  
- Plan irrigation if rainfall is unreliable.  
      ''',
    },
    'Preparation & Tools': {
      'icon': Icons.agriculture,
      'content': '''
🌱 **Preparation & Tools**  
Proper preparation ensures a healthy coffee crop. Here’s what you need:

🌍 **Land Preparation**  
- Clear weeds, rocks, and debris.  
- Dig trenches or terraces on slopes for drainage and erosion control.  
- Add organic matter (compost, manure) to enrich soil.  

🛠 **Tools Required**  
- **Hoe/Shovel**: For digging planting holes (30cm deep, 30cm wide).  
- **Pruning Shears**: For trimming plants and shade trees.  
- **Wheelbarrow**: For transporting manure or compost.  
- **Watering Can/Sprinkler**: For irrigation during dry spells.  
- **pH Test Kit**: To monitor soil acidity.  

📏 **Planting Setup**  
- Space plants 2–3m apart (depending on variety) to allow root growth and airflow.  
- Mark rows with stakes and string for uniformity.  

💡 **Key Tips**  
- Sterilize tools to prevent disease spread.  
- Prepare nursery beds for seedlings if starting from seeds.  
      ''',
    },
    'Coffee Varieties & Growth Periods': {
      'icon': Icons.local_florist,
      'content': '''
🌱 **Coffee Varieties & Growth Periods**  
Coffee comes in two main varieties with distinct growth timelines:

☕ **Arabica (Coffea arabica)**  
- **Flavor**: Mild, aromatic, acidic.  
- **Growth Conditions**: High altitudes, cooler climates, shaded areas.  
- **Growth Period**:  
  - Seedling to first harvest: 3–5 years.  
  - Flowering: 6–8 weeks after rain.  
  - Cherry ripening: 6–8 months after flowering.  
- **Yield**: Lower but higher quality.  

☕ **Robusta (Coffea canephora)**  
- **Flavor**: Strong, bitter, earthy.  
- **Growth Conditions**: Lower altitudes, warmer climates, full sun.  
- **Growth Period**:  
  - Seedling to first harvest: 2–3 years.  
  - Flowering: Similar to Arabica.  
  - Cherry ripening: 9–11 months after flowering.  
- **Yield**: Higher, more pest-resistant.  

💡 **Key Tips**  
- Choose variety based on your region and market demand.  
- Hybrid varieties (e.g., SL28, Ruiru 11) may offer disease resistance.  
      ''',
    },
    'How to Cultivate Coffee': {
      'icon': Icons.spa,
      'content': '''
🌱 **How to Cultivate Coffee**  
Step-by-step guide to growing coffee:

1️⃣ **Seed Selection**  
- Use certified seeds or healthy cuttings from vigorous plants.  
- Soak seeds in water for 24 hours to speed germination.  

2️⃣ **Nursery Stage**  
- Plant seeds in shaded nursery beds with sandy loam soil.  
- Transplant seedlings (15–20cm tall) after 6–12 months.  

3️⃣ **Planting**  
- Dig holes 30cm deep, mix soil with manure, and plant seedlings.  
- Water immediately and mulch around the base.  

4️⃣ **Care**  
- Water weekly (20–30mm) during dry seasons.  
- Apply nitrogen-rich fertilizer annually after the first year.  
- Prune yearly to remove dead branches and improve airflow.  

5️⃣ **Harvesting**  
- Pick only ripe red cherries by hand (selective harvesting).  
- Process (wet or dry method) within 24 hours of picking.  

💡 **Key Tips**  
- Mulch with coffee husks or grass to retain moisture.  
- Train workers for efficient harvesting.  
      ''',
    },
    'Common Coffee Pests': {
      'icon': Icons.bug_report,
      'content': '''
🌱 **Common Coffee Pests**  
Pests can devastate coffee crops. Here are the main ones:

🐜 **Coffee Berry Borer**  
- **Damage**: Tunnels into cherries, reducing yield and quality.  
- **Control**: Use traps, remove fallen berries, apply neem oil.  

🐞 **Antestia Bug**  
- **Damage**: Feeds on cherries, causing rot and off-flavors.  
- **Control**: Introduce natural predators (e.g., wasps), use organic sprays.  

🦗 **Leaf Miner**  
- **Damage**: Burrows into leaves, reducing photosynthesis.  
- **Control**: Remove affected leaves, use sticky traps.  

🐛 **White Stem Borer**  
- **Damage**: Attacks stems, killing young plants.  
- **Control**: Paint stems with lime, burn infested plants.  

💡 **Key Tips**  
- Monitor fields weekly during peak seasons.  
- Use integrated pest management (IPM) for sustainable control.  
      ''',
    },
    'Common Coffee Diseases': {
      'icon': Icons.local_hospital,
      'content': '''
🌱 **Common Coffee Diseases**  
Diseases threaten coffee health. Here’s how to manage them:

🍂 **Coffee Leaf Rust**  
- **Symptoms**: Orange spots on leaves, leaf drop.  
- **Control**: Use resistant varieties, apply copper fungicides.  

🦠 **Coffee Berry Disease**  
- **Symptoms**: Black, sunken spots on cherries.  
- **Control**: Remove infected cherries, improve airflow with pruning.  

🌿 **Wilt Disease (Fusarium)**  
- **Symptoms**: Wilting branches, root rot.  
- **Control**: Avoid waterlogging, use healthy planting material.  

🍃 **Root Rot**  
- **Symptoms**: Yellowing leaves, plant collapse.  
- **Control**: Improve drainage, apply organic compost.  

💡 **Key Tips**  
- Burn or bury infected plant parts.  
- Rotate crops if disease persists.  
      ''',
    },
    'Common Cultivation Challenges': {
      'icon': Icons.warning,
      'content': '''
🌱 **Common Cultivation Challenges**  
Coffee farming has its hurdles. Here’s how to address them:

🌧 **Unpredictable Weather**  
- **Issue**: Droughts or excessive rain affect yields.  
- **Solution**: Install irrigation, plant shade trees.  

💰 **High Input Costs**  
- **Issue**: Fertilizers, labor, and tools add up.  
- **Solution**: Use organic alternatives, join cooperatives.  

🐛 **Pest & Disease Outbreaks**  
- **Issue**: Rapid spread in humid conditions.  
- **Solution**: Regular scouting, early intervention.  

📉 **Market Fluctuations**  
- **Issue**: Price drops hurt profits.  
- **Solution**: Diversify income (e.g., intercrop with beans).  

💡 **Key Tips**  
- Build resilience with sustainable practices.  
- Seek government or NGO support during crises.  
      ''',
    },
    'How to Manage Pests': {
      'icon': Icons.shield,
      'content': '''
🌱 **How to Manage Pests**  
Effective pest control keeps your coffee thriving:

1️⃣ **Monitoring**  
- Check plants weekly for signs (holes, discoloration).  
- Use yellow sticky traps to track pest populations.  

2️⃣ **Natural Methods**  
- Plant marigolds or garlic to repel pests.  
- Encourage birds and beneficial insects (e.g., ladybugs).  

3️⃣ **Organic Sprays**  
- Mix neem oil or soap with water and spray affected areas.  
- Apply early morning for best results.  

4️⃣ **Cultural Practices**  
- Remove fallen cherries and debris to reduce breeding sites.  
- Prune dense foliage for better air circulation.  

5️⃣ **Chemical Control**  
- Use pesticides as a last resort, following local guidelines.  

💡 **Key Tips**  
- Combine methods for integrated pest management (IPM).  
- Train workers to spot early pest signs.  
      ''',
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E8C7), // Light beige background
      appBar: AppBar(
        backgroundColor: const Color(0xFF3E2723), // Dark brown
        title: Text(
          "Learn Coffee Farming",
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 20),
          
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Default Minor Information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Text(
                  '''
☕ **Coffee Growing Basics**  
Coffee thrives in tropical and subtropical regions with distinct wet and dry seasons. Arabica prefers cooler highlands (1,200–2,200m), while Robusta grows in warmer lowlands (0–800m). Growth from seedling to first harvest takes 2–5 years, depending on the variety. Rich, well-draining soils and moderate rainfall (1,200–2,000mm) are key to success.
                  ''',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: const Color(0xFF424242),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Expandable Cards
              ..._coffeeFarmingGuide.entries.map((entry) {
                final isExpanded = _selectedSection == entry.key;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSection = isExpanded ? null : entry.key;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF3E2723), width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            entry.value['icon'],
                            color: const Color(0xFF3E2723),
                            size: 30,
                          ),
                          title: Text(
                            entry.key,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF3E2723),
                            ),
                          ),
                          trailing: Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: const Color(0xFF3E2723),
                          ),
                        ),
                        if (isExpanded)
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              entry.value['content'],
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                height: 1.5,
                                color: const Color(0xFF424242),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// Navigation function to integrate with home page
void navigateToLearnCoffeeFarming(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const LearnCoffeeFarming()),
  );
}