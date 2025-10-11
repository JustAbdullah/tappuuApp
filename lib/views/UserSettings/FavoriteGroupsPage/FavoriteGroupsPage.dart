import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../controllers/LoadingController.dart';
import '../../../controllers/ThemeController.dart';
import '../../../controllers/favorite_groups_controller.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';
import '../../../core/data/model/favorite.dart';
import '../itemsUserSettings/FavoritesScreen/FavoritesScreen.dart';


class FavoriteGroupsPage extends StatefulWidget {
  const FavoriteGroupsPage({Key? key}) : super(key: key);

  @override
  State<FavoriteGroupsPage> createState() => _FavoriteGroupsPageState();
}

class _FavoriteGroupsPageState extends State<FavoriteGroupsPage> {
  final FavoriteGroupsController groupsCtrl = Get.put(FavoriteGroupsController());
  final ThemeController themeController = Get.find<ThemeController>();
  final LoadingController loadingController = Get.find<LoadingController>();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initFetch());
  }

  void _initFetch() {
    if (_initialized) return;
    final user = loadingController.currentUser;
    if (user != null) {
      _initialized = true;
      groupsCtrl.fetchGroups(userId: user?.id??0);
    }
  }

  Future<void> _refresh() async {
    final user = loadingController.currentUser;
    if (user != null) {
      await groupsCtrl.fetchGroups(userId: user?.id??0);
    }
  }

  void _showCreateGroupDialog(bool isDark) {
    TextEditingController nameController = TextEditingController();
    final user = loadingController.currentUser;

    Get.dialog(
      Dialog(
        backgroundColor: AppColors.card(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'إنشاء مجموعة جديدة'.tr,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: AppTextStyles.xlarge,

                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(isDark),
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'اسم المجموعة'.tr,
                  labelStyle: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    color: AppColors.textSecondary(isDark),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text(
                      'إلغاء'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        color: AppColors.textSecondary(isDark),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isNotEmpty && user != null) {
                        Get.back();
                        await groupsCtrl.createGroup(
                          userId: user?.id??0,
                          name: nameController.text,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'إنشاء'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditGroupDialog(FavoriteGroup group, bool isDark) {
    TextEditingController nameController = TextEditingController(text: group.name);
    final user = loadingController.currentUser;

    Get.dialog(
      Dialog(
        backgroundColor: AppColors.card(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'تعديل المجموعة'.tr,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: AppTextStyles.xlarge,

                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(isDark),
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'اسم المجموعة'.tr,
                  labelStyle: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    color: AppColors.textSecondary(isDark),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text(
                      'إلغاء'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        color: AppColors.textSecondary(isDark),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isNotEmpty && user != null) {
                        Get.back();
                        await groupsCtrl.updateGroup(
                          id: group.id,
                          userId: user?.id??0,
                          name: nameController.text,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'حفظ'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptionsForGroup(FavoriteGroup group, bool isDark) {
    final user = loadingController.currentUser;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card(isDark),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit, color: AppColors.textPrimary(isDark)),
                title: Text('تعديل المجموعة'.tr, 
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    color: AppColors.textPrimary(isDark)
                  )
                ),
                onTap: () {
                  Get.back();
                  _showEditGroupDialog(group, isDark);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('حذف المجموعة'.tr, 
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    color: Colors.red
                  )
                ),
                onTap: () async {
                  Get.back();
                  if (user != null) {
                    final success = await groupsCtrl.deleteGroup(
                      id: group.id,
                      userId: user?.id??0,
                    );
                    if (success) {
                      Get.snackbar(
                        'نجح'.tr, 
                        'تم حذف المجموعة بنجاح'.tr,
                        backgroundColor: Colors.green.withOpacity(0.9),
                        colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    } else {
                      Get.snackbar(
                        'فشل'.tr, 
                        'حدث خطأ أثناء الحذف'.tr,
                        backgroundColor: Colors.red.withOpacity(0.9),
                        colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeController.isDarkMode.value;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.appBar(isDark),
        title: Text(
          'مجموعات المفضلة'.tr,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.onPrimary,
            fontSize: AppTextStyles.xlarge,

          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.onPrimary),
          onPressed: (){
             Get.back();
             Get.back();
          }
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateGroupDialog(isDark),
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add, color: Colors.white),
      ),
      body: Obx(() {
        if (groupsCtrl.isLoading.value && !_initialized) {
          return Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (groupsCtrl.groups.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: 120.h),
                Center(
                  child: Text(
                    'لا توجد مجموعات مفضلة'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.large,

                      color: AppColors.textPrimary(isDark),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
            itemCount: groupsCtrl.groups.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              thickness: 0.5,
              color: AppColors.grey.withOpacity(0.5),
            ),
            itemBuilder: (context, index) {
              final FavoriteGroup group = groupsCtrl.groups[index];
              final subtitle = '${group.favoritesCount} ${'اعلان'.tr}';
              
              return ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
               
                title: Text(
                  group.name,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.medium,

                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(isDark),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.small,

                    color: AppColors.textSecondary(isDark),
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.more_vert, color: AppColors.textSecondary(isDark)),
                  onPressed: () => _showOptionsForGroup(group, isDark),
                ),
                onTap: () {
                
                Get.to(() => FavoritesScreen(idGroup: group.id,nameOfGroup: group.name,));
                },
              );
            },
          ),
        );
      }),
    );
  }
}