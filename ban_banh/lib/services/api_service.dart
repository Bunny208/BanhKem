import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.0.2.2:5006/api";
  static String? _userId;
  static String? _fullName;

  static String? get userId => _userId;
  static String? get fullName => _fullName;
  static String? _token;
  static String? get token => _token; // Token người dùng sau khi đăng nhập

  /// Gán token để dùng cho các request có xác thực
  static void setToken(String token) {
    _token = token;
  }

  static Map<String, String> get headers => {
    "Content-Type": "application/json",
    if (_token != null && _token!.isNotEmpty)
      "Authorization": "Bearer $_token",
  };

  // Đăng ký tài khoản
  static Future<Map<String, dynamic>> signup({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String address,
  }) async {
    final url = Uri.parse("$baseUrl/AccountApi/register");
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        "FullName": fullName,
        "Email": email,
        "Password": password,
        "PhoneNumber": phone,
        "Address": address,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Lỗi đăng ký: ${response.body}");
    }
  }

  // Đăng nhập
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/AccountApi/login");
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data["accessToken"];
      setToken(token); // Lưu token để sử dụng cho các API khác
      _userId = data["user"]["id"];
      _fullName = data["user"]["fullName"];
      return {
        "token": token,
        "userId": data["user"]["id"],
        "fullName": data["user"]["fullName"],
        "email": data["user"]["email"],
      };
    } else {
      throw Exception("Lỗi đăng nhập: ${response.body}");
    }
  }

  // Lấy danh mục bánh
  static Future<List<dynamic>> getCategories() async {
    final url = Uri.parse("$baseUrl/CategoryApi");
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Không tải được danh mục: ${response.body}");
    }
  }

  // Lấy tất cả sản phẩm
  static Future<List<dynamic>> getProducts() async {
    final url = Uri.parse("$baseUrl/ProductApi");
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Không tải được sản phẩm: ${response.body}");
    }
  }

  // Lấy sản phẩm theo danh mục
  static Future<List<dynamic>> getProductsByCategory(int categoryId) async {
    final url = Uri.parse("$baseUrl/ProductApi/by-category/$categoryId");
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Không tải được sản phẩm theo danh mục: ${response.body}");
    }
  }

  // Lấy giỏ hàng theo userId
  static Future<Map<String, dynamic>> getCart(String userId) async {
    final url = Uri.parse("$baseUrl/CartApi?userId=$userId");
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Không tải được giỏ hàng: ${response.body}");
    }
  }

  // Thêm sản phẩm vào giỏ hàng
  static Future<bool> addToCart({
    required String userId,
    required int productId,
    required int quantity,

  }) async {
    final url = Uri.parse("$baseUrl/CartApi/add");
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        "productId": productId,
        "quantity": quantity,
        "userId": userId,
      }),
    );

    if (response.statusCode == 200) return true;
    throw Exception("Không thể thêm sản phẩm: ${response.body}");
  }

  // Xóa sản phẩm khỏi giỏ
  static Future<bool> removeFromCart({
    required String userId,
    required int productId,
  }) async {
    final url =
    Uri.parse("$baseUrl/CartApi/remove?userId=$userId&productId=$productId");
    final response = await http.delete(url, headers: headers);

    if (response.statusCode == 200) return true;
    throw Exception("Không thể xóa sản phẩm: ${response.body}");
  }

  // Cập nhật số lượng sản phẩm trong giỏ
  static Future<bool> updateQuantity({
    required String userId,
    required int productId,
    required int quantity,
  }) async {
    final url = Uri.parse("$baseUrl/CartApi/update");
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode({
        "userId": userId,
        "productId": productId,
        "quantity": quantity,
      }),
    );

    if (response.statusCode == 200) return true;
    throw Exception("Không thể cập nhật số lượng: ${response.body}");
  }
  static Future<Map<String, dynamic>> checkout(
      Map<String, dynamic> checkoutData) async {
    final url = Uri.parse("$baseUrl/ShoppingCartApi/checkout");
    final body = {
      "recipientName": checkoutData["recipientName"] ?? "",
      "recipientPhone": checkoutData["recipientPhone"] ?? "",
      "specificAddress": checkoutData["specificAddress"] ?? "",
      "district": checkoutData["district"] ?? "",
      "ward": checkoutData["ward"] ?? "",
      "deliveryDateTime": checkoutData["deliveryDateTime"],
      "notes": checkoutData["notes"] ?? "",
      "paymentMethod": checkoutData["paymentMethod"] ?? "COD",
      "orderDetails": checkoutData["orderDetails"] ?? [],
      "totalPrice": checkoutData["totalPrice"] ?? 0,
    };

    final res = await http.post(url, headers: headers, body: jsonEncode(body));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data;
    } else {
      throw Exception("Lỗi thanh toán: ${res.body}");
    }
  }

  /// --------------------------
  /// KIỂM TRA TRẠNG THÁI THANH TOÁN
  /// --------------------------
  static Future<String> checkPaymentStatus(int orderId) async {
    final url = Uri.parse("$baseUrl/ShoppingCartApi/check-payment-status/$orderId");
    final res = await http.get(url, headers: headers);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data["status"];
    } else {
      throw Exception("Không kiểm tra được trạng thái: ${res.body}");
    }
  }

  // Lấy hồ sơ người dùng
  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    // Sửa đúng endpoint theo backend của bạn
    final url = Uri.parse("$baseUrl/AccountApi/$userId");
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        "id": data["id"],
        "fullName": data["fullName"] ?? "",
        "email": data["email"] ?? "",
        "phoneNumber": data["phoneNumber"] ?? "",
        "address": data["address"] ?? "",
      };
    } else {
      throw Exception("Không tải được hồ sơ: ${response.body}");
    }
  }

  // Cập nhật hồ sơ người dùng
  static Future<bool> updateUserProfile({
    required String userId,
    required String fullName,
    required String email,
    required String phoneNumber,
    required String address,
  }) async {
    // Giữ nguyên endpoint theo controller của bạn
    final url = Uri.parse("$baseUrl/AccountApi/update/$userId");
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode({
        "fullName": fullName,
        "email": email,
        "phoneNumber": phoneNumber,
        "address": address,
      }),
    );

    if (response.statusCode == 200) return true;
    throw Exception("Không thể cập nhật hồ sơ: ${response.body}");
  }

