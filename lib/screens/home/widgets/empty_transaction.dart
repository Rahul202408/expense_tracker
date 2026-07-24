import 'package:flutter/material.dart';

class EmptyTransaction extends StatelessWidget {
  const EmptyTransaction({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 90,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 20),

          const Text(
            "No Transactions Yet",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          Text(
            "Tap the + button below to add your first income or expense.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
