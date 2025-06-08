import 'package:flutter/material.dart';

class BibleScreen extends StatefulWidget {
  const BibleScreen({super.key});

  @override
  State<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen> {
  final List<Map<String, String>> bibleQA = [
    {
      "question": "1. How are the first six days of the week to be occupied?",
      "answer":
          "\"Six days shalt thou labour, and do all thy work.\" Exodus 20:9",
    },
    {
      "question":
          "2. How is the seventh day to be distinguished from the six working days?",
      "answer":
          "\"Six days shall work be done: but the seventh day is the Sabbath of rest, an holy convocation; ye shall do no work therein.\" Leviticus 23:3",
    },
    {
      "question":
          "3. Should the Sabbath be strictly observed even under pressure of work?",
      "answer":
          "\"Six days thou shalt work, but on the seventh day thou shalt rest: in earing time and in harvest thou shalt rest.\" Exodus 34:21",
    },
    {
      "question":
          "4. Beside work on the land what other activities are to cease on the Sabbath?",
      "answer":
          "\"Tomorrow is the rest of the holy Sabbath unto the Lord: bake that which ye will bake today, and seethe that ye will seethe; and that which remaineth over lay up for you to be kept until the morning.\" Exodus 16:23\n\n\"And if the people of the land bring ware or any victuals on the Sabbath day to sell … we would not buy it of them on the Sabbath.\" Nehemiah 10:31",
    },
    {
      "question":
          "5. On whom is the obligation to observe the Sabbath rest enjoined?",
      "answer":
          "\"But the seventh day is the Sabbath of the Lord thy God: in it thou shalt not do any work, thou, nor thy son, nor thy daughter, thy manservant, nor thy maidservant, nor thy cattle, nor thy stranger that is within thy gates.\" Exodus 20:10",
    },
    {
      "question": "6. When do the Sabbath hours begin and end?",
      "answer":
          "“From evening unto evening, shall ye celebrate your Sabbath.\" Leviticus 23:32",
    },
    {
      "question": "7. Where does this division of the days originate?",
      "answer":
          "\"And God called the light Day, and the darkness He called Night. And the evening and the morning were the first day.\" Genesis 1:5 (See verses 8, 13, 19, 23, 31)",
    },
    {
      "question": "8. In what reverence are the Sabbath hours to be held?",
      "answer":
          "\"Remember the Sabbath day, to keep it holy.\" Exodus 20:8\n\"And they shall hallow My Sabbaths.\" Ezekiel 44:24\n\"Keep the Sabbath day to sanctify it, as the Lord thy God hath commanded thee.\" Deuteronomy 5:12",
    },
    {
      "question": "9. How was the Sabbath employed in Israel?",
      "answer":
          "\"The seventh day is the Sabbath of rest, an holy convocation.\" Leviticus 23:3",
    },
    {
      "question":
          "10. What example did Jesus set of proper Sabbath observance?",
      "answer":
          "\"And He came to Nazareth, where He had been brought up: and, as His custom was, He went into the synagogue on the Sabbath day.\" Luke 4:16\n\n\"Jesus taught men how to observe the Sabbath. He made no attempt to destroy but He did glorify it.\" — \"God's Answer,\" edited by J. Clyde Mahaffery.",
    },
    {
      "question": "11. How is the church of the last days exhorted?",
      "answer":
          "“Not forsaking the assembling of ourselves together, as the manner of some is; but exhorting one another: and so much the more, as ye see the day approaching.\" Hebrews 10:25",
    },
    {
      "question": "12. What record is kept in the books of heaven?",
      "answer":
          "\"Then they that feared the Lord spake often one to another: and the Lord hearkened, and heard it, and a book of remembrance was written before Him for them that feared the Lord, and that thought upon His name.\" Malachi 3:16",
    },
    {
      "question":
          "13. Beside worship, what other occupations are perfectly proper on the Sabbath day?",
      "answer": "“It is lawful to do well on the Sabbath days.\" Matthew 12:12",
    },
    {
      "question": "14. What typical good works did Jesus do on the Sabbath?",
      "answer":
          "\"And it was the Sabbath day when Jesus made the clay, and opened his eyes.\" John 9:14\n\"Then saith He to the man, Stretch forth thine hand. And he stretched it forth; and it was restored whole, like as the other.\" Matthew 12:13",
    },
    {
      "question":
          "15. In order that the Sabbath may be a day of physical rest and spiritual blessing for all, what preparation is necessary on the previous day?",
      "answer":
          "\"And it shall come to pass, that on the sixth day they shall prepare that which they bring in; … tomorrow is the rest of the holy Sabbath unto the Lord.\"  Exodus 16:5-23\n\n\"At the very beginning of the fourth commandment the Lord said, 'Remember.'… All through the week we are to have the Sabbath in mind, and be making preparation to keep it according to the commandment.\" — E. G. White",
    },
    {
      "question":
          "16. What special name is, therefore, given to the sixth day of the week?",
      "answer":
          "\"Now when the even was come, because it was the preparation, that is, the day before the Sabbath, Joseph of Arimathaea … went in boldly unto Pilate, and craved the body of Jesus.\" Mark 15:42-43\n\"And that day was the preparation, and the Sabbath drew on.\" Luke 23:54",
    },
    {
      "question":
          "17. While God indicated specifically how the Sabbath should be kept, for whose benefit was the day intended?",
      "answer":
          "\"And He said unto them, The Sabbath was made for man, and not man for the Sabbath.\" Mark 2:27",
    },
    {
      "question":
          "18. If we observe it as God intended, what joy shall we find in its sacred hours?",
      "answer":
          "\"This is the day which the Lord hath made; we will rejoice and be glad in it.\" Psalm 118:24",
    },
  ];

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
          child: ListView.builder(
            itemCount: bibleQA.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bibleQA[index]['question']!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bibleQA[index]['answer']!,
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
