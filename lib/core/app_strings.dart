import 'package:flutter/widgets.dart';

class AppStrings {
  final String code;
  const AppStrings(this.code);

  static const supported = ['en', 'ur', 'ar', 'hi', 'fa'];

  static AppStrings of(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return AppStrings(supported.contains(locale) ? locale : 'en');
  }

  String _t(String key) {
    final map = _values[code] ?? _values['en']!;
    return map[key] ?? _values['en']![key] ?? key;
  }

  String get appName => _t('appName');
  String get newBook => _t('newBook');
  String get importFile => _t('importFile');
  String get settings => _t('settings');
  String get noBooks => _t('noBooks');
  String get noMatches => _t('noMatches');
  String get searchHint => _t('searchHint');
  String get untitledBook => _t('untitledBook');
  String get chapters => _t('chapters');
  String get chapter => _t('chapter');
  String get delete => _t('delete');
  String get cancel => _t('cancel');
  String get create => _t('create');
  String get ok => _t('ok');
  String get title => _t('title');
  String get author => _t('author');
  String get language => _t('language');
  String get deleteBook => _t('deleteBook');
  String get appearance => _t('appearance');
  String get appLanguage => _t('appLanguage');
  String get themeMode => _t('themeMode');
  String get themeColor => _t('themeColor');
  String get system => _t('system');
  String get light => _t('light');
  String get dark => _t('dark');
  String get bookTemplate => _t('bookTemplate');
  String get applyToAll => _t('applyToAll');
  String get selectBlocks => _t('selectBlocks');
  String get selected => _t('selected');
  String get wholePage => _t('wholePage');
  String get preview => _t('preview');
  String get write => _t('write');
  String get format => _t('format');
  String get outline => _t('outline');
  String get ai => _t('ai');
  String get livePreview => _t('livePreview');
  String get updatesAsYouType => _t('updatesAsYouType');
  String get noBlocksSelected => _t('noBlocksSelected');

