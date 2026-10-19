import 'package:quotation/l10n/locale_controller.dart';

class AppStrings {
  const AppStrings(this.language);

  final AppLanguage language;

  bool get _ko => language == AppLanguage.korean;

  static AppStrings get current => AppStrings(localeController.language);

  String get homeTab => _ko ? '홈' : 'Home';
  String get archiveTab => _ko ? '보관함' : 'Archive';
  String get settingsTab => _ko ? '설정' : 'Settings';

  String get brandTitle => 'DAILY WORD';
  String get brandSubtitle => 'FOR A KINDER YOU';

  String get todaysFortune => _ko ? '오늘의 운세' : "Today's Fortune";
  String get fortuneShuffled =>
      _ko ? '오늘의 운세를 새로 뽑았어요' : 'Fortune refreshed';
  String get browseTitle =>
      _ko ? '어떤 문장을 읽고 싶나요?' : 'What would you like to read?';

  String get archiveTitle => _ko ? '보관함' : 'Archive';
  String get archiveHint => _ko
      ? '하트로 담아둔 문장을 카테고리별로 모아봤어요'
      : 'Hearted quotes are grouped by category';
  String get archiveEmptyTitle =>
      _ko ? '아직 담아둔 문장이 없어요' : 'No saved quotes yet';
  String get archiveEmptyHint =>
      _ko ? '문장 카드의 ♥ 를 눌러 보관해 보세요' : 'Tap ♥ on a quote to save it';

  String get settingsTitle => _ko ? '설정' : 'Settings';
  String get styleSection => _ko ? '화면 스타일' : 'Visual style';
  String get styleTitle => _ko ? '앱 스타일' : 'App style';
  String get styleSubtitle => _ko
      ? '픽셀 또는 클린 스타일을 선택할 수 있어요'
      : 'Choose pixel or clean style';
  String styleName(String id) {
    switch (id) {
      case 'clean':
        return _ko ? '클린' : 'Clean';
      case 'pixel':
      default:
        return _ko ? '픽셀' : 'Pixel';
    }
  }

  String styleChanged(String name) =>
      _ko ? '$name 스타일로 변경했어요' : 'Style changed to $name';

  String get themeSection => _ko ? '테마 색상' : 'Theme color';
  String get themeTitle => _ko ? '앱 테마' : 'App theme';
  String get themeSubtitle => _ko
      ? '포인트 색을 바꿔 분위기를 바꿔보세요'
      : 'Change the accent color of the app';
  String themeChanged(String name) =>
      _ko ? '$name 테마로 변경했어요' : 'Theme changed to $name';

  String get fontSection => _ko ? '글자 크기' : 'Font size';
  String get fontTitle => _ko ? '본문 글자 크기' : 'Body text size';
  String get fontSubtitle =>
      _ko ? '읽기 편한 크기로 조절할 수 있어요' : 'Choose a comfortable reading size';
  String fontChanged(String name) =>
      _ko ? '글자 크기: $name' : 'Font size: $name';

  String get accountSection => _ko ? '계정' : 'Account';
  String get googleLoginTitle =>
      _ko ? 'Google 계정으로 로그인' : 'Sign in with Google';
  String get googleLoginSubtitle => _ko
      ? '로그인하면 데이터를 동기화할 수 있어요'
      : 'Sign in to sync your data';
  String get googleLoggedInTitle =>
      _ko ? 'Google 계정' : 'Google account';
  String googleLoggedInSubtitle(String email) =>
      _ko ? '$email 으로 로그인됨' : 'Signed in as $email';
  String get login => _ko ? '로그인' : 'Sign in';
  String get logout => _ko ? '로그아웃' : 'Sign out';
  String get googleLoginToast =>
      _ko ? 'Google 로그인' : 'Google sign-in';
  String get googleLoginSuccess =>
      _ko ? 'Google 로그인 완료' : 'Signed in with Google';
  String get googleLogoutSuccess =>
      _ko ? '로그아웃했어요' : 'Signed out';
  String get googleLoginCanceled =>
      _ko ? '로그인을 취소했어요' : 'Sign-in canceled';
  String get googleLoginConfigError => _ko
      ? 'Google 설정 오류예요. OAuth 동의 화면이 Testing이면 Test users에 본인 계정을 추가하고, Android 클라이언트(패키지+SHA-1)를 확인해 주세요'
      : 'Google config error. If consent is Testing, add your account under Test users, and verify Android OAuth package+SHA-1';
  String get googleLoginConfigMissing => _ko
      ? 'Google Web 클라이언트 ID를 아직 설정하지 않았어요'
      : 'Google Web client ID is not configured yet';
  String get googleLoginFailed =>
      _ko ? 'Google 로그인에 실패했어요' : 'Google sign-in failed';
  String googleLoginFailedDetail(String detail) => _ko
      ? 'Google 로그인 실패: $detail'
      : 'Google sign-in failed: $detail';

