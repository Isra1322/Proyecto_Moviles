class ApiResponseModel<T> {
  final bool success;
  final String? message;
  final T? data;

  const ApiResponseModel({
    required this.success,
    this.message,
    this.data,
  });

  factory ApiResponseModel.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    return ApiResponseModel<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
    );
  }
}

