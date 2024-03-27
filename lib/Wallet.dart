// The wallet widget, which displays the wallet page for sponsors and creators.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class Wallet extends StatefulWidget {
  final String type;
  const Wallet({super.key, required this.type});
  @override
  WalletState createState() => WalletState();

  // Getter for currentCoins
  Future<double> get currentCoins async {
    // Fetch current coins from Firestore
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
    if (currentUserEmail == null) {
      return 0;
    }
    final docSnapshot = await FirebaseFirestore.instance
        .collection('Payments')
        .doc(type)
        .collection('wallet')
        .orderBy('payment_time', descending: true)
        .limit(1)
        .get();

    if (docSnapshot.docs.isNotEmpty) {
      final latestPayment = docSnapshot.docs.first;
      return latestPayment['amount'] as double;
    } else {
      return 0;
    }
  }

  // Function to deduct coins
  Future<void> deductCoins(double coinsNeeded) async {
    try {
      // Fetch current coins
      final currentCoins = await this.currentCoins;

      // Deduct coins if sufficient balance
      if (currentCoins >= coinsNeeded) {
        // Calculate new balance
        final newBalance = currentCoins - coinsNeeded;

        // Update balance in Firestore
        final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
        if (currentUserEmail != null) {
          await FirebaseFirestore.instance
              .collection('Payments')
              .doc(type)
              .collection('wallet')
              .add({
            'Authemail': currentUserEmail,
            'payment_time': DateTime.now(),
            'amount': newBalance,
          });
        }
      } else {
        throw Exception('Insufficient balance');
      }
    } catch (e) {
      print('Error deducting coins: $e');
      throw Exception('Failed to deduct coins');
    }
  }
}

class WalletState extends State<Wallet> {
  double currentCoins = 0; // Initial balance
  List<String> transactionHistory = [];

  @override
  void initState() {
    super.initState();
    fetchCurrentCoins();
    fetchTransactionHistory();
  }

  Future<void> fetchCurrentCoins() async {
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
    if (currentUserEmail == null) {
      setState(() {
        currentCoins = 0;
      });
      return;
    }
    final docSnapshot = await FirebaseFirestore.instance
        .collection('Payments')
        .doc(widget.type)
        .collection('wallet')
        .orderBy('payment_time', descending: true)
        .get();

    if (docSnapshot.docs.isNotEmpty) {
      final latestPayment = docSnapshot.docs.first;
      final double amount = latestPayment['amount'];
      setState(() {
        currentCoins = amount;
      });
    } else {
      setState(() {
        currentCoins = 0;
      });
    }
  }

