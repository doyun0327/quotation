import 'package:quotation/data/dday_friend_models.dart';
import 'package:quotation/l10n/locale_controller.dart';

class AppStrings {
  const AppStrings(this.language);

  final AppLanguage language;

  String _t(String ko, String en, String ja) {
    switch (language) {
      case AppLanguage.korean:
        return ko;
      case AppLanguage.japanese:
        return ja;
      case AppLanguage.english:
        return en;
    }
  }

  List<String> _lines(List<String> ko, List<String> en, List<String> ja) {
    switch (language) {
      case AppLanguage.korean:
        return ko;
      case AppLanguage.japanese:
        return ja;
      case AppLanguage.english:
        return en;
    }
  }

  static AppStrings get current => AppStrings(localeController.language);

  String get homeTab => _t('홈', 'Home', 'ホーム');
  String get ddayTab => _t('같이', 'Together', '一緒');
  String get archiveTab => _t('보관함', 'Archive', '保存');
  String get settingsTab => _t('설정', 'Settings', '設定');

  String get ddayTitle => _t('같이', 'Together', '一緒');
  String get ddayHint => _t('친구와 같은 방에서 캐릭터를 공유하고, 위젯을 꾸미며 응원 문구를 남겨요', 'Share a room with friends — characters, widget, and cheers together', '友だちと同じルームでキャラクターを共有し、ウィジェットを飾って応援メッセージを残せます');
  String get ddayEmptyTitle =>
      _t('아직 같이 방이 없어요', 'No rooms yet', 'まだ一緒のルームがありません');
  String get ddayEmptyHint => _t('방을 만들거나, 상단 초대 코드로 참여해 보세요', 'Create a room, or join with an invite code above', 'ルームを作るか、上の招待コードで参加してみてください');
  String get ddayLeaveRoom => _t('방 나가기', 'Leave room', 'ルームを出る');
  String get ddayAdd => _t('방 만들기', 'Create room', 'ルームを作る');
  String get ddayEdit => _t('방 수정', 'Edit room', 'ルームを編集');
  String get ddayAddSubtitle => _t('친구들과 응원할 방 이름을 정해 보세요', 'Name a room to cheer with friends', '友だちと応援するルームの名前を決めましょう');
  String get ddayWhatDay => _t('방 이름', 'Room name', 'ルーム名');
  String get ddayPickIcon => _t('아이콘을 골라 주세요', 'Choose an icon', 'アイコンを選んでください');
  String get ddayTitlePlaceholder =>
      _t('예: 우리 팀, 스터디 방', 'e.g. Our team, study buddies', '例: 私たちのチーム、勉強ルーム');
  String get ddayTitleHint => _t('방 이름', 'Room name', 'ルーム名');
  String get ddayTitleRequired =>
      _t('방 이름을 입력해 주세요', 'Please enter a room name', 'ルーム名を入力してください');
  String get ddayPickDate =>
      _t('날짜를 선택해 주세요', 'Please select a date', '日付を選んでください');
  String get ddayDate => _t('날짜', 'Date', '日付');
  String get ddayRepeat => _t('반복 설정', 'Repeat', '繰り返し');
  String get ddayRepeatNone => _t('반복 안 함', 'Does not repeat', '繰り返さない');
  String get ddayRepeatYearly => _t('매년 반복', 'Every year', '毎年繰り返す');
  String get ddaySave => _t('방 저장', 'Save room', 'ルームを保存');
  String get ddayPinWidget => _t('위젯에 표시', 'Show on widget', 'ウィジェットに表示');
  String get ddayPinnedWidget => _t('위젯에 표시 중', 'On widget', 'ウィジェットに表示中');
  String get ddayDuoBadge => _t('같이', 'Together', '一緒');
  String get ddayDuoTestSection =>
      _t('위젯 꾸미기', 'Customize widget', 'ウィジェットを飾る');
  String get ddayDuoTestUpdatedToast =>
      _t('홈 화면 같이 위젯에 반영했어요', 'Applied to the Together home widget', 'ホームの一緒ウィジェットに反映しました');
  String get ddayDuoDecorateOpen => _t('위젯 꾸미기', 'Customize widget', 'ウィジェットを飾る');
  String get ddayDuoDecorateTitle =>
      _t('위젯 꾸미기', 'Customize widget', 'ウィジェットを飾る');
  String get ddayDuoDecorateSubtitle => _t('같은 방 친구와 캐릭터 위치를 함께 맞추고, 홈 위젯에 바로 반영해요', 'Place characters with room friends — changes sync to the home widget', '同じルームの友だちとキャラクターの位置を合わせ、ホームウィジェットにすぐ反映します');
  String get ddayDuoDecoratePreview => _t('미리보기', 'Preview', 'プレビュー');
  String get ddayDuoDecorateDragHint => _t('캐릭터를 눌러 고른 뒤, 배경 안에서 끌어 옮기세요', 'Tap a character, then drag it inside the background', 'キャラクターをタップして選び、背景の中でドラッグして移動してください');
  String get ddayDuoDecorateMenuHint => _t('친구와 함께 꾸미는 응원 위젯', 'Cheer widget you decorate with friends', '友だちと一緒に飾る応援ウィジェット');
  String get ddayDuoDecorateDone => _t('홈에 적용', 'Apply to home', 'ホームに適用');
  String get ddayDuoDecorateSampleTitle => _t('우리 방', 'Our room', '私たちのルーム');
  String get ddayDecorateSoloHint => _t('친구가 초대를 수락하면 같이 위젯으로 바뀌어요', 'Together widget appears after a friend accepts your invite', '友だちが招待を受けると、一緒ウィジェットに変わります');
  String get ddayDecorateInviteHint => _t('방에서 친구를 초대해 보세요', 'Invite friends from the room', 'ルームから友だちを招待してみてください');
  String get ddayDecorateShapeLabel => _t('모양', 'Shape', '形');
  String get ddayDecorateSizeLabel => _t('위젯 크기', 'Widget size', 'ウィジェットサイズ');
  String get ddayDecorateBgLabel => _t('배경테마', 'Background theme', '背景テーマ');

