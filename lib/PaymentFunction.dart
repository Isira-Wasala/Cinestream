import 'package:main/Wallet.dart';

Future<bool> processPayment(String Price, String Type) async {
  int price = int.parse(Price);
  String type = Type;

  // Calculate the number of coins needed based on the price
  int coinsNeeded = price; // 1 coin = Rs.1

  // Get the current state of the wallet
  Wallet walletState = Wallet(type: type);
  Future<int> currentCoins = walletState.currentCoins;
  // Check if the user has enough coins in the wallet
  int currentCoinsValue = await currentCoins;
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
