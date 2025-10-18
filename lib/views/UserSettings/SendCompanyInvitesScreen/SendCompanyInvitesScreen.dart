import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tappuu_app/core/constant/appcolors.dart';
import 'package:tappuu_app/core/constant/app_text_styles.dart';

import 'package:tappuu_app/controllers/ThemeController.dart';
import 'package:tappuu_app/controllers/CompanyInvitesController.dart';
import 'package:tappuu_app/controllers/LoadingController.dart';

import 'package:tappuu_app/core/data/model/company_invite.dart';
import 'package:tappuu_app/core/data/model/CompanySummary.dart';

class SendCompanyInvitesScreen extends StatefulWidget {
  const SendCompanyInvitesScreen({Key? key}) : super(key: key);

  @override
  State<SendCompanyInvitesScreen> createState() => _SendCompanyInvitesScreenState();
}

class _SendCompanyInvitesScreenState extends State<SendCompanyInvitesScreen> {
  final ThemeController themeC = Get.find<ThemeController>();
  final LoadingController loadingC = Get.find<LoadingController>();
  final CompanyInvitesController c = Get.put(CompanyInvitesController());

  final _emailCtrl = TextEditingController();
  final _emailNode = FocusNode();

  // الدور المختار
  final RxString _role = 'publisher'.obs;

  // الشركة المختارة
  final Rxn<CompanySummary> _selectedCompany = Rxn<CompanySummary>();

  // نجعل الإيميل Rx حتى أي تغيير يعيد بناء واجهة الزر
  final RxString _email = ''.obs;