  static const Map<String, Map<String, String>> _values = {
    'en': {
      'appName': 'Urdu Book Studio',
      'newBook': 'New book',
      'importFile': 'Import book file',
      'settings': 'Settings',
      'noBooks': 'No books yet. Tap "New book" or import a file.',
      'noMatches': 'No matching books.',
      'searchHint': 'Search books, authors or languages',
      'untitledBook': 'Untitled book',
      'chapters': 'chapters',
      'chapter': 'Chapter',
      'delete': 'Delete',
      'cancel': 'Cancel',
      'create': 'Create',
      'ok': 'OK',
      'title': 'Title',
      'author': 'Author',
      'language': 'Language',
      'deleteBook': 'Delete book?',
      'appearance': 'Appearance',
      'appLanguage': 'App language',
      'themeMode': 'Theme mode',
      'themeColor': 'Theme color',
      'system': 'System',
      'light': 'Light',
      'dark': 'Dark',
      'bookTemplate': 'Book template',
      'applyToAll': 'Apply to all blocks',
      'selectBlocks': 'Select blocks',
      'selected': 'selected',
      'wholePage': 'Whole page font',
      'preview': 'Preview',
      'write': 'Write',
      'format': 'Format',
      'outline': 'Outline',
      'ai': 'AI',
      'livePreview': 'Live preview',
      'updatesAsYouType': 'Updates as you type',
      'noBlocksSelected': 'Select blocks to apply font changes.',
    },
    'ur': {
      'appName': 'اردو بک اسٹوڈیو',
      'newBook': 'نئی کتاب',
      'importFile': 'کتاب فائل درآمد کریں',
      'settings': 'ترتیبات',
      'noBooks': 'ابھی کوئی کتاب نہیں۔ "نئی کتاب" پر ٹیپ کریں یا فائل درآمد کریں۔',
      'noMatches': 'کوئی ملتی ہوئی کتاب نہیں۔',
      'searchHint': 'کتابیں، مصنفین یا زبانیں تلاش کریں',
      'untitledBook': 'بے نام کتاب',
      'chapters': 'ابواب',
      'chapter': 'باب',
      'delete': 'حذف کریں',
      'cancel': 'منسوخ',
      'create': 'بنائیں',
      'ok': 'ٹھیک ہے',
      'title': 'عنوان',
      'author': 'مصنف',
      'language': 'زبان',
      'deleteBook': 'کتاب حذف کریں؟',
      'appearance': 'ظاہری شکل',
      'appLanguage': 'ایپ کی زبان',
      'themeMode': 'تھیم موڈ',
      'themeColor': 'تھیم رنگ',
      'system': 'سسٹم',
      'light': 'ہلکا',
      'dark': 'گہرا',
      'bookTemplate': 'کتاب کا سانچہ',
      'applyToAll': 'تمام بلاکس پر لگائیں',
      'selectBlocks': 'بلاکس منتخب کریں',
      'selected': 'منتخب',
      'wholePage': 'پورے صفحے کا فونٹ',
      'preview': 'پیش منظر',
      'write': 'لکھیں',
      'format': 'فارمیٹ',
      'outline': 'خاکہ',
      'ai': 'اے آئی',
      'livePreview': 'براہ راست پیش منظر',
      'updatesAsYouType': 'لکھتے وقت اپ ڈیٹ ہوتا ہے',
      'noBlocksSelected': 'فونٹ تبدیلی کے لیے بلاکس منتخب کریں۔',
    },
    'ar': {
      'appName': 'استوديو الكتب الأردية',
      'newBook': 'كتاب جديد',
      'importFile': 'استيراد ملف كتاب',
      'settings': 'الإعدادات',
      'noBooks': 'لا توجد كتب بعد. اضغط "كتاب جديد" أو استورد ملفًا.',
      'noMatches': 'لا توجد كتب مطابقة.',
      'searchHint': 'ابحث عن الكتب أو المؤلفين أو اللغات',
      'untitledBook': 'كتاب بلا عنوان',
      'chapters': 'فصول',
      'chapter': 'فصل',
      'delete': 'حذف',
      'cancel': 'إلغاء',
      'create': 'إنشاء',
      'ok': 'موافق',
      'title': 'العنوان',
      'author': 'المؤلف',
      'language': 'اللغة',
      'deleteBook': 'حذف الكتاب؟',
      'appearance': 'المظهر',
      'appLanguage': 'لغة التطبيق',
      'themeMode': 'وضع السمة',
      'themeColor': 'لون السمة',
      'system': 'النظام',
      'light': 'فاتح',
      'dark': 'داكن',
      'bookTemplate': 'قالب الكتاب',
      'applyToAll': 'تطبيق على كل الكتل',
      'selectBlocks': 'تحديد الكتل',
      'selected': 'محدد',
      'wholePage': 'خط الصفحة كاملة',
      'preview': 'معاينة',
      'write': 'كتابة',
      'format': 'تنسيق',
      'outline': 'مخطط',
      'ai': 'ذكاء اصطناعي',
      'livePreview': 'معاينة مباشرة',
      'updatesAsYouType': 'يتحدث أثناء الكتابة',
      'noBlocksSelected': 'حدد الكتل لتطبيق تغييرات الخط.',
    },
    'hi': {
      'appName': 'उर्दू बुक स्टूडियो',
      'newBook': 'नई किताब',
      'importFile': 'किताब फ़ाइल आयात करें',
      'settings': 'सेटिंग्स',
      'noBooks': 'अभी कोई किताब नहीं। "नई किताब" दबाएँ या फ़ाइल आयात करें।',
      'noMatches': 'कोई मिलती-जुलती किताब नहीं।',
      'searchHint': 'किताबें, लेखक या भाषाएँ खोजें',
      'untitledBook': 'बिना शीर्षक की किताब',
      'chapters': 'अध्याय',
      'chapter': 'अध्याय',
      'delete': 'हटाएँ',
      'cancel': 'रद्द करें',
      'create': 'बनाएँ',
      'ok': 'ठीक है',
      'title': 'शीर्षक',
      'author': 'लेखक',
      'language': 'भाषा',
      'deleteBook': 'किताब हटाएँ?',
      'appearance': 'दिखावट',
      'appLanguage': 'ऐप भाषा',
      'themeMode': 'थीम मोड',
      'themeColor': 'थीम रंग',
      'system': 'सिस्टम',
      'light': 'हल्का',
      'dark': 'गहरा',
      'bookTemplate': 'किताब टेम्पलेट',
      'applyToAll': 'सभी ब्लॉकों पर लागू करें',
      'selectBlocks': 'ब्लॉक चुनें',
      'selected': 'चयनित',
      'wholePage': 'पूरे पेज का फ़ॉन्ट',
      'preview': 'पूर्वावलोकन',
      'write': 'लिखें',
      'format': 'फ़ॉर्मेट',
      'outline': 'रूपरेखा',
      'ai': 'एआई',
      'livePreview': 'लाइव पूर्वावलोकन',
      'updatesAsYouType': 'लिखते समय अपडेट होता है',
      'noBlocksSelected': 'फ़ॉन्ट बदलने के लिए ब्लॉक चुनें।',
    },
    'fa': {
      'appName': 'استودیوی کتاب اردو',
      'newBook': 'کتاب جدید',
      'importFile': 'وارد کردن فایل کتاب',
      'settings': 'تنظیمات',
      'noBooks': 'هنوز کتابی نیست. «کتاب جدید» را بزنید یا فایل وارد کنید.',
      'noMatches': 'کتاب مطابقی پیدا نشد.',
      'searchHint': 'جستجوی کتاب، نویسنده یا زبان',
      'untitledBook': 'کتاب بی‌عنوان',
      'chapters': 'فصل‌ها',
      'chapter': 'فصل',
      'delete': 'حذف',
      'cancel': 'لغو',
      'create': 'ایجاد',
      'ok': 'تأیید',
      'title': 'عنوان',
      'author': 'نویسنده',
      'language': 'زبان',
      'deleteBook': 'حذف کتاب؟',
      'appearance': 'ظاهر',
      'appLanguage': 'زبان برنامه',
      'themeMode': 'حالت پوسته',
      'themeColor': 'رنگ پوسته',
      'system': 'سیستم',
      'light': 'روشن',
      'dark': 'تیره',
      'bookTemplate': 'قالب کتاب',
      'applyToAll': 'اعمال روی همه بلوک‌ها',
      'selectBlocks': 'انتخاب بلوک‌ها',
      'selected': 'انتخاب شده',
      'wholePage': 'فونت کل صفحه',
      'preview': 'پیش‌نمایش',
      'write': 'نوشتن',
      'format': 'قالب‌بندی',
      'outline': 'طرح',
      'ai': 'هوش مصنوعی',
      'livePreview': 'پیش‌نمایش زنده',
      'updatesAsYouType': 'همزمان با نوشتن به‌روز می‌شود',
      'noBlocksSelected': 'برای تغییر فونت، بلوک‌ها را انتخاب کنید.',
    },
  };
}
