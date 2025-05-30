import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class ChallengeNotification extends StatefulWidget {
  const ChallengeNotification({Key? key}) : super(key: key);

  @override
  _ChallengeNotificationState createState() => _ChallengeNotificationState();
}

class _ChallengeNotificationState extends State<ChallengeNotification> {
  late Stream<QuerySnapshot> _challengesStream;

  @override
  void initState() {
    super.initState();
    _initChallengesStream();
  }

  void _initChallengesStream() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _challengesStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('type', isEqualTo: 'challenge')
          .where('status', isEqualTo: 'pending')
          .orderBy('timestamp', descending: true)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Container();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _challengesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container();
        }

        List<DocumentSnapshot> challenges = snapshot.data?.docs ?? [];
        if (challenges.isEmpty) {
          return Container();
        }

        // Display the latest challenge notification
        return _buildChallengeNotification(challenges.first);
      },
    );
  }

  Widget _buildChallengeNotification(DocumentSnapshot challenge) {
    Map<String, dynamic> data = challenge.data() as Map<String, dynamic>;
    String senderNickname = data['senderNickname'] ?? 'Unknown';
    String gridSize = data['gridSize'] ?? '4x4';
    String challengeId = data['challengeId'] ?? '';

    // Mark as read
    if (data['read'] == false) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('notifications')
          .doc(challenge.id)
          .update({'read': true});
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF833AB4), Color(0xFFF77737)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.sports_kabaddi, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Challenge Request',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                '$senderNickname has challenged you to a Memory Game!',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Grid Size: $gridSize',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () =>
                        _respondToChallenge(challengeId, 'rejected'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text('Decline'),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () =>
                        _respondToChallenge(challengeId, 'accepted'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFF833AB4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text('Accept'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _respondToChallenge(String challengeId, String response) async {
    try {
      // Update the challenge status in main challenges collection
      await FirebaseFirestore.instance
          .collection('challenges')
          .doc(challengeId)
          .update({'status': response});

      // Update status in user's notifications
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('notifications')
          .doc(challengeId)
          .update({'status': response});

      if (response == 'accepted') {
        // Get the challenge details to prepare the game
        DocumentSnapshot challengeDoc = await FirebaseFirestore.instance
            .collection('challenges')
            .doc(challengeId)
            .get();

        if (challengeDoc.exists) {
          Map<String, dynamic> data =
              challengeDoc.data() as Map<String, dynamic>;

          // TODO: Navigate to game setup or directly to the game
          // This will be implemented in the main app navigation
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Challenge accepted! Game starting soon...'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Challenge declined'),
            backgroundColor: Colors.grey,
          ),
        );
      }

      // Notify the sender about the response
      _notifySender(challengeId, response);
    } catch (e) {
      print('Error responding to challenge: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to respond to challenge. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _notifySender(String challengeId, String response) async {
    try {
      // Get challenge details to find sender
      DocumentSnapshot challengeDoc = await FirebaseFirestore.instance
          .collection('challenges')
          .doc(challengeId)
          .get();

      if (!challengeDoc.exists) return;

      Map<String, dynamic> challengeData =
          challengeDoc.data() as Map<String, dynamic>;
      String senderId = challengeData['senderId'];

      // Get current user's info
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      String responderNickname = 'Unknown Player';
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        responderNickname = userData['nickname'] ??
            (currentUser.displayName ??
                currentUser.email?.split('@')[0] ??
                'Unknown Player');
      }

      // Create notification
      await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .collection('notifications')
          .add({
        'type': 'challenge_response',
        'challengeId': challengeId,
        'status': response,
        'senderNickname': responderNickname,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Challenge response notification created successfully');
    } catch (e) {
      print('Error notifying sender: $e');
    }
  }
}
