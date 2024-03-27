import 'package:main/Wallet.dart';

Future<bool> processPayment(String Price) async {
  double price = double.parse(Price);

  // Calculate the number of coins needed based on the price
  double coinsNeeded = price; // 1 coin = Rs.1

  // Get the current state of the wallet
  Wallet walletState = const Wallet(type: 'user');
  Future<double> currentCoins = walletState.currentCoins;
  // Check if the user has enough coins in the wallet
  double currentCoinsValue = await currentCoins;
  if (currentCoinsValue >= coinsNeeded) {
    // Deduct the coins from the wallet balance
    walletState.deductCoins(coinsNeeded);
    // Payment processed successfully
    return true;
  } else {
    // Insufficient coins in the wallet
    return false;
  }
}
