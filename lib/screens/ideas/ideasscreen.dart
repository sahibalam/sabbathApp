import 'package:flutter/material.dart';

class IdeaScreen extends StatefulWidget {
  const IdeaScreen({super.key});

  @override
  State<IdeaScreen> createState() => _IdeaScreenState();
}

class _IdeaScreenState extends State<IdeaScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) {
          if (MediaQuery.of(context).orientation == Orientation.portrait) {
            return contentWidget(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
            );
          } else {
            return contentWidget(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
            );
          }
        },
      ),
    );
  }

  Widget contentWidget({required EdgeInsets padding}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF4732F),
            Color(0xFFFBB13A),
            Color(0xFFFBB13A),
            Color(0xFFF4732F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: padding,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionTitle('🕊️ Spiritual Enrichment'),
                bulletPoint('Attend Sabbath School and Church Services'),
                bulletPoint('Study the Bible or Sabbath School Quarterly'),
                bulletPoint('Have a Family Worship or Devotional'),
                bulletPoint(
                  "Read Ellen G. White's books (e.g., *Steps to Christ*, *The Desire of Ages*)",
                ),
                bulletPoint('Memorize and meditate on scripture'),
                bulletPoint('Listen to sacred music or hymns'),
                bulletPoint('Watch a sermon or uplifting spiritual video'),
                bulletPoint('Write in a prayer or spiritual journal'),
                const SizedBox(height: 24),

                sectionTitle('🌿 Nature and Creation'),
                bulletPoint('Take a nature walk and observe God’s handiwork'),
                bulletPoint('Visit a nearby park, garden, or forest'),
                bulletPoint('Go birdwatching or look at constellations'),
                bulletPoint('Sketch, paint, or photograph scenes in nature'),
                bulletPoint(
                  'Collect leaves or flowers and make a Creation collage',
                ),
                bulletPoint('Sit quietly and reflect on God’s power in nature'),
                const SizedBox(height: 24),

                sectionTitle('👥 Fellowship and Community'),
                bulletPoint(
                  'Share a Sabbath meal with friends or church members',
                ),
                bulletPoint('Visit someone who is sick or elderly'),
                bulletPoint(
                  'Write encouraging notes to church members or missionaries',
                ),
                bulletPoint(
                  'Participate in a Bible study group or small group discussion',
                ),
                bulletPoint(
                  'Sing hymns or gospel songs together at a home or nursing facility',
                ),
                bulletPoint(
                  'Host a Bible game night (Sabbath-appropriate trivia or charades)',
                ),
                const SizedBox(height: 24),

                sectionTitle('🛌 Rest and Reflection'),
                bulletPoint('Take a quiet Sabbath nap'),
                bulletPoint('Reflect on blessings from the past week'),
                bulletPoint('Journal your prayers or answered prayers'),
                bulletPoint('Spend time in silence, listening for God’s voice'),
                bulletPoint('Unplug from screens and focus on personal growth'),
                bulletPoint(
                  'Light a candle or use a special item to set apart Sabbath time',
                ),
                const SizedBox(height: 24),

                sectionTitle('🔍 Teaching and Mentoring'),
                bulletPoint(
                  'Lead or support a children\'s Sabbath School class',
                ),
                bulletPoint('Share a personal testimony or spiritual story'),
                bulletPoint('Help someone learn to read or study the Bible'),
                bulletPoint(
                  'Create simple Bible-based crafts or skits for children',
                ),
                bulletPoint('Practice storytelling with Bible stories'),
                bulletPoint('Share nature object lessons with children'),
                const SizedBox(height: 24),

                sectionTitle('🏕️ Pathfinder & Youth Activities'),
                bulletPoint(
                  'Plan a Sabbath hike with a spiritual theme or devotion stop',
                ),
                bulletPoint(
                  'Practice honors that are Sabbath-appropriate (e.g., Nature Study, Birds, Christian Storytelling)',
                ),
                bulletPoint(
                  'Lead a Pathfinder Sabbath service or outreach event',
                ),
                bulletPoint(
                  'Organize a nature scavenger hunt with biblical symbolism',
                ),
                bulletPoint('Role-play Bible characters or parables'),
                bulletPoint(
                  'Journal reflections from nature or outreach experience',
                ),
                bulletPoint('Sing Pathfinder songs and discuss their meanings'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16, color: Colors.white)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
