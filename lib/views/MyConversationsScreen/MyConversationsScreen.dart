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

class _ConversationsListScreenState extends State<ConversationsListScreen>
    with SingleTickerProviderStateMixin {
  final ChatController _chatController = Get.put(ChatController());
  final LoadingController _loadingController = Get.find<LoadingController>();
  final ThemeController _themeController = Get.find<ThemeController>();

  late TabController _tabController;
  // خرائط نوع التاب إلى باراميتر الـ API
  final Map<int, String> _tabType = {
    0: 'incoming', // عرض رسائل المستخدمين لي (حد تواصل معي)
    1: 'outgoing', // عرض رسائلي للمعلنين (أنا بادي)
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    // جلب أول صفحة (تاب افتراضي 0 -> incoming)
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadConversations());
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return; // نتجنب النداء أثناء التحويل الداخلي
    _loadConversations();
  }

  void _loadConversations() {
    final currentUser = _loadingController.currentUser;
    if (currentUser != null) {
      final type = _tabType[_tabController.index] ?? 'all';
      _chatController.fetchConversations(userId: currentUser.id??0, type: type);
    }
  }

  // تنسيق الوقت (/م)
  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute;
    final period = hour < 12 ? 'ص' : 'م';
    final formattedHour = (hour == 0) ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${formattedHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  String _truncateText(String text, {int maxLength = 30}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
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
          'المحادثات'.tr,
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.onPrimary,
          unselectedLabelColor: AppColors.onPrimary.withOpacity(0.8),
          tabs: [
            Tab(
              child: Text(
                'عرض رسائل المستخدمين لي',
                style: TextStyle(fontSize: AppTextStyles.small,
 fontFamily: AppTextStyles.appFontFamily),
              ),
            ),
            Tab(
              child: Text(
                'عرض رسائلي للمعلنين',
                style: TextStyle(fontSize: AppTextStyles.small,
 fontFamily: AppTextStyles.appFontFamily),
              ),
            ),
          ],
        ),
      ),
      body: Obx(() {
        if (_chatController.isLoadingConversations.value) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final list = _chatController.conversationsList;
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
                    'لا توجد محادثات'.tr,
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
            padding: EdgeInsets.symmetric(vertical: 16.h),
            itemCount: list.length,
            separatorBuilder: (context, index) => Divider(
              height: 1.h,
              color: dividerColor,
              indent: 80.w,
              endIndent: 16.w,
            ),
            itemBuilder: (context, index) {
              final conversation = list[index];
              return _buildConversationItem(
                conversation,
                isDarkMode,
                cardColor,
                textPrimary,
                textSecondary,
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildConversationItem(
   con. Conversation conversation,
    bool isDarkMode,
    Color cardColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return InkWell(
      onTap: () {
        // التنقل لواجهة المحادثة المنفردة
        Get.to(() => ConversationScreenInMy(
              advertiser: conversation.advertiser,
              ad: conversation.ad,
              idAdv: conversation.advertiser.id,
            ));
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        color: cardColor,
        child: Row(
          children: [
            _buildAdvertiserAvatar(conversation.advertiser.logo),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // اسم المعلن والوقت
                  Row(
                    children: [
                      SizedBox(
                        width: 180.w,
                        child: Text(
                          conversation.advertiser.name,
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
                      Spacer(),
                      Text(
                        _formatTime(conversation.lastMessageAt),
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.small,

                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),

                  // عنوان الإعلان (إن وجد)
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

                  // آخر رسالة وعدد الرسائل غير المقروءة
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage != null
                              ? _truncateText(conversation.lastMessage!.body ?? '')
                              : 'بدء محادثة جديدة'.tr,
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            fontSize: AppTextStyles.medium,

                            color: textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.unreadCount > 0)
                        Container(
                          margin: EdgeInsets.only(left: 8.w),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
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
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.greyLight,
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