  @override
  void initState() {
    super.initState();

    // اسمع تغيّر الإيميل (lowercase + trim)
    _emailCtrl.addListener(() {
      _email.value = _emailCtrl.text.trim().toLowerCase();
    });

    // حمّل الشركات ثم اضبط المختارة بأمان
    final userId = loadingC.currentUser?.id ?? 0;
    Future.microtask(() async {
      await c.fetchMyCompanies(userId: userId, scope: 'owner');
      if (c.myCompanies.isNotEmpty) {
        // اختر أول شركة فقط إذا لم يُعيّن شيء بعد
        _selectedCompany.value ??= c.myCompanies.first;
        // حمّل دعوات الشركة المختارة
        await c.fetchCompanyInvites(_selectedCompany.value!.id);
      }
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _emailNode.dispose();
    super.dispose();
  }

  bool _isValidEmail(String v) {
    final s = v.trim().toLowerCase();
    // تحقق بسيط وخفيف
    return s.contains('@') && s.contains('.') && s.length >= 6;
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
          'دعوات الشركة'.tr,
          style: TextStyle(
            fontSize: AppTextStyles.xxxlarge,
            fontFamily: AppTextStyles.appFontFamily,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary(isDark),
          ),
        ),
      ),
      body: Obx(() {
        // احتسب جاهزية الإرسال بشكل تفاعلي
        final canSend = _selectedCompany.value != null &&
            _isValidEmail(_email.value) &&
            !c.isSaving.value;

        return RefreshIndicator(
          onRefresh: () async {
            final userId = loadingC.currentUser?.id ?? 0;
            await c.fetchMyCompanies(userId: userId, scope: 'owner');

            // حافظ على الشركة المختارة إن وُجدت، وإن اختفت اختر الأولى
            if (_selectedCompany.value != null) {
              final exist = c.myCompanies.any((x) => x.id == _selectedCompany.value!.id);
              if (!exist && c.myCompanies.isNotEmpty) {
                _selectedCompany.value = c.myCompanies.first;
              }
            } else if (c.myCompanies.isNotEmpty) {
              _selectedCompany.value = c.myCompanies.first;
            }

            if (_selectedCompany.value != null) {
              await c.fetchCompanyInvites(_selectedCompany.value!.id);
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderInfo(isDark: isDark),
                SizedBox(height: 16.h),

                _CompanyPicker(
                  isDark: isDark,
                  selected: _selectedCompany,
                  companies: c.myCompanies,
                  onChanged: (co) async {
                    _selectedCompany.value = co;
                    if (co != null) {
                      await c.fetchCompanyInvites(co.id);
                    }
                  },
                ),

                SizedBox(height: 18.h),

                // بطاقة نموذج الدعوة
                _InviteFormCard(
                  isDark: isDark,
                  role: _role,
                  emailCtrl: _emailCtrl,
                  onRoleChanged: (r) => _role.value = r,
                  // onSend: نُحدّث داخل Obx لنضمن آخر حالة
                  onSend: canSend
                      ? () async {
                          final company = _selectedCompany.value;
                          if (company == null) return;
                          final userId = loadingC.currentUser?.id ?? 0;

                          final ok = await c.createInvite(
                            companyId: company.id,
                            inviterUserId: userId,
                            inviteeEmail: _email.value, // مُطبّع
                            role: _role.value,
                          );

                          if (ok) {
                            _emailCtrl.clear();
                            _emailNode.unfocus();
                            Get.snackbar('تم الإرسال'.tr, 'تم إرسال الدعوة بنجاح'.tr,
                                snackPosition: SnackPosition.BOTTOM,
                                duration: const Duration(seconds: 2));
                          } else {
                            Get.snackbar('تعذّر الإرسال'.tr, 'تحقق من صحة البريد والصلاحيات'.tr,
                                snackPosition: SnackPosition.BOTTOM);
                          }
                        }
                      : null,
                  isSending: c.isSaving.value,
                  canSend: canSend,
                  emailFocusNode: _emailNode,
                ),

                SizedBox(height: 20.h),

                _SectionTitle(
                  isDark: isDark,
                  title: 'دعوات الشركة الحالية'.tr,
                  trailing: _selectedCompany.value != null
                      ? Text(
                          '#${_selectedCompany.value!.id}',
                          style: TextStyle(
                            fontSize: AppTextStyles.medium,
                            color: AppColors.textSecondary(isDark),
                            fontFamily: AppTextStyles.appFontFamily,
                          ),
                        )
                      : null,
                ),
                SizedBox(height: 10.h),

                if (_selectedCompany.value == null)
                  _EmptyHint(isDark: isDark, text: 'اختر شركة أولاً'.tr)
                else if (c.isLoading.value && c.invites.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 24.h),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else if (c.invites.isEmpty)
                  _EmptyHint(isDark: isDark, text: 'لا توجد دعوات بعد'.tr)
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: c.invites.length,
                    separatorBuilder: (_, __) => SizedBox(height: 10.h),
                    itemBuilder: (_, i) => _InviteCard(
                      isDark: isDark,
                      invite: c.invites[i],
                      onChangeRole: (newRole) async {
                        final company = _selectedCompany.value!;
                        final userId = loadingC.currentUser?.id ?? 0;
                        final ok = await c.updateInvite(
                          companyId: company.id,
                          inviteId: c.invites[i].id!,
                          actorUserId: userId,
                          role: newRole,
                        );
                        if (!ok) {
                          Get.snackbar('لم يتم التعديل'.tr, 'تحقق من صلاحياتك'.tr,
                              snackPosition: SnackPosition.BOTTOM);
                        }
                      },
                      onCancel: () async {
                        final company = _selectedCompany.value!;
                        final userId = loadingC.currentUser?.id ?? 0;
                        final ok = await c.deleteInvite(
                          companyId: company.id,
                          inviteId: c.invites[i].id!,
                          actorUserId: userId,
                        );
                        if (!ok) {
                          Get.snackbar('تعذّر الإلغاء'.tr, 'حاول مجدداً'.tr,
                              snackPosition: SnackPosition.BOTTOM);
                        }
                      },
                    ),
                  ),
                SizedBox(height: 30.h),
              ],
            ),
          ),
        );
      }),
    );
  }
}

/* ================== Widgets ================== */