  String get languageSection => _ko ? '앱 언어' : 'App language';
  String get languageTitle => _ko ? '앱 언어' : 'App language';
  String get languageSubtitle =>
      _ko ? '원하는 언어로 앱을 사용할 수 있어요' : 'Choose Korean or English';
  String languageChanged(String name) =>
      _ko ? '언어: $name' : 'Language: $name';

  String get subscriptionSection => _ko ? '구독 관리' : 'Subscription';
  String get premiumTitle => _ko ? '프리미엄 구독' : 'Premium';
  String get premiumSubtitle =>
      _ko ? '광고 없이 모든 기능을 이용하세요' : 'Enjoy all features without ads';
  String get viewPremium => _ko ? '프리미엄 보기' : 'View Premium';
  String get premiumToast => _ko ? '프리미엄 보기' : 'View Premium';
  String get premiumToggleTitle =>
      _ko ? '프리미엄 (임시)' : 'Premium (temp)';
  String get premiumToggleSubtitle => _ko
      ? '결제 연동 전 테스트용 스위치예요'
      : 'Temporary switch before billing';
  String get premiumEnabledToast =>
      _ko ? '프리미엄이 켜졌어요' : 'Premium turned on';
  String get premiumDisabledToast =>
      _ko ? '무료 회원으로 전환했어요' : 'Switched to free';
  String get premiumLockedTitle =>
      _ko ? '프리미엄 전용' : 'Premium only';
  String get premiumLockedBody => _ko
      ? '이 카테고리는 프리미엄 회원만 볼 수 있어요. 행복한 일상은 무료로 이용할 수 있어요.'
      : 'This category is for premium members. Happy Everyday is free.';
  String get premiumLockedDismiss => _ko ? '닫기' : 'Close';
  String get premiumLockedCta => _ko ? '프리미엄 켜기' : 'Turn on Premium';

  String get otherSection => _ko ? '기타 설정' : 'Other';
  String get eveningDebugTitle =>
      _ko ? '저녁 알림 테스트' : 'Test evening alert';
  String get eveningDebugSubtitle => _ko
      ? '디버그용으로 저녁 위로를 지금 한 건 보냅니다'
      : 'Send one evening comfort notification now';
  String get eveningDebugToast =>
      _ko ? '저녁 알림을 보냈어요' : 'Evening notification sent';
  String get termsTitle =>
      _ko ? '이용약관 및 개인정보처리방침' : 'Terms & Privacy';
  String get termsSubtitle =>
      _ko ? '서비스 이용 관련 정보를 확인하세요' : 'Review terms and privacy policy';
  String get termsToast => _ko ? '이용약관' : 'Terms';
  String get appInfoTitle => _ko ? '앱 정보' : 'App info';
  String get appInfoSubtitle =>
      _ko ? '버전 및 앱 정보를 확인하세요' : 'Version and app details';
  String get appInfoToast => _ko ? '앱 정보' : 'App info';

  String get filterAll => _ko ? '전체' : 'All';
  String get filterNewest => _ko ? '최신순' : 'Newest';
  String get filterPopular => _ko ? '인기순' : 'Popular';
  String get noQuotes => _ko ? '표시할 문장이 없어요' : 'No quotes to show';
  String get savedToArchive =>
      _ko ? '보관함에 담았어요' : 'Saved to archive';
  String get removedFromArchive =>
      _ko ? '보관함에서 뺐어요' : 'Removed from archive';
  String get share => _ko ? '공유하기' : 'Share';
  String get swipeHint =>
      _ko ? '위·아래로 넘겨 보세요' : 'Swipe up or down';

