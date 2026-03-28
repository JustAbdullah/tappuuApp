import 'package:tappuu_app/controllers/LoadingController.dart';
import '../../core/data/model/City.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dotted_border/dotted_border.dart';
import '../../controllers/AdsManageController.dart';
import '../../controllers/ThemeController.dart';
import '../../controllers/areaController.dart';
import '../../core/constant/app_text_styles.dart';
import '../../core/constant/appcolors.dart';
import '../../core/data/model/AdvertiserProfile.dart';
import '../../core/data/model/Area.dart';
import '../../core/data/model/Attribute.dart';
import '../../core/data/model/category.dart';
import '../../core/data/model/subcategory_level_one.dart';
import '../../core/data/model/subcategory_level_two.dart';
import '../HomeScreen/home_screen.dart';

class EditAdScreen extends StatefulWidget {
  final int adId;
  const EditAdScreen({super.key, required this.adId});

  @override
  _EditAdScreenState createState() => _EditAdScreenState();
}

class _EditAdScreenState extends State<EditAdScreen> {
  final ManageAdController controller = Get.find<ManageAdController>();
  final ThemeController themeC = Get.find<ThemeController>();
  final AreaController areaController = Get.find<AreaController>();
  final LoadingController _loading = Get.find<LoadingController>();

  bool _isInitialDataLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // جلب التصنيفات والمدن أولاً
      await controller.fetchCategories('ar');
      await controller.fetchCities('SY', 'ar');
      
      // جلب تفاصيل الإعلان
      await controller.fetchAdDetails(widget.adId);
      
      // جلب بيانات المعلن
      controller.fetchAdvertiserProfiles(_loading.currentUser?.id ?? 0);
      
      // تحميل الخصائص بعد تعيين التصنيفات
      _loadAttributesBasedOnSelectedCategory();
      
