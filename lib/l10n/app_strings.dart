import 'package:quotation/data/dday_friend_models.dart';
import 'package:quotation/l10n/locale_controller.dart';

class AppStrings {
  const AppStrings(this.language);

  final AppLanguage language;

  bool get _ko => language == AppLanguage.korean;

  static AppStrings get current => AppStrings(localeController.language);

  String get homeTab => _ko ? '홈' : 'Home';
  String get ddayTab => _ko ? '같이' : 'Together';
  String get archiveTab => _ko ? '보관함' : 'Archive';
  String get settingsTab => _ko ? '설정' : 'Settings';

  String get ddayTitle => _ko ? '같이' : 'Together';
  String get ddayHint => _ko
      ? '친구와 같은 방에서 캐릭터를 공유하고, 위젯을 꾸미며 응원 문구를 남겨요'
      : 'Share a room with friends — characters, widget, and cheers together';
  String get ddayEmptyTitle =>
      _ko ? '아직 같이 방이 없어요' : 'No rooms yet';
  String get ddayEmptyHint => _ko
      ? '방을 만들거나, 상단 초대 코드로 참여해 보세요'
      : 'Create a room, or join with an invite code above';
  String get ddayLeaveRoom => _ko ? '방 나가기' : 'Leave room';
  String get ddayAdd => _ko ? '방 만들기' : 'Create room';
  String get ddayEdit => _ko ? '방 수정' : 'Edit room';
  String get ddayAddSubtitle => _ko
      ? '친구들과 응원할 방 이름을 정해 보세요'
      : 'Name a room to cheer with friends';
  String get ddayWhatDay => _ko ? '방 이름' : 'Room name';
  String get ddayPickIcon => _ko ? '아이콘을 골라 주세요' : 'Choose an icon';
  String get ddayTitlePlaceholder =>
      _ko ? '예: 우리 팀, 스터디 방' : 'e.g. Our team, study buddies';
  String get ddayTitleHint => _ko ? '방 이름' : 'Room name';
  String get ddayTitleRequired =>
      _ko ? '방 이름을 입력해 주세요' : 'Please enter a room name';
  String get ddayPickDate =>
      _ko ? '날짜를 선택해 주세요' : 'Please select a date';
  String get ddayDate => _ko ? '날짜' : 'Date';
  String get ddayRepeat => _ko ? '반복 설정' : 'Repeat';
  String get ddayRepeatNone => _ko ? '반복 안 함' : 'Does not repeat';
  String get ddayRepeatYearly => _ko ? '매년 반복' : 'Every year';
  String get ddaySave => _ko ? '방 저장' : 'Save room';
  String get ddayPinWidget => _ko ? '위젯에 표시' : 'Show on widget';
  String get ddayPinnedWidget => _ko ? '위젯에 표시 중' : 'On widget';
  String get ddayDuoBadge => _ko ? '같이' : 'Together';
  String get ddayDuoTestSection =>
      _ko ? '위젯 꾸미기' : 'Customize widget';
  String get ddayDuoTestUpdatedToast =>
      _ko ? '홈 화면 같이 위젯에 반영했어요' : 'Applied to the Together home widget';
  String get ddayDuoDecorateOpen => _ko ? '위젯 꾸미기' : 'Customize widget';
  String get ddayDuoDecorateTitle =>
      _ko ? '위젯 꾸미기' : 'Customize widget';
  String get ddayDuoDecorateSubtitle => _ko
      ? '같은 방 친구와 캐릭터 위치를 함께 맞추고, 홈 위젯에 바로 반영해요'
      : 'Place characters with room friends — changes sync to the home widget';
  String get ddayDuoDecoratePreview => _ko ? '미리보기' : 'Preview';
  String get ddayDuoDecorateDragHint => _ko
      ? '캐릭터를 눌러 고른 뒤, 배경 안에서 끌어 옮기세요'
      : 'Tap a character, then drag it inside the background';
  String get ddayDuoDecorateMenuHint => _ko
      ? '친구와 함께 꾸미는 응원 위젯'
      : 'Cheer widget you decorate with friends';
  String get ddayDuoDecorateDone => _ko ? '홈에 적용' : 'Apply to home';
  String get ddayDuoDecorateSampleTitle => _ko ? '우리 방' : 'Our room';
  String get ddayDecorateSoloHint => _ko
      ? '친구가 초대를 수락하면 같이 위젯으로 바뀌어요'
      : 'Together widget appears after a friend accepts your invite';
  String get ddayDecorateInviteHint => _ko
      ? '방에서 친구를 초대해 보세요'
      : 'Invite friends from the room';
  String get ddayDecorateShapeLabel => _ko ? '모양' : 'Shape';
  String get ddayDecorateSizeLabel => _ko ? '위젯 크기' : 'Widget size';
  String get ddayDecorateBgLabel => _ko ? '배경테마' : 'Background theme';

