enum InvoiceType {
  importBarn,    // Nhập Kho (Từ Trại về)
  importMarket,  // Nhập Chợ (Đi thẳng từ Trại ra Chợ hoặc Nhập mua ngoài)
  exportMarket,  // Xuất Chợ (Bán cho khách)
  returnToBarn,  // Chuyển hàng thừa từ Chợ về Kho
}

enum TransactionType {
  payment, // Thanh toán tiền mặt/CK (Khách trả mình hoặc Mình trả Trại)
  refund,  // Hoàn tiền
  adjustment // Điều chỉnh công nợ (nếu có sai sót)
}

enum PaymentMethod {
  cash,           // Tiền mặt
  bankTransfer,   // Chuyển khoản
  debt            // Ghi nợ
}