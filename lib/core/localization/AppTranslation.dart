import 'package:get/get.dart';

import 'en_us.dart';
import 'ar_ae.dart';


class AppTranslation extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en': enUS,
        'ar': arAE,
       
      };
}
