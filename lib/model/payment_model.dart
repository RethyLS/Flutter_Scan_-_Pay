class Payment {
  final int id;
  final int storeId;
  final double amount;
  final String status;
  final String? transactionId;
  String? note;
  final DateTime? createdAt;

  Payment({
    required this.id,
    required this.storeId,
    required this.amount,
    required this.status,
    this.transactionId,
    this.note,
    this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      storeId: json['store_id'],
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] ?? 'pending',
      transactionId: json['transaction_id'],
      note: json['note'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_id': storeId,
      'amount': amount,
      'status': status,
      'transaction_id': transactionId,
      'note': note,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