  String get ddayDecorateBgNone => _ko ? '투명' : 'Transparent';
  String get ddayDecorateBgAlbum => _ko ? '앨범' : 'Album';
  String get ddayDecorateBgAlbumFailed => _ko
      ? '사진을 불러오지 못했어요'
      : 'Could not open that photo';
  String get ddayDecorateTextColorLabel => _ko ? '글자색' : 'Text color';
  String get ddayDecorateTransparent => _ko ? '투명' : 'Transparent';
  String get ddayDecoratePickColor => _ko ? '색 고르기' : 'Pick a color';
  String get ddayDecoratePickColorDone => _ko ? '이 색으로 적용' : 'Use this color';
  String get ddayDecoratePaletteHue => _ko ? '색조' : 'Hue';
  String get ddayDecoratePalettePresets => _ko ? '팔레트' : 'Palette';
  String get ddayDecorateMoreColors => _ko ? '더 고르기' : 'More colors';
  String get ddayDecorateCharScaleLabel => _ko ? '캐릭터 크기' : 'Character size';
  String ddayDecorateCharScaleFor(String name) =>
      _ko ? '$name 크기' : '$name size';
  String ddayDecorateMeChip(String name) => _ko ? '나 · $name' : 'Me · $name';
  String ddayDecorateFriendChip(String name) =>
      _ko ? '친구 · $name' : 'Friend · $name';
  String get ddayDecorateTextScaleLabel => _ko ? '글자 크기' : 'Text size';
  String ddayDecorateShapeName(String id) {
    switch (id) {
      case 'circle':
        return _ko ? '동그라미' : 'Circle';
      case 'square':
        return _ko ? '정사각형' : 'Square';
      case 'portrait':
        return _ko ? '세로 네모' : 'Portrait';
      case 'landscape':
      default:
        return _ko ? '가로 네모' : 'Landscape';
    }
  }

  String ddayDecorateSizeName(String id) {
    switch (id) {
      case 's33':
      case 'sq':
        return '3×3';
      case 's43':
      case 'xl':
        return '4×3';
      case 's32':
      case 'm':
        return '3×2';
      case 's42':
      case 'l':
      default:
        return '4×2';
    }
  }