class _HeaderInfo extends StatelessWidget {
  const _HeaderInfo({required this.isDark});
  final bool isDark;

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
              : [AppColors.primary.withOpacity(.10), Colors.white],
        ),
        border: Border.all(color: AppColors.primary.withOpacity(.18), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.group_add_rounded, color: AppColors.primary, size: 26.w),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'أرسل دعوات الانضمام إلى شركتك وحدد دور المدعو'.tr,
              style: TextStyle(
                fontSize: AppTextStyles.large,
                height: 1.35,
                color: AppColors.textPrimary(isDark),
                fontFamily: AppTextStyles.appFontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyPicker extends StatelessWidget {
  const _CompanyPicker({
    required this.isDark,
    required this.selected,
    required this.companies,
    required this.onChanged,
  });

  final bool isDark;
  final Rxn<CompanySummary> selected;
  final List<CompanySummary> companies;
  final ValueChanged<CompanySummary?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasValue = selected.value != null && companies.any((e) => e.id == selected.value!.id);
      final value = hasValue ? selected.value : null;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اختر الشركة'.tr,
            style: TextStyle(
              fontSize: AppTextStyles.xlarge,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(isDark),
              fontFamily: AppTextStyles.appFontFamily,
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: AppColors.surface(isDark),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AppColors.textSecondary(isDark).withOpacity(.25)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<CompanySummary>(
                isExpanded: true,
                value: value,
                hint: Text(
                  companies.isEmpty ? 'لا توجد شركات'.tr : 'اختر...'.tr,
                  style: TextStyle(
                    color: AppColors.textSecondary(isDark),
                    fontFamily: AppTextStyles.appFontFamily,
                  ),
                ),
                items: companies.map((co) {
                  return DropdownMenuItem<CompanySummary>(
                    value: co,
                    child: Row(
                      children: [
                        _CompanyAvatar(url: co.logo),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(co.name ?? 'بدون اسم',
                                  style: TextStyle(
                                    fontSize: AppTextStyles.large,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary(isDark),
                                    fontFamily: AppTextStyles.appFontFamily,
                                  )),
                              SizedBox(height: 2.h),
                              Text(
                                'أعضاء: ${co.membersCount} • دعوات معلّقة: ${co.pendingInvitesCount}',
                                style: TextStyle(
                                  fontSize: AppTextStyles.small,
                                  color: AppColors.textSecondary(isDark),
                                  fontFamily: AppTextStyles.appFontFamily,
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _CompanyAvatar extends StatelessWidget {
  const _CompanyAvatar({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18.w,
      backgroundColor: Colors.black12,
      backgroundImage: (url != null && url!.isNotEmpty) ? NetworkImage(url!) : null,
      child: (url == null || url!.isEmpty)
          ? Icon(Icons.apartment_rounded, size: 18.w, color: Colors.white)
          : null,
    );
  }
}

class _InviteFormCard extends StatelessWidget {
  const _InviteFormCard({
    required this.isDark,
    required this.role,
    required this.emailCtrl,
    required this.onRoleChanged,
    required this.onSend,
    required this.isSending,
    required this.canSend,
    required this.emailFocusNode,
  });

  final bool isDark;
  final RxString role;
  final TextEditingController emailCtrl;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback? onSend;
  final bool isSending;
  final bool canSend;
  final FocusNode emailFocusNode;

  @override
  Widget build(BuildContext context) {
    final btnColor = canSend ? Colors.amber : AppColors.textSecondary(isDark).withOpacity(.25);
    final btnFg = canSend ? Colors.black : AppColors.textSecondary(isDark);

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('تفاصيل الدعوة'.tr,
              style: TextStyle(
                fontSize: AppTextStyles.xlarge,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary(isDark),
                fontFamily: AppTextStyles.appFontFamily,
              )),
          SizedBox(height: 12.h),

          // البريد
          TextFormField(
            controller: emailCtrl,
            focusNode: emailFocusNode,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.send,
            onFieldSubmitted: (_) {
              if (onSend != null) onSend!();
            },
            decoration: InputDecoration(
              labelText: 'بريد المدعو'.tr,
              prefixIcon: const Icon(Icons.alternate_email_rounded),
              filled: true,
              fillColor: AppColors.surface(isDark),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.textSecondary(isDark).withOpacity(.25)),
              ),
            ),
            style: TextStyle(
              fontSize: AppTextStyles.large,
              color: AppColors.textPrimary(isDark),
              fontFamily: AppTextStyles.appFontFamily,
            ),
          ),

          SizedBox(height: 12.h),

          // اختيار الدور
          Text('الدور'.tr,
              style: TextStyle(
                fontSize: AppTextStyles.large,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(isDark),
                fontFamily: AppTextStyles.appFontFamily,
              )),
          SizedBox(height: 8.h),
          Obx(() {
            return Row(
              children: [
                _RoleChip(
                  label: 'ناشر'.tr,
                  selected: role.value == 'publisher',
                  icon: Icons.campaign_rounded,
                  onTap: () => onRoleChanged('publisher'),
                ),
                SizedBox(width: 10.w),
              
              ],
            );
          }),

          SizedBox(height: 14.h),
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton.icon(
              onPressed: canSend ? onSend : null,
              icon: isSending
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                isSending ? 'جار الإرسال...'.tr : 'إرسال الدعوة'.tr,
                style: TextStyle(
                  fontSize: AppTextStyles.xlarge,
                  fontWeight: FontWeight.w800,
                  fontFamily: AppTextStyles.appFontFamily,
                  color: canSend ? btnFg : AppColors.onPrimary.withOpacity(.6),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: btnColor,
                foregroundColor: btnFg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                elevation: canSend ? 2 : 0,
                shadowColor: Colors.black12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: selected ? Colors.deepPurple : Colors.deepPurple.withOpacity(.08),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.deepPurple.withOpacity(selected ? .0 : .25)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18.w, color: selected ? Colors.white : Colors.deepPurple),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: AppTextStyles.medium,
                color: selected ? Colors.white : Colors.deepPurple,
                fontFamily: AppTextStyles.appFontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.isDark, required this.title, this.trailing});
  final bool isDark;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: TextStyle(
              fontSize: AppTextStyles.xlarge,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary(isDark),
              fontFamily: AppTextStyles.appFontFamily,
            )),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.isDark,
    required this.invite,
    required this.onChangeRole,
    required this.onCancel,
  });

  final bool isDark;
  final CompanyInvite invite;
  final ValueChanged<String> onChangeRole;
  final VoidCallback onCancel;

  Color _statusColor(String? s) {
    switch (s) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.redAccent;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = invite.status != 'pending';

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.textSecondary(isDark).withOpacity(.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 18.w,
            backgroundColor: Colors.indigo.withOpacity(.15),
            child: Icon(Icons.mail_outline_rounded, color: Colors.indigo, size: 18.w),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // البريد + الحالة
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        invite.inviteeEmail ?? '',
                        style: TextStyle(
                          fontSize: AppTextStyles.large,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary(isDark),
                          fontFamily: AppTextStyles.appFontFamily,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: _statusColor(invite.status).withOpacity(.12),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: _statusColor(invite.status).withOpacity(.5)),
                      ),
                      child: Text(
                        (invite.status ?? 'pending').tr,
                        style: TextStyle(
                          fontSize: AppTextStyles.small,
                          color: _statusColor(invite.status),
                          fontWeight: FontWeight.w800,
                          fontFamily: AppTextStyles.appFontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                // الدور
                Row(
                  children: [
                    Icon(Icons.badge_rounded, size: 16.w, color: AppColors.textSecondary(isDark)),
                    SizedBox(width: 6.w),
                    Text(
                      (invite.role == 'viewer' ? 'عارض' : 'ناشر').tr,
                      style: TextStyle(
                        fontSize: AppTextStyles.medium,
                        color: AppColors.textSecondary(isDark),
                        fontFamily: AppTextStyles.appFontFamily,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),

          // إجراءات
          PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz, color: AppColors.textSecondary(isDark)),
            onSelected: (val) async {
              if (val == 'publisher' || val == 'viewer') {
                if (disabled) {
                  Get.snackbar('غير متاح'.tr, 'لا يمكن تعديل دعوة منتهية'.tr,
                      snackPosition: SnackPosition.BOTTOM);
                  return;
                }
                onChangeRole(val);
              } else if (val == 'cancel') {
                onCancel();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                value: 'publisher',
                child: Row(
                  children: [
                    const Icon(Icons.campaign_rounded),
                    SizedBox(width: 8.w),
                    Text('تحويل إلى ناشر'.tr),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'viewer',
                child: Row(
                  children: [
                    const Icon(Icons.visibility_rounded),
                    SizedBox(width: 8.w),
                    Text('تحويل إلى عارض'.tr),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'cancel',
                child: Row(
                  children: [
                    const Icon(Icons.close_rounded, color: Colors.redAccent),
                    SizedBox(width: 8.w),
                    Text('إلغاء الدعوة'.tr,
                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.isDark, required this.text});
  final bool isDark;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.textSecondary(isDark).withOpacity(.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.textSecondary(isDark)),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: AppTextStyles.large,
                color: AppColors.textSecondary(isDark),
                fontFamily: AppTextStyles.appFontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
