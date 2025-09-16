import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationBadge extends StatelessWidget {
  final Widget child;
  final Stream<QuerySnapshot>? stream;

  const NotificationBadge({
    super.key,
    required this.child,
    this.stream,
  });

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return child;
    }

    // Use provided stream or create default one
    final notificationStream = stream ??
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .where('status', isEqualTo: 'pending')
            .where('read', isEqualTo: false)
            .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: notificationStream,
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) {
          return child;
        }

        final count = snapshot.data?.docs.length ?? 0;

        if (count == 0) {
          return child;
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            Positioned(
              right: -5,
              top: -5,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  count > 9 ? '9+' : count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
