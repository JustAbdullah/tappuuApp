import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:tappuu_app/controllers/ChatController.dart';
import 'package:tappuu_app/controllers/LoadingController.dart';
import 'package:tappuu_app/controllers/ThemeController.dart';
import 'package:tappuu_app/core/constant/appcolors.dart';
import 'package:tappuu_app/core/constant/app_text_styles.dart';
import 'package:tappuu_app/core/data/model/conversation.dart' as con;

import 'ConversationScreenInMy.dart';

class ConversationsListScreen extends StatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  State<ConversationsListScreen> createState() => _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  final ChatController _chatController = Get.put(ChatController());
  final LoadingController _loadingController = Get.find<LoadingController>();
  final ThemeController _themeController = Get.find<ThemeController>();

  // لون صحّتين القراءة (لآخر رسالة إن كانت مني)
  static const _receiptGrey = Color(0xFF9AA0A6);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadConversations());
  }

  void _loadConversations() {
    final currentUser = _loadingController.currentUser;
    if (currentUser != null) {
      // قائمة واحدة: نطلب الكل ونرتبه حديث -> قديم
      _chatController.fetchConversations(userId: currentUser.id ?? 0, type: 'all');
    }
  }

  // لإظهار الوقت/أمس/التاريخ بأسلوب واتساب
  String _formatConversationTimestamp(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thatDay = DateTime(dt.year, dt.month, dt.day);
    final diffDays = today.difference(thatDay).inDays;

    if (diffDays == 0) {
      // اليوم -> وقت فقط
      final hour = dt.hour;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = hour < 12 ? 'ص' : 'م';
      final formattedHour = (hour == 0) ? 12 : (hour > 12 ? hour - 12 : hour);
      return '${formattedHour.toString().padLeft(2, '0')}:$minute $period';
    } else if (diffDays == 1) {
      return 'أمس';
    } else if (dt.year == now.year) {
      return '${dt.day}/${dt.month}';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  // قص نص
  String _truncateText(String text, {int maxLength = 34}) {
    if (text.isEmpty) return text;
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  // اعتبر "حديث" خلال آخر 24 ساعة
  bool _isRecent(DateTime dt) {
    final now = DateTime.now();
    return now.difference(dt) <= const Duration(hours: 24);
  }

  // أيقونة مقروئية على مستوى آخر رسالة بالمحادثة (لو آخر رسالة منّي)
  Widget _conversationReadReceipt(con.Conversation c, int? currentUserId) {
    if (c.lastMessage == null) return const SizedBox.shrink();
    final last = c.lastMessage!;
    final isMine = (currentUserId != null) && last.senderId == currentUserId;
    if (!isMine) return const SizedBox.shrink();

    // تقدير: إن كان لا يوجد رسائل غير مقروءة للطرف الآخر نعتبر آخر رسالة مني قد قُرئت
    final read = (c.unreadCount == 0);
    return Padding(
      padding: EdgeInsets.only(right: 6.w),
      child: Icon(
        Icons.done_all_rounded,
        size: 16.sp,
        color: read ? AppColors.buttonAndLinksColor : _receiptGrey.withOpacity(0.85),
      ),
    );
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
          return Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        // تأكُّد إضافي: الأحدث أولاً
        final list = [..._chatController.conversationsList];
        list.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

        if (list.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => _loadConversations(),
            color: AppColors.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: 80.h),
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
            padding: EdgeInsets.symmetric(vertical: 8.h),
            itemCount: list.length,
            separatorBuilder: (context, index) => Divider(
              height: 1.h,
              color: dividerColor,
              indent: 80.w,
              endIndent: 16.w,
            ),
            itemBuilder: (context, index) {
              final conversation = list[index];
              final highlightRecent = _isRecent(conversation.lastMessageAt);
              return _buildConversationItem(
                conversation: conversation,
                isDarkMode: isDarkMode,
                baseCardColor: cardColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                highlightRecent: highlightRecent,
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
    required Color baseCardColor,
    required Color textPrimary,
    required Color textSecondary,
    required bool highlightRecent,
  }) {
    final currentUserId = _loadingController.currentUser?.id;
    final hasUnread = (conversation.unreadCount > 0);

    // خلفية مميّزة للمحادثات الحديثة + أقوى لو فيها غير مقروء
    final bg = hasUnread
        ? AppColors.primary.withOpacity(isDarkMode ? 0.15 : 0.10)
        : (highlightRecent ? AppColors.primary.withOpacity(isDarkMode ? 0.09 : 0.06) : baseCardColor);

    final lastMsg = conversation.lastMessage;

    return InkWell(
      onTap: () {
        Get.to(() => ConversationScreenInMy(
              advertiser: conversation.advertiser,
              ad: conversation.ad,
              idAdv: conversation.advertiser.id,
            ));
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        color: bg,
        child: Row(
          children: [
            _buildAdvertiserAvatar(conversation.advertiser.logo),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // السطر الأول: اسم + وقت/أمس/تاريخ + مؤشّر المقروئية لآخر رسالة (لو منّي)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          conversation.advertiser?.name??"",
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            fontSize: AppTextStyles.medium,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                            overflow: TextOverflow.ellipsis,
                          ),
                          maxLines: 1,
                        ),
                      ),
                      _conversationReadReceipt(conversation, currentUserId),
                      Text(
                        _formatConversationTimestamp(conversation.lastMessageAt),
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.small,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),

                  // عنوان الإعلان (إن وُجد)
                  if (conversation.ad != null) ...[
                    Text(
                      conversation.ad!.title,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.small,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                  ],

                  // آخر رسالة + أيقونة ميكروفون لو صوت + بادج غير مقروء + شارة "اليوم" إن لزم
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            if (lastMsg?.isVoice == true) ...[
                              Icon(Icons.mic, size: 16.sp, color: textSecondary),
                              SizedBox(width: 6.w),
                            ],
                            Flexible(
                              child: Text(
                                lastMsg == null
                                    ? 'بدء محادثة جديدة'.tr
                                    : _truncateText(
                                        lastMsg.isVoice ? '[صوت]' : (lastMsg.body ?? ''),
                                      ),
                                style: TextStyle(
                                  fontFamily: AppTextStyles.appFontFamily,
                                  fontSize: AppTextStyles.medium,
                                  color: hasUnread ? textPrimary : textSecondary,
                                  fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // بادج غير مقروء
                      if (hasUnread)
                        Container(
                          margin: EdgeInsets.only(left: 8.w),
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            conversation.unreadCount.toString(),
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              fontSize: AppTextStyles.small,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      // شارة "اليوم" لو المحادثة حديثة ولا يوجد غير مقروء
                     
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Icon(Icons.arrow_forward_ios, size: 18.sp, color: textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvertiserAvatar(String? logoUrl) {
    return Container(
      width: 56.w,
      height: 56.w,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFE0E0E0),
      ),
      child: ClipOval(
        child: (logoUrl != null && logoUrl.isNotEmpty)
            ? Image.network(
                logoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Icon(Icons.person, size: 24.sp, color: AppColors.greyDark),
                ),
              )
            : Center(
                child: Icon(Icons.person, size: 24.sp, color: AppColors.greyDark),
              ),
      ),
    );
  }
}
