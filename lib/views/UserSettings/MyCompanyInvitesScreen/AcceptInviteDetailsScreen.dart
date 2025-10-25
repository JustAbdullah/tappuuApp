import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'package:tappuu_app/core/constant/appcolors.dart';
import 'package:tappuu_app/core/constant/app_text_styles.dart';

import 'package:tappuu_app/controllers/ThemeController.dart';
import 'package:tappuu_app/controllers/CompanyInvitesController.dart';

class AcceptInviteDetailsScreen extends StatefulWidget {
  const AcceptInviteDetailsScreen({
    Key? key,
    required this.inviteId,
    required this.companyName,
    required this.roleLabel, // بالعربي: ناشر/عارض
    required this.userId,
  }) : super(key: key);

  final int inviteId;
  final String companyName;
  final String roleLabel; // نص عربي جاهز من الشاشة السابقة
  final int userId;

  @override
  State<AcceptInviteDetailsScreen> createState() => _AcceptInviteDetailsScreenState();
}

class _AcceptInviteDetailsScreenState extends State<AcceptInviteDetailsScreen> {
  final ThemeController themeC = Get.find<ThemeController>();
  final CompanyInvitesController c = Get.find<CompanyInvitesController>();

  final _formKey = GlobalKey<FormState>();
  final _displayNameCtrl = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();
  final _waPhoneCtrl = TextEditingController();
  final _waCallCtrl = TextEditingController();

  // === أفاتار العضو (اختياري) ===
  static const String _root = "https://stayinme.arabiagroup.net/lar_stayInMe/public/api";
  static const String _uploadApi = "$_root/upload";

