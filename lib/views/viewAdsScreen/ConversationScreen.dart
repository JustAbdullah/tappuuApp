// ConversationScreen.dart — Part 1/3

import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tappuu_app/controllers/ChatController.dart';
import 'package:tappuu_app/core/constant/appcolors.dart';
import 'package:tappuu_app/core/constant/app_text_styles.dart';
import 'package:tappuu_app/controllers/LoadingController.dart';
import 'package:tappuu_app/controllers/ThemeController.dart';
import '../../core/data/model/AdResponse.dart';
import '../../core/data/model/Message.dart';
import '../HomeScreen/menubar.dart';

enum PendingVoiceStatus { recording, uploading, failed, sent }

class PendingVoice {
  int tempId;
  String? localPath;
  Duration duration;
  PendingVoiceStatus status;
  double uploadProgress;
  String? uploadedUrl;
  DateTime createdAt;

  PendingVoice({
    required this.tempId,
    this.localPath,
    this.duration = Duration.zero,
    this.status = PendingVoiceStatus.recording,
    this.uploadProgress = -1,
    this.uploadedUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class ConversationScreen extends StatefulWidget {
  final Advertiser advertiser;
  final Ad? ad;
  final int idAdv;

  const ConversationScreen({
    super.key,
    required this.advertiser,
    this.ad,
    required this.idAdv,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final ChatController _chatController = Get.put(ChatController());
  final LoadingController _loadingController = Get.find<LoadingController>();
  final ThemeController _themeController = Get.find<ThemeController>();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _playingMessageId;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;

  Duration _currentPosition = Duration.zero;
  Duration _currentDuration = Duration.zero;

  final List<PendingVoice> _pendingVoices = [];

  Timer? _recTimer;
  Duration _recDuration = Duration.zero;
  bool _isLocallyRecording = false;
  int _nextTempId = -1;

  final Map<int, Duration> _messageDurations = {};
  final FocusNode _messageFocusNode = FocusNode();

  static const _receiptGrey = Color(0xFF9AA0A6);

  @override
  void initState() {
    super.initState();
    _loadMessages();

    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _playingMessageId = null;
        _currentPosition = Duration.zero;
      });
    });

    _positionSub = _audioPlayer.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() => _currentPosition = p);
    });

    _durationSub = _audioPlayer.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _currentDuration = d);
    });

    // Scroll للأسفل عند ظهور الكيبورد
    _messageFocusNode.addListener(() {
      if (_messageFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (!mounted) return;
          try {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
              );
            }
          } catch (_) {}
        });
      }
    });
  }

  @override
  void dispose() {
    try { _audioPlayer.dispose(); } catch (_) {}
    _messageController.dispose();
    try { _scrollController.dispose(); } catch (_) {}
    _recTimer?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _messageFocusNode.dispose();
    super.dispose();
  }

  // ===== تحميل الرسائل + تعليم الواردة =====
  void _loadMessages() {
    final user = _loading_controller_currentUser();
    if (user != null) {
      _chatController
          .fetchMessages(
            userId: user.id ?? 0,
            partnerId: widget.ad?.userId ?? widget.idAdv,
            adId: widget.ad?.id,
            advertiserProfileId: widget.idAdv,
          )
          .then((_) async {
        if (!mounted) return;
        await _autoMarkIncomingAsRead();
        if (_scrollController.hasClients) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            try {
              _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
            } catch (_) {}
          });
        }
      });
    }
  }

  Future<void> _autoMarkIncomingAsRead() async {
    final user = _loading_controller_currentUser();
    if (user == null) return;

    for (final m in _chatController.messagesList) {
      final isIncoming = m.recipientId == user.id;
      if (isIncoming && m.isRead == false) {
        final ok = await _chatController.markAsRead(m.id);
        if (ok) {
          final idx = _chatController.messagesList.indexWhere((x) => x.id == m.id);
          if (idx >= 0) {
            final old = _chatController.messagesList[idx];
            _chatController.messagesList[idx] = Message(
              id: old.id,
              senderId: old.senderId,
              senderEmail: old.senderEmail,
              recipientId: old.recipientId,
              recipientEmail: old.recipientEmail,
              body: old.body,
              isVoice: old.isVoice,
              voiceUrl: old.voiceUrl,
              isRead: true,
              createdAt: old.createdAt,
              readAt: DateTime.now(),
              updatedAt: old.updatedAt,
              adId: old.adId,
              adNumber: old.adNumber,
              adTitleAr: old.adTitleAr,
              adTitleEn: old.adTitleEn,
              adSlug: old.adSlug,
              adDescriptionAr: old.adDescriptionAr,
              adDescriptionEn: old.adDescriptionEn,
              adPrice: old.adPrice,
              adShowTime: old.adShowTime,
              adCreatedAt: old.adCreatedAt,
              adImages: old.adImages,
              advertiserProfileId: old.advertiserProfileId,
              advertiserUserId: old.advertiserUserId,
              advertiserName: old.advertiserName,
              advertiserLogo: old.advertiserLogo,
              advertiserDescription: old.advertiserDescription,
              advertiserContactPhone: old.advertiserContactPhone,
              advertiserWhatsappPhone: old.advertiserWhatsappPhone,
              advertiserWhatsappCallNumber: old.advertiserWhatsappCallNumber,
              advertiserWhatsappUrl: old.advertiserWhatsappUrl,
              advertiserTelUrl: old.advertiserTelUrl,
              advertiserLatitude: old.advertiserLatitude,
              advertiserLongitude: old.advertiserLongitude,
              adCompanyMember: old.adCompanyMember,
            );
          }
        }
      }
    }
    if (mounted) setState(() {});
  }

  // ===== إرسال نص =====
  void _sendMessage() {
    final user = _loading_controller_currentUser();
    if (user != null && _messageController.text.trim().isNotEmpty) {
      final text = _messageController.text.trim();
      _messageController.clear();

      _chatController
          .sendMessage(
            senderId: user.id ?? 0,
            recipientId: widget.ad?.userId ?? widget.idAdv,
            adId: widget.ad?.id,
            advertiserProfileId: widget.idAdv,
            body: text,
          )
          .then((success) async {
        if (success) {
          await _loadAndScrollAfterDelay();
        } else {
          _messageController.text = text;
          Get.snackbar('خطأ', 'فشل إرسال الرسالة', backgroundColor: Colors.red, colorText: Colors.white);
        }
      });
    }
  }

  dynamic _loading_controller_currentUser() => _loadingController.currentUser;

  // ===== واجهة التسجيل المحلي =====
  void _startLocalRecordingUI(PendingVoice pv) {
    _recTimer?.cancel();
    _recDuration = Duration.zero;
    _recTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _recDuration = _recDuration + const Duration(seconds: 1);
        pv.duration = _recDuration;
      });
    });
    if (!mounted) return;
    setState(() => _isLocallyRecording = true);
  }

  void _stopLocalRecordingUI() {
    _recTimer?.cancel();
    if (!mounted) return;
    setState(() => _isLocallyRecording = false);
  }

  String _formatRecDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  Future<void> _onStartRecordingGesture() async {
    final user = _loading_controller_currentUser();
    if (user == null) {
      Get.snackbar('خطأ', 'المستخدم غير مسجل', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    final pv = PendingVoice(tempId: _nextTempId--, status: PendingVoiceStatus.recording);
    if (!mounted) return;
    setState(() => _pendingVoices.add(pv));
    try {
      await _chatController.startRecording();
      _startLocalRecordingUI(pv);
    } catch (e) {
      if (!mounted) return;
      setState(() => pv.status = PendingVoiceStatus.failed);
      Get.snackbar('خطأ', 'فشل بدء التسجيل', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _onStopRecordingGestureAndSend() async {
    if (_pendingVoices.isEmpty) {
      try {
        final localPath = await _chatController.stopRecording();
        _stopLocalRecordingUI();
        if (localPath != null && localPath.isNotEmpty) {
          await _uploadAndSendFromLocalPath(localPath, Duration.zero);
        } else {
          Get.snackbar('خطأ', 'لم يتم تسجيل أي صوت', backgroundColor: Colors.red, colorText: Colors.white);
        }
      } catch (e) {
        Get.snackbar('خطأ', 'فشل إنهاء التسجيل', backgroundColor: Colors.red, colorText: Colors.white);
      }
      return;
    }

    final pv = _pendingVoices.lastWhere((p) => p.status == PendingVoiceStatus.recording, orElse: () => _pendingVoices.last);

    try {
      final localPath = await _chatController.stopRecording();
      _stopLocalRecordingUI();

      if (localPath == null || localPath.isEmpty) {
        if (!mounted) return;
        setState(() => pv.status = PendingVoiceStatus.failed);
        Get.snackbar('خطأ', 'لم يتم تسجيل أي صوت', backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      if (!mounted) return;
      setState(() {
        pv.localPath = localPath;
        pv.status = PendingVoiceStatus.uploading;
        pv.uploadProgress = -1;
      });

      final user = _loading_controller_currentUser();
      if (user == null) {
        if (!mounted) return;
        setState(() => pv.status = PendingVoiceStatus.failed);
        Get.snackbar('خطأ', 'المستخدم غير مسجل', backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      final success = await _chatController.sendVoiceMessage(
        senderId: user.id ?? 0,
        recipientId: widget.ad?.userId ?? widget.idAdv,
        adId: widget.ad?.id,
        advertiserProfileId: widget.idAdv,
        localFilePath: localPath,
      );

      if (success) {
        if (!mounted) return;
        setState(() => _pendingVoices.removeWhere((x) => x.localPath == localPath || x.tempId == pv.tempId));
        try { await _chatController.deleteLocalRecording(); } catch (_) {}
        await _loadAndScrollAfterDelay();
      } else {
        if (!mounted) return;
        setState(() => pv.status = PendingVoiceStatus.failed);
        Get.snackbar('فشل', 'لم يتم إرسال الرسالة الصوتية', backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (_pendingVoices.isNotEmpty) _pendingVoices.last.status = PendingVoiceStatus.failed;
        });
      }
      Get.snackbar('خطأ', 'فشل إنهاء التسجيل', backgroundColor: Colors.red, colorText: Colors.white);
      _stopLocalRecordingUI();
    }
  }

  Future<void> _cancelRecording() async {
    if (_pendingVoices.isEmpty) return;
    final pv = _pendingVoices.last;

    try {
      try {
        final path = await _chatController.stopRecording();
        if (path != null) {
          final f = File(path);
          if (await f.exists()) await f.delete();
        }
      } catch (_) {}

      try { await _chatController.deleteLocalRecording(); } catch (_) {}

      if (!mounted) return;
      setState(() => _pendingVoices.removeWhere((p) => p.tempId == pv.tempId));
      _stopLocalRecordingUI();
    } catch (e) {
      Get.snackbar('خطأ', 'فشل إلغاء التسجيل', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _uploadAndSendFromLocalPath(String localPath, Duration duration) async {
    final user = _loading_controller_currentUser();
    if (user == null) return;

    final ok = await _chatController.sendVoiceMessage(
      senderId: user.id ?? 0,
      recipientId: widget.ad?.userId ?? widget.idAdv,
      adId: widget.ad?.id,
      advertiserProfileId: widget.idAdv,
      localFilePath: localPath,
    );

    if (ok) {
      if (mounted) setState(() => _pendingVoices.removeWhere((p) => p.localPath == localPath));
      await _loadAndScrollAfterDelay();
    } else {
      if (mounted) {
        setState(() {
          final p = _pendingVoices.firstWhere(
            (p) => p.localPath == localPath,
            orElse: () => PendingVoice(tempId: -9999, status: PendingVoiceStatus.failed),
          );
          if (p.tempId != -9999) p.status = PendingVoiceStatus.failed;
        });
      }
    }
  }

  Future<void> _loadAndScrollAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    await _chatController.fetchMessages(
      userId: _loading_controller_currentUser()?.id ?? 0,
      partnerId: widget.ad?.userId ?? widget.idAdv,
      adId: widget.ad?.id,
      advertiserProfileId: widget.idAdv,
    );
    if (!mounted) return;
    await _autoMarkIncomingAsRead();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      } catch (_) {}
    });
  }

  Future<void> _playPauseVoice(Message message) async {
    final url = message.voiceUrl;
    if (url == null || url.isEmpty) return;

    if (_playingMessageId == message.id) {
      try { await _audioPlayer.pause(); } catch (_) {}
      if (!mounted) return;
      setState(() => _playingMessageId = null);
    } else {
      try {
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(url));
        if (!mounted) return;
        setState(() => _playingMessageId = message.id);
      } catch (e) {
        Get.snackbar('خطأ', 'لا يمكن تشغيل الصوت', backgroundColor: Colors.red, colorText: Colors.white);
      }
    }
  }

  Future<void> _ensureMessageDuration(Message message) async {
    if (message.id == null) return;
    if (_messageDurations.containsKey(message.id)) return;

    final player = AudioPlayer();
    try {
      if (message.voiceUrl == null || message.voiceUrl!.isEmpty) return;
      await player.setSourceUrl(message.voiceUrl!);
      final duration = await player.getDuration().timeout(const Duration(seconds: 10));
      if (duration != null && duration.inMilliseconds > 0) {
        _messageDurations[message.id!] = duration;
        if (mounted) setState(() {});
      }
    } on TimeoutException {
    } catch (e) {
    } finally {
      try { await player.dispose(); } catch (_) {}
    }
  }

  // تنسيق التاريخ
  String _formatDateTimeFull(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'ص' : 'م';
    final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$day/$month/$year  ${formattedHour.toString().padLeft(2, '0')}:$minute $period';
  }

  // تنسيق السعر: بدون كسور + فواصل آلاف
  String _formatPrice(num value) {
    final s = value.toStringAsFixed(0);
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return s.replaceAllMapped(reg, (m) => ',');
  }
// ConversationScreen.dart — Part 2/3 (build/UI)

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeController.isDarkMode.value;
    final cardColor = AppColors.background(isDarkMode);
    final textPrimary = AppColors.textPrimary(isDarkMode);
    final textSecondary = AppColors.textSecondary(isDarkMode);
    final dividerColor = AppColors.divider(isDarkMode);

    const whatsappLightGreen = Color(0xFFDCF8C6);
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      key: _scaffoldKey,
      drawer: Menubar(),
      backgroundColor: AppColors.background(isDarkMode),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildCustomAppBar(isDarkMode, textPrimary),
                if (widget.ad != null)
                  _buildAdMiniCard(cardColor, textPrimary, textSecondary)
                else
                  _buildNoAdNotice(cardColor, textPrimary),

                Expanded(
                  child: Obx(() {
                    if (_chatController.isLoadingMessages.value) {
                      return Center(child: CircularProgressIndicator(color: AppColors.primary));
                    }

                    final serverMessages = _chatController.messagesList;
                    final totalCount = serverMessages.length + _pendingVoices.length;

                    return ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.only(bottom: viewInsetsBottom + 160.h, top: 12.h),
                      itemCount: totalCount,
                      itemBuilder: (context, idx) {
                        if (idx < serverMessages.length) {
                          final message = serverMessages[idx];
                          final currentUser = _loading_controller_currentUser();
                          final isCurrentUser = currentUser != null && (currentUser.id == message.senderId);

                          if (message.isVoice == true && (message.voiceUrl ?? '').isNotEmpty) {
                            _ensureMessageDuration(message);
                          }

                          return _buildMessageBubbleWithDelete(
                            message,
                            isDarkMode,
                            isCurrentUser,
                            widget.advertiser,
                            whatsappLightGreen,
                          );
                        } else {
                          final pvIndex = idx - serverMessages.length;
                          final pv = _pendingVoices[pvIndex];
                          return _buildPendingVoiceBubble(pv, isDarkMode, true, widget.advertiser, whatsappLightGreen);
                        }
                      },
                    );
                  }),
                ),
              ],
            ),

            // الإدخال العائم
            Positioned(
              left: 12.w,
              right: 12.w,
              bottom: viewInsetsBottom + 12.h,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLocallyRecording) _buildRecordingBar(),
                    _buildFloatingInput(isDarkMode, cardColor, dividerColor),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(bool isDarkMode, Color titleColor) {
    final adv = widget.advertiser;
    return Container(
      height: 60.h,
      color: AppColors.appBar(isDarkMode),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(
              padding: EdgeInsets.all(4.w),
              child: InkWell(onTap: () => Get.back(), child: Icon(Icons.arrow_back, color: AppColors.onPrimary, size: 22.w)),
            ),
            SizedBox(width: 2.w),
            Container(
              padding: EdgeInsets.all(4.w),
              child: InkWell(onTap: () => _scaffoldKey.currentState?.openDrawer(), child: Icon(Icons.menu, color: AppColors.onPrimary, size: 22.w)),
            ),
            SizedBox(width: 12.w),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                width: 200.w,
                child: Text(
                  adv.name ?? 'معلن',
                  style: TextStyle(color: AppColors.onPrimary, fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                (adv.contactPhone ?? '').trim(),
                style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.small, color: AppColors.onPrimary.withOpacity(0.9), fontWeight: FontWeight.w600),
              ),
            ]),
          ]),
          Row(children: [
            // كلا الأزرار تفتح نفس شاشة التواصل الموحدة حسب نوع الحساب
            Container(
              padding: EdgeInsets.all(4.w),
              child: InkWell(onTap: _openContactSideSheet, child: Icon(Icons.phone, color: AppColors.onPrimary, size: 22.w)),
            ),
            SizedBox(width: 2.w),
            Container(
              padding: EdgeInsets.all(4.w),
              child: InkWell(onTap: _openContactSideSheet, child: Icon(Icons.more_vert, color: AppColors.onPrimary, size: 22.w)),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildRecordingBar() {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
      child: Row(
        children: [
          const Icon(Icons.mic, color: Colors.white),
          SizedBox(width: 8.w),
          Expanded(child: Text('تسجيل... ${_formatRecDuration(_recDuration)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: _cancelRecording,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12.r)),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white)),
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: _onStopRecordingGestureAndSend,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12.r)),
              child: const Text('إيقاف وإرسال', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingInput(bool isDarkMode, Color cardColor, Color dividerColor) {
    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(28.r),
      color: cardColor,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(28.r), color: cardColor),
        child: Row(
          children: [
            GestureDetector(
              onLongPressStart: (_) async => await _onStartRecordingGesture(),
              onLongPressEnd: (_) async => await _onStopRecordingGestureAndSend(),
              onTap: () async {
                if (_isLocallyRecording) {
                  await _onStopRecordingGestureAndSend();
                } else {
                  await _onStartRecordingGesture();
                }
              },
              child: Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(shape: BoxShape.circle, color: _isLocallyRecording ? Colors.red : AppColors.buttonAndLinksColor),
                child: Icon(_isLocallyRecording ? Icons.mic_off : Icons.mic, color: Colors.white),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Container(
                height: 48.h,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(color: AppColors.border(isDarkMode), borderRadius: BorderRadius.circular(20.r)),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      focusNode: _messageFocusNode,
                      controller: _messageController,
                      style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.large, color: AppColors.textPrimary(isDarkMode)),
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالة...'.tr,
                        hintStyle: TextStyle(color: AppColors.textSecondary(isDarkMode)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ]),
              ),
            ),
            SizedBox(width: 8.w),
            FloatingActionButton(
              onPressed: _sendMessage,
              mini: true,
              backgroundColor: AppColors.buttonAndLinksColor,
              child: const Icon(Icons.send, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdMiniCard(Color cardColor, Color textPrimary, Color textSecondary) {
    return Container(
      padding: EdgeInsets.all(12.r),
      margin: EdgeInsets.symmetric(horizontal: 0.w, vertical: 6.h),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(0.r)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.ad?.images.isNotEmpty == true)
            SizedBox(
              width: 60.w,
              height: 60.h,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.network(
                  widget.ad!.images[0],
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(color: AppColors.greyLight, child: Icon(Icons.image, size: 30.sp)),
                ),
              ),
            ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.ad?.title ?? 'اعلان',
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.medium,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 24, 117, 232),
                  ),
                ),
                SizedBox(height: 6.h),
                if (widget.ad?.price != null)
                  Text(
                    '${_formatPrice(widget.ad!.price!)}${" ليرة سورية".tr}',
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.medium,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(_themeController.isDarkMode.value),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAdNotice(Color cardColor, Color textPrimary) {
    return Container(
      padding: EdgeInsets.all(12.r),
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12.r)),
      child: Row(children: [
        Icon(Icons.info_outline, color: AppColors.primary, size: 20.sp),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            'هذه المحادثة تتم بدون أي إعلان ذي صلة بين المعلن والمتحدث'.tr,
            style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.small, color: textPrimary),
          ),
        ),
      ]),
    );
  }

  // مؤشر القراءة لرسائلي
  Widget _readReceiptIcon(Message msg, bool isMine) {
    if (!isMine) return const SizedBox.shrink();
    final read = msg.isRead == true;
    return Padding(
      padding: const EdgeInsets.only(left: 6.0),
      child: Icon(
        Icons.done_all_rounded,
        size: 16,
        color: read ? Color(0xFF34B7F1) : _receiptGrey.withOpacity(0.85),
      ),
    );
  }

  // فقاعة الرسائل + حذف
  Widget _buildMessageBubbleWithDelete(
    Message message,
    bool isDarkMode,
    bool isCurrentUser,
    Advertiser? advertiser,
    Color userBubbleColor, {
    PendingVoice? pendingVoice,
  }) {
    final otherBubbleColor = AppColors.card(isDarkMode);
    final textColor = isCurrentUser ? Colors.black : AppColors.textPrimary(isDarkMode);
    final timeColor = isCurrentUser ? Colors.black.withOpacity(0.6) : AppColors.textSecondary(isDarkMode);
    final align = isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final mainAxis = isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start;

    final isVoice = message.isVoice == true;
    final dur = (message.id != null && _messageDurations.containsKey(message.id))
        ? _messageDurations[message.id]!
        : Duration.zero;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: Row(
              mainAxisAlignment: mainAxis,
              children: [
                if (isCurrentUser)
                  GestureDetector(
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: AppColors.background(_themeController.isDarkMode.value),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                          title: Text(
                            'حذف الرسالة',
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              fontSize: AppTextStyles.medium,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary(_themeController.isDarkMode.value),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          content: Text(
                            'هل تريد حذف هذه الرسالة؟',
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              fontSize: AppTextStyles.medium,
                              color: AppColors.textSecondary(_themeController.isDarkMode.value),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          actions: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.grey[300],
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                      padding: EdgeInsets.symmetric(vertical: 12.h),
                                    ),
                                    child: const Text('لا', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                      padding: EdgeInsets.symmetric(vertical: 12.h),
                                    ),
                                    child: const Text('نعم', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await _confirmAndDeleteMessage(message);
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.r)),
                      child: Icon(Icons.more_vert, size: 18.sp, color: AppColors.textSecondary(isDarkMode)),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: mainAxis,
            children: [
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: 300.w),
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: isCurrentUser ? userBubbleColor : otherBubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isCurrentUser ? 16.r : 6.r),
                      topRight: Radius.circular(isCurrentUser ? 6.r : 16.r),
                      bottomLeft: Radius.circular(16.r),
                      bottomRight: Radius.circular(16.r),
                    ),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isVoice)
                        _buildVoiceBubbleContent(message, null, dur, isCurrentUser)
                      else
                        Text(
                          message.body ?? '',
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            fontSize: AppTextStyles.large,
                            color: textColor,
                            height: 1.4,
                          ),
                        ),
                      SizedBox(height: 6.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_formatDateTimeFull(message.createdAt), style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 10.sp, color: timeColor)),
                          _readReceiptIcon(message, isCurrentUser),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingVoiceBubble(
    PendingVoice pv,
    bool isDarkMode,
    bool isCurrentUser,
    Advertiser? advertiser,
    Color userBubbleColor,
  ) {
    final timeColor = isCurrentUser ? Colors.black.withOpacity(0.6) : AppColors.textSecondary(isDarkMode);
    final align = isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final mainAxis = isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: Row(
              mainAxisAlignment: mainAxis,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(color: AppColors.border(isDarkMode), borderRadius: BorderRadius.circular(8.r)),
                  child: Text('أنا', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.small, fontWeight: FontWeight.w600, color: AppColors.textSecondary(isDarkMode))),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: mainAxis,
            children: [
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: 300.w),
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: userBubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.r),
                      topRight: Radius.circular(6.r),
                      bottomLeft: Radius.circular(16.r),
                      bottomRight: Radius.circular(16.r),
                    ),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_pendingIconForStatus(pv.status), size: 30.sp, color: Colors.white),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_pendingTitleForStatus(pv.status), style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.large, color: Colors.white)),
                                SizedBox(height: 6.h),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_formatRecDuration(pv.duration), style: TextStyle(fontSize: 12.sp, color: Colors.white70)),
                                    if (pv.status == PendingVoiceStatus.uploading)
                                      Row(children: [SizedBox(width: 8.w), SizedBox(width: 16.w, height: 16.w, child: const CircularProgressIndicator(strokeWidth: 2))]),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Align(alignment: Alignment.centerRight, child: Text(_formatDateTimeFull(pv.createdAt), style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 10.sp, color: timeColor))),
                      if (pv.status == PendingVoiceStatus.failed)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () async {
                                if (pv.localPath != null) {
                                  if (!mounted) return;
                                  setState(() => pv.status = PendingVoiceStatus.uploading);
                                  final user = _loading_controller_currentUser();
                                  if (user != null) {
                                    final ok = await _chatController.sendVoiceMessage(
                                      senderId: user.id ?? 0,
                                      recipientId: widget.ad?.userId ?? widget.idAdv,
                                      adId: widget.ad?.id,
                                      advertiserProfileId: widget.idAdv,
                                      localFilePath: pv.localPath!,
                                    );
                                    if (ok) {
                                      if (!mounted) return;
                                      setState(() => pv.status = PendingVoiceStatus.sent);
                                      await _loadAndScrollAfterDelay();
                                    } else {
                                      if (!mounted) return;
                                      setState(() => pv.status = PendingVoiceStatus.failed);
                                    }
                                  }
                                } else {
                                  Get.snackbar('خطأ', 'لا يوجد ملف محلي لإعادة المحاولة', backgroundColor: Colors.red, colorText: Colors.white);
                                }
                              },
                              child: const Text('إعادة المحاولة'),
                            ),
                            TextButton(onPressed: () async => await _cancelRecording(), child: const Text('حذف')),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceBubbleContent(Message message, PendingVoice? pv, Duration? cachedDuration, bool isCurrentUser) {
    final isPending = pv != null;
    final displayDuration = isPending ? pv!.duration : (cachedDuration ?? Duration.zero);

    if (!isPending && message.voiceUrl != null && (message.id != null) && !_messageDurations.containsKey(message.id)) {
      _ensureMessageDuration(message);
    }

    final playing = _playingMessageId == message.id;
    final currentPos = playing ? _currentPosition : Duration.zero;
    final totalDur = playing ? (_currentDuration > Duration.zero ? _currentDuration : (cachedDuration ?? Duration.zero)) : (cachedDuration ?? Duration.zero);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: isPending ? null : () => _playPauseVoice(message),
              icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 30.sp, color: isCurrentUser ? Colors.black : AppColors.primary),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isPending)
                    Row(children: [const Expanded(child: Text('...')), SizedBox(width: 8.w), Text(_formatRecDuration(displayDuration), style: TextStyle(fontSize: 12.sp))])
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (playing || (totalDur.inSeconds > 0))
                          Column(
                            children: [
                              Slider(
                                value: currentPos.inMilliseconds.toDouble().clamp(0, (totalDur.inMilliseconds > 0 ? totalDur.inMilliseconds : 1).toDouble()),
                                max: (totalDur.inMilliseconds > 0 ? totalDur.inMilliseconds.toDouble() : 1.0),
                                onChanged: (v) async {
                                  try { await _audioPlayer.seek(Duration(milliseconds: v.toInt())); } catch (e) {}
                                },
                              ),
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Text(_formatRecDuration(currentPos), style: TextStyle(fontSize: 11.sp)),
                                Text(_formatRecDuration(totalDur), style: TextStyle(fontSize: 11.sp)),
                              ]),
                            ],
                          )
                        else
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            const Text('00:00', style: TextStyle(fontSize: 11)),
                            Text(_formatRecDuration(cachedDuration ?? Duration.zero), style: const TextStyle(fontSize: 11)),
                          ]),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _pendingIconForStatus(PendingVoiceStatus s) {
    switch (s) {
      case PendingVoiceStatus.recording: return Icons.mic;
      case PendingVoiceStatus.uploading: return Icons.cloud_upload;
      case PendingVoiceStatus.failed:    return Icons.error;
      case PendingVoiceStatus.sent:      return Icons.check_circle;
    }
  }

  String _pendingTitleForStatus(PendingVoiceStatus s) {
    switch (s) {
      case PendingVoiceStatus.recording: return 'تسجيل...';
      case PendingVoiceStatus.uploading: return 'جاري الرفع...';
      case PendingVoiceStatus.failed:    return 'فشل الرفع';
      case PendingVoiceStatus.sent:      return 'أُرسل';
    }
  }