  String get ddayDecorateBgNone => _t('투명', 'Transparent', '透明');
  String get ddayDecorateBgAlbum => _t('앨범', 'Album', 'アルバム');
  String get ddayDecorateBgAlbumFailed => _t('사진을 불러오지 못했어요', 'Could not open that photo', '写真を読み込めませんでした');
  String get ddayDecorateTextColorLabel => _t('글자색', 'Text color', '文字色');
  String get ddayDecorateTransparent => _t('투명', 'Transparent', '透明');
  String get ddayDecoratePickColor => _t('색 고르기', 'Pick a color', '色を選ぶ');
  String get ddayDecoratePickColorDone => _t('이 색으로 적용', 'Use this color', 'この色で適用');
  String get ddayDecoratePaletteHue => _t('색조', 'Hue', '色相');
  String get ddayDecoratePalettePresets => _t('팔레트', 'Palette', 'パレット');
  String get ddayDecorateMoreColors => _t('더 고르기', 'More colors', 'もっと選ぶ');
  String get ddayDecorateCharScaleLabel => _t('캐릭터 크기', 'Character size', 'キャラクターサイズ');
  String ddayDecorateCharScaleFor(String name) =>
      _t('$name 크기', '$name size', '$nameのサイズ');
  String ddayDecorateMeChip(String name) => _t('나 · $name', 'Me · $name', 'わたし · $name');
  String ddayDecorateFriendChip(String name) =>
      _t('친구 · $name', 'Friend · $name', '友だち · $name');
  String get ddayDecorateTextScaleLabel => _t('글자 크기', 'Text size', '文字サイズ');
  String ddayDecorateShapeName(String id) {
    switch (id) {
      case 'circle':
        return _t('동그라미', 'Circle', '丸');
      case 'square':
        return _t('정사각형', 'Square', '正方形');
      case 'portrait':
        return _t('세로 네모', 'Portrait', '縦長');
      case 'landscape':
      default:
        return _t('가로 네모', 'Landscape', '横長');
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

  String get ddayInviteTitle => _t('친구 초대', 'Invite friends', '友だちを招待');
  String get ddayInviteOpen => _t('초대 코드·링크 만들기', 'Create invite', '招待コード・リンクを作る');
  String get ddayInviteSubtitle => _t('초대를 수락한 친구만 같은 방에 들어와요.', 'Only friends who accept join the room.', '招待を受けた友だちだけが同じルームに入れます。');
  String ddayInviteFriendCount(int n) =>
      _t('친구 $n명', 'Friends $n', '友だち $n人');
  String get ddayInviteCodeLabel => _t('초대 코드', 'Invite code', '招待コード');
  String get ddayInviteCopyCode => _t('코드 복사', 'Copy code', 'コードをコピー');
  String get ddayInviteCodeCopied => _t('코드를 복사했어요', 'Code copied', 'コードをコピーしました');
  String get ddayInviteShare => _t('초대 링크 공유', 'Share invite link', '招待リンクを共有');
  String ddayInviteShareText(String title, String code, String url) => _t('「$title」 같이 방에 초대해요!\n코드: $code\n$url', 'Join my Together room "$title"!\nCode: $code\n$url', '「$title」の一緒ルームに招待します！\nコード: $code\n$url');
  String ddayInviteSlotsLeft(int n) =>
      _t('남은 자리 $n명', '$n spots left', '残り $n人');
  String get ddayInviteFull => _t('이 방은 방장 포함 ${DdayInviteLimits.maxPeople}명까지예요', 'This room is full (${DdayInviteLimits.maxPeople} people, including the host)', 'このルームはホストを含めて${DdayInviteLimits.maxPeople}人までです');
  String get ddayInviteNeedLogin =>
      _t('Google로 로그인해 주세요', 'Please sign in with Google', 'Googleでログインしてください');
  /// Shown only when cloud auth is not ready (host create-invite path).
  String get ddayInviteLoginAgain => _t('초대를 만들려면 Google로 다시 로그인해 주세요', 'Sign in with Google again to create an invite', '招待を作るには、Googleでもう一度ログインしてください');
  String get ddayInviteCreateFailed =>
      _t('초대를 만들지 못했어요. 잠시 후 다시 시도해 주세요', 'Could not create invite. Try again shortly', '招待を作れませんでした。しばらくしてからもう一度お試しください');
  String get ddayInviteRetry => _t('다시 시도', 'Retry', 'もう一度');
  String get togetherFriendFallbackName => _t('친구', 'Friend', '友だち');
  String togetherWidgetChangedBodyFor(String name) => _t('$name - 위젯을 수정했어요!', '$name updated the widget!', '$nameさんがウィジェットを更新しました！');
  String get ddayInviteAcceptTitle => _t('초대 코드 입력', 'Enter invite code', '招待コードを入力');
  String get ddayInviteAcceptSubtitle => _t('친구가 보낸 6자리 코드를 입력하세요.', 'Enter the 6-digit code from your friend.', '友だちからもらった6桁のコードを入力してください。');
  String get ddayInviteAcceptAction => _t('입장', 'Enter', '入室');
  String get ddayInviteAcceptSuccess =>
      _t('같은 방에 참여했어요! 위젯에 반영돼요', 'Joined the room! It will show on the widget', '同じルームに参加しました！ウィジェットに反映されます');
  String get ddayInviteAcceptFailed =>
      _t('수락에 실패했어요', 'Could not accept invite', '参加できませんでした');
  String get ddayInviteNotFound =>
      _t('유효한 초대 코드를 찾지 못했어요', 'Invite code not found', '有効な招待コードが見つかりません');
  String get ddayInviteExpired =>
      _t('만료된 초대예요', 'This invite has expired', 'この招待は期限切れです');
  String get ddayInviteOwnCode =>
      _t('내가 만든 초대에는 참여할 수 없어요', "You can't join your own invite", '自分が作った招待には参加できません');
  String get ddayInviteInvalidCode =>
      _t('코드는 6자리예요', 'Code must be 6 characters', 'コードは6桁です');
  String get ddayInviteEnterCodeMenu =>
      _t('초대 코드로 참여', 'Join with invite code', '招待コードで参加');

  String get togetherOpenRoom => _t('방 열기', 'Open room', 'ルームを開く');
  String get togetherCheerTitle => _t('응원 문구', 'Cheer', '応援メッセージ');
  String get togetherCheerHint => _t('문구를 눌러 수정할 수 있어요. 방마다 하나 · 위젯에 바로 반영돼요', 'Tap the cheer to edit. One per room — syncs to the widget', 'メッセージをタップして編集できます。ルームにつき1つ、ウィジェットにすぐ反映されます');
  String get togetherCheerPlaceholder =>
      _t('예: 오늘도 화이팅!', 'e.g. You got this today!', '例: 今日もがんばって！');
  String get togetherCheerSend => _t('저장', 'Save', '保存');
  String get togetherCheerLoggingIn => _t('로그인 중…', 'Signing in…', 'ログイン中…');
  String get togetherCheerCancel => _t('취소', 'Cancel', 'キャンセル');
  String get togetherCheerEmpty =>
      _t('탭해서 응원 문구를 적어 보세요', 'Tap to write a cheer', 'タップして応援メッセージを書いてみてください');
  String get togetherCheerTapHint =>
      _t('탭해서 수정', 'Tap to edit', 'タップして編集');
  String get togetherCheerNeedLogin =>
      _t('응원을 남기려면 Google로 로그인해 주세요', 'Sign in with Google to cheer', '応援を残すにはGoogleでログインしてください');
  String get togetherCheerFailed =>
      _t('응원을 남기지 못했어요', 'Could not send cheer', '応援を残せませんでした');
  String get togetherCheerPermission => _t('Google 로그인 후 다시 시도해 주세요', 'No permission to cheer. Sign in with Google and try again', 'Googleでログインしてから、もう一度お試しください');
  String get togetherWidgetPinnedToast => _t('홈 화면 추가 창이 열렸어요. 추가를 눌러 주세요', 'Add-to-home sheet opened — tap Add to place the widget', 'ホーム画面への追加が表示されました。追加をタップしてください');
  String get togetherWidgetSyncToast => _t('위젯에 수정 내용을 반영했어요!', 'Widget updated!', '変更をウィジェットに反映しました！');
  String get togetherFriendsLabel => _t('같은 방 친구', 'Friends in room', '同じルームの友だち');
  String get togetherSoloFriends =>
      _t('아직 친구가 없어요. 초대해 보세요', 'No friends yet — invite someone', 'まだ友だちがいません。招待してみてください');
  String get togetherLatestCheerFallback =>
      _t('응원을 남겨 보세요', 'Leave a cheer', '応援を残してみてください');
  String get safetyReport => _t('신고', 'Report', '通報');
  String get safetyReportTitle =>
      _t('응원 문구 신고', 'Report this cheer', '応援メッセージを通報');
  String get safetyReportBody => _t(
        '불쾌한 문구를 운영자에게 알립니다. 확인한 뒤 문구를 지우거나 이용을 제한합니다.',
        'This tells the operator. They review the cheer and can remove it or limit the account.',
        '不快なメッセージを運営に知らせます。確認のうえ、文章の削除や利用制限を行います。',
      );
  String get safetyReasonHarassment =>
      _t('괴롭힘', 'Harassment', '嫌がらせ');
  String get safetyReasonSexual =>
      _t('성적 내용', 'Sexual content', '性的な内容');
  String get safetyReasonSpam => _t('스팸', 'Spam', 'スパム');
  String get safetyReasonOther => _t('기타', 'Other', 'その他');
  String get safetyNoteHint => _t(
        '추가로 알릴 내용 (선택)',
        'Extra details (optional)',
        '追加で伝えること（任意）',
      );
  String get safetyBlockUser =>
      _t('이 사용자 차단', 'Block this person', 'このユーザーをブロック');
  String get safetyBlockHint => _t(
        '차단하면 이 기기에서 그 사람의 문구와 캐릭터가 보이지 않습니다.',
        'Blocking hides their cheer and character on this device.',
        'ブロックすると、この端末ではその人のメッセージとキャラクターが非表示になります。',
      );
  String get safetySubmit => _t('신고하기', 'Submit report', '通報する');
  String get safetySent => _t(
        '신고를 접수했어요. 확인 후 조치합니다.',
        'Report received. We will review it.',
        '通報を受け付けました。確認して対応します。',
      );
  String get safetyNeedLogin => _t(
        '신고하려면 로그인이 필요해요. 잠시 후 다시 시도해 주세요.',
        'Sign-in is required to report. Please try again.',
        '通報にはログインが必要です。しばらくしてからもう一度お試しください。',
      );
  String get safetyFailed => _t(
        '신고를 보내지 못했어요. 잠시 후 다시 시도해 주세요.',
        'Could not send the report. Please try again.',
        '通報を送れませんでした。しばらくしてからもう一度お試しください。',
      );
  String get safetyCheerHidden => _t(
        '차단한 사용자의 문구는 숨겼어요',
        'A blocked person’s cheer is hidden',
        'ブロックした人のメッセージは非表示です',
      );
  String get safetyNoCheer => _t(
        '지금 신고할 응원 문구가 없어요. 방에 있는 친구는 아래에서 차단할 수 있어요.',
        'There is no cheer to report. You can still block a friend below.',
        '今通報できる応援メッセージはありません。下の友だちはブロックできます。',
      );
  String get safetyOwnCheer => _t(
        '내가 쓴 문구는 신고할 수 없어요. 다른 사람의 문구가 있을 때 이유와 함께 보낼 수 있어요.',
        'You can’t report your own cheer. When someone else writes one, you can send a reason.',
        '自分が書いたメッセージは通報できません。ほかの人のメッセージがあるときに理由を選んで送れます。',
      );
  String get safetyFriends =>
      _t('같은 방 친구', 'People in this room', 'このルームの人');
  String get safetyBlocked =>
      _t('차단한 사용자', 'Blocked people', 'ブロックした人');
  String get safetyUnblock => _t('차단 해제', 'Unblock', 'ブロック解除');
  String get safetyBlockedDone =>
      _t('이 기기에서 차단했어요', 'Blocked on this device', 'この端末でブロックしました');
  String togetherFriendCountLabel(int n) =>
      _t('친구 $n명', '$n friends', '友だち $n人');
  String get save => _t('저장', 'Save', '保存');
  String get delete => _t('삭제', 'Delete', '削除');

  String get brandTitle => 'Dearly';
  String get brandSubtitle => 'FOR A KINDER YOU';

  String get todaysFortune => _t('오늘의 운세', "Today's Fortune", '今日の運勢');
  String get fortuneShuffled =>
      _t('오늘의 운세를 새로 뽑았어요', 'Fortune refreshed', '今日の運勢を引き直しました');
  String get browseTitle =>
      _t('어떤 문장을 읽고 싶나요?', 'What would you like to read?', 'どの文章を読みたいですか？');
  String get readerMenu => _t('메뉴', 'Menu', 'メニュー');
  String get readerTheme => _t('테마', 'Theme', 'テーマ');
  String get readerCategories => _t('카테고리', 'Categories', 'カテゴリー');

  String get archiveTitle => _t('보관함', 'Archive', '保存');
  String get archiveEmptyTitle =>
      _t('아직 담아둔 문장이 없어요', 'No saved quotes yet', 'まだ保存した文章がありません');
  String get archiveEmptyHint =>
      _t('문장 카드의 ♥ 를 눌러 보관해 보세요', 'Tap ♥ on a quote to save it', '文章カードの♥をタップして保存してみてください');

  String get settingsTitle => _t('설정', 'Settings', '設定');
  String get characterSection => _t('캐릭터', 'Character', 'キャラクター');
  String get characterTitle => _t('내 캐릭터', 'My character', 'マイキャラクター');
  String get characterSubtitle => _t('홈과 위젯에 보여줄 캐릭터를 고를 수 있어요', 'Choose the character for home and widget', 'ホームとウィジェットに出すキャラクターを選べます');
  String get characterSelectTitle =>
      _t('캐릭터를 골라 주세요', 'Pick your character', 'キャラクターを選んでください');
  String get characterSelectSubtitle => _t('나중에 설정에서 언제든 바꿀 수 있어요', 'You can change this anytime in Settings', 'あとから設定でいつでも変えられます');
  String get characterTapHint => _t('클릭해보세요!', 'Tap here!', 'タップしてみて！');
  String get characterWidgetHint => _t('캐릭터와 말풍선을 위젯으로 내보낼 수 있어요!', 'You can send your character and speech bubble to a widget!', 'キャラクターと吹き出しをウィジェットに書き出せます！');
  String get characterWidgetHintExport => _t('내보내기', 'Export', '書き出す');
  String get characterWidgetHintClose => _t('닫기', 'Close', '閉じる');
  String get characterWidgetHintClosed => _t('홈 화면을 길게 눌러 위젯을 추가할 수 있어요!', 'Long-press the home screen to add the widget!', 'ホーム画面を長押ししてウィジェットを追加できます！');
  String get characterSelectConfirm => _t('이 캐릭터로 시작', 'Start with this', 'このキャラクターで始める');
  String get characterChange => _t('캐릭터 변경', 'Change character', 'キャラクターを変更');
  String get shopTitle => _t('상점', 'Shop', 'ショップ');
  String get characterSettingsTitle =>
      _t('캐릭터 설정', 'Character settings', 'キャラクター設定');
  String get shopCategoryCharacter => _t('캐릭터', 'Characters', 'キャラクター');
  String get shopGroupFemale => _t('여', 'Women', '女');
  String get shopGroupMale => _t('남', 'Men', '男');
  String get shopMaleEmpty =>
      _t('남자 캐릭터를 준비 중이에요', 'Male characters are on the way', '男性キャラクターは準備中です');
  String get shopAdUnlock => _t('캐릭터 소유하기', 'Get this character', 'キャラクターを手に入れる');
  String get shopAdUnlockBody => _t('영상을 시청하고 새로운 캐릭터를 받아보세요!', 'Watch a video and get a new character!', '動画を見て、新しいキャラクターを受け取ってみてください！');
  String get shopAdConfirm => _t('확인', 'OK', '確認');
  String shopAdLeft(int n) => _t('광고로 열 수 있는 캐릭터가 $n개 남았어요.', '$n characters left to unlock with ads.', '広告で開放できるキャラクターはあと$n体です。');
  String get shopNeedPremium => _t('구독하면 캐릭터가 모두 열려요.', 'Subscribe to unlock every character.', '登録するとキャラクターがすべて開放されます。');
  String get shopAdFailed => _t('광고를 불러오지 못했어요. 잠시 후 다시 시도해 주세요.', 'Could not load the ad. Try again shortly.', '広告を読み込めませんでした。しばらくしてからもう一度お試しください。');
  String get shopUnlocked => _t('캐릭터를 열었어요', 'Character unlocked', 'キャラクターを開放しました');
  String get shopSubscribe => _t('구독하기', 'Subscribe', '登録する');
  String get friendCharacterTitle => _t('친구 캐릭터', 'Friend character', '友だちキャラクター');
  String get friendCharacterSubtitle => _t('켜면 같은 방에 들어와요. 서로 고친 위젯이 양쪽 폰에 반영돼요', 'Turn on to join the same room. Edits show on both phones', 'オンにすると同じルームに入ります。お互いの編集が両方のスマホに反映されます');
  String get friendCharacterOnToast =>
      _t('같은 방에 들어왔어요', 'Joined the shared room', '同じルームに入りました');
  String get friendCharacterOffToast =>
      _t('방에서 나왔어요', 'Left the shared room', 'ルームを出ました');
  String get friendCharacterFailedToast =>
      _t('같은 방에 들어가지 못했어요', 'Could not join the shared room', '同じルームに入れませんでした');
  String characterName(String id) {
    if (id == 'bul') return _t('불', 'Bul', 'ブル');
    if (id == 'basic') return _t('기본', 'Basic', '基本');
    if (id.startsWith('c')) {
      final n = id.substring(1);
      return _t('스타일 $n', 'Style $n', 'スタイル $n');
    }
    return _t('기본', 'Basic', '基本');
  }

  String get styleSection => _t('화면 스타일', 'Visual style', '画面スタイル');
  String get styleTitle => _t('앱 스타일', 'App style', 'アプリスタイル');
  String get styleSubtitle => _t('픽셀 또는 클린 스타일을 선택할 수 있어요', 'Choose pixel or clean style', 'ピクセルまたはクリーンのスタイルを選べます');
  String styleName(String id) {
    switch (id) {
      case 'clean':
        return _t('클린', 'Clean', 'クリーン');
      case 'pixel':
      default:
        return _t('픽셀', 'Pixel', 'ピクセル');
    }
  }

  String styleChanged(String name) =>
      _t('$name 스타일로 변경했어요', 'Style changed to $name', '$nameスタイルに変更しました');

  String get themeSection => _t('테마 색상', 'Theme color', 'テーマカラー');
  String get themeTitle => _t('앱 테마', 'App theme', 'アプリテーマ');
  String get themeSubtitle => _t('포인트 색을 바꿔 분위기를 바꿔보세요', 'Change the accent color of the app', 'アクセントカラーを変えて雰囲気を変えてみましょう');
  String themeChanged(String name) =>
      _t('$name 테마로 변경했어요', 'Theme changed to $name', '$nameテーマに変更しました');

  String get fontSection => _t('글자 크기', 'Font size', '文字サイズ');
  String get fontTitle => _t('본문 글자 크기', 'Body text size', '本文の文字サイズ');
  String get fontSubtitle =>
      _t('읽기 편한 크기로 조절할 수 있어요', 'Choose a comfortable reading size', '読みやすいサイズに調節できます');
  String fontChanged(String name) =>
      _t('글자 크기: $name', 'Font size: $name', '文字サイズ: $name');

  String get accountSection => _t('계정', 'Account', 'アカウント');
  String get nicknameTitle => _t('닉네임', 'Nickname', 'ニックネーム');
  String get nicknameHint =>
      _t('친구에게 보일 이름', 'Name your friends will see', '友だちに表示される名前');
  String get nicknameSave => _t('저장', 'Save', '保存');
  String get nicknameEmptyTitle =>
      _t('닉네임을 입력해 주세요', 'Add a nickname', 'ニックネームを入力してください');
  String get nicknameEditSubtitle =>
      _t('탭해서 닉네임 수정', 'Tap to edit nickname', 'タップしてニックネームを編集');
  String get nicknameRequired =>
      _t('닉네임을 입력해 주세요', 'Enter a nickname', 'ニックネームを入力してください');
  String get nicknameSaved => _t('닉네임을 저장했어요', 'Nickname saved', 'ニックネームを保存しました');
  String get googleLoginTitle =>
      _t('Google 계정으로 로그인', 'Sign in with Google', 'Googleアカウントでログイン');
  String get googleLoginSubtitle => _t('로그인하면 데이터를 동기화할 수 있어요', 'Sign in to sync your data', 'ログインするとデータを同期できます');
  String get googleLoggedInTitle =>
      _t('Google 계정', 'Google account', 'Googleアカウント');
  String googleLoggedInSubtitle(String email) =>
      _t('$email 으로 로그인됨', 'Signed in as $email', '$email でログイン中');
  String get login => _t('로그인', 'Sign in', 'ログイン');
  String get logout => _t('로그아웃', 'Sign out', 'ログアウト');
  String get googleLoginToast =>
      _t('Google 로그인', 'Google sign-in', 'Googleログイン');
  String get googleLoginSuccess =>
      _t('Google 로그인 완료', 'Signed in with Google', 'Googleログインが完了しました');
  String get googleLogoutSuccess =>
      _t('로그아웃했어요', 'Signed out', 'ログアウトしました');
  String get googleLoginCanceled =>
      _t('로그인을 취소했어요', 'Sign-in canceled', 'ログインをキャンセルしました');
  String get googleLoginConfigError => _t('Google 설정 오류예요. OAuth 동의 화면이 Testing이면 Test users에 본인 계정을 추가하고, Android 클라이언트(패키지+SHA-1)를 확인해 주세요', 'Google config error. If consent is Testing, add your account under Test users, and verify Android OAuth package+SHA-1', 'Googleの設定エラーです。同意画面がTestingならTest usersに自分のアカウントを追加し、Androidクライアント（パッケージ+SHA-1）を確認してください');
  String get googleLoginConfigMissing => _t('Google Web 클라이언트 ID를 아직 설정하지 않았어요', 'Google Web client ID is not configured yet', 'Google WebクライアントIDがまだ設定されていません');
  String get googleLoginFailed =>
      _t('Google 로그인에 실패했어요', 'Google sign-in failed', 'Googleログインに失敗しました');
  String googleLoginFailedDetail(String detail) => _t('Google 로그인 실패: $detail', 'Google sign-in failed: $detail', 'Googleログイン失敗: $detail');

  String get languageSection => _t('앱 언어', 'App language', 'アプリの言語');
  String get languageTitle => _t('앱 언어', 'App language', 'アプリの言語');
  String get languageSubtitle =>
      _t('원하는 언어로 앱을 사용할 수 있어요', 'Choose Korean, English, or Japanese', '好きな言語でアプリを使えます');
  String languageChanged(String name) =>
      _t('언어: $name', 'Language: $name', '言語: $name');

  String get subscriptionSection => _t('구독 관리', 'Subscription', '登録の管理');
  String get premiumTitle => _t('프리미엄 구독', 'Premium', 'プレミアム登録');
  String get premiumSubtitle =>
      _t('광고 없이 모든 기능을 이용하세요', 'Enjoy all features without ads', '広告なしですべての機能を利用できます');
  String get viewPremium => _t('구독하기', 'Subscribe', '登録する');
  String billingError(String code) {
    switch (code) {
      case 'missing_key':
        return _t('RevenueCat 공개 키가 아직 없어요. 키를 넣은 뒤 다시 눌러 주세요', 'The RevenueCat public key is missing. Add it, then try again', 'RevenueCatの公開キーがまだありません。キーを入れてからもう一度押してください');
      case 'unavailable':
        return _t('Play 스토어 결제를 사용할 수 없어요', 'Play Store billing is unavailable', 'Playストアの決済を利用できません');
      case 'not_found':
        return _t('월 구독 상품을 아직 찾을 수 없어요. RevenueCat 오퍼링을 만든 뒤 다시 눌러 주세요', 'Monthly plan is not available yet. Create the RevenueCat offering, then try again', '月額プランがまだ見つかりません。RevenueCatのオファリングを作ってからもう一度押してください');
      default:
        return _t('구독을 시작하지 못했어요', 'Could not start the subscription', '登録を開始できませんでした');
    }
  }
  String get premiumToast => _t('프리미엄 보기', 'View Premium', 'プレミアムを見る');
  String get premiumToggleTitle =>
      _t('프리미엄 (임시)', 'Premium (temp)', 'プレミアム（仮）');
  String get premiumToggleSubtitle => _t('결제 연동 전 테스트용 스위치예요', 'Temporary switch before billing', '決済連携前のテスト用スイッチです');
  String get premiumEnabledToast =>
      _t('프리미엄이 켜졌어요', 'Premium turned on', 'プレミアムをオンにしました');
  String get premiumDisabledToast =>
      _t('무료 회원으로 전환했어요', 'Switched to free', '無料会員に切り替えました');
  String get premiumLockedTitle =>
      _t('프리미엄 전용', 'Premium only', 'プレミアム限定');
  String get premiumLockedBody => _t('이 카테고리는 프리미엄 회원만 볼 수 있어요. 행복한 일상은 무료로 이용할 수 있어요.', 'This category is for premium members. Happy Everyday is free.', 'このカテゴリーはプレミアム会員だけが見られます。幸せな日常は無料で利用できます。');
  String get premiumLockedDismiss => _t('닫기', 'Close', '閉じる');
  String get premiumLockedCta => _t('월 구독하기', 'Subscribe monthly', '月額で登録');

  String get otherSection => _t('기타 설정', 'Other', 'その他');
  String get eveningDebugTitle =>
      _t('저녁 알림 테스트', 'Test evening alert', '夜の通知テスト');
  String get eveningDebugSubtitle => _t('디버그용으로 저녁 위로를 지금 한 건 보냅니다', 'Send one evening comfort notification now', 'デバッグ用に、夜の慰め通知を今1件送ります');
  String get eveningDebugToast =>
      _t('저녁 알림을 보냈어요', 'Evening notification sent', '夜の通知を送りました');
  String get termsTitle =>
      _t('이용약관 및 개인정보처리방침', 'Terms & Privacy', '利用規約とプライバシーポリシー');
  String get termsSubtitle =>
      _t('서비스 이용 관련 정보를 확인하세요', 'Review terms and privacy policy', 'サービスの利用に関する情報を確認してください');
  String get appInfoTitle => _t('앱 정보', 'App info', 'アプリ情報');
  String get appInfoSubtitle =>
      _t('버전 및 앱 정보를 확인하세요', 'Version and app details', 'バージョンとアプリ情報を確認してください');
  String get appInfoToast => _t('앱 정보', 'App info', 'アプリ情報');

  String get filterAll => _t('전체', 'All', 'すべて');
  String get filterNewest => _t('최신순', 'Newest', '新しい順');
  String get filterPopular => _t('인기순', 'Popular', '人気順');
  String get noQuotes => _t('표시할 문장이 없어요', 'No quotes to show', '表示する文章がありません');
  String get savedToArchive =>
      _t('보관함에 담았어요', 'Saved to archive', '保存しました');
  String get archiveRemove => _t('보관 해제', 'Remove from archive', '保存を解除');
  String get removedFromArchive =>
      _t('보관함에서 뺐어요', 'Removed from archive', '保存から外しました');
  String get share => _t('공유하기', 'Share', '共有する');
  String get swipeHint =>
      _t('위·아래로 넘겨 보세요', 'Swipe up or down', '上下にスワイプしてみてください');

  String get searchHint =>
      _t('단어로 검색해 보세요', 'Search by keyword', '言葉で検索してみてください');
  String searchIn(String title) =>
      _t('$title에서 검색', 'Search in $title', '$titleで検索');
  String searchResults(int count) =>
      _t('$count개의 결과', '$count results', '$count件の結果');
  String get searchEmpty =>
      _t('검색 결과가 없어요', 'No results found', '検索結果がありません');
  String get searchExample =>
      _t('예: 위로, 용기, 감사', 'e.g. comfort, courage, thanks', '例: 慰め、勇気、感謝');

  String get placeholderArchiveSubtitle =>
      _t('마음에 둔 문장이 여기에 모예요', 'Your hearted quotes will appear here', '気に入った文章がここに集まります');

  String themeName(String id) {
    switch (id) {
      case 'sky':
        return _t('하늘', 'Sky', '空');
      case 'mint':
        return _t('민트', 'Mint', 'ミント');
      case 'lavender':
        return _t('라벤더', 'Lavender', 'ラベンダー');
      case 'peach':
        return _t('피치', 'Peach', 'ピーチ');
      case 'rose':
        return _t('로즈', 'Rose', 'ローズ');
      default:
        return id;
    }
  }

  String ddayIconName(String id) {
    switch (id) {
      case 'cake':
        return _t('케이크', 'Cake', 'ケーキ');
      case 'plane':
        return _t('비행기', 'Plane', '飛行機');
      case 'cat':
        return _t('고양이', 'Cat', '猫');
      case 'dog':
        return _t('강아지', 'Dog', '犬');
      case 'pen':
        return _t('볼펜', 'Pen', 'ペン');
      case 'notebook':
        return _t('공책', 'Notebook', 'ノート');
      case 'sport':
        return _t('운동', 'Sport', '運動');
      case 'medal':
        return _t('메달', 'Medal', 'メダル');
      case 'home':
        return _t('집', 'Home', '家');
      case 'baby':
        return _t('아기', 'Baby', '赤ちゃん');
      case 'tree':
        return _t('나무', 'Tree', '木');
      case 'star':
        return _t('별', 'Star', '星');
      case 'wine':
        return _t('와인', 'Wine', 'ワイン');
      case 'heart':
        return _t('하트', 'Heart', 'ハート');
      default:
        return id;
    }
  }

  String get fontSample => _t('가', 'A', 'あ');

  String fontName(String id) {
    switch (id) {
      case 'small':
        return _t('작게', 'Small', '小さく');
      case 'medium':
        return _t('보통', 'Medium', '普通');
      case 'large':
        return _t('크게', 'Large', '大きく');
      case 'xlarge':
        return _t('더 크게', 'X-Large', 'もっと大きく');
      default:
        return id;
    }
  }

  String mainCategoryTitle(String id) {
    switch (id) {
      case 'comfort':
        return _t('위로와 응원', 'Comfort & Cheer', '慰めと応援');
      case 'faith':
        return _t('종교와 지혜', 'Faith & Wisdom', '宗教と知恵');
      case 'literature':
        return _t('명언과 문학', 'Quotes & Literature', '名言と文学');
      case 'daily':
        return _t('행복한 일상', 'Happy Everyday', '幸せな日常');
      default:
        return id;
    }
  }

  List<String> mainCategoryLines(String id) {
    switch (id) {
      case 'comfort':
        return _lines(['지친 마음에', '따뜻한 한마디'], ['Warm words', 'for a tired heart'], ['疲れた心に', 'あたたかい一言']);
      case 'faith':
        return _lines(['불교 · 천주교', '개신교 · 가르침'], ['Buddhism · Catholicism', 'Protestant · Teachings'], ['仏教・カトリック', 'プロテスタント・教え']);
      case 'literature':
        return _lines(['유명인의 명언', '작가의 문장'], ['Famous quotes', "Writers' lines"], ['有名人の名言', '作家の文章']);
      case 'daily':
        return _lines(['사랑, 관계, 감사', '매일의 작은 기쁨'], ['Love, connection, gratitude', 'Small daily joys'], ['愛、関係、感謝', '毎日の小さな喜び']);
      default:
        return const [];
    }
  }

  String mainCategoryBanner(String id) {
    switch (id) {
      case 'comfort':
        return _t('지금, 네 마음에 따뜻한 위로를 보낼게요.', 'Sending warm comfort to your heart.', 'いま、あなたの心にあたたかい慰めを届けます。');
      case 'faith':
        return _t('고요한 마음이 필요할 때, 지혜의 말을 건네줄게요.', 'When you need quiet wisdom, these words are here.', '静かな心がほしいとき、知恵の言葉を届けます。');
      case 'literature':
        return _t('오래 남는 문장으로 마음에 불을 밝혀줄게요.', 'Let lasting lines light your heart.', '長く残る文章で、心に灯をともします。');
      case 'daily':
        return _t('평범한 하루 속 반짝임을 함께 찾아봐요.', "Let's find sparkle in ordinary days.", 'ふつうの一日の中のきらめきを、一緒に見つけましょう。');
      default:
        return '';
    }
  }

  String subCategoryTitle(String id) {
    switch (id) {
      case 'tired':
        return _t('지친 하루', 'A tired day', '疲れた一日');
      case 'self':
        return _t('자존감과 자기 사랑', 'Self-love', '自尊心と自分への愛');
      case 'courage':
        return _t('용기와 도전', 'Courage', '勇気と挑戦');
      case 'anxiety':
        return _t('불안과 걱정', 'Anxiety', '不安と心配');
      case 'lonely':
        return _t('외로움과 위로', 'Loneliness', '孤独と慰め');
      case 'growth':
        return _t('실패와 성장', 'Growth', '失敗と成長');
      case 'relation':
        return _t('인간관계', 'Relationships', '人間関係');
      case 'dream':
        return _t('꿈과 동기부여', 'Dreams', '夢とやる気');
      case 'buddhism':
        return _t('불교', 'Buddhism', '仏教');
      case 'christian':
        return _t('기독교', 'Christianity', 'キリスト教');
      case 'quotes':
        return _t('유명인 명언', 'Famous quotes', '有名人の名言');
      case 'writers':
        return _t('작가의 문장', "Writers' lines", '作家の文章');
      case 'gratitude':
        return _t('감사와 기쁨', 'Gratitude', '感謝と喜び');
      case 'love':
        return _t('사랑과 관계', 'Love', '愛と関係');
      default:
        return id;
    }
  }

  String subCategorySubtitle(String id) {
    switch (id) {
      case 'tired':
        return _t('힘든 하루를 보낸 나에게', 'For me after a hard day', 'つらい一日を終えた自分へ');
      case 'self':
        return _t('나 자신을 아끼고 싶을 때', 'When I want to cherish myself', '自分を大切にしたくなったとき');
      case 'courage':
        return _t('새로운 시작이 두려울 때', 'When a new start feels scary', '新しい始まりがこわいとき');
      case 'anxiety':
        return _t('미래가 걱정되고 마음이 복잡할 때', 'When worry fills the mind', '未来が心配で心がざわつくとき');
      case 'lonely':
        return _t('누군가에게 위로받고 싶을 때', 'When I need comfort', '誰かに慰めてほしいとき');
      case 'growth':
        return _t('실수했거나 다시 일어서고 싶을 때', 'When I want to rise again', '失敗したあと、また立ち上がりたいとき');
      case 'relation':
        return _t('친구, 가족, 사람 때문에 힘들 때', 'When people feel heavy', '友だちや家族、人のことでつらいとき');
      case 'dream':
        return _t('목표를 향해 나아가고 싶을 때', 'When I want to move toward a goal', '目標に向かって進みたくなったとき');
      case 'buddhism':
        return _t('마음에 고요를 담고 싶을 때', 'When I seek quiet mindfulness', '心に静けさを置きたくなったとき');
      case 'christian':
        return _t('믿음과 소망이 필요할 때', 'When I need faith and hope', '信仰と希望が必要なとき');
      case 'quotes':
        return _t('삶을 비추는 한마디', 'Lines that light life', '人生を照らす一言');
      case 'writers':
        return _t('책 속에서 건진 위로', 'Comfort found in books', '本の中で見つけた慰め');
      case 'gratitude':
        return _t('작은 행복을 발견하고 싶을 때', 'When I want small joys', '小さな幸せを見つけたくなったとき');
      case 'love':
        return _t('마음이 따뜻해지고 싶을 때', 'When I want warmth', '心があたたかくなりたくなったとき');
      default:
        return '';
    }
  }

  String subCategoryBanner(String id) {
    switch (id) {
      case 'tired':
        return _t('오늘도 수고한 너에게 따뜻한 문장을 전해요.', 'Warm lines for you who worked hard today.', '今日もがんばったあなたへ、あたたかい文章を届けます。');
      case 'self':
        return _t('너를 가장 먼저 아껴주는 사람이 되어봐.', 'Be the first to cherish yourself.', '自分をいちばん大切にしてくれる人になってみて。');
      case 'courage':
        return _t('작은 한 걸음도 멋진 시작이야.', 'Even a small step is a brave start.', '小さな一歩も、すてきな始まりだよ。');
      case 'anxiety':
        return _t('지금 이 순간만 천천히 바라보자.', 'Look gently at this moment only.', 'いまこの瞬間だけを、ゆっくり見てみよう。');
      case 'lonely':
        return _t('혼자가 아니야. 여기 따뜻한 말이 있어.', "You're not alone. Warm words are here.", 'ひとりじゃないよ。ここにあたたかい言葉があるよ。');
      case 'growth':
        return _t('넘어짐도 성장의 일부야.', 'Falling is part of growing.', '転ぶことも、成長の一部だよ。');
      case 'relation':
        return _t('관계는 천천히, 진심으로 가꿔가면 돼.', 'Grow relationships slowly and sincerely.', '関係はゆっくり、真心で育てていけばいいよ。');
      case 'dream':
        return _t('네 꿈은 여전히 반짝이고 있어.', 'Your dream is still shining.', 'あなたの夢は、いまもきらめいているよ。');
      case 'buddhism':
        return _t('집착을 내려놓고 숨을 고르자.', 'Let go a little, and breathe.', 'こだわりを置いて、呼吸を整えよう。');
      case 'christian':
        return _t('따뜻한 위로가 네 마음에 닿기를.', 'May warm comfort reach your heart.', 'あたたかい慰めが、あなたの心に届きますように。');
      case 'quotes':
        return _t('짧은 문장, 긴 울림.', 'Short lines, lasting echoes.', '短い文章、長い響き。');
      case 'writers':
        return _t('문학이 건네는 따뜻한 손길.', 'Literature offering a warm hand.', '文学が差し伸べる、あたたかい手。');
      case 'gratitude':
        return _t('오늘도 고마운 일이 분명 있어.', 'There is something to be thankful for today.', '今日も、感謝できることがきっとあるよ。');
      case 'love':
        return _t('사랑은 가까운 곳에서 피어나.', 'Love blooms nearby.', '愛は、すぐ近くで咲くよ。');
      default:
        return '';
    }
  }

  String get cancel => _t('취소', 'Cancel', 'キャンセル');
  String get meLabel => _t('나', 'Me', 'わたし');
  String deleteRoomConfirm(String title) => _t(
        '「$title」 방을 삭제할까요?',
        'Delete room "$title"?',
        '「$title」ルームを削除しますか？',
      );
  String get homeGreeting => _t(
        '안녕, 오늘도 잘하고 있어.',
        "Hi, you're doing well today.",
        'こんにちは。今日もよく頑張ってるよ。',
      );
  String get doingWell => _t(
        '오늘도 잘하고 있어.',
        "You're doing well today.",
        '今日もよく頑張ってるよ。',
      );
  String get fortuneFallbackLine => _t(
        '오늘도 좋은 일이 생길 거예요.',
        'Something good is waiting today.',
        '今日もいいことがあるよ。',
      );
}