  File? _avatarFile;
  String _uploadedAvatarUrl = ""; // ناتج /upload
  bool _uploadingAvatar = false;

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _contactPhoneCtrl.dispose();
    _waPhoneCtrl.dispose();
    _waCallCtrl.dispose();
    super.dispose();
  }

  String? _reqValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'حقل مطلوب';
    return null;
  }

  String? _phoneValidator(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final digits = v.replaceAll(RegExp(r'\D+'), '');
    if (digits.length < 7) return 'رقم غير صالح';
    return null;
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _avatarFile = File(picked.path);
        _uploadedAvatarUrl = ""; // إعادة ضبط في حال تغيير الصورة
      });
    }
  }

  void _removeAvatar() {
    setState(() {
      _avatarFile = null;
      _uploadedAvatarUrl = "";
    });
  }

  Future<void> _uploadAvatarIfNeeded() async {
    if (_avatarFile == null || _uploadedAvatarUrl.isNotEmpty) return;
    setState(() => _uploadingAvatar = true);
    try {
      final req = http.MultipartRequest('POST', Uri.parse(_uploadApi));
      req.files.add(await http.MultipartFile.fromPath('images[]', _avatarFile!.path));

      final resp = await req.send();
      final body = await resp.stream.bytesToString();

      if (resp.statusCode == 201) {
        final jsonBody = jsonDecode(body) as Map<String, dynamic>;
        final urls = List<String>.from(jsonBody['image_urls'] ?? const []);
        setState(() {
          _uploadedAvatarUrl = urls.isNotEmpty ? urls.first : "";
        });
      } else {
        Get.snackbar('فشل رفع الصورة', '(${resp.statusCode}) $body',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('خطأ في الرفع', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeC.isDarkMode.value;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background(isDark),
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: AppColors.primary),
          onPressed: () => Get.back(),
        ),
        centerTitle: true,
        title: Text(
          'إكمال البيانات',
          style: TextStyle(
            fontSize: AppTextStyles.xxxlarge,
            fontFamily: AppTextStyles.appFontFamily,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary(isDark),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderInfo(
              isDark: isDark,
              companyName: widget.companyName,
              roleLabel: widget.roleLabel,
            ),
            SizedBox(height: 16.h),

            // ======= كتلة الأفاتار الجديدة =======
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: AppColors.surface(isDark),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.textSecondary(isDark).withOpacity(.18)),
              ),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 36.r,
                        backgroundColor: AppColors.textSecondary(isDark).withOpacity(.15),
                        backgroundImage:
                            _avatarFile != null ? FileImage(_avatarFile!) : null,
                        child: _avatarFile == null
                            ? Icon(Icons.person_rounded,
                                size: 36.r, color: AppColors.textSecondary(isDark))
                            : null,
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Material(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16.r),
                          child: InkWell(
                            onTap: _pickAvatar,
                            borderRadius: BorderRadius.circular(16.r),
                            child: Padding(
                              padding: EdgeInsets.all(6.r),
                              child: Icon(Icons.edit_rounded,
                                  size: 16.r, color: AppColors.onPrimary),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('صورة العضو (اختياري)',
                            style: TextStyle(
                              fontSize: AppTextStyles.large,
                              fontFamily: AppTextStyles.appFontFamily,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary(isDark),
                            )),
                        SizedBox(height: 6.h),
                        Text(
                          'اختر صورة شخصية واضحة. بإمكانك المتابعة بدون صورة.',
                          style: TextStyle(
                            fontSize: AppTextStyles.small,
                            color: AppColors.textSecondary(isDark),
                          ),
                        ),
                        if (_avatarFile != null) ...[
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              if (_uploadingAvatar)
                                const SizedBox(
                                  height: 18, width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              if (_uploadingAvatar) SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  _avatarFile!.path.split('/').last,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: AppTextStyles.small,
                                    color: AppColors.textSecondary(isDark),
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _uploadingAvatar ? null : _removeAvatar,
                                icon: const Icon(Icons.delete_outline_rounded),
                                label: const Text('إزالة'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // ======= نموذج البيانات =======
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: AppColors.surface(isDark),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.textSecondary(isDark).withOpacity(.18)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? .18 : .08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // الاسم الظاهر
                    TextFormField(
                      controller: _displayNameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(isDark, 'الاسم الظاهر', Icons.person_rounded),
                      validator: _reqValidator,
                    ),
                    SizedBox(height: 12.h),

                    // هاتف التواصل
                    TextFormField(
                      controller: _contactPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(isDark, 'هاتف التواصل', Icons.phone_rounded),
                      validator: _phoneValidator,
                    ),
                    SizedBox(height: 12.h),

                    // واتساب (نص)
                    TextFormField(
                      controller: _waPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(isDark, 'رقم واتساب', Icons.chat_rounded),
                      validator: _phoneValidator,
                    ),
                    SizedBox(height: 12.h),

                    // واتساب للاتصال (wa.me)
                    TextFormField(
                      controller: _waCallCtrl,
                      keyboardType: TextInputType.phone,
                      decoration:
                          _inputDecoration(isDark, 'رقم واتساب للاتصال (wa.me)', Icons.call_rounded),
                      validator: _phoneValidator,
                    ),
                    SizedBox(height: 16.h),

                    Obx(() {
                      final saving = c.isSaving.value || _uploadingAvatar;
                      return SizedBox(
                        width: double.infinity,
                        height: 52.h,
                        child: ElevatedButton.icon(
                          onPressed: saving ? null : _onSubmit,
                          icon: saving
                              ? SizedBox(
                                  width: 18.w,
                                  height: 18.w,
                                  child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check_rounded),
                          label: Text(
                            saving ? 'جارِ الحفظ...' : 'تأكيد القبول',
                            style: TextStyle(
                              fontSize: AppTextStyles.xlarge,
                              fontWeight: FontWeight.w800,
                              fontFamily: AppTextStyles.appFontFamily,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                            elevation: 3,
                            shadowColor: AppColors.primary.withOpacity(.22),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(bool isDark, String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: AppColors.surface(isDark),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: AppColors.textSecondary(isDark).withOpacity(.25)),
      ),
    );
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // لو فيه صورة مختارة ولم تُرفع بعد → ارفعها أولاً لتحصل على avatar_url
    if (_avatarFile != null && _uploadedAvatarUrl.isEmpty) {
      await _uploadAvatarIfNeeded();
      if (_uploadedAvatarUrl.isEmpty) {
        // فشل الرفع
        return;
      }
    }

    final ok = await c.acceptInvite(
      inviteId: widget.inviteId,
      userId: widget.userId,
      displayName: _displayNameCtrl.text.trim(),
      contactPhone: _contactPhoneCtrl.text.trim().isEmpty ? null : _contactPhoneCtrl.text.trim(),
      whatsappPhone: _waPhoneCtrl.text.trim().isEmpty ? null : _waPhoneCtrl.text.trim(),
      whatsappCallNumber: _waCallCtrl.text.trim().isEmpty ? null : _waCallCtrl.text.trim(),
      // الجديد:
      avatarUrl: _uploadedAvatarUrl.isNotEmpty ? _uploadedAvatarUrl : null,
    );

    if (ok) {
      Get.back(); // ارجع لشاشة الدعوات
      Get.snackbar('تم القبول', 'تمت إضافة حسابك كعضو نشط في الشركة',
          snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));
    } else {
      Get.snackbar('تعذر الإكمال', 'تحقق من صحة البيانات وحاول مجدداً',
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}

class _HeaderInfo extends StatelessWidget {
  const _HeaderInfo({
    required this.isDark,
    required this.companyName,
    required this.roleLabel,
  });

  final bool isDark;
  final String companyName;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.primary.withOpacity(.16), Colors.transparent]
              : [AppColors.primary.withOpacity(.12), Colors.white],
        ),
        border: Border.all(color: AppColors.primary.withOpacity(.18), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.assignment_turned_in_rounded, color: AppColors.primary, size: 26.w),
          SizedBox(width: 10.w),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: AppTextStyles.large,
                  height: 1.35,
                  color: AppColors.textPrimary(isDark),
                  fontFamily: AppTextStyles.appFontFamily,
                ),
                children: [
                  const TextSpan(text: 'أنت على وشك قبول دعوة من شركة '),
                  TextSpan(
                    text: companyName,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const TextSpan(text: ' كـ '),
                  TextSpan(
                    text: roleLabel, // نص عربي «ناشر/عارض»
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
