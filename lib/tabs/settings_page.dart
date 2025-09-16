import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsPage extends StatefulWidget {
  final Function(int) updateNumberOfPlayers;
  final Function(String) updateGridSize;
  final int numberOfPlayers;
  final String gridSize;

  const SettingsPage({
    super.key,
    required this.updateNumberOfPlayers,
    required this.updateGridSize,
    required this.numberOfPlayers,
    required this.gridSize,
  });

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  User? _user;
  String? _nickname;

  // 기존 데이터 마이그레이션 도우미 함수
  Future<void> _migrateUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        String uid = user.uid;
        String emailPrefix = user.email!.split('@')[0];
        String oldDocumentId = '$emailPrefix$uid';
        String newDocumentId = uid;

        // 이미 신규 문서가 있는지 확인
        DocumentSnapshot newUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(newDocumentId)
            .get();

        // 기존 문서 확인
        DocumentSnapshot oldUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(oldDocumentId)
            .get();

        // 신규 문서가 없고 기존 문서가 있는 경우 마이그레이션 진행
        if (!newUserDoc.exists && oldUserDoc.exists) {
          // 기존 데이터 복사
          Map<String, dynamic> userData =
              oldUserDoc.data() as Map<String, dynamic>;

          // 신규 문서에 저장
          await FirebaseFirestore.instance
              .collection('users')
              .doc(newDocumentId)
              .set(userData);

          print(
              'User data migrated from old ID ($oldDocumentId) to new ID ($newDocumentId)');

          // 필요에 따라 기존 문서 삭제 (선택적)
          // await FirebaseFirestore.instance.collection('users').doc(oldDocumentId).delete();
          // print('Old document deleted');
        }
      }
    } catch (e) {
      print('Error during data migration: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
    _migrateUserData(); // 데이터 마이그레이션 시도

    // 인증 상태 변경 감지
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        setState(() {
          _user = null;
          _nickname = null;
        });
      } else {
        _checkCurrentUser();
      }
    });
  }

  Future<void> _checkCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String uid = user.uid;
      String documentId = uid;

      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(documentId)
            .get();

        if (userDoc.exists) {
          setState(() {
            _user = user;
            _nickname = userDoc['nickname'];
          });
        } else {
          // If user document does not exist
          setState(() {
            _user = null;
            _nickname = null;
          });
        }
      } catch (e) {
        print('Error fetching user information: $e');
        setState(() {
          _user = null;
          _nickname = null;
        });
      }
    } else {
      setState(() {
        _user = null;
        _nickname = null;
      });
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    setState(() {
      _user = null;
      _nickname = null;
    });
  }

  void _showSignInDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _signIn(
                      context, emailController.text, passwordController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Sign In'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showSignUpDialog(context);
                  },
                  child: const Text('Don\'t have an account? Sign Up'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _signIn(
      BuildContext context, String email, String password) async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _checkCurrentUser(); // Update user information immediately after login

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in successful')),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred during sign in.';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  void _showSignUpDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController nicknameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nicknameController,
                  decoration: InputDecoration(
                    hintText: 'Nickname',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _signUp(
                    context,
                    emailController.text,
                    passwordController.text,
                    nicknameController.text,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Create Account'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _signUp(BuildContext context, String email, String password,
      String nickname) async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;
      String documentId = uid;

      await FirebaseFirestore.instance.collection('users').doc(documentId).set({
        'email': email,
        'nickname': nickname,
        'language': 'en',
      });

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully.')),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred during account creation.';
      if (e.code == 'weak-password') {
        errorMessage = 'The password is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'The email address is already in use.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is invalid.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('An error occurred during account creation: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _user == null
            ? ElevatedButton(
                onPressed: () => _showSignInDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: const Text('Sign In'),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Welcome, $_nickname',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: _signOut,
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
