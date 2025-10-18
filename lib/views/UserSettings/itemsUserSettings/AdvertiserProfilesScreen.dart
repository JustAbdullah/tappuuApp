import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tappuu_app/core/constant/app_text_styles.dart';
import 'package:tappuu_app/core/constant/appcolors.dart';
import 'package:tappuu_app/controllers/ThemeController.dart';
import 'package:tappuu_app/controllers/AdvertiserController.dart';
import '../../../controllers/LoadingController.dart';
import '../../../core/data/model/AdvertiserProfile.dart';
import '../../AdvertiserScreen/AdvertiserDataScreen.dart';
import '../../AdvertiserScreen/EditAdvertiserScreen.dart';

class AdvertiserProfilesScreen extends StatefulWidget {
  const AdvertiserProfilesScreen({Key? key}) : super(key: key);

  @override
  State<AdvertiserProfilesScreen> createState() => _AdvertiserProfilesScreenState();
}

class _AdvertiserProfilesScreenState extends State<AdvertiserProfilesScreen> {
  final ThemeController themeC = Get.find<ThemeController>();
  final AdvertiserController advC = Get.put(AdvertiserController(), permanent: true);
  final LoadingController loadingC = Get.find<LoadingController>();

  @override
  void initState() {
    super.initState();
    _fetchProfiles();
  }