  String get ddayInviteTitle => _ko ? '친구 초대' : 'Invite friends';
  String get ddayInviteOpen => _ko ? '초대 코드·링크 만들기' : 'Create invite';
  String get ddayInviteSubtitle => _ko
      ? '초대를 수락한 친구만 같은 방에 들어와요.'
      : 'Only friends who accept join the room.';
  String ddayInviteFriendCount(int n) =>
      _ko ? '친구 $n명' : 'Friends $n';
  String get ddayInviteCodeLabel => _ko ? '초대 코드' : 'Invite code';
  String get ddayInviteCopyCode => _ko ? '코드 복사' : 'Copy code';
  String get ddayInviteCodeCopied => _ko ? '코드를 복사했어요' : 'Code copied';
  String get ddayInviteShare => _ko ? '초대 링크 공유' : 'Share invite link';
  String ddayInviteShareText(String title, String code, String url) => _ko
      ? '「$title」 같이 방에 초대해요!\n코드: $code\n$url'
      : 'Join my Together room "$title"!\nCode: $code\n$url';
  String ddayInviteSlotsLeft(int n) =>
      _ko ? '남은 자리 $n명' : '$n spots left';
  String get ddayInviteFull => _ko
      ? '이 방은 방장 포함 ${DdayInviteLimits.maxPeople}명까지예요'
      : 'This room is full (${DdayInviteLimits.maxPeople} people, including the host)';
  String get ddayInviteNeedLogin =>
      _ko ? 'Google로 로그인해 주세요' : 'Please sign in with Google';
  /// Shown only when cloud auth is not ready (host create-invite path).
  String get ddayInviteLoginAgain => _ko
      ? '초대를 만들려면 Google로 다시 로그인해 주세요'
      : 'Sign in with Google again to create an invite';
  String get ddayInviteCreateFailed =>
      _ko ? '초대를 만들지 못했어요. 잠시 후 다시 시도해 주세요' : 'Could not create invite. Try again shortly';
  String get ddayInviteRetry => _ko ? '다시 시도' : 'Retry';
  String get togetherFriendFallbackName => _ko ? '친구' : 'Friend';
  String togetherWidgetChangedBodyFor(String name) => _ko
      ? '$name - 위젯을 수정했어요!'
      : '$name updated the widget!';
  String get ddayInviteAcceptTitle => _ko ? '초대 코드 입력' : 'Enter invite code';
  String get ddayInviteAcceptSubtitle => _ko
      ? '친구가 보낸 6자리 코드를 입력하세요.'
      : 'Enter the 6-digit code from your friend.';
  String get ddayInviteAcceptAction => _ko ? '초대 수락' : 'Accept invite';
  String get ddayInviteAcceptSuccess =>
      _ko ? '같은 방에 참여했어요! 위젯에 반영돼요' : 'Joined the room! It will show on the widget';
  String get ddayInviteAcceptFailed =>
      _ko ? '수락에 실패했어요' : 'Could not accept invite';
  String get ddayInviteNotFound =>
      _ko ? '유효한 초대 코드를 찾지 못했어요' : 'Invite code not found';
  String get ddayInviteExpired =>
      _ko ? '만료된 초대예요' : 'This invite has expired';
  String get ddayInviteOwnCode =>
      _ko ? '내가 만든 초대에는 참여할 수 없어요' : "You can't join your own invite";
  String get ddayInviteInvalidCode =>
      _ko ? '코드는 6자리예요' : 'Code must be 6 characters';
  String get ddayInviteEnterCodeMenu =>
      _ko ? '초대 코드로 참여' : 'Join with invite code';

  String get togetherOpenRoom => _ko ? '방 열기' : 'Open room';
  String get togetherCheerTitle => _ko ? '응원 문구' : 'Cheer';
  String get togetherCheerHint => _ko
      ? '문구를 눌러 수정할 수 있어요. 방마다 하나 · 위젯에 바로 반영돼요'
      : 'Tap the cheer to edit. One per room — syncs to the widget';
  String get togetherCheerPlaceholder =>
      _ko ? '예: 오늘도 화이팅!' : 'e.g. You got this today!';
  String get togetherCheerSend => _ko ? '저장' : 'Save';
  String get togetherCheerLoggingIn => _ko ? '로그인 중…' : 'Signing in…';
  String get togetherCheerCancel => _ko ? '취소' : 'Cancel';
  String get togetherCheerEmpty =>
      _ko ? '탭해서 응원 문구를 적어 보세요' : 'Tap to write a cheer';
  String get togetherCheerTapHint =>
      _ko ? '탭해서 수정' : 'Tap to edit';
  String get togetherCheerNeedLogin =>
      _ko ? '응원을 남기려면 Google로 로그인해 주세요' : 'Sign in with Google to cheer';
  String get togetherCheerFailed =>
      _ko ? '응원을 남기지 못했어요' : 'Could not send cheer';
  String get togetherCheerPermission => _ko
      ? 'Google 로그인 후 다시 시도해 주세요'
      : 'No permission to cheer. Sign in with Google and try again';
  String get togetherWidgetPinnedToast => _ko
      ? '홈 화면 추가 창이 열렸어요. 추가를 눌러 주세요'
      : 'Add-to-home sheet opened — tap Add to place the widget';
  String get togetherWidgetSyncToast => _ko
      ? '위젯에 수정 내용을 반영했어요!'
      : 'Widget updated!';
  String get togetherFriendsLabel => _ko ? '같은 방 친구' : 'Friends in room';
  String get togetherSoloFriends =>
      _ko ? '아직 친구가 없어요. 초대해 보세요' : 'No friends yet — invite someone';
  String get togetherLatestCheerFallback =>
      _ko ? '응원을 남겨 보세요' : 'Leave a cheer';
  String togetherFriendCountLabel(int n) =>
      _ko ? '친구 $n명' : '$n friends';
  String get save => _ko ? '저장' : 'Save';
  String get delete => _ko ? '삭제' : 'Delete';

