class Store {
  final int? id;
  final String stallId;
  final String name;
  final String owner;
  final String? group;
  final double defaultAmount;
  final String status;
  final Payment? latestPayment;
   final int? userId;

  Store({
    this.id,
    required this.stallId,
    required this.name,
    required this.owner,
    this.group,
    required this.defaultAmount,
    required this.status,
    this.latestPayment,
    this.userId, 
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] as int?,
      stallId: json['stall_id'] ?? '',
      name: json['name'] ?? '',
      owner: json['owner'] ?? '',
      group: json['group'],
      defaultAmount: (json['default_amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'unpaid',
      latestPayment: json['latest_payment'] != null
          ? Payment.fromJson(json['latest_payment'])
          : null,
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stall_id': stallId,
      'name': name,
      'owner': owner,
      'group': group,
      'default_amount': defaultAmount,
      'status': status,
      'user_id': userId,
    };
  }
}

class Payment {
  final int id;
  final double amount;
  String? note;
  final String createdAt;
  final String? transactionId;

  Payment({
    required this.id,
    required this.amount,
    this.note,
    required this.createdAt,
    this.transactionId,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      amount: (json['amount'] as num).toDouble(),
      note: json['note'],
      createdAt: json['created_at'],
      transactionId: json['transaction_id'],
    );
  }
}