  void _fetchProfiles() {
    final userId = loadingC.currentUser?.id ?? 0;
    if (userId > 0) {
      advC.fetchProfiles(userId).then((_) => advC.resetSelection());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeC.isDarkMode.value;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            advC.resetSelection();
            Get.back();
          },
        ),
        title: Text(
          'ملفات المعلنين'.tr,
          style: TextStyle(
            fontSize: AppTextStyles.xxxlarge,
            fontFamily: AppTextStyles.appFontFamily,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
        backgroundColor: AppColors.background(isDarkMode),
        elevation: 0,
        centerTitle: true,
      ),
      body: GetBuilder<AdvertiserController>(
        builder: (controller) {
          if (controller.isLoading.value) {
            return Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'ملفات المعلنين الخاصة بك'.tr,
                    style: TextStyle(
                      fontSize: AppTextStyles.xxxlarge,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTextStyles.appFontFamily,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Center(
                  child: Text(
                    'اختر ملفًا لعرض تفاصيله أو قم بإنشاء ملف جديد'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppTextStyles.large,
                      fontFamily: AppTextStyles.appFontFamily,
                      color: AppColors.textSecondary(isDarkMode),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

                // القائمة المنسدلة
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface(isDarkMode),
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                  child: _buildDropdown(controller, isDarkMode),
                ),

                SizedBox(height: 24.h),

                if (controller.selected.value != null)
                  _ProfileAndMemberCard(
                    profile: controller.selected.value!,
                    isDark: isDarkMode,
                    onEditCompany: () {
                      // تعديل الشركة (مالك فقط)
                      controller.loadProfileForEdit(controller.selected.value!);
                      Get.to(() => EditAdvertiserScreen());
                    },
                    onDeleteCompany: () async {
                      // حذف الشركة (مالك فقط)
                      final p = controller.selected.value!;
                      if (p.id == null) return;
                      final yes = await _confirm(context, isDarkMode,
                          title: 'تأكيد الحذف',
                          message: 'هل أنت متأكد أنك تريد حذف هذا الملف؟');
                      if (yes == true) {
                        await controller.deleteProfile(p.id!);
                      }
                    },
                    onEditMember: (member) async {
                      // فتح فورم تعديل بيانات العضو (غير المالك)
                      await _openMemberEditSheet(context, isDarkMode, member);
                    },
                    onLeaveCompany: (member) async {
                      // مغادرة الشركة (تغيير status=removed)
                      final yes = await _confirm(context, isDarkMode,
                          title: 'مغادرة الشركة',
                          message: 'هل تريد بالتأكيد مغادرة هذه الشركة؟');
                      if (yes == true) {
                        final userId = loadingC.currentUser?.id ?? 0;
                        await advC.removeMyCompanyMembership(
                          companyId: member.advertiserProfileId!,
                          memberId: member.id!,
                          actorUserId: userId,
                        );
                        // حدّث القوائم
                        _fetchProfiles();
                      }
                    },
                  ),

                SizedBox(height: 24.h),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      advC.resetSelection();
                      Get.to(() => AdvertiserDataScreen());
                    },
                    icon: Icon(Icons.add, size: 22.w),
                    label: Text(
                      'إنشاء ملف جديد'.tr,
                      style: TextStyle(
                        fontSize: AppTextStyles.xlarge,
                        fontFamily: AppTextStyles.appFontFamily,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDropdown(AdvertiserController controller, bool isDarkMode) {
    if (controller.profiles.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Text(
          'لا توجد ملفات متاحة'.tr,
          style: TextStyle(
            fontSize: AppTextStyles.large,
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.textSecondary(isDarkMode),
          ),
        ),
      );
    }

    return DropdownButton<AdvertiserProfile>(
      isExpanded: true,
      value: controller.selected.value,
      underline: const SizedBox(),
      dropdownColor: AppColors.surface(isDarkMode),
      icon: Icon(Icons.arrow_drop_down, color: AppColors.textPrimary(isDarkMode)),
      iconSize: 28.w,
      hint: Text(
        'اختر ملف المعلن'.tr,
        style: TextStyle(
          fontSize: AppTextStyles.large,
          fontFamily: AppTextStyles.appFontFamily,
          color: AppColors.textSecondary(isDarkMode),
        ),
      ),
      items: controller.profiles.map((profile) {
        final title = profile.name ??
            profile.description ??
            '${'ملف بدون وصف (ID:'.tr} ${profile.id})';
        return DropdownMenuItem<AdvertiserProfile>(
          value: profile,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: AppTextStyles.large,
              fontFamily: AppTextStyles.appFontFamily,
              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
        );
      }).toList(),
      onChanged: (AdvertiserProfile? newValue) {
        controller.selected.value = newValue;
        controller.update();
      },
    );
  }

  Future<bool?> _confirm(BuildContext ctx, bool isDarkMode,
      {required String title, required String message}) {
    return showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface(isDarkMode),
        title: Text(title,
            style: TextStyle(
              color: AppColors.textPrimary(isDarkMode),
              fontFamily: AppTextStyles.appFontFamily,
              fontWeight: FontWeight.w800,
            )),
        content: Text(message,
            style: TextStyle(
              color: AppColors.textSecondary(isDarkMode),
              fontFamily: AppTextStyles.appFontFamily,
            )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: TextStyle(color: AppColors.textSecondary(isDarkMode))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  Future<void> _openMemberEditSheet(BuildContext context, bool isDark, CompanyMemberLite member) async {
    final nameCtrl = TextEditingController(text: member.displayName ?? '');
    final phoneCtrl = TextEditingController(text: member.contactPhone ?? '');
    final waCtrl = TextEditingController(text: member.whatsappPhone ?? '');
    final waCallCtrl = TextEditingController(text: member.whatsappCallNumber ?? '');
    final formKey = GlobalKey<FormState>();
    final userId = loadingC.currentUser?.id ?? 0;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface(isDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16.w, right: 16.w,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
          top: 16.h,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(height: 4, width: 44, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(4))),
              SizedBox(height: 12.h),
              Text('تعديل بياناتي كعضو', style: TextStyle(fontSize: AppTextStyles.xlarge, fontWeight: FontWeight.w800)),
              SizedBox(height: 12.h),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'الاسم الظاهر', prefixIcon: Icon(Icons.person)),
                validator: (v)=> v==null||v.trim().isEmpty ? 'حقل مطلوب' : null,
              ),
              SizedBox(height: 10.h),
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'هاتف التواصل', prefixIcon: Icon(Icons.phone)),
              ),
              SizedBox(height: 10.h),
              TextFormField(
                controller: waCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'رقم واتساب', prefixIcon: Icon(Icons.chat)),
              ),
              SizedBox(height: 10.h),
              TextFormField(
                controller: waCallCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'واتساب (للاتصال wa.me)', prefixIcon: Icon(Icons.call)),
              ),
              SizedBox(height: 14.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ'),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    await advC.updateMyCompanyMembership(
                      companyId: member.advertiserProfileId!,
                      memberId: member.id!,
                      actorUserId: userId,
                      displayName: nameCtrl.text.trim(),
                      contactPhone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                      whatsappPhone: waCtrl.text.trim().isEmpty ? null : waCtrl.text.trim(),
                      whatsappCallNumber: waCallCtrl.text.trim().isEmpty ? null : waCallCtrl.text.trim(),
                    );
                    Navigator.pop(context);
                    _fetchProfiles();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// كرت موحّد: يعرض الشركة أولاً ثم بيانات العضو (إن وُجد) ويقيّد الأزرار حسب الدور
class _ProfileAndMemberCard extends StatelessWidget {
  const _ProfileAndMemberCard({
    required this.profile,
    required this.isDark,
    required this.onEditCompany,
    required this.onDeleteCompany,
    required this.onEditMember,
    required this.onLeaveCompany,
  });

  final AdvertiserProfile profile;
  final bool isDark;
  final VoidCallback onEditCompany;
  final VoidCallback onDeleteCompany;
  final void Function(CompanyMemberLite member) onEditMember;
  final void Function(CompanyMemberLite member) onLeaveCompany;

  @override
  Widget build(BuildContext context) {
    final isCompany = (profile.accountType == 'company');
    final isOwner = (profile.isOwner ?? false);
    final member = profile.companyMember; // CompanyMemberLite? (قد يكون null)

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0,6))],
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======= الشركة =======
          Row(
            children: [
              CircleAvatar(
                radius: 22.w,
                backgroundColor: isCompany ? Colors.blue.withOpacity(.1) : Colors.green.withOpacity(.1),
                child: Icon(isCompany ? Icons.apartment : Icons.person, color: isCompany ? Colors.blue : Colors.green),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  profile.name ?? 'بدون اسم',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: AppTextStyles.xxlarge, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: (isCompany ? Colors.blue : Colors.green)[700],
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(isCompany ? 'شركة' : 'فردي', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if ((profile.description ?? '').isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(profile.description!, style: TextStyle(fontSize: AppTextStyles.large, color: AppColors.textPrimary(isDark))),
          ],
          SizedBox(height: 12.h),
          _info(icon: Icons.phone, label: 'رقم الاتصال', value: profile.contactPhone ?? 'غير محدد', isDark: isDark),
          _info(icon: Icons.chat, label: 'واتساب', value: profile.whatsappPhone ?? 'غير محدد', isDark: isDark),
          _info(icon: Icons.call, label: 'واتساب للاتصال', value: profile.whatsappCallNumber ?? 'غير محدد', isDark: isDark),

          SizedBox(height: 14.h),
          Divider(color: AppColors.textSecondary(isDark).withOpacity(.15)),
          SizedBox(height: 8.h),

          // ======= أزرار الشركة (مالك فقط) / الفردي (مالك فقط) =======
          if (profile.isOwner == true) _ownerCompanyActions(context) else const SizedBox.shrink(),

          // ======= بيانات العضو (لو شركة و المستخدم عضو) =======
          if (isCompany && member != null) ...[
            SizedBox(height: 16.h),
            Text('بياناتي كعضو في الشركة', style: TextStyle(fontSize: AppTextStyles.xlarge, fontWeight: FontWeight.w800, color: AppColors.textPrimary(isDark))),
            SizedBox(height: 8.h),
            _info(icon: Icons.badge, label: 'الدور', value: _roleAr(member.role), isDark: isDark),
            _info(icon: Icons.person, label: 'الاسم الظاهر', value: member.displayName ?? 'غير محدد', isDark: isDark),
            _info(icon: Icons.phone, label: 'هاتف التواصل', value: member.contactPhone ?? 'غير محدد', isDark: isDark),
            _info(icon: Icons.chat, label: 'واتساب', value: member.whatsappPhone ?? 'غير محدد', isDark: isDark),
            _info(icon: Icons.call, label: 'واتساب للاتصال', value: member.whatsappCallNumber ?? 'غير محدد', isDark: isDark),

            SizedBox(height: 10.h),

            // أزرار العضو: لو مالك ⇠ غالبًا ما يحتاجها، لكن نُظهرها فقط لغير المالك
            if (!(isOwner)) Wrap(
              spacing: 8.w, runSpacing: 8.h, alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => onLeaveCompany(member),
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text('مغادرة الشركة'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[700],
                    side: BorderSide(color: Colors.red[700]!),
                    minimumSize: Size(120.w, 40.h),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => onEditMember(member),
                  icon: const Icon(Icons.edit),
                  label: const Text('تعديل بياناتي'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    minimumSize: Size(140.w, 40.h),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _ownerCompanyActions(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Wrap(
        spacing: 8.w,
        children: [
          OutlinedButton.icon(
            onPressed: onDeleteCompany,
            icon: const Icon(Icons.delete),
            label: const Text('حذف الملف'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red[700],
              side: BorderSide(color: Colors.red[700]!),
              minimumSize: Size(120.w, 40.h),
            ),
          ),
          ElevatedButton.icon(
            onPressed: onEditCompany,
            icon: const Icon(Icons.edit),
            label: const Text('تعديل الشركة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.yellow,
              foregroundColor: AppColors.onSecondary,
              minimumSize: Size(140.w, 40.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _info({required IconData icon, required String label, required String value, required bool isDark}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Icon(icon, size: 18.w, color: AppColors.primary),
          SizedBox(width: 8.w),
          Text('$label: ', style: TextStyle(fontSize: AppTextStyles.medium, color: AppColors.textSecondary(isDark))),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.start,
              style: TextStyle(fontSize: AppTextStyles.medium, color: AppColors.textPrimary(isDark), fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _roleAr(String? role) {
    switch ((role ?? '').toLowerCase()) {
      case 'owner': return 'مالك';
      case 'publisher': return 'ناشر';
      case 'viewer': return 'عارض';
      default: return role ?? 'غير محدد';
    }
  }
}