  Future<void> fetchTransactionHistory() async {
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
    if (currentUserEmail == null) {
      return;
    }
    final querySnapshot = await FirebaseFirestore.instance
        .collection('Payments')
        .doc(widget.type)
        .collection('wallet')
        .orderBy('payment_time', descending: true)
        .get();

    // Clear existing transaction history
    setState(() {
      transactionHistory.clear();
    });

    // Format and add transactions to history
    querySnapshot.docs.forEach((doc) {
      final DateTime paymentTime = (doc['payment_time'] as Timestamp).toDate();
      final double amount = doc['amount'] as double;
      final String formattedTime =
          DateFormat('dd/MM/yyyy - HH:mm').format(paymentTime);
      setState(() {
        transactionHistory.add('Time: $formattedTime, Amount: $amount');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.blue,
            child: Text(
              'Current Coins: $currentCoins',
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.grey[200],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Transaction History:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Column(
                  children: transactionHistory
                      .map((entry) => ListTile(
                            title: Text(entry),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              children: [
                buildBuyCoinsOption(10, Colors.green),
                buildBuyCoinsOption(50, Colors.purple),
                buildBuyCoinsOption(100, Colors.orange),
                buildBuyCoinsOption(150, Colors.blue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBuyCoinsOption(double coins, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CheckoutPage(
                    coinsToAdd: coins,
                    type: widget.type,
                  )),
        );
      },
      child: Card(
        color: color,
        child: Center(
          child: Text(
            'Buy $coins Coins',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class CheckoutPage extends StatefulWidget {
  final double coinsToAdd;
  final String type;

  const CheckoutPage({Key? key, required this.coinsToAdd, required this.type})
      : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late double coinsToAdd; // Track the number of coins to add
  final FirebaseService _firebaseService = FirebaseService();
  @override
  void initState() {
    super.initState();
    coinsToAdd = widget.coinsToAdd;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Buy Coins",
          style: TextStyle(fontSize: 20),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await initiatePayment(coinsToAdd);
              },
              child: Text('Checkout for $coinsToAdd Coins'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> initiatePayment(double coinsToAdd) async {
    // Assuming you have the user's email
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
    if (currentUserEmail == null) {
      return;
    }

    double amount;
    if (coinsToAdd == 10) {
      amount = 2426;
    } else if (coinsToAdd == 50) {
      amount = 12128;
    } else if (coinsToAdd == 100) {
      amount = 24256;
    } else if (coinsToAdd == 150) {
      amount = 36384;
    } else {
      // Handle any other coin amount
      amount = coinsToAdd * 1.0;
    }

    // Add payment information to Firebase
    await _firebaseService.addPayment(widget.type, currentUserEmail, amount);

    // Launch the appropriate PayPal payment URL
    String paypalPaymentUrl;
    if (coinsToAdd == 10) {
      paypalPaymentUrl = "https://www.paypal.com/ncp/payment/6KQAPYUWZZSBQ";
    } else if (coinsToAdd == 50) {
      paypalPaymentUrl = "https://www.paypal.com/ncp/payment/8GUQN4E8REFS4";
    } else if (coinsToAdd == 100) {
      paypalPaymentUrl = "https://www.paypal.com/ncp/payment/QB7WVBS6A9SW2";
    } else if (coinsToAdd == 150) {
      paypalPaymentUrl = "https://www.paypal.com/ncp/payment/PLN3AM7D759XC";
    } else {
      // Handle any other coin amount
      return;
    }

    // Launch the PayPal payment URL
    await launch(paypalPaymentUrl, forceSafariVC: false, forceWebView: false);
    // if () {
    //   // Update the user's wallet balance
    //   await _firebaseService.addPayment(widget.type, currentUserEmail, amount);
    // }
  }
}

class FirebaseService {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('Payments');

  Future<void> addPayment(String type, String userEmail, double amount) async {
    try {
      // Get the user document reference
      final userDocRef = usersCollection.doc(type);

      // Check if a document already exists in the "Wallet" subcollection
      final walletDocs = await userDocRef.collection('wallet').get();
      DateTime paymentTime = DateTime.now();

      if (walletDocs.docs.isNotEmpty) {
        // If a document exists, update it with the new amount
        final docSnapshot = await FirebaseFirestore.instance
            .collection('Payments')
            .doc(type)
            .collection('wallet')
            .orderBy('payment_time', descending: true)
            .get();

        if (docSnapshot.docs.isNotEmpty) {
          final latestPayment = docSnapshot.docs.first;
          final double Pamount = latestPayment['amount'];
          await userDocRef
              .collection('wallet')
              .doc(walletDocs.docs.last.id)
              .update({
            'amount': amount + Pamount,
            'payment_time': paymentTime, // Update timestamp
          });
        }

        print('Payment updated successfully');
      } else {
        // If no document exists, add a new one
        await userDocRef.collection('wallet').add({
          'Authemail': userEmail,
          'payment_time': paymentTime,
          'amount': amount, // Capture server timestamp
        });
        print('Payment added successfully');
      }
    } catch (e) {
      print('Error adding payment: $e');
      throw Exception('Failed to add payment');
    }
  }
}