  String get brandTitle => 'Dearly';
  String get brandSubtitle => 'FOR A KINDER YOU';

  String get todaysFortune => _ko ? '오늘의 운세' : "Today's Fortune";
  String get fortuneShuffled =>
      _ko ? '오늘의 운세를 새로 뽑았어요' : 'Fortune refreshed';
  String get browseTitle =>
      _ko ? '어떤 문장을 읽고 싶나요?' : 'What would you like to read?';
  String get readerMenu => _ko ? '메뉴' : 'Menu';
  String get readerTheme => _ko ? '테마' : 'Theme';
  String get readerCategories => _ko ? '카테고리' : 'Categories';

  String get archiveTitle => _ko ? '보관함' : 'Archive';
  String get archiveHint => _ko
      ? '하트로 담아둔 문장을 카테고리별로 모아봤어요'
      : 'Hearted quotes are grouped by category';
  String get archiveEmptyTitle =>
      _ko ? '아직 담아둔 문장이 없어요' : 'No saved quotes yet';
  String get archiveEmptyHint =>
      _ko ? '문장 카드의 ♥ 를 눌러 보관해 보세요' : 'Tap ♥ on a quote to save it';

  String get settingsTitle => _ko ? '설정' : 'Settings';
  String get characterSection => _ko ? '캐릭터' : 'Character';
  String get characterTitle => _ko ? '내 캐릭터' : 'My character';
  String get characterSubtitle => _ko
      ? '홈과 위젯에 보여줄 캐릭터를 고를 수 있어요'
      : 'Choose the character for home and widget';
  String get characterSelectTitle =>
      _ko ? '캐릭터를 골라 주세요' : 'Pick your character';
  String get characterSelectSubtitle => _ko
      ? '나중에 설정에서 언제든 바꿀 수 있어요'
      : 'You can change this anytime in Settings';
  String get characterWidgetHint => _ko
      ? '캐릭터와 말풍선을 위젯으로 내보낼 수 있어요!'
      : 'You can send your character and speech bubble to a widget!';
  String get characterWidgetHintExport => _ko ? '내보내기' : 'Export';
  String get characterWidgetHintClose => _ko ? '닫기' : 'Close';
  String get characterWidgetHintClosed => _ko
      ? '홈 화면을 길게 눌러 위젯을 추가할 수 있어요!'
      : 'Long-press the home screen to add the widget!';
  String get characterSelectConfirm => _ko ? '이 캐릭터로 시작' : 'Start with this';
  String get characterChange => _ko ? '캐릭터 변경' : 'Change character';
  String get shopTitle => _ko ? '상점' : 'Shop';
  String get characterSettingsTitle =>
      _ko ? '캐릭터 설정' : 'Character settings';
  String get shopCategoryCharacter => _ko ? '캐릭터' : 'Characters';
  String get shopGroupFemale => _ko ? '여' : 'Women';
  String get shopGroupMale => _ko ? '남' : 'Men';
  String get shopMaleEmpty =>
      _ko ? '남자 캐릭터를 준비 중이에요' : 'Male characters are on the way';
  String get shopAdUnlock => _ko ? '캐릭터 소유하기' : 'Get this character';
  String get shopAdUnlockBody => _ko
      ? '영상을 시청하고 새로운 캐릭터를 받아보세요!'
      : 'Watch a video and get a new character!';
  String get shopAdConfirm => _ko ? '확인' : 'OK';
  String shopAdLeft(int n) => _ko
      ? '광고로 열 수 있는 캐릭터가 $n개 남았어요.'
      : '$n characters left to unlock with ads.';
  String get shopNeedPremium => _ko
      ? '구독하면 캐릭터가 모두 열려요.'
      : 'Subscribe to unlock every character.';
  String get shopAdFailed => _ko
      ? '광고를 불러오지 못했어요. 잠시 후 다시 시도해 주세요.'
      : 'Could not load the ad. Try again shortly.';
  String get shopUnlocked => _ko ? '캐릭터를 열었어요' : 'Character unlocked';
  String get shopSubscribe => _ko ? '구독하기' : 'Subscribe';
  String get friendCharacterTitle => _ko ? '친구 캐릭터' : 'Friend character';
  String get friendCharacterSubtitle => _ko
      ? '켜면 같은 방에 들어와요. 서로 고친 위젯이 양쪽 폰에 반영돼요'
      : 'Turn on to join the same room. Edits show on both phones';
  String get friendCharacterOnToast =>
      _ko ? '같은 방에 들어왔어요' : 'Joined the shared room';
  String get friendCharacterOffToast =>
      _ko ? '방에서 나왔어요' : 'Left the shared room';
  String get friendCharacterFailedToast =>
      _ko ? '같은 방에 들어가지 못했어요' : 'Could not join the shared room';
  String characterName(String id) {
    if (id == 'bul') return _ko ? '불' : 'Bul';
    if (id == 'basic') return _ko ? '기본' : 'Basic';
    if (id.startsWith('c')) {
      final n = id.substring(1);
      return _ko ? '스타일 $n' : 'Style $n';
    }
    return _ko ? '기본' : 'Basic';
  }

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
  String get nicknameTitle => _ko ? '닉네임' : 'Nickname';
  String get nicknameHint =>
      _ko ? '친구에게 보일 이름' : 'Name your friends will see';
  String get nicknameSave => _ko ? '저장' : 'Save';
  String get nicknameEmptyTitle =>
      _ko ? '닉네임을 입력해 주세요' : 'Add a nickname';
  String get nicknameEditSubtitle =>
      _ko ? '탭해서 닉네임 수정' : 'Tap to edit nickname';
  String get nicknameRequired =>
      _ko ? '닉네임을 입력해 주세요' : 'Enter a nickname';
  String get nicknameSaved => _ko ? '닉네임을 저장했어요' : 'Nickname saved';
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
  String get viewPremium => _ko ? '구독하기' : 'Subscribe';
  String billingError(String code) {
    switch (code) {
      case 'missing_key':
        return _ko
            ? 'RevenueCat 공개 키가 아직 없어요. 키를 넣은 뒤 다시 눌러 주세요'
            : 'The RevenueCat public key is missing. Add it, then try again';
      case 'unavailable':
        return _ko
            ? 'Play 스토어 결제를 사용할 수 없어요'
            : 'Play Store billing is unavailable';
      case 'not_found':
        return _ko
            ? '월 구독 상품을 아직 찾을 수 없어요. RevenueCat 오퍼링을 만든 뒤 다시 눌러 주세요'
            : 'Monthly plan is not available yet. Create the RevenueCat offering, then try again';
      default:
        return _ko ? '구독을 시작하지 못했어요' : 'Could not start the subscription';
    }
  }
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
  String get premiumLockedCta => _ko ? '월 구독하기' : 'Subscribe monthly';

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
  String get archiveRemove => _ko ? '보관 해제' : 'Remove from archive';
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

  String ddayIconName(String id) {
    switch (id) {
      case 'cake':
        return _ko ? '케이크' : 'Cake';
      case 'plane':
        return _ko ? '비행기' : 'Plane';
      case 'cat':
        return _ko ? '고양이' : 'Cat';
      case 'dog':
        return _ko ? '강아지' : 'Dog';
      case 'pen':
        return _ko ? '볼펜' : 'Pen';
      case 'notebook':
        return _ko ? '공책' : 'Notebook';
      case 'sport':
        return _ko ? '운동' : 'Sport';
      case 'medal':
        return _ko ? '메달' : 'Medal';
      case 'home':
        return _ko ? '집' : 'Home';
      case 'baby':
        return _ko ? '아기' : 'Baby';
      case 'tree':
        return _ko ? '나무' : 'Tree';
      case 'star':
        return _ko ? '별' : 'Star';
      case 'wine':
        return _ko ? '와인' : 'Wine';
      case 'heart':
        return _ko ? '하트' : 'Heart';
      default:
        return id;
    }
  }

  String get fontSample => _ko ? '가' : 'A';

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
