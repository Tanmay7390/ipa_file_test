import 'package:flutter/cupertino.dart';
import 'package:aesurg26/components/page_scaffold.dart';

class CommitteeMessagesPage extends StatelessWidget {
  const CommitteeMessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPageScaffold(
      heading: 'Committee Messages',
      hideSearch: true,
      isLoading: false,
      sliverList: SliverList(
        delegate: SliverChildListDelegate([
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),

                // Message from Organizing Chair
                Text(
                  'MESSAGE FROM ORGANIZING CHAIR',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Display',
                    color: CupertinoColors.systemGrey,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Dr. Medha Bhave',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Dear Friends,\n\nIt is my privilege and honor to organize AESURG-26, the official annual conference of the Indian Association of Aesthetic Plastic Surgeons. I am confident that AESURG-26 will be the largest and most impactful conference in Asia in 2026.\n\nThe AESURG-26 team is working diligently to ensure every aspect of the conference exceeds expectations, especially the academic extravaganza and innovative workshops. Our goal is to INSPIRE everyone, from senior practitioners to fresh graduates.\n\nOur theme "INITIATE, INNOVATE, INSPIRE" will guide every aspect of the conference. We are thrilled to welcome exceptional international faculty for prestigious orations, masterclasses, and talks, alongside our esteemed national faculty.\n\nMumbai, the City of Dreams, offers vibrant culture, unmatched hospitality, buzzing nightlife, diverse culinary delights, and family-friendly attractions for a memorable stay.\n\nWe look forward to welcoming you with open arms!\n\nLong live IAAPS!',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),

                SizedBox(height: 32),

                // Message from Organizing Secretaries
                Text(
                  'MESSAGE FROM ORGANIZING SECRETARIES',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Display',
                    color: CupertinoColors.systemGrey,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Dr. Parag Telang, Dr. Preetish Bhavsar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'It gives us immense pleasure to invite all delegates to the 21st Edition of AESURG 2026 at Mumbai, India. With the theme "Initiate, Innovate and Inspire," we want to initiate patient safety practices, promote innovation in aesthetic surgery, and inspire young plastic surgeons to venture into this field.\n\nThe beautiful Westin Powai provides the perfect setting for the best minds in aesthetic surgery from India and abroad to meet, discuss ideas, and enjoy cultural extravaganzas each evening. We have organized an amazing scientific program with internationally renowned speakers, so you can pick their brains and enrich your experience.\n\nAlong with days filled with knowledge, we promise fun-filled evenings with mesmerizing cultural events and scrumptious delicacies. We have also curated wonderful activities and programs for accompanying persons.\n\nWe, The Team AESURG Mumbai 2026, are eager to welcome you to Mumbai (The City of Dreams).',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),

                SizedBox(height: 32),

                // Message from Scientific Chairs
                Text(
                  'MESSAGE FROM SCIENTIFIC CHAIRS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Display',
                    color: CupertinoColors.systemGrey,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Dr. Vinod Vij - Scientific Chair, Dr. Viraj Tambwekar - Scientific Co-Chair',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Dear esteemed colleagues and participants,\n\nIt is with great honor and excitement that we welcome you to AESURG 2026, the leading conference on aesthetic surgery in the vibrant city of Mumbai. This event serves as a unique platform for global exchange of knowledge, expertise, and innovations in the ever-evolving field of aesthetic surgery.\n\nWe are thrilled to present a carefully curated program showcasing the latest advancements, cutting-edge techniques, and emerging trends in aesthetic surgery. Our aim is to foster an environment of collaboration, learning, and inspiration, where professionals from all backgrounds can share insights and explore new frontiers in patient care and surgical artistry.\n\nThis conference offers residents a unique opportunity to engage with the latest advancements and shape the future of aesthetic surgery.\n\nWe look forward to engaging discussions, enriching interactions, and a collective drive to elevate the standards of aesthetic surgery worldwide.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),

                SizedBox(height: 32),

                // Message from Treasurer
                Text(
                  'MESSAGE FROM TREASURER',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Display',
                    color: CupertinoColors.systemGrey,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Dr. Ajay Hariani',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Dear Esteemed Members,\n\nOn behalf of AESURG 2026, one of the leading conferences on aesthetic surgery being held in the Financial Capital of India, Mumbai, I extend my heartfelt greetings to all. It is an honor to serve as the Treasurer for this conference.\n\nOur conference is committed to advancing aesthetic practice and education, fostering collaboration and innovations in the ever-evolving field of aesthetic surgery. Financial prudence and transparency are key to achieving these goals, and I assure you that the AESURG Team and I are dedicated to managing our resources efficiently to support our initiatives.\n\nI urge all members to actively participate in our activities and contribute to our shared success. Your involvement and support are essential as we work towards making significant advancements in aesthetic surgery care and education.\n\nTogether, we will reach new milestones and establish standards of excellence in the field of Aesthetic Medicine & Surgery.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),

                SizedBox(height: 40),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
