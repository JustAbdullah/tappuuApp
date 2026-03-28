import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:tappuu_app/controllers/ChatController.dart';
import 'package:tappuu_app/controllers/LoadingController.dart';
import 'package:tappuu_app/controllers/ThemeController.dart';
import 'package:tappuu_app/core/constant/appcolors.dart';
import 'package:tappuu_app/core/constant/app_text_styles.dart';
import 'package:tappuu_app/core/data/model/conversation.dart' as con;
import 'package:tappuu_app/core/data/model/AdvertiserProfile.dart';

import 'ConversationScreenInMy.dart';

class ConversationsListScreen extends StatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  State<ConversationsListScreen> createState() =>
      _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  final ChatController _chatController = Get.put(ChatController());
  final LoadingController _loadingController = Get.find<LoadingController>();
  final ThemeController _themeController = Get.find<ThemeController>();

  // لون باهت للتاريخ
  static const _dateFaded = Color(0xFF9AA0A6);

  // أبعاد صورة الإعلان (مستطيل: العرض > الارتفاع)
  static const double _thumbWidth = 110.0;
  static const double _thumbHeight = 70.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _loadConversations());
  }

  void _loadConversations() {
    final currentUser = _loadingController.currentUser;
    if (currentUser != null) {
      _chatController.fetchConversations(
        userId: currentUser.id ?? 0,
        type: 'all',
      );
    }
  }

  // قص نص
  String _truncateText(String text, {int maxLength = 80}) {
    if (text.isEmpty) return text;
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  // تنسيق تاريخ بسيط dd/MM/yyyy
  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$d/$m/$y';
  }

  // محاولة جلب صورة للإعلان
  String? _resolveAdImageUrl(con.Ad? ad) {
    if (ad == null) return null;
    try {
      final imgs = (ad.images as List?)?.cast();
      if (imgs != null && imgs.isNotEmpty) {
        final first = imgs.first;
        if (first is String && first.isNotEmpty) return first;
        if (first is Map &&
            (first['url'] is String) &&
            first['url'].toString().isNotEmpty) {
          return first['url'].toString();
        }
      }
    } catch (_) {}
    try {
      final url = (ad as dynamic).imageUrl;
      if (url is String && url.isNotEmpty) return url;
    } catch (_) {}
    return null;
  }

  // تاريخ الإعلان أو آخر رسالة
  DateTime _resolveAdDate(con.Conversation c) {
    try {
      final createdAt = (c.ad as dynamic)?.createdAt;
      if (createdAt is DateTime) return createdAt;
      if (createdAt is String) {
        final parsed = DateTime.tryParse(createdAt);
        if (parsed != null) return parsed;
      }
    } catch (_) {}
    return c.lastMessageAt; // fallback
  }

  /// اسم المعلن (اسم البروفايل نفسه: فرد أو شركة)
  String _resolveAdvertiserMainName(con.Conversation c) {
    final adv = c.advertiser;
    if (adv == null) return '';
    // لو كان AdvertiserProfile (موديل قديم)
    if (adv is AdvertiserProfile) {
      final name = (adv.name ?? '').trim();
      if (name.isNotEmpty) return name;
    }
    // موديل conversation.Advertiser (الداتا تايب الجديد)
    try {
      final name = ((adv as dynamic).name ?? '').toString().trim();
      return name;
    } catch (_) {
      return '';
    }
  }

  /// نوع المعلن (شركة / فردي) إن توفر
  String? _resolveAdvertiserTypeLabel(con.Conversation c) {
    final adv = c.advertiser;
    if (adv == null) return null;

    try {
      final t =
          ((adv as dynamic).accountType ?? '').toString().toLowerCase().trim();
      if (t == 'company') return 'شركة';
      if (t == 'individual') return 'فرد';
    } catch (_) {}

    return null;
  }

  bool _isCompany(con.Conversation c) {
    final adv = c.advertiser;
    if (adv == null) return false;
    try {
      final t =
          ((adv as dynamic).accountType ?? '').toString().toLowerCase().trim();
      return t == 'company';
    } catch (_) {
      return false;
    }
  }

  /// اسم الفرد داخل الشركة (CompanyMember.displayName) إن وجد
  String _resolveCompanyMemberName(con.Conversation c) {
    final ad = c.ad;
    if (ad == null) return '';
    try {
      final cm = ad.companyMember;
      final name = (cm?.displayName ?? '').toString().trim();
      return name;
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeController.isDarkMode.value;
    final bgColor = AppColors.background(isDarkMode);
    final cardColor = AppColors.card(isDarkMode);
    final textPrimary = AppColors.textPrimary(isDarkMode);
    final textSecondary = AppColors.textSecondary(isDarkMode);
    final dividerColor = AppColors.divider(isDarkMode);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'الرسائل'.tr,
          style: TextStyle(
            color: AppColors.onPrimary,
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: AppTextStyles.xxlarge,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.appBar(isDarkMode),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.onPrimary),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            onPressed: _loadConversations,
            icon: Icon(Icons.refresh, color: AppColors.onPrimary),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Obx(() {
        if (_chatController.isLoadingConversations.value) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final list = [..._chatController.conversationsList];
        list.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

        if (list.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => _loadConversations(),
            color: AppColors.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: 60.h),
                Center(
                  child: Text(
                    'لا توجد رسائل'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.xlarge,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _loadConversations(),
          color: AppColors.primary,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(vertical: 0.h),
            itemCount: list.length,
            separatorBuilder: (context, index) => Padding(
              padding: EdgeInsets.symmetric(horizontal: 0.w),
              child: Divider(
                height: 0.4,
                thickness: 0.4,
                color: dividerColor.withOpacity(0.7),
              ),
            ),
            itemBuilder: (context, index) {
              final conversation = list[index];
              return _buildConversationItem(
                conversation: conversation,
                isDarkMode: isDarkMode,
                backgroundColor: cardColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildConversationItem({
    required con.Conversation conversation,
    required bool isDarkMode,
    required Color backgroundColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final hasUnread = (conversation.unreadCount > 0);

    // صورة الإعلان
    final adThumbUrl = _resolveAdImageUrl(conversation.ad);

    // هل شركة؟
    final isCompany = _isCompany(conversation);

    // اسم المعلن (بروفايل رئيسي)
    final rawAdvertiserName = _resolveAdvertiserMainName(conversation);

    // اسم الفرد داخل الشركة (لو فيه)
    final memberName = _resolveCompanyMemberName(conversation);

    // نوع المعلن (شركة / فردي)
    final advertiserType = _resolveAdvertiserTypeLabel(conversation);

    // الاسم الذي سيُعرض في السطر الأول
    String mainName = rawAdvertiserName;

    if (isCompany) {
      if (memberName.isNotEmpty) {
        // نعرض اسم الفرد داخل الشركة فقط
        mainName = memberName;
      } else {
        mainName = rawAdvertiserName;
      }
    }

    // لو فاضي الاسم بالكامل، نسقط على اسم الشريك أو الإيميل
    if (mainName.trim().isEmpty) {
      final partnerName = conversation.inquirer.name?.trim();
      if (partnerName != null && partnerName.isNotEmpty) {
        mainName = partnerName;
      } else {
        mainName = conversation.inquirer.email;
      }
    }

    // عنوان الإعلان
    final adTitle = conversation.ad?.title ?? '';

    // تاريخ المراسلة
    final adDate = _resolveAdDate(conversation);

    final Color rowColor = hasUnread
        ? backgroundColor.withOpacity(isDarkMode ? 0.97 : 1.0)
        : Colors.transparent;

    return InkWell(
      onTap: () {
        Get.to(
          () => ConversationScreenInMy(
            advertiser: conversation.advertiser,
            ad: conversation.ad,
            idAdv: conversation.advertiser.id,
          ),
        );
      },
      child: Container(
        color: rowColor,
        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
        child: Row(
          // RTL: الصورة على اليمين، النص في الوسط، السهم يسار
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // الصورة — مستطيلة (العرض > الارتفاع)
            _buildAdThumbWide(adThumbUrl),
            SizedBox(width: 10.w),

            // النصوص في الوسط
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // السطر الأول: اسم المعلن / الفرد داخل الشركة
                  Text(
                    mainName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.medium,
                      fontWeight:
                          hasUnread ? FontWeight.w700 : FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                  SizedBox(height: 1.h),

                  // عنوان الإعلان (سطرين كحد أقصى)
                  Text(
                    _truncateText(adTitle, maxLength: 80),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.small,
                      fontWeight:
                          hasUnread ? FontWeight.w800 : FontWeight.w400,
                      color: hasUnread ? textPrimary : textSecondary,
                    ),
                  ),
                  SizedBox(height: 1.h),

                  // التاريخ أسفل
                  Text(
                    _formatDate(adDate),
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.small,
                      color:
                          _dateFaded.withOpacity(isDarkMode ? 0.9 : 0.8),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 8.w),

            // نوع المعلن + مؤشر الرسائل غير المقروءة + السهم
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (advertiserType != null && advertiserType.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Text(
                      advertiserType,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.small,
                        color: textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (hasUnread)
                  Container(
                    width: 8.w,
                    height: 8.w,
                    margin: EdgeInsets.only(bottom: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16.sp,
                  color: textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // صورة إعلان مستطيلة (العرض > الارتفاع) في اليمين
  Widget _buildAdThumbWide(String? url) {
    return Container(
      width: _thumbWidth.w,
      height: _thumbHeight.h,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(0.r),
      ),
      clipBehavior: Clip.hardEdge,
      child: (url != null && url.isNotEmpty)
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const _AdThumbPlaceholder(),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const _AdThumbPlaceholder(isLoading: true);
              },
            )
          : const _AdThumbPlaceholder(),
    );
  }
}

class _AdThumbPlaceholder extends StatelessWidget {
  final bool isLoading;
  const _AdThumbPlaceholder({this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        isLoading ? Icons.downloading_rounded : Icons.image_outlined,
        size: 22,
        color: Colors.grey.shade500,
      ),
    );
  }
}