  String get searchHint =>
      _ko ? '단어로 검색해 보세요' : 'Search by keyword';
  String searchIn(String title) =>
      _ko ? '$title에서 검색' : 'Search in $title';
  String searchResults(int count) =>
      _ko ? '$count개의 결과' : '$count results';
  String get searchEmpty =>
      _ko ? '검색 결과가 없어요' : 'No results found';
  String get searchExample =>
      _ko ? '예: 위로, 용기, 감사' : 'e.g. comfort, courage, thanks';

  String get placeholderArchiveSubtitle =>
      _ko ? '마음에 둔 문장이 여기에 모예요' : 'Your hearted quotes will appear here';

  String themeName(String id) {
    switch (id) {
      case 'sky':
        return _ko ? '하늘' : 'Sky';
      case 'mint':
        return _ko ? '민트' : 'Mint';
      case 'lavender':
        return _ko ? '라벤더' : 'Lavender';
      case 'peach':
        return _ko ? '피치' : 'Peach';
      case 'rose':
        return _ko ? '로즈' : 'Rose';
      default:
        return id;
    }
  }

  String fontName(String id) {
    switch (id) {
      case 'small':
        return _ko ? '작게' : 'Small';
      case 'medium':
        return _ko ? '보통' : 'Medium';
      case 'large':
        return _ko ? '크게' : 'Large';
      case 'xlarge':
        return _ko ? '더 크게' : 'X-Large';
      default:
        return id;
    }
  }

  String mainCategoryTitle(String id) {
    switch (id) {
      case 'comfort':
        return _ko ? '위로와 응원' : 'Comfort & Cheer';
      case 'faith':
        return _ko ? '종교와 지혜' : 'Faith & Wisdom';
      case 'literature':
        return _ko ? '명언과 문학' : 'Quotes & Literature';
      case 'daily':
        return _ko ? '행복한 일상' : 'Happy Everyday';
      default:
        return id;
    }
  }

  List<String> mainCategoryLines(String id) {
    switch (id) {
      case 'comfort':
        return _ko
            ? ['지친 마음에', '따뜻한 한마디']
            : ['Warm words', 'for a tired heart'];
      case 'faith':
        return _ko
            ? ['불교 · 천주교', '개신교 · 가르침']
            : ['Buddhism · Catholicism', 'Protestant · Teachings'];
      case 'literature':
        return _ko
            ? ['유명인의 명언', '작가의 문장']
            : ['Famous quotes', "Writers' lines"];
      case 'daily':
        return _ko
            ? ['사랑, 관계, 감사', '매일의 작은 기쁨']
            : ['Love, connection, gratitude', 'Small daily joys'];
      default:
        return const [];
    }
  }

  String mainCategoryBanner(String id) {
    switch (id) {
      case 'comfort':
        return _ko
            ? '지금, 네 마음에 따뜻한 위로를 보낼게요.'
            : 'Sending warm comfort to your heart.';
      case 'faith':
        return _ko
            ? '고요한 마음이 필요할 때, 지혜의 말을 건네줄게요.'
            : 'When you need quiet wisdom, these words are here.';
      case 'literature':
        return _ko
            ? '오래 남는 문장으로 마음에 불을 밝혀줄게요.'
            : 'Let lasting lines light your heart.';
      case 'daily':
        return _ko
            ? '평범한 하루 속 반짝임을 함께 찾아봐요.'
            : "Let's find sparkle in ordinary days.";
      default:
        return '';
    }
  }

  String subCategoryTitle(String id) {
    switch (id) {
      case 'tired':
        return _ko ? '지친 하루' : 'A tired day';
      case 'self':
        return _ko ? '자존감과 자기 사랑' : 'Self-love';
      case 'courage':
        return _ko ? '용기와 도전' : 'Courage';
      case 'anxiety':
        return _ko ? '불안과 걱정' : 'Anxiety';
      case 'lonely':
        return _ko ? '외로움과 위로' : 'Loneliness';
      case 'growth':
        return _ko ? '실패와 성장' : 'Growth';
      case 'relation':
        return _ko ? '인간관계' : 'Relationships';
      case 'dream':
        return _ko ? '꿈과 동기부여' : 'Dreams';
      case 'buddhism':
        return _ko ? '불교' : 'Buddhism';
      case 'christian':
        return _ko ? '기독교' : 'Christianity';
      case 'quotes':
        return _ko ? '유명인 명언' : 'Famous quotes';
      case 'writers':
        return _ko ? '작가의 문장' : "Writers' lines";
      case 'gratitude':
        return _ko ? '감사와 기쁨' : 'Gratitude';
      case 'love':
        return _ko ? '사랑과 관계' : 'Love';
      default:
        return id;
    }
  }

