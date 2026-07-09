import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants.dart';

class OfferingScreen extends StatelessWidget {
  const OfferingScreen({super.key});

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Account copied successfully"),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildInfo(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(
    BuildContext context, {
    required String title,
    required String bank,
    required String accountName,
    required String accountNumber,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _copyToClipboard(context, accountNumber),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔵 TITLE BAR ONLY COLOUR
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _buildInfo("Bank", bank),
                  _buildInfo("Account Name", accountName),
                  _buildInfo("Account Number", accountNumber),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "Tap to copy",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📖 BIBLE VERSE WIDGET (NEW)
  Widget _bibleVerseCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
      ),
      child: const Column(
        children: [
          Icon(Icons.menu_book, color: Colors.deepPurple),
          SizedBox(height: 8),
          Text(
            "“Give, and it will be given to you. A good measure, pressed down, shaken together and running over, will be poured into your lap.”",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "— Luke 6:38",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final crossAxisCount = width > 1000
        ? 3
        : width > 700
            ? 2
            : 1;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        title: const Text("Tithes & Offerings"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Church Account Dashboard",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // 📖 BIBLE VERSE ADDED HERE
            _bibleVerseCard(),

            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 1.05,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              children: [
                _buildAccountCard(
                  context,
                  title: "Main Account",
                  bank: AppConstants.bankName,
                  accountName: AppConstants.accountName,
                  accountNumber: AppConstants.accountNumber,
                  icon: Icons.account_balance,
                  color: Colors.deepPurple,
                ),
                _buildAccountCard(
                  context,
                  title: "Missions (Naira)",
                  bank: "FCMB",
                  accountName: "LOCCIM Missions",
                  accountNumber: "4039184011",
                  icon: Icons.public,
                  color: Colors.green,
                ),
                _buildAccountCard(
                  context,
                  title: "Missions (USD)",
                  bank: "FCMB",
                  accountName: "LOCCIM Missions",
                  accountNumber: "4039184035",
                  icon: Icons.attach_money,
                  color: Colors.blue,
                ),
                _buildAccountCard(
                  context,
                  title: "Missions (GBP)",
                  bank: "FCMB",
                  accountName: "LOCCIM Missions",
                  accountNumber: "4039184042",
                  icon: Icons.currency_pound,
                  color: Colors.orange,
                ),
                _buildAccountCard(
                  context,
                  title: "Missions (EUR)",
                  bank: "FCMB",
                  accountName: "LOCCIM Missions",
                  accountNumber: "4039184059",
                  icon: Icons.euro,
                  color: Colors.teal,
                ),
                _buildAccountCard(
                  context,
                  title: "Building Fund",
                  bank: "Access Bank",
                  accountName: "LOCCIM Building",
                  accountNumber: "000000000",
                  icon: Icons.apartment,
                  color: Colors.red,
                ),
                _buildAccountCard(
                  context,
                  title: "Welfare Fund",
                  bank: "UBA",
                  accountName: "LOCCIM Welfare",
                  accountNumber: "1122222222",
                  icon: Icons.favorite,
                  color: Colors.pink,
                ),
                _buildAccountCard(
                  context,
                  title: "Youth Ministry",
                  bank: "First Bank",
                  accountName: "LOCCIM Youth",
                  accountNumber: "5566778899",
                  icon: Icons.group,
                  color: Colors.indigo,
                ),
              ],
            ),

            const SizedBox(height: 20),

            Card(
              color: Colors.white,
              elevation: 1,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "Tap any card to copy account number instantly.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
