import 'package:flutter/material.dart';

class PaymentStatusScreen extends StatelessWidget {
  const PaymentStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> payments = [
      {
        'name': 'Green Valley Society',
        'type': 'Society',
        'month': 'May',
        'status': 'Paid',
        'amount': 12000
      },
      {
        'name': 'Lake View Residency',
        'type': 'Apartment',
        'month': 'May',
        'status': 'Unpaid',
        'amount': 8000
      },
      {
        'name': 'FixIt Services',
        'type': 'Service Provider',
        'month': 'May',
        'status': 'Paid',
        'amount': 4500
      },
      {
        'name': 'Bright Power Co.',
        'type': 'Service Provider',
        'month': 'May',
        'status': 'Unpaid',
        'amount': 6200
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Status'),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: payments.length,
        itemBuilder: (context, index) {
          final item = payments[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: Icon(
                item['status'] == 'Paid' ? Icons.check_circle : Icons.warning,
                color: item['status'] == 'Paid' ? Colors.green : Colors.red,
              ),
              title: Text('${item['name']} (${item['type']})'),
              subtitle: Text('Month: ${item['month']} | Amount: Rs. ${item['amount']}'),
              trailing: Text(
                item['status'],
                style: TextStyle(
                  color: item['status'] == 'Paid' ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