  String subCategorySubtitle(String id) {
    switch (id) {
      case 'tired':
        return _ko ? '힘든 하루를 보낸 나에게' : 'For me after a hard day';
      case 'self':
        return _ko ? '나 자신을 아끼고 싶을 때' : 'When I want to cherish myself';
      case 'courage':
        return _ko ? '새로운 시작이 두려울 때' : 'When a new start feels scary';
      case 'anxiety':
        return _ko ? '미래가 걱정되고 마음이 복잡할 때' : 'When worry fills the mind';
      case 'lonely':
        return _ko ? '누군가에게 위로받고 싶을 때' : 'When I need comfort';
      case 'growth':
        return _ko ? '실수했거나 다시 일어서고 싶을 때' : 'When I want to rise again';
      case 'relation':
        return _ko ? '친구, 가족, 사람 때문에 힘들 때' : 'When people feel heavy';
      case 'dream':
        return _ko ? '목표를 향해 나아가고 싶을 때' : 'When I want to move toward a goal';
      case 'buddhism':
        return _ko ? '마음에 고요를 담고 싶을 때' : 'When I seek quiet mindfulness';
      case 'christian':
        return _ko ? '믿음과 소망이 필요할 때' : 'When I need faith and hope';
      case 'quotes':
        return _ko ? '삶을 비추는 한마디' : 'Lines that light life';
      case 'writers':
        return _ko ? '책 속에서 건진 위로' : 'Comfort found in books';
      case 'gratitude':
        return _ko ? '작은 행복을 발견하고 싶을 때' : 'When I want small joys';
      case 'love':
        return _ko ? '마음이 따뜻해지고 싶을 때' : 'When I want warmth';
      default:
        return '';
    }
  }

  String subCategoryBanner(String id) {
    switch (id) {
      case 'tired':
        return _ko
            ? '오늘도 수고한 너에게 따뜻한 문장을 전해요.'
            : 'Warm lines for you who worked hard today.';
      case 'self':
        return _ko
            ? '너를 가장 먼저 아껴주는 사람이 되어봐.'
            : 'Be the first to cherish yourself.';
      case 'courage':
        return _ko
            ? '작은 한 걸음도 멋진 시작이야.'
            : 'Even a small step is a brave start.';
      case 'anxiety':
        return _ko
            ? '지금 이 순간만 천천히 바라보자.'
            : 'Look gently at this moment only.';
      case 'lonely':
        return _ko
            ? '혼자가 아니야. 여기 따뜻한 말이 있어.'
            : "You're not alone. Warm words are here.";
      case 'growth':
        return _ko
            ? '넘어짐도 성장의 일부야.'
            : 'Falling is part of growing.';
      case 'relation':
        return _ko
            ? '관계는 천천히, 진심으로 가꿔가면 돼.'
            : 'Grow relationships slowly and sincerely.';
      case 'dream':
        return _ko
            ? '네 꿈은 여전히 반짝이고 있어.'
            : 'Your dream is still shining.';
      case 'buddhism':
        return _ko
            ? '집착을 내려놓고 숨을 고르자.'
            : 'Let go a little, and breathe.';
      case 'christian':
        return _ko
            ? '따뜻한 위로가 네 마음에 닿기를.'
            : 'May warm comfort reach your heart.';
      case 'quotes':
        return _ko ? '짧은 문장, 긴 울림.' : 'Short lines, lasting echoes.';
      case 'writers':
        return _ko
            ? '문학이 건네는 따뜻한 손길.'
            : 'Literature offering a warm hand.';
      case 'gratitude':
        return _ko
            ? '오늘도 고마운 일이 분명 있어.'
            : 'There is something to be thankful for today.';
      case 'love':
        return _ko
            ? '사랑은 가까운 곳에서 피어나.'
            : 'Love blooms nearby.';
      default:
        return '';
    }
  }
}