// ConversationScreen.dart — Part 3/3 (Contact Sheet + helpers)

  // ===== الإطلاقات =====
  Future<void> _launchWhatsAppChat(String? phone) async {
    if (phone == null || phone.isEmpty) {
      Get.snackbar('خطأ', 'رقم غير متاح', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    final cleaned = _cleanPhoneNumber(phone);
    final Uri url = Uri.parse('https://wa.me/$cleaned');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('خطأ', 'لا يمكن فتح واتساب', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _launchWhatsAppCall(String? phone) async {
    await _launchWhatsAppChat(phone);
  }

  Future<void> _launchPhoneCall(String? phone) async {
    if (phone == null || phone.isEmpty) {
      Get.snackbar('خطأ', 'رقم غير متاح', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    final cleaned = _cleanPhoneNumber(phone);
    final Uri url = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('خطأ', 'لا يمكن فتح تطبيق الهاتف', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  String _cleanPhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }

  // ===== حذف رسالة (مع تأكيد سبق عرضه) =====
  Future<void> _confirmAndDeleteMessage(Message message) async {
    final user = _loading_controller_currentUser();
    if (user == null) return;

    final isMine = message.senderId == user.id;
    if (!isMine) {
      Get.snackbar('تنبيه', 'لا يمكنك حذف رسالة ليست لك', backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    final ok = await _chatController.deleteMessage(message.id ?? 0);
    if (ok) {
      if (!mounted) return;
      setState(() {});
      Get.snackbar('تم', 'تم حذف الرسالة', backgroundColor: Colors.green, colorText: Colors.white);
    } else {
      Get.snackbar('خطأ', 'فشل حذف الرسالة', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  // ===== شاشة التواصل الموحّدة: شركة/فردي =====
  void _openContactSideSheet() {
    final adv = widget.advertiser;

    // نحاول استخراج عضو الشركة من الرسائل (إن وجد)
    CompanyMemberMessage? member;
    if (_chatController.messagesList.isNotEmpty) {
      member = _chatController.messagesList.firstWhereOrNull((m) => m.adCompanyMember != null)?.adCompanyMember;
    }

    // تحديد نوع الحساب:
    final bool isCompany = (adv.accountType?.toLowerCase() == 'company') || (member != null);

    showGeneralDialog(
      context: context,
      barrierLabel: 'contact-sheet',
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) {
        final isDark = _themeController.isDarkMode.value;
        final bg = AppColors.card(isDark);
        final titleStyle = TextStyle(fontFamily: AppTextStyles.appFontFamily, fontWeight: FontWeight.w700, fontSize: 16.sp, color: AppColors.textPrimary(isDark));
        final labelStyle = TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 12.sp, color: AppColors.textSecondary(isDark));
        final valueStyle = TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 13.sp, color: AppColors.textPrimary(isDark));

        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.86,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12)],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // رأس
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      child: Row(
                        children: [
                          Expanded(child: Text('التواصل', style: titleStyle)),
                          IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.close)),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // العنوان الأعلى حسب النوع
                            _sectionHeader(isCompany ? 'بيانات الشركة' : 'بيانات المعلن'),
                            SizedBox(height: 8.h),

                            // في حالة فردي: اسم الشخص وأرقامه فقط
                            // في حالة شركة: اسم الشركة، ثم قسم "الشخص المسؤول" بأرقام العضو فقط
                            if (!isCompany) ...[
                              _kv('الاسم', adv.name ?? '-', labelStyle, valueStyle),
                              if ((adv.contactPhone ?? '').isNotEmpty) ...[
                                SizedBox(height: 6.h),
                                _contactTile('اتصال هاتفي', adv.contactPhone!, onTap: () => _launchPhoneCall(adv.contactPhone)),
                              ],
                              if ((adv.whatsappPhone ?? '').isNotEmpty) ...[
                                SizedBox(height: 6.h),
                                _contactTile('واتساب', adv.whatsappPhone!, onTap: () => _launchWhatsAppChat(adv.whatsappPhone)),
                              ],
                              if ((adv.whatsappPhone ?? '').isNotEmpty) ...[
                                SizedBox(height: 6.h),
                                _contactTile('اتصال واتساب', adv.whatsappPhone!, onTap: () => _launchWhatsAppCall(adv.whatsappPhone)),
                              ],
                              SizedBox(height: 20.h),
                              _sectionHeader('اختصارات سريعة'),
                              SizedBox(height: 8.h),
                              Wrap(
                                spacing: 8.w,
                                runSpacing: 8.h,
                                children: [
                                  if ((adv.contactPhone ?? '').isNotEmpty)
                                    _quickActionChip(icon: Icons.call, label: 'اتصال', onTap: () => _launchPhoneCall(adv.contactPhone)),
                                  if ((adv.whatsappPhone ?? '').isNotEmpty)
                                    _quickActionChip(icon: Icons.chat, label: 'واتساب', onTap: () => _launchWhatsAppChat(adv.whatsappPhone)),
                                  if ((adv.whatsappPhone ?? '').isNotEmpty)
                                    _quickActionChip(icon: Icons.call, label: 'اتصال واتساب', onTap: () => _launchWhatsAppCall(adv.whatsappPhone)),
                                ],
                              ),
                            ] else ...[
                              // شركة: نعرض اسم الشركة فقط هنا (بدون أرقام الشركة)
                              _kv('اسم الشركة', adv.name ?? '-', labelStyle, valueStyle),

                              // عضو الشركة (المسؤول) + أرقامه فقط
                              SizedBox(height: 16.h),
                              _sectionHeader('الشخص المسؤول'),
                              SizedBox(height: 8.h),
                              _kv('الاسم', (member?.displayName ?? adv.name) ?? '-', labelStyle, valueStyle),
                              if ((member?.contactPhone ?? '').isNotEmpty) ...[
                                SizedBox(height: 6.h),
                                _contactTile('اتصال هاتفي (العضو)', member!.contactPhone!, onTap: () => _launchPhoneCall(member!.contactPhone)),
                              ],
                              if ((member?.whatsappPhone ?? '').isNotEmpty) ...[
                                SizedBox(height: 6.h),
                                _contactTile('واتساب (العضو)', member!.whatsappPhone!, onTap: () => _launchWhatsAppChat(member!.whatsappPhone)),
                              ],
                              if ((member?.whatsappCallNumber ?? '').isNotEmpty) ...[
                                SizedBox(height: 6.h),
                                _contactTile('اتصال واتساب (العضو)', member!.whatsappCallNumber!, onTap: () => _launchWhatsAppCall(member!.whatsappCallNumber)),
                              ],

                              SizedBox(height: 20.h),
                              _sectionHeader('اختصارات سريعة'),
                              SizedBox(height: 8.h),
                              Wrap(
                                spacing: 8.w,
                                runSpacing: 8.h,
                                children: [
                                  if ((member?.contactPhone ?? '').isNotEmpty)
                                    _quickActionChip(icon: Icons.person, label: 'اتصال بالعضو', onTap: () => _launchPhoneCall(member!.contactPhone)),
                                  if ((member?.whatsappPhone ?? '').isNotEmpty)
                                    _quickActionChip(icon: Icons.chat, label: 'واتساب العضو', onTap: () => _launchWhatsAppChat(member!.whatsappPhone)),
                                  if ((member?.whatsappCallNumber ?? '').isNotEmpty)
                                    _quickActionChip(icon: Icons.call, label: 'اتصال واتساب العضو', onTap: () => _launchWhatsAppCall(member!.whatsappCallNumber)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim, _, child) {
        final offset = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
        return SlideTransition(position: offset, child: child);
      },
    );
  }

  Widget _sectionHeader(String title) {
    final isDark = _themeController.isDarkMode.value;
    return Row(
      children: [
        Icon(Icons.info, color: AppColors.primary, size: 18.sp),
        SizedBox(width: 6.w),
        Text(
          title,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 14.sp,
            color: AppColors.textPrimary(isDark),
          ),
        ),
      ],
    );
  }

  Widget _kv(String label, String value, TextStyle labelStyle, TextStyle valueStyle) {
    return Row(
      children: [
        SizedBox(width: 120.w, child: Text(label, style: labelStyle)),
        Expanded(child: Text(value, style: valueStyle, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _contactTile(String title, String phone, {required VoidCallback onTap}) {
    final isDark = _themeController.isDarkMode.value;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: const Icon(Icons.call),
      title: Text(
        title,
        style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontWeight: FontWeight.w600, color: AppColors.textPrimary(isDark)),
      ),
      subtitle: Text(
        phone,
        style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.textSecondary(isDark)),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      tileColor: AppColors.border(isDark).withOpacity(0.4),
    );
  }

  Widget _quickActionChip({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          color: AppColors.primary.withOpacity(0.08),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16.sp, color: AppColors.primary),
            SizedBox(width: 6.w),
            Text(label, style: TextStyle(fontFamily: AppTextStyles.appFontFamily)),
          ],
        ),
      ),
    );
  }
}
