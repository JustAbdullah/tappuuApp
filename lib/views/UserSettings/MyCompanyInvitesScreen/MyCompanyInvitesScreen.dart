import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tappuu_app/core/constant/appcolors.dart';
import 'package:tappuu_app/core/constant/app_text_styles.dart';

import 'package:tappuu_app/controllers/ThemeController.dart';
import 'package:tappuu_app/controllers/CompanyInvitesController.dart';
import 'package:tappuu_app/controllers/LoadingController.dart';

import 'AcceptInviteDetailsScreen.dart';
import 'package:tappuu_app/core/data/model/company_invite.dart';

class MyCompanyInvitesScreen extends StatefulWidget {
  const MyCompanyInvitesScreen({Key? key}) : super(key: key);

  @override
  State<MyCompanyInvitesScreen> createState() => _MyCompanyInvitesScreenState();
}

class _MyCompanyInvitesScreenState extends State<MyCompanyInvitesScreen> {
  final ThemeController themeC = Get.find<ThemeController>();
  final LoadingController loadingC = Get.find<LoadingController>();
  final CompanyInvitesController c = Get.put(CompanyInvitesController());

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final userId = loadingC.currentUser?.id ?? 0;
      await c.fetchMyInvites(userId: userId); // افتراضيًا pending
    });
  }

  // تعريب حالة الدعوة
  String _statusAr(String? s) {
    switch ((s ?? 'pending').toLowerCase()) {
      case 'accepted':
        return 'مقبولة';
      case 'rejected':
        return 'مرفوضة';
      default:
        return 'معلّقة';
    }
  }

  // لون حالة الدعوة
  Color _statusColor(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.redAccent;
      default:
        return Colors.orange;
    }
  }

  // تعريب الدور
  String _roleLabel(String? r) {
    switch ((r ?? 'publisher').toLowerCase()) {
      case 'viewer':
        return 'عارض';
      default:
        return 'ناشر';
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
          icon: Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Get.back(),
        ),
        centerTitle: true,
        title: Text(
          'دعواتي',
          style: TextStyle(
            fontSize: AppTextStyles.xxxlarge,
            fontFamily: AppTextStyles.appFontFamily,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary(isDark),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list_rounded, color: AppColors.textPrimary(isDark)),
            onSelected: (v) async {
              final userId = loadingC.currentUser?.id ?? 0;
              await c.fetchMyInvites(userId: userId, status: v == 'any' ? null : v);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'pending', child: Text('معلّقة')),
              PopupMenuItem(value: 'accepted', child: Text('مقبولة')),
              PopupMenuItem(value: 'rejected', child: Text('مرفوضة')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'any', child: Text('الكل')),
            ],
          ),
          SizedBox(width: 6.w),
        ],
      ),
      body: Obx(() {
        return RefreshIndicator(
          onRefresh: () async {
            final userId = loadingC.currentUser?.id ?? 0;
            await c.fetchMyInvites(userId: userId);
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: c.isLoading.value && c.myInvitesList.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 30.h),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                : c.myInvitesList.isEmpty
                    ? _EmptyState(isDark: isDark)
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: c.myInvitesList.length,
                        separatorBuilder: (_, __) => SizedBox(height: 10.h),
                        itemBuilder: (_, i) {
                          final CompanyInvite invite = c.myInvitesList[i];
                          final isPending = (invite.status).toLowerCase() == 'pending';

                          return Card(
                            elevation: 0,
                            color: AppColors.surface(isDark),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              side: BorderSide(color: AppColors.textSecondary(isDark).withOpacity(.18)),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(12.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ========== Header: اسم الشركة + شارة الحالة ==========
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18.w,
                                        backgroundColor: Colors.indigo.withOpacity(.12),
                                        child: Icon(Icons.apartment_rounded, color: Colors.indigo, size: 18.w),
                                      ),
                                      SizedBox(width: 10.w),
                                      Expanded(
                                        child: Text(
                                          invite.companyName ?? 'شركة',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: AppTextStyles.large,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary(isDark),
                                            fontFamily: AppTextStyles.appFontFamily,
                                          ),
                                        ),
                                      ),
                                      _StatusChip(
                                        label: _statusAr(invite.status),
                                        color: _statusColor(invite.status),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 8.h),
                                  Divider(height: 1, color: AppColors.textSecondary(isDark).withOpacity(.12)),
                                  SizedBox(height: 8.h),

                                  // ========== Info: الدور + التاريخ ==========
                                  Row(
                                    children: [
                                      Icon(Icons.badge_rounded,
                                          size: 16.w, color: AppColors.textSecondary(isDark)),
                                      SizedBox(width: 6.w),
                                      Text(
                                        _roleLabel(invite.role),
                                        style: TextStyle(
                                          fontSize: AppTextStyles.medium,
                                          color: AppColors.textSecondary(isDark),
                                          fontFamily: AppTextStyles.appFontFamily,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (invite.createdAt != null)
                                        Row(
                                          children: [
                                            Icon(Icons.schedule_rounded,
                                                size: 15.w, color: AppColors.textSecondary(isDark)),
                                            SizedBox(width: 4.w),
                                            Text(
                                              invite.createdAt!.toString().split('.').first,
                                              style: TextStyle(
                                                fontSize: AppTextStyles.small,
                                                color: AppColors.textSecondary(isDark),
                                                fontFamily: AppTextStyles.appFontFamily,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),

                                  SizedBox(height: 10.h),

                                  // ========== Actions: أسفل الكرت بدون تراكب ==========
                                  if (isPending)
                                    Wrap(
                                      alignment: WrapAlignment.end,
                                      spacing: 8.w,
                                      runSpacing: 8.h,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () async {
                                            final userId = loadingC.currentUser?.id ?? 0;
                                            final yes = await _confirmReject(context, isDark: isDark);
                                            if (yes != true) return;
                                            final ok = await c.rejectInvite(inviteId: invite.id, userId: userId);
                                            if (!ok) {
                                              Get.snackbar('لم يتم الرفض', 'حاول مجدداً',
                                                  snackPosition: SnackPosition.BOTTOM);
                                            } else {
                                              await c.fetchMyInvites(userId: userId);
                                            }
                                          },
                                          icon: const Icon(Icons.close_rounded),
                                          label: const Text('رفض'),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: Colors.redAccent),
                                            foregroundColor: Colors.redAccent,
                                            minimumSize: Size(110.w, 40.h),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10.r),
                                            ),
                                          ),
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            final userId = loadingC.currentUser?.id ?? 0;
                                            await Get.to(() => AcceptInviteDetailsScreen(
                                                  inviteId: invite.id,
                                                  companyName: invite.companyName ?? 'شركة',
                                                  roleLabel: _roleLabel(invite.role),
                                                  userId: userId,
                                                ));
                                            await c.fetchMyInvites(userId: userId);
                                          },
                                          icon: const Icon(Icons.check_circle_outline_rounded),
                                          label: const Text('قبول'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            minimumSize: Size(110.w, 40.h),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10.r),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Align(
                                      alignment: AlignmentDirectional.centerEnd,
                                      child: Text(
                                        'تمت معالجة هذه الدعوة',
                                        style: TextStyle(
                                          fontSize: AppTextStyles.small,
                                          color: AppColors.textSecondary(isDark),
                                          fontFamily: AppTextStyles.appFontFamily,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        );
      }),
    );
  }

  Future<bool?> _confirmReject(BuildContext context, {required bool isDark}) async {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface(isDark),
        title: Text('رفض الدعوة؟',
            style: TextStyle(
              color: AppColors.textPrimary(isDark),
              fontFamily: AppTextStyles.appFontFamily,
              fontWeight: FontWeight.w800,
            )),
        content: Text('هل تريد بالتأكيد رفض هذه الدعوة؟',
            style: TextStyle(
              color: AppColors.textSecondary(isDark),
              fontFamily: AppTextStyles.appFontFamily,
            )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('تراجع'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppTextStyles.small,
          color: color,
          fontWeight: FontWeight.w800,
          fontFamily: AppTextStyles.appFontFamily,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: 40.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.surface(isDark),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.textSecondary(isDark).withOpacity(.18)),
          ),
          child: Row(
            children: [
              Icon(Icons.mail_outline_rounded, color: AppColors.textSecondary(isDark)),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'لا توجد دعوات حالياً',
                  style: TextStyle(
                    fontSize: AppTextStyles.large,
                    color: AppColors.textSecondary(isDark),
                    fontFamily: AppTextStyles.appFontFamily,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
