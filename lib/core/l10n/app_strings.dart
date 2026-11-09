class AppStrings {
  const AppStrings(this.languageCode);

  final String languageCode;

  bool get isBangla => languageCode == 'bn';

  String _t(String en, String bn) => isBangla ? bn : en;

  String get appName => 'DocPad';
  String get home => _t('Home', 'হোম');
  String get patients => _t('Patients', 'রোগী');
  String get advice => _t('Advice', 'পরামর্শ');
  String get settings => _t('Settings', 'সেটিংস');
  String get newPrescription => _t('New prescription', 'নতুন প্রেসক্রিপশন');
  String get recentPrescriptions =>
      _t('Recent prescriptions', 'সাম্প্রতিক প্রেসক্রিপশন');
  String get recentPatients =>
      _t('Recently accessed patients', 'সাম্প্রতিক রোগী');
  String get drafts => _t('Drafts', 'খসড়া');
  String get quickActions => _t('Quick actions', 'দ্রুত কাজ');
  String get seeAll => _t('See all', 'সব দেখুন');
  String get emptyTitle =>
      _t('No prescriptions yet', 'এখনো কোনো প্রেসক্রিপশন নেই');
  String get emptyBody => _t(
    'When you document a visit, it will appear here. DocPad does not create sample patients.',
    'আপনি কোনো ভিজিট লিখলে তা এখানে দেখা যাবে। ডকপ্যাড নমুনা রোগী তৈরি করে না।',
  );
  String get createFirst =>
      _t('Create the first prescription', 'প্রথম প্রেসক্রিপশন লিখুন');
  String get disclaimer => _t(
    'DocPad records what you type. It does not diagnose, select medicines, or calculate doses. You are responsible for every clinical entry.',
    'ডকপ্যাড শুধু আপনার লেখা সংরক্ষণ করে। এটি রোগ নির্ণয় করে না, ওষুধ বাছাই করে না এবং মাত্রা হিসাব করে না। প্রতিটি ক্লিনিক্যাল তথ্যের দায়িত্ব আপনার।',
  );
  String get addYourName =>
      _t('Add your name in Settings', 'সেটিংসে আপনার নাম যোগ করুন');
  String get offlineBanner => _t(
    'Offline. Your medicine library and drafts remain available on this device.',
    'অফলাইন। এই ডিভাইসের ওষুধের লাইব্রেরি ও খসড়া পাওয়া যাবে।',
  );
  String get noPatients => _t(
    'Patients you document will appear here.',
    'আপনি যাঁদের নথি রাখবেন, তাঁরা এখানে দেখা যাবেন।',
  );
  String get noDrafts => _t('No drafts', 'কোনো খসড়া নেই');
  String get patientInformation => _t('Patient information', 'রোগীর তথ্য');
  String get patientName => _t('Patient name', 'রোগীর নাম');
  String get phone => _t('Phone', 'ফোন');
  String get age => _t('Age', 'বয়স');
  String get sex => _t('Sex', 'লিঙ্গ');
  String get prescriptionDate =>
      _t('Prescription date', 'প্রেসক্রিপশনের তারিখ');
  String get patientId => _t('Patient ID', 'রোগীর আইডি');
  String get address => _t('Address', 'ঠিকানা');
  String get identificationNotes =>
      _t('Identification notes', 'পরিচয় সংক্রান্ত নোট');
  String get optional => _t('Optional', 'ঐচ্ছিক');
  String get sexFemale => _t('Female', 'নারী');
  String get sexMale => _t('Male', 'পুরুষ');
  String get sexIntersex => _t('Intersex', 'ইন্টারসেক্স');
  String get sexUndisclosed => _t('Prefer not to say', 'বলতে চাই না');
  String get nameRequired => _t('Enter the patient name.', 'রোগীর নাম লিখুন।');
  String get phoneRequired => _t('Enter a phone number.', 'ফোন নম্বর লিখুন।');
  String get phoneInvalid => _t(
    'Enter a phone number with 6 to 15 digits. Spaces and a leading + are fine.',
    '৬ থেকে ১৫ সংখ্যার ফোন নম্বর লিখুন। স্পেস এবং শুরুতে + ব্যবহার করা যাবে।',
  );
  String get ageRequired => _t('Enter the age in years.', 'বয়স বছরে লিখুন।');
  String get ageInvalid => _t(
    'Enter age as a whole number from 0 to 130.',
    'বয়স ০ থেকে ১৩০-এর পূর্ণসংখ্যা হতে হবে।',
  );
  String get sexRequired => _t('Select sex.', 'লিঙ্গ নির্বাচন করুন।');
  String get clinicalAssessment => _t('Clinical assessment', 'ক্লিনিক্যাল নোট');
  String get clinicalHint => _t(
    'Write only what you assessed. DocPad does not generate diagnoses or interpret investigations.',
    'শুধু আপনার নিজের মূল্যায়ন লিখুন। ডকপ্যাড রোগ নির্ণয় বা পরীক্ষার ব্যাখ্যা তৈরি করে না।',
  );
  String get chiefComplaint => _t('Chief complaint', 'প্রধান অভিযোগ');
  String get history =>
      _t('History of present illness', 'বর্তমান অসুস্থতার ইতিহাস');
  String get medicalHistory =>
      _t('Relevant medical history', 'প্রাসঙ্গিক চিকিৎসা ইতিহাস');
  String get investigationNotes => _t('Investigation notes', 'পরীক্ষার নোট');
  String get examinationNotes =>
      _t('Examination notes', 'পরীক্ষা-নিরীক্ষার নোট');
  String get assessment => _t("Doctor's assessment", 'চিকিৎসকের মূল্যায়ন');
  String get medicineSearch => _t('Medicine search', 'ওষুধ খোঁজা');
  String get searchHint =>
      _t('Search your medicine library', 'আপনার ওষুধের লাইব্রেরিতে খুঁজুন');
  String get brands => _t('Brands', 'ব্র্যান্ড');
  String get generics => _t('Generics', 'জেনেরিক');
  String get demoTitle => _t('DEMO DATA', 'ডেমো ডেটা');
  String get demoBody => _t(
    'These records come from a synthetic fixture provider, not a verified MedEx database. Do not use them for clinical decisions.',
    'এই তথ্য কৃত্রিম ফিক্সচার থেকে এসেছে, যাচাই করা মেডেক্স তথ্য নয়। ক্লিনিক্যাল সিদ্ধান্তে ব্যবহার করবেন না।',
  );
  String get liveBody => _t(
    'The configured source marked this result as live. You still choose the product and enter every instruction yourself.',
    'কনফিগার করা উৎস এই ফলাফলকে লাইভ হিসেবে চিহ্নিত করেছে। ওষুধ এবং প্রতিটি নির্দেশনা আপনাকেই লিখতে হবে।',
  );
  String get cachedLead => _t(
    'Cached catalog result. This is not a current catalog.',
    'ক্যাশ করা ক্যাটালগ ফল। এটি বর্তমান ক্যাটালগ নয়।',
  );
  String get loading => _t('Searching the catalog…', 'ক্যাটালগ খোঁজা হচ্ছে…');
  String get noResults => _t(
    'No catalog records matched that search.',
    'এই খোঁজায় কোনো রেকর্ড মেলেনি।',
  );
  String get loadMore => _t('Load more', 'আরও দেখুন');
  String get catalogError => _t(
    'The catalog request did not complete. Your prescription text is still on this screen.',
    'ক্যাটালগ অনুরোধ সম্পূর্ণ হয়নি। প্রেসক্রিপশনের লেখা এই স্ক্রিনেই আছে।',
  );
  String get catalogInfo => _t('Catalog information', 'ক্যাটালগের তথ্য');
  String get yourInstructions => _t('Your instructions', 'আপনার নির্দেশনা');
  String get instructionHint => _t(
    'Type each value yourself. Nothing here is calculated or suggested.',
    'প্রতিটি মান নিজে লিখুন। এখানে কিছু হিসাব বা পরামর্শ করা হয় না।',
  );
  String get dose => _t('Dose', 'মাত্রা');
  String get frequency => _t('Frequency', 'কতবার');
  String get duration => _t('Duration', 'কতদিন');
  String get route => _t('Route', 'পথ');
  String get timing => _t('Timing', 'সময়');
  String get specialInstructions =>
      _t('Special instructions', 'বিশেষ নির্দেশনা');
  String get quantity => _t('Quantity', 'পরিমাণ');
  String get requiredEntry => _t('Enter this yourself.', 'এটি নিজে লিখুন।');
  String get addToPrescription =>
      _t('Add to prescription', 'প্রেসক্রিপশনে যোগ করুন');
  String get saveChanges => _t('Save changes', 'পরিবর্তন সংরক্ষণ');
  String get edit => _t('Edit', 'সম্পাদনা');
  String get remove => _t('Remove', 'সরান');
  String get removeMedicineTitle =>
      _t('Remove this medicine?', 'এই ওষুধ সরাবেন?');
  String get removeMedicineBody => _t(
    'The line will be removed from this prescription. This cannot be undone from the list.',
    'এই লাইন প্রেসক্রিপশন থেকে সরবে।',
  );
  String get moveUp => _t('Move up', 'উপরে');
  String get moveDown => _t('Move down', 'নিচে');
  String get genericsNote => _t(
    'Generic entries are catalog records only. They are not added to the prescription. Choose a brand, then type the instructions yourself.',
    'জেনেরিক এন্ট্রি শুধু ক্যাটালগের রেকর্ড। এগুলো প্রেসক্রিপশনে যোগ হয় না। একটি ব্র্যান্ড বেছে নিয়ে নির্দেশনা নিজে লিখুন।',
  );
  String get prescribedMedicines =>
      _t('Prescribed medicines', 'প্রেসক্রাইব করা ওষুধ');
  String get emptyMedicines => _t(
    'No medicines on this prescription yet.',
    'এই প্রেসক্রিপশনে এখনো কোনো ওষুধ নেই।',
  );
  String get manufacturer => _t('Manufacturer', 'প্রস্তুতকারক');
  String get adviceLibrary => _t('Advice templates', 'পরামর্শ টেমপ্লেট');
  String get adviceHint => _t(
    'Templates are your own words. DocPad does not generate advice.',
    'টেমপ্লেট আপনার নিজের ভাষা। ডকপ্যাড পরামর্শ তৈরি করে না।',
  );
  String get addTemplate => _t('Add template', 'টেমপ্লেট যোগ');
  String get editTemplate => _t('Edit template', 'টেমপ্লেট সম্পাদনা');
  String get templateTitle => _t('Title', 'শিরোনাম');
  String get templateBody => _t('Advice text', 'পরামর্শের লেখা');
  String get templateBodyRequired =>
      _t('Enter the advice text.', 'পরামর্শের লেখা লিখুন।');
  String get searchTemplates => _t('Search templates', 'টেমপ্লেট খুঁজুন');
  String get noTemplates => _t(
    'You have not saved any advice templates.',
    'আপনি এখনো কোনো পরামর্শ টেমপ্লেট সংরক্ষণ করেননি।',
  );
  String get customAdvice =>
      _t('Custom advice for this prescription', 'এই প্রেসক্রিপশনের পরামর্শ');
  String get addCustom => _t('Add advice', 'পরামর্শ যোগ');
  String get selectedAdvice => _t('Selected advice', 'নির্বাচিত পরামর্শ');
  String get adviceCopiedNote => _t(
    'Selected text is copied onto this prescription. Editing a template later does not change prescriptions already written.',
    'নির্বাচিত লেখা এই প্রেসক্রিপশনে কপি হয়। পরে টেমপ্লেট বদলালে আগের প্রেসক্রিপশন বদলায় না।',
  );
  String get alreadyAdded => _t(
    'That advice is already on this prescription.',
    'এই পরামর্শ ইতিমধ্যে এই প্রেসক্রিপশনে আছে।',
  );
  String get deleteTemplateTitle =>
      _t('Delete this template?', 'এই টেমপ্লেট মুছবেন?');
  String get deleteTemplateBody => _t(
    'The template will be removed from this device. Prescriptions that already copied the text are left as they are.',
    'টেমপ্লেট এই ডিভাইস থেকে মুছবে। যে প্রেসক্রিপশনে লেখা আগে কপি হয়েছে, সেগুলো আগের মতোই থাকবে।',
  );
  String get followUp => _t('Follow-up', 'ফলো-আপ');
  String get nextVisit => _t('Next visit', 'পরবর্তী সাক্ষাৎ');
  String get chooseDate => _t('Choose date', 'তারিখ বেছে নিন');
  String get clearDate => _t('Clear', 'মুছুন');
  String get preview => _t('Preview', 'প্রিভিউ');
  String get draft => _t('Draft', 'খসড়া');
  String get finalized => _t('Finalized', 'চূড়ান্ত');
  String get notRecorded => _t('Not recorded', 'লেখা হয়নি');
  String get noMedicinesRecorded =>
      _t('No medicines recorded.', 'কোনো ওষুধ লেখা হয়নি।');
  String get exportPdf => _t('Save PDF', 'পিডিএফ সংরক্ষণ');
  String get print => _t('Print', 'প্রিন্ট');
  String get saveDraft => _t('Save draft', 'খসড়া সংরক্ষণ');
  String get finalize => _t('Finalize', 'চূড়ান্ত করুন');
  String get finalizeBody => _t(
    'Finalizing removes the draft mark. You can still edit later, which returns the document to draft until you finalize again.',
    'চূড়ান্ত করলে খসড়ার চিহ্ন সরবে। পরে সম্পাদনা করলে আবার খসড়া হবে, যতক্ষণ না আবার চূড়ান্ত করেন।',
  );
  String get missingFields => _t(
    'Enter the required patient fields before finalizing.',
    'চূড়ান্ত করার আগে রোগীর প্রয়োজনীয় ঘরগুলো পূরণ করুন।',
  );
  String get returnedToDraft => _t(
    'This prescription returned to draft because it changed.',
    'পরিবর্তনের কারণে এই প্রেসক্রিপশন আবার খসড়া হয়েছে।',
  );
  String get saving => _t('Saving…', 'সংরক্ষণ হচ্ছে…');
  String get saved => _t('Saved on this device.', 'এই ডিভাইসে সংরক্ষিত।');
  String get saveFailed => _t(
    'Could not save. Your edits are still on this screen and were not discarded.',
    'সংরক্ষণ হয়নি। আপনার লেখা এই স্ক্রিনেই আছে, মুছে যায়নি।',
  );
  String get pdfSaved => _t('PDF saved.', 'পিডিএফ সংরক্ষিত।');
  String get pdfFailed => _t(
    'The PDF was not created. The prescription is still saved on this device.',
    'পিডিএফ তৈরি হয়নি। প্রেসক্রিপশন এই ডিভাইসে সংরক্ষিত আছে।',
  );
  String get exportCancelled => _t(
    'Export cancelled. The prescription is still saved on this device.',
    'রপ্তানি বাতিল। প্রেসক্রিপশন এই ডিভাইসে সংরক্ষিত আছে।',
  );
  String get printCompleted => _t('Print completed.', 'প্রিন্ট সম্পন্ন।');
  String get printCancelled => _t('Print cancelled.', 'প্রিন্ট বাতিল।');
  String get printFailed => _t(
    'Printing did not complete. The prescription is still saved on this device.',
    'প্রিন্ট সম্পন্ন হয়নি। প্রেসক্রিপশন এই ডিভাইসে সংরক্ষিত আছে।',
  );
  String get deletePrescription =>
      _t('Delete prescription', 'প্রেসক্রিপশন মুছুন');
  String get deletePrescriptionBody => _t(
    'This deletes the prescription from this device. It does not contact a server.',
    'এটি এই ডিভাইস থেকে প্রেসক্রিপশন মুছে দেবে। কোনো সার্ভারে পাঠানো হয় না।',
  );
  String get leaveTitle =>
      _t('Save this prescription before leaving?', 'যাওয়ার আগে সংরক্ষণ করবেন?');
  String get leaveBody => _t(
    'You have edits that are not saved yet. Discarding drops those edits from the editor.',
    'কিছু পরিবর্তন এখনো সংরক্ষিত নয়। বাতিল করলে এডিটর থেকে সেই পরিবর্তন সরবে।',
  );
  String get saveAndLeave => _t('Save and leave', 'সংরক্ষণ করে যান');
  String get discard => _t('Discard edits', 'পরিবর্তন বাতিল');
  String get cancel => _t('Cancel', 'বাতিল');
  String get delete => _t('Delete', 'মুছুন');
  String get doctorProfile => _t('Doctor profile', 'চিকিৎসকের প্রোফাইল');
  String get doctorName => _t('Name', 'নাম');
  String get designation => _t('Designation', 'পদবি');
  String get registrationNumber => _t('Registration number', 'নিবন্ধন নম্বর');
  String get clinicName => _t('Clinic name', 'ক্লিনিকের নাম');
  String get clinicAddress => _t('Clinic address', 'ক্লিনিকের ঠিকানা');
  String get contact => _t('Contact', 'যোগাযোগ');
  String get headerExtra => _t('Header line', 'হেডার লাইন');
  String get headerHint => _t(
    'Shown under the clinic details. Leave blank if you do not want an extra line.',
    'ক্লিনিকের তথ্যের নিচে দেখা যাবে। অতিরিক্ত লাইন না চাইলে খালি রাখুন।',
  );
  String get logo => _t('Clinic logo', 'ক্লিনিকের লোগো');
  String get chooseLogo => _t('Choose logo', 'লোগো বেছে নিন');
  String get removeLogo => _t('Remove logo', 'লোগো সরান');
  String get logoTooLarge =>
      _t('Choose an image under 512 KB.', '৫১২ কেবির ছোট একটি ছবি বেছে নিন।');
  String get logoFailed =>
      _t('That image could not be read.', 'এই ছবি পড়া যায়নি।');
  String get language => _t('Language', 'ভাষা');
  String get english => 'English';
  String get bangla => 'বাংলা';
  String get theme => _t('Theme', 'থিম');
  String get themeLight => _t('Light', 'লাইট');
  String get themeDark => _t('Dark', 'ডার্ক');
  String get themeSystem => _t('System', 'সিস্টেম');
  String get catalogAddress =>
      _t('Medicine catalog address', 'ওষুধ ক্যাটালগের ঠিকানা');
  String get catalogAddressHint => _t(
    'DGHS terminology registry. Drug names are loaded from the medication feed after you save a TR API CONSUMER login.',
    'ডিজিএইচএস টার্মিনোলজি রেজিস্ট্রি। টিআর এপিআই কনজিউমার লগইন সেভ করলে ওষুধের নাম মেডিকেশন ফিড থেকে আসে।',
  );
  String get trUsername => _t('TR username', 'টিআর ব্যবহারকারী');
  String get trPassword => _t('TR password', 'টিআর পাসওয়ার্ড');
  String get trPasswordHint => _t(
    'Leave blank to keep the saved password.',
    'সেভ করা পাসওয়ার্ড রাখতে খালি রাখুন।',
  );
  String get trAuthHint => _t(
    'Basic login for a Terminology Registry user with the TR API CONSUMER role. It is stored in the device secure store.',
    'টিআর এপিআই কনজিউমার ভূমিকার ব্যবহারকারীর বেসিক লগইন। এটি ডিভাইসের সিকিউর স্টোরে থাকে।',
  );
  String get save => _t('Save', 'সংরক্ষণ');
  String get testConnection => _t('Test connection', 'সংযোগ পরীক্ষা');
  String get invalidUrl =>
      _t('Enter an http or https address.', 'একটি http বা https ঠিকানা লিখুন।');
  String get connectionFailed => _t(
    'Could not reach the catalog at that address.',
    'সেই ঠিকানায় ক্যাটালগে পৌঁছানো যায়নি।',
  );
  String fixtureConnection(String name) => _t(
    'Connected. Provider kind: fixture ($name). This is demo data, not verified MedEx records.',
    'সংযুক্ত। প্রোভাইডারের ধরন: fixture ($name)। এটি ডেমো ডেটা, যাচাই করা মেডেক্স রেকর্ড নয়।',
  );
  String liveConnection(String name) => _t(
    'Connected. Provider kind: live ($name).',
    'সংযুক্ত। প্রোভাইডারের ধরন: live ($name)।',
  );
  String get dataManagement => _t('Data on this device', 'এই ডিভাইসের ডেটা');
  String get localStorageNotice => _t(
    'Prescriptions, patients, and advice templates are stored only on this device. DocPad encrypts that database with a key kept in the platform secure store when that store is available. This is not a substitute for a secure, backed-up medical record system. Export what your clinic requires and protect this device.',
    'প্রেসক্রিপশন, রোগী এবং পরামর্শ টেমপ্লেট শুধু এই ডিভাইসে থাকে। প্ল্যাটফর্মের সিকিউর স্টোর পাওয়া গেলে ডকপ্যাড সেই কী দিয়ে ডেটাবেস এনক্রিপ্ট করে। এটি নিরাপদ, ব্যাকআপসহ চিকিৎসা নথিব্যবস্থার বিকল্প নয়।',
  );
  String get eraseAll =>
      _t('Erase local clinical data', 'স্থানীয় ক্লিনিক্যাল ডেটা মুছুন');
  String get eraseBody => _t(
    'This permanently removes prescriptions, the patient directory, advice templates, the catalog cache, and the doctor profile from this device. Theme, language, and the catalog address are kept.',
    'এটি এই ডিভাইস থেকে প্রেসক্রিপশন, রোগীর তালিকা, পরামর্শ টেমপ্লেট, ক্যাটালগ ক্যাশ এবং চিকিৎসকের প্রোফাইল স্থায়ীভাবে মুছে দেবে। থিম, ভাষা এবং ক্যাটালগ ঠিকানা থাকবে।',
  );
  String get typeDelete =>
      _t('Type DELETE to confirm', 'নিশ্চিত করতে DELETE লিখুন');
  String get eraseSuccess => _t(
    'Local clinical data was erased.',
    'স্থানীয় ক্লিনিক্যাল ডেটা মুছে ফেলা হয়েছে।',
  );
  String get eraseFailed => _t(
    'Erasing did not finish. Check the lists before continuing. Nothing was reported as deleted unless this message says so.',
    'মোছা শেষ হয়নি। এগোনোর আগে তালিকা দেখে নিন।',
  );
  String get profileSaved => _t('Profile saved.', 'প্রোফাইল সংরক্ষিত।');
  String get prescription => _t('Prescription', 'প্রেসক্রিপশন');
  String get missingPrescription => _t(
    'That prescription is not on this device.',
    'এই প্রেসক্রিপশন এই ডিভাইসে নেই।',
  );
  String get couldNotOpen => _t(
    'This prescription could not be opened. It was not deleted.',
    'এই প্রেসক্রিপশন খোলা যায়নি। এটি মুছে ফেলা হয়নি।',
  );
  String get couldNotRead => _t(
    'Saved records could not be read. They were not deleted.',
    'সংরক্ষিত রেকর্ড পড়া যায়নি। সেগুলো মুছে ফেলা হয়নি।',
  );
  String get signature => _t('Signature', 'স্বাক্ষর');
  String get doctorNameMissingPdf =>
      _t('Doctor name not set', 'চিকিৎসকের নাম সেট করা নেই');
  String get rx => 'Rx';
  String get clinicalNotes => _t('Clinical notes', 'ক্লিনিক্যাল নোট');
  String get advicePdf => _t('Advice', 'পরামর্শ');
  String get prescriberNote => _t(
    'Clinical content, product selection, and instructions were entered by the prescriber.',
    'ক্লিনিক্যাল তথ্য, ওষুধ নির্বাচন এবং নির্দেশনা প্রেসক্রাইবার লিখেছেন।',
  );
  String get fixturePdfNote => _t(
    'One or more product names were taken from synthetic demo catalog data and confirmed by the prescriber. They are not verified MedEx records.',
    'এক বা একাধিক পণ্যের নাম কৃত্রিম ডেমো ক্যাটালগ থেকে নেওয়া এবং প্রেসক্রাইবার নিশ্চিত করেছেন। এগুলো যাচাই করা মেডেক্স রেকর্ড নয়।',
  );
  String get draftBanner =>
      _t('DRAFT — not a finalized document', 'খসড়া — চূড়ান্ত নথি নয়');
  String get newForPatient =>
      _t('New prescription for this patient', 'এই রোগীর নতুন প্রেসক্রিপশন');
  String get deletePatientTitle => _t(
    'Remove this patient from the directory?',
    'তালিকা থেকে এই রোগী সরাবেন?',
  );
  String get deletePatientBody => _t(
    'The directory card is removed. Prescriptions that already include this patient stay on this device until you delete those prescriptions.',
    'তালিকার কার্ড সরবে। যে প্রেসক্রিপশনে এই রোগী আগে থেকে আছেন, সেগুলো আলাদাভাবে না মোছা পর্যন্ত থাকবে।',
  );
  String get searchPatients => _t('Search patients', 'রোগী খুঁজুন');
  String get detailsUnavailable => _t(
    'The catalog detail request failed. The listed record is shown unchanged.',
    'ক্যাটালগের বিস্তারিত আনা যায়নি। তালিকার রেকর্ড আগের মতোই দেখানো হচ্ছে।',
  );
  String get notVerified =>
      _t('Not verified MedEx records', 'যাচাই করা মেডেক্স রেকর্ড নয়');
  String get sourceLabel => _t('Source', 'উৎস');
  String get back => _t('Back', 'ফিরে যান');
  String get retry => _t('Retry', 'আবার চেষ্টা');
  String get startupFailed => _t(
    'DocPad could not open local storage, so it did not start with an empty record list. Your existing data was not erased. Restart the app after the device secure store is available.',
    'ডকপ্যাড স্থানীয় স্টোরেজ খুলতে পারেনি, তাই খালি তালিকা নিয়ে চালু হয়নি। আগের ডেটা মোছা হয়নি।',
  );
  String characters(int count) =>
      isBangla ? '$count অক্ষর' : '$count characters';
  String page(int number, int total) =>
      isBangla ? 'পৃষ্ঠা $number / $total' : 'Page $number / $total';
  String cachedAt(String when) =>
      isBangla ? 'এই ডিভাইসে সংরক্ষিত: $when' : 'Stored on this device: $when';

  String sexLabel(String? code) {
    return switch (code) {
      'female' => sexFemale,
      'male' => sexMale,
      'intersex' => sexIntersex,
      'undisclosed' => sexUndisclosed,
      _ => notRecorded,
    };
  }
}
