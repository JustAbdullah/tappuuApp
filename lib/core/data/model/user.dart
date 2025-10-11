class User {
  final int? id;
  final String? email;
  final String? password;
   var date;  
  final int is_delete; // غير قابل للnull كرقم
  final int is_block; // غير قابل للnull كرقم
  final int max_free_posts; // غير قابل للnull كرقم
  final int free_posts_used; // غير قابل للnull كرقم
  final String? signup_method;

  User({
    this.id,
    this.email,
    this.password,
    this.date,
   required this.is_delete,
   required this.is_block,
    required this.max_free_posts, // إجباري
  required this.free_posts_used,
  required this.signup_method,
  });

  factory User.fromJson(Map<String, dynamic> json) {
  return User(
    id: _parseInt(json['id']),
    email: json['email']?.toString(),
    password: json['password']?.toString(),
    date: json['date']?.toString() ?? '', // إصلاح الخطأ هنا
    is_delete: _parseInt(json['is_delete']) ?? 0,
    is_block: _parseInt(json['is_block']) ?? 0,
    max_free_posts: _parseInt(json['max_free_posts']) ?? 10,
    free_posts_used: _parseInt(json['free_posts_used']) ?? 0,
    signup_method:  json['signup_method']?.toString()?? 'email',
  );
}
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
  

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'date': date,
      'is_delete': is_delete,
      'is_block': is_block,
      'max_free_posts': max_free_posts, // القيمة كرقم مباشرة
   'free_posts_used':free_posts_used,
   'signup_method':signup_method,
    };
  }
}