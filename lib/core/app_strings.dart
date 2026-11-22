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
  String get sepia => _t('sepia');
  String get lastEdited => _t('lastEdited');
  String get open => _t('open');
  String get editDetails => _t('editDetails');
  String get duplicate => _t('duplicate');
  String get export => _t('export');
  String get moveToTrash => _t('moveToTrash');
  String get undo => _t('undo');
  String get restored => _t('restored');
  String get sortBy => _t('sortBy');
  String get recentlyEdited => _t('recentlyEdited');
  String get sortTitle => _t('sortTitle');
  String get sortAuthor => _t('sortAuthor');
  String get sortLanguage => _t('sortLanguage');
  String get allLanguages => _t('allLanguages');
  String get lineSpacing => _t('lineSpacing');
  String get paragraphSpacing => _t('paragraphSpacing');
  String get saving => _t('saving');
  String get saved => _t('saved');
  String get saveFailed => _t('saveFailed');
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
      'appName': 'Book Writer & Publisher',
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
      'sepia': 'Sepia',
      'lastEdited': 'Last edited',
      'open': 'Open',
      'editDetails': 'Edit details',
      'duplicate': 'Duplicate',
      'export': 'Export',
      'moveToTrash': 'Move to Trash',
      'undo': 'Undo',
      'restored': 'Restored',
      'sortBy': 'Sort by',
      'recentlyEdited': 'Recently edited',
      'sortTitle': 'Title',
      'sortAuthor': 'Author',
      'sortLanguage': 'Language',
      'allLanguages': 'All languages',
      'lineSpacing': 'Line spacing',
      'paragraphSpacing': 'Paragraph spacing',
      'saving': 'Saving…',
      'saved': 'Saved',
      'saveFailed': 'Save failed',
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
      'appName': 'کتاب لکھیں اور شائع کریں',
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
      'sepia': 'سیپیا',
      'lastEdited': 'آخری ترمیم',
      'open': 'کھولیں',
      'editDetails': 'تفصیلات ترمیم کریں',
      'duplicate': 'نقل بنائیں',
      'export': 'برآمد کریں',
      'moveToTrash': 'ردی میں منتقل کریں',
      'undo': 'واپس',
      'restored': 'بحال ہو گیا',
      'sortBy': 'ترتیب',
      'recentlyEdited': 'حال ہی میں ترمیم شدہ',
      'sortTitle': 'عنوان',
      'sortAuthor': 'مصنف',
      'sortLanguage': 'زبان',
      'allLanguages': 'تمام زبانیں',
      'lineSpacing': 'سطری فاصلہ',
      'paragraphSpacing': 'پیراگراف فاصلہ',
      'saving': 'محفوظ ہو رہا ہے…',
      'saved': 'محفوظ',
      'saveFailed': 'محفوظ ناکام',
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
      'appName': 'كاتب وناشر الكتب',
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
      'sepia': 'بني داكن',
      'lastEdited': 'آخر تعديل',
      'open': 'فتح',
      'editDetails': 'تعديل التفاصيل',
      'duplicate': 'تكرار',
      'export': 'تصدير',
      'moveToTrash': 'نقل إلى المهملات',
      'undo': 'تراجع',
      'restored': 'تمت الاستعادة',
      'sortBy': 'ترتيب حسب',
      'recentlyEdited': 'المحررة حديثًا',
      'sortTitle': 'العنوان',
      'sortAuthor': 'المؤلف',
      'sortLanguage': 'اللغة',
      'allLanguages': 'كل اللغات',
      'lineSpacing': 'تباعد الأسطر',
      'paragraphSpacing': 'تباعد الفقرات',
      'saving': 'جارٍ الحفظ…',
      'saved': 'تم الحفظ',
      'saveFailed': 'فشل الحفظ',
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
      'appName': 'बुक राइटर और पब्लिशर',
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
      'sepia': 'सीपिया',
      'lastEdited': 'अंतिम संपादन',
      'open': 'खोलें',
      'editDetails': 'विवरण संपादित करें',
      'duplicate': 'डुप्लिकेट',
      'export': 'निर्यात',
      'moveToTrash': 'ट्रैश में भेजें',
      'undo': 'पूर्ववत करें',
      'restored': 'पुनर्स्थापित',
      'sortBy': 'क्रम',
      'recentlyEdited': 'हाल ही में संपादित',
      'sortTitle': 'शीर्षक',
      'sortAuthor': 'लेखक',
      'sortLanguage': 'भाषा',
      'allLanguages': 'सभी भाषाएँ',
      'lineSpacing': 'पंक्ति अंतर',
      'paragraphSpacing': 'पैराग्राफ अंतर',
      'saving': 'सहेज रहा है…',
      'saved': 'सहेजा गया',
      'saveFailed': 'सहेजना विफल',
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
      'appName': 'کتاب‌نویس و ناشر',
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
      'sepia': 'سپیا',
      'lastEdited': 'آخرین ویرایش',
      'open': 'باز کردن',
      'editDetails': 'ویرایش جزئیات',
      'duplicate': 'تکرار',
      'export': 'برون‌ریزی',
      'moveToTrash': 'انتقال به زباله‌دان',
      'undo': 'واگرد',
      'restored': 'بازیابی شد',
      'sortBy': 'مرتب‌سازی',
      'recentlyEdited': 'اخیراً ویرایش شده',
      'sortTitle': 'عنوان',
      'sortAuthor': 'نویسنده',
      'sortLanguage': 'زبان',
      'allLanguages': 'همه زبان‌ها',
      'lineSpacing': 'فاصله خطوط',
      'paragraphSpacing': 'فاصله پاراگراف',
      'saving': 'در حال ذخیره…',
      'saved': 'ذخیره شد',
      'saveFailed': 'ذخیره نشد',
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