      setState(() {
        _isInitialDataLoading = false;
      });
    });
  }

  // دالة مساعدة لتحميل الخصائص بناءً على التصنيف المختار
  void _loadAttributesBasedOnSelectedCategory() {
    if (controller.selectedSubcategoryLevelTwo.value != null) {
      controller.fetchAttributes(
          controller.selectedSubcategoryLevelTwo.value!.id, 'ar');
    } else if (controller.selectedSubcategoryLevelOne.value != null) {
      controller.fetchAttributes(
          controller.selectedSubcategoryLevelOne.value!.id, 'ar');
    } else if (controller.selectedMainCategory.value != null) {
      controller.fetchAttributes(
          controller.selectedMainCategory.value!.id, 'ar');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(themeC.isDarkMode.value),
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'تعديل الإعلان'.tr,
        style: TextStyle(
          fontFamily: AppTextStyles.appFontFamily,
          fontWeight: FontWeight.bold,
          fontSize: AppTextStyles.xlarge,

          color: Colors.white,
        ),
      ),
       leading: IconButton(
          icon: Icon(Icons.arrow_back,color: AppColors.onPrimary,),
          onPressed: () {
           
 Get.back();
                Get.back();          },
        ),
      centerTitle: true,
      backgroundColor: AppColors.buttonAndLinksColor,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  Widget _buildBody() {
    if (_isInitialDataLoading || controller.isLoadingAd.value) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Obx(() {
      if (controller.currentAd.value == null) {
        return Center(
          child: Text('لا يوجد بيانات للإعلان'.tr,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.xlarge,

            )
          ),
        );
      }

      return SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentDataIndicator(),
            SizedBox(height: 24.h),
            _buildAdvertiserProfileSection(),
            SizedBox(height: 24.h),
            _buildCategorySection(),
            SizedBox(height: 24.h),
            Obx(() {
              // عرض مؤشر التحميل أثناء جلب الخصائص
              if (controller.isLoadingAttributes.value) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              // عرض الخصائص إذا كانت متوفرة
              return controller.attributes.isNotEmpty
                  ? Column(
                      children: [
                        _buildAttributesSection(),
                        SizedBox(height: 24.h),
                      ],
                    )
                  : const SizedBox();
            }),
            _buildBasicInfoSection(),
            SizedBox(height: 24.h),
            _buildImagesSection(),
            SizedBox(height: 24.h),
            _buildLocationSection(),
            SizedBox(height: 32.h),
            _buildUpdateButton(),
              SizedBox(height: 32.h),
          ],
        ),
      );
    });
  }

  Widget _buildCurrentDataIndicator() {
    final isDark = themeC.isDarkMode.value;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.primary),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: AppColors.primary),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'يتم عرض البيانات الحالية للإعلان. قم بتعديل ما ترغب في تغييره'.tr,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.medium,

                color: AppColors.textPrimary(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvertiserProfileSection() {
    final isDark = themeC.isDarkMode.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('بيانات المعلن'.tr),
        SizedBox(height: 16.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card(isDark),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
          )],
          ),
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'سيتم عرض هذه البيانات للتواصل معك'.tr,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: AppTextStyles.medium,

                  color: AppColors.textSecondary(isDark),
                ),
              ),
              SizedBox(height: 16.h),
              _buildProfileDropdown(isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileDropdown(bool isDark) {
    return Obx(() {
      if (controller.isProfilesLoading.value) {
        return _buildLoadingIndicator();
      }

      if (controller.advertiserProfiles.isEmpty) {
        return Text(
          'لا توجد بيانات معلن متاحة'.tr,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.textSecondary(isDark),
         ) );
      }

      return _buildDropdown<AdvertiserProfile>(
        hint: 'اختر بيانات المعلن'.tr,
        value: controller.selectedProfile.value,
        items: controller.advertiserProfiles.map((profile) {
          return DropdownMenuItem<AdvertiserProfile>(
            value: profile,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name ?? 'بدون اسم'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.medium,

                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(isDark),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  '${profile.contactPhone}',
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.small,

                    color: AppColors.textSecondary(isDark)),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (profile) {
          controller.selectedProfile.value = profile;
        },
        icon: Icons.person,
        isDark: isDark,
      );
    });
  }

  Widget _buildCategorySection() {
    final isDark = themeC.isDarkMode.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('اختيار التصنيف'.tr),   
        SizedBox(height: 16.h),
         Text(
            'اعد اختيار اي تصنيف لتظهر الخصائص'.tr,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: AppTextStyles.medium,

                  color: AppColors.textSecondary(isDark),
                ),
              ),
            
        SizedBox(height: 16.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card(isDark),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
            )  ],
          ),
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              _buildMainCategoryDropdown(isDark),
              SizedBox(height: 16.h),
              Obx(() => controller.subCategories.isNotEmpty
                  ? _buildSubcategoryDropdown(isDark)
                  : const SizedBox()),
              SizedBox(height: 16.h),
              Obx(() => controller.subCategoriesLevelTwo.isNotEmpty
                  ? _buildSubcategoryLevelTwoDropdown(isDark)
                  : const SizedBox()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainCategoryDropdown(bool isDark) {
    return Obx(() {
      if (controller.isLoadingCategories.value) {
        return _buildLoadingIndicator();
      }
      return _buildDropdown<Category>(
        hint: 'التصنيف الرئيسي'.tr,
        value: controller.selectedMainCategory.value,
        items: controller.categoriesList.map((category) {
          return DropdownMenuItem<Category>(
            value: category,
            child: Text(
              category.name,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.medium,

                color: AppColors.textPrimary(isDark),
              ),
            ),
          );
        }).toList(),
        onChanged: (category) {
          if (category != null) controller.selectMainCategory(category);
        },
        icon: Icons.category,
        isDark: isDark,
      );
    });
  }

  Widget _buildSubcategoryDropdown(bool isDark) {
    return Obx(() {
      if (controller.isLoadingSubcategoryLevelOne.value) {
        return _buildLoadingIndicator();
      }
      return _buildDropdown<SubcategoryLevelOne>(
        hint: 'التصنيف الفرعي'.tr,
        value: controller.selectedSubcategoryLevelOne.value,
        items: controller.subCategories.map((subcategory) {
          return DropdownMenuItem<SubcategoryLevelOne>(
            value: subcategory,
            child: Text(
              subcategory.name,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.medium,

                color: AppColors.textPrimary(isDark),
              ),
            ),
          );
        }).toList(),
        onChanged: (subcategory) {
          if (subcategory != null) controller.selectSubcategoryLevelOne(subcategory);
        },
        icon: Icons.list,
        isDark: isDark,
      );
    });
  }

  Widget _buildSubcategoryLevelTwoDropdown(bool isDark) {
    return Obx(() {
      if (controller.isLoadingSubcategoryLevelTwo.value) {
        return _buildLoadingIndicator();
      }
      return _buildDropdown<SubcategoryLevelTwo>(
        hint: 'التصنيف الثانوي'.tr,
        value: controller.selectedSubcategoryLevelTwo.value,
        items: controller.subCategoriesLevelTwo.map((subcategory) {
          return DropdownMenuItem<SubcategoryLevelTwo>(
            value: subcategory,
            child: Text(
              subcategory.name,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.medium,

                color: AppColors.textPrimary(isDark),
              ),
            ),
          );
        }).toList(),
        onChanged: (subcategory) {
          controller.selectSubcategoryLevelTwo(subcategory!);
        },
        icon: Icons.list_alt,
        isDark: isDark,
      );
    });
  }

  Widget _buildAttributesSection() {
    final isDark = themeC.isDarkMode.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('خصائص الإعلان'.tr),
        SizedBox(height: 16.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card(isDark),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )    ],
          ),
          padding: EdgeInsets.all(16.w),
          child: Obx(() => ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.attributes.length,
                separatorBuilder: (context, index) => Divider(
                  height: 32.h,
                  color: AppColors.divider(isDark),
                  thickness: 1,
                ),
                itemBuilder: (context, index) {
                  final attribute = controller.attributes[index];
                  return _buildAttributeField(attribute, isDark);
                },
              )),
        ),
      ],
    );
  }

  Widget _buildAttributeField(Attribute attribute, bool isDark) {
    final currentValue = controller.attributeValues[attribute.attributeId]?.toString() ?? '';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          attribute.label,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: AppTextStyles.medium,

            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(isDark),
          ),
        ),
        SizedBox(height: 8.h),
        if (currentValue.isNotEmpty)
          Text(
            '${'القيمة الحالية:'.tr} $currentValue',
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.small,

              color: AppColors.textSecondary(isDark)),
          ),
        SizedBox(height: 8.h),
        _buildAttributeInput(attribute, isDark),
      ],
    );
  }

  Widget _buildAttributeInput(Attribute attribute, bool isDark) {
    switch (attribute.type) {
      case 'number':
        return _buildNumberField(attribute, isDark);
      case 'text':
        return _buildTextField(attribute, isDark);
      case 'boolean':
        return _buildBooleanField(attribute, isDark);
      case 'options':
        return _buildOptionsField(attribute, isDark);
      default:
        return _buildTextField(attribute, isDark);
    }
  }

  Widget _buildNumberField(Attribute attribute, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border(isDark)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: TextFormField(
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: '${'أدخل'.tr} ${attribute.label}',
          hintStyle: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.textSecondary(isDark),
          ),
          suffixIcon: Icon(Icons.numbers, color: AppColors.primary, size: 20.w),
        ),
        style: TextStyle(
          fontFamily: AppTextStyles.appFontFamily,
          fontSize: AppTextStyles.medium,

          color: AppColors.textPrimary(isDark),
        ),
        onChanged: (value) {
          controller.attributeValues[attribute.attributeId] = value;
        },
      ),
    );
  }

  Widget _buildTextField(Attribute attribute, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border(isDark)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: TextFormField(
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: '${'أدخل'.tr}${attribute.label}',
          hintStyle: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.textSecondary(isDark),
          ),
          suffixIcon: Icon(Icons.text_fields, color: AppColors.primary, size: 20.w),
        ),
        style: TextStyle(
          fontFamily: AppTextStyles.appFontFamily,
          fontSize: AppTextStyles.medium,

          color: AppColors.textPrimary(isDark),
        ),
        onChanged: (value) {
          controller.attributeValues[attribute.attributeId] = value;
        },
      ),
    );
  }

  Widget _buildBooleanField(Attribute attribute, bool isDark) {
    bool? value = controller.attributeValues[attribute.attributeId] as bool?;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildBooleanOption('نعم'.tr, true, value == true, attribute, isDark),
        SizedBox(width: 12.w),
        _buildBooleanOption('لا'.tr, false, value == false, attribute, isDark),
      ],
    );
  }

  Widget _buildBooleanOption(String label, bool optionValue, bool isSelected, Attribute attribute, bool isDark) {
    return GestureDetector(
      onTap: () {
        setState(() {
          controller.attributeValues[attribute.attributeId] = optionValue;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface(isDark),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border(isDark),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: AppTextStyles.small,

            color: isSelected ? Colors.white : AppColors.textPrimary(isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsField(Attribute attribute, bool isDark) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 12.h,
      children: attribute.options.map((option) {
        final isSelected = controller.attributeValues[attribute.attributeId] == option.id;
        return _buildOptionChip(
          option.value,
          option.id,
          isSelected,
          attribute,
          isDark,
        );
      }).toList(),
    );
  }

  Widget _buildOptionChip(String label, int value, bool isSelected, Attribute attribute, bool isDark) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontFamily: AppTextStyles.appFontFamily,
          fontSize: AppTextStyles.small,

          color: isSelected ? Colors.white : AppColors.textPrimary(isDark),
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          controller.attributeValues[attribute.attributeId] = selected ? value : null;
        });
      },
      backgroundColor: AppColors.surface(isDark),
      selectedColor: AppColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border(isDark),
          width: 1.5,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
    );
  }

  Widget _buildBasicInfoSection() {
    final isDark = themeC.isDarkMode.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('تفاصيل الإعلان'.tr),
        SizedBox(height: 16.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card(isDark),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4)),
            ],
          ),
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              _buildInputField(
                controller: controller.titleArController,
                label: 'عنوان الإعلان'.tr,
                icon: Icons.title,
                currentValue: controller.titleArController.text,
              ),
              SizedBox(height: 16.h),
              _buildInputField(
                controller: controller.descriptionArController,
                label: 'وصف الإعلان'.tr,
                icon: Icons.description,
                maxLines: 6,
                currentValue: controller.descriptionArController.text,
              ),
              SizedBox(height: 16.h),
              _buildInputField(
                controller: controller.priceController,
                label: 'السعر'.tr,
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                currentValue: controller.priceController.text,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    required String currentValue,
  }) {
    final isDark = themeC.isDarkMode.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: AppTextStyles.medium,

            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(isDark),
          ),
        ),
        SizedBox(height: 8.h),
        if (currentValue.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: 4.h),
            child: Text(
              '${'القيمة الحالية:'.tr} $currentValue',
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.small,

                color: AppColors.textSecondary(isDark)),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface(isDark),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.border(isDark)),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              border: InputBorder.none,
              suffixIcon: Icon(icon, color: AppColors.primary, size: 20.w),
            ),
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.medium,

              color: AppColors.textPrimary(isDark),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagesSection() {
    final isDark = themeC.isDarkMode.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('صور الإعلان'.tr),
        SizedBox(height: 16.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card(isDark),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4)),
            ],
          ),
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              // عرض الصور الحالية
              Obx(() {
                if (controller.currentAd.value?.images == null || 
                    controller.currentAd.value!.images!.isEmpty) {
                  return _buildEmptyImagesPlaceholder(isDark);
                }
                return _buildCurrentImagesGrid(isDark);
              }),
              SizedBox(height: 16.h),
              
              // عرض الصور الجديدة
              Obx(() => controller.images.isNotEmpty
                  ? _buildNewImagesGrid()
                  : const SizedBox()),
              SizedBox(height: 16.h),
              
              ElevatedButton.icon(
                onPressed: controller.pickImages,
                icon: Icon(Icons.add_photo_alternate, size: 20.w),
                label: Text('إضافة صور جديدة'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 24.w),
                  minimumSize: Size(double.infinity, 50.h),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentImagesGrid(bool isDark) {
    return Obx(() {
      if (controller.currentAd.value?.images == null) {
        return const SizedBox();
      }
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الصور الحالية'.tr,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: AppTextStyles.large,

              color: AppColors.textPrimary(isDark),
            ),
          ),
          SizedBox(height: 8.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8.w,
              mainAxisSpacing: 8.h,
              childAspectRatio: 0.8,
            ),
            itemCount: controller.currentAd.value!.images!.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Image.network(
                      controller.currentAd.value!.images![index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        // يمكن إضافة وظيفة لحذف الصورة من السيرفر
                        Get.snackbar('معلومات'.tr, 'لا يمكن حذف الصور الحالية من هنا'.tr);
                      },
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        padding: EdgeInsets.all(4.w),
                        child: Icon(Icons.close, size: 16.w, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 16.h),
        ],
      );
    });
  }

  Widget _buildNewImagesGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الصور الجديدة'.tr,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: AppTextStyles.large,

          ),
        ),
        SizedBox(height: 8.h),
        Obx(() => GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8.w,
            mainAxisSpacing: 8.h,
            childAspectRatio: 0.8,
          ),
          itemCount: controller.images.length,
          itemBuilder: (context, index) {
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Image.file(
                    controller.images[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => controller.removeImage(index),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      padding: EdgeInsets.all(4.w),
                      child: Icon(Icons.close, size: 16.w, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        )),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildEmptyImagesPlaceholder(bool isDark) {
    return DottedBorder(
      borderType: BorderType.RRect,
      radius: Radius.circular(12.r),
      color: AppColors.border(isDark),
      dashPattern: const [6, 3],
      child: Container(
        height: 120.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface(isDark),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_library, size: 36.w, color: AppColors.textSecondary(isDark)),
              SizedBox(height: 8.h),
              Text(
                'لم يتم إضافة أي صور بعد'.tr,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  color: AppColors.textSecondary(isDark)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    final isDark = themeC.isDarkMode.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('الموقع الجغرافي'.tr),
        SizedBox(height: 16.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card(isDark),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
             )   ],
          ),
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              _buildCityDropdown(isDark),
              SizedBox(height: 16.h),
              Obx(() => controller.selectedCity.value != null
                  ? _buildAreaDropdown(isDark)
                  : const SizedBox()),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: controller.fetchCurrentLocation,
                      icon: Icon(Icons.location_on, size: 18.w),
                      label: Text('تحديد الموقع الحالي'.tr),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                  )),
                  SizedBox(width: 10.w),
                  Obx(() => controller.latitude.value != null
                      ? IconButton(
                          icon: Icon(Icons.check_circle, color: Colors.green),
                          onPressed: () {},
                        )
                      : const SizedBox()),
                ],
              ),
              Obx(() => controller.latitude.value != null
                  ? Padding(
                      padding: EdgeInsets.only(top: 16.h),
                      child: Text(
                        '${'الإحداثيات:'.tr} ${controller.latitude.value!.toStringAsFixed(6)}, ${controller.longitude.value!.toStringAsFixed(6)}',
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          color: AppColors.textSecondary(isDark)),
                      ),
                    )
                  : const SizedBox()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCityDropdown(bool isDark) {
    return Obx(() {
      if (controller.isLoadingCities.value) {
        return _buildLoadingIndicator();
      }
      return _buildDropdown<TheCity>(
        hint: 'اختر المدينة'.tr,
        value: controller.selectedCity.value,
        items: controller.citiesList.map((city) {
          return DropdownMenuItem<TheCity>(
            value: city,
            child: Text(
              city.translations.first.name,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.medium,

                color: AppColors.textPrimary(isDark)),
            ),
          );
        }).toList(),
        onChanged: (city) {
          if (city != null) controller.selectCity(city);
        },
        icon: Icons.location_city,
        isDark: isDark,
      );
    });
  }

  Widget _buildAreaDropdown(bool isDark) {
    return Obx(() {
      return _buildDropdown<Area>(
        hint: 'اختر المنطقة'.tr,
        value: controller.selectedArea.value,
        items: areaController.areas.map((area) {
          return DropdownMenuItem<Area>(
            value: area,
            child: Text(
              area.name,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.medium,

                color: AppColors.textPrimary(isDark)),
            ),
          );
        }).toList(),
        onChanged: (area) {
          if (area != null) controller.selectArea(area);
        },
        icon: Icons.map,
        isDark: isDark,
      );
    });
  }

  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: value != null ? AppColors.primary : AppColors.border(isDark),
          width: 1.5,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Row(
        children: [
          Icon(icon, color: AppColors.icon(isDark), size: 20.w),
          SizedBox(width: 12.w),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                isExpanded: true,
                hint: Text(
                  hint,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    color: AppColors.textSecondary(isDark),
                    fontSize: AppTextStyles.medium,

                  )),
                value: value,
                items: items,
                onChanged: onChanged,
                icon: Icon(Icons.arrow_drop_down, color: AppColors.primary, size: 28.w),
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  color: AppColors.textPrimary(isDark),
                  fontSize: AppTextStyles.medium,

                ),
                dropdownColor: AppColors.card(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () => controller.updateAd(widget.adId),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 48.w, vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 2,
          shadowColor: AppColors.primary.withOpacity(0.3),
        ),
        child: Text(
          'تحديث الإعلان'.tr,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: AppTextStyles.large,

            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 8.w),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: AppTextStyles.appFontFamily,
          fontWeight: FontWeight.bold,
          fontSize: AppTextStyles.xlarge,

          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}