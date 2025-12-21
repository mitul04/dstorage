import 'package:flutter/material.dart';
import '../services/blockchain_service.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final BlockchainService _service = BlockchainService();
  String _balance = "---";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    // Fetch the real balance from blockchain
    await _service.init();
    final bal = await _service.getRewardTokenBalance();
    if (mounted) {
      setState(() {
        _balance = bal;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("My Rewards", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // --- 1. GRADIENT BALANCE CARD ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4facfe), Color(0xFF00f2fe)], // Matches your UI
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF4facfe).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  children: [
                    _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text("$_balance DEC", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 8),
                    const Text("≈ \$1,500.00 USD", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 24),
                    
                    // Claim Button
                    ElevatedButton(
                      onPressed: () {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                           content: Text("💰 Rewards Claimed! (Simulation)"), 
                           backgroundColor: Colors.green
                         ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      ),
                      child: const Text("Claim Rewards"),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- 2. STATS SUMMARY ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Rewards Earned Summary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 5),
                        Text("Total Earned This Month:", style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                    const Text("12.5 DEC", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pinkAccent, fontSize: 16)),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- 3. TRANSACTION HISTORY (Visual Mock) ---
              const Text("Transaction History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 15),

              _buildTransactionItem("File Upload Reward", "Project_Brief_V2.pdf", "+ 6.2 DEC", true),
              _buildTransactionItem("Storage Node Reward", "Hosting Data", "+ 88 DEC", true),
              _buildTransactionItem("Network Fee", "Smart Contract Interaction", "- 0.5 DEC", false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(String title, String subtitle, String amount, bool isPositive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade50, blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isPositive ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPositive ? Icons.arrow_downward : Icons.arrow_upward,
              color: isPositive ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(amount, style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: isPositive ? Colors.green : Colors.redAccent
          )),
        ],
      ),
    );
  }
}