// Lịch sử đơn hàng (JWT version)
// ========================
  static Future<List<dynamic>> getOrderHistory({String? status}) async {
    final query = status != null && status.isNotEmpty && status != "Tất cả"
        ? "?status=$status"
        : "";
    final url = Uri.parse("$baseUrl/OrdersApi/history$query");

    final res = await http.get(url, headers: headers);

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else if (res.statusCode == 401) {
      throw Exception("Chưa đăng nhập hoặc token hết hạn");
    } else {
      throw Exception("Lỗi khi tải lịch sử đơn hàng: ${res.body}");
    }
  }


  // Lấy chi tiết đơn hàng theo ID
  static Future<Map<String, dynamic>> getOrderDetail(int orderId) async {
    final url = Uri.parse("$baseUrl/OrdersApi/detail/$orderId");
    final response = await http.get(url, headers: headers);
    print("🔹 Request URL: $url");
    print("🔹 Headers: $headers");
    print("🔹 Status code: ${response.statusCode}");
    print("🔹 Body (preview): ${response.body.substring(0, 200)}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Không tải được chi tiết đơn hàng: ${response.body}");
    }
  }


  // Hủy đơn hàng
  static Future<bool> cancelOrder(int id) async {
    final url = Uri.parse("$baseUrl/OrdersApi/cancel/$id");
    final res = await http.post(url, headers: headers);

    if (res.statusCode == 200) {
      return true;
    } else {
      throw Exception("Không thể hủy đơn hàng: ${res.body}");
    }
  }


}
