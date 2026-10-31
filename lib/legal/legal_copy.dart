import 'package:quotation/l10n/locale_controller.dart';

class LegalBlock {
  const LegalBlock(this.heading, this.body);

  final String heading;
  final String body;
}

class LegalCopy {
  const LegalCopy({
    required this.updated,
    required this.termsHeading,
    required this.privacyHeading,
    required this.terms,
    required this.privacy,
  });

  final String updated;
  final String termsHeading;
  final String privacyHeading;
  final List<LegalBlock> terms;
  final List<LegalBlock> privacy;

  static const contact = 'idoyun781@gmail.com';

  static LegalCopy forLanguage(AppLanguage language) {
    switch (language) {
      case AppLanguage.korean:
        return _korean;
      case AppLanguage.japanese:
        return _japanese;
      case AppLanguage.english:
        return _english;
    }
  }
}

const _korean = LegalCopy(
  updated: '최종 업데이트: 2026년 10월 31일 · 앱 이름: Dearly',
  termsHeading: '이용약관',
  privacyHeading: '개인정보처리방침',
  terms: [
    LegalBlock(
      '1. 약관의 적용',
      'Dearly(이하 “서비스”)를 설치하거나 이용하면 이 약관과 개인정보처리방침에 동의한 것으로 봅니다. 동의하지 않으면 서비스를 이용하지 말아 주세요.',
    ),
    LegalBlock(
      '2. 서비스 내용',
      'Dearly는 응원 문구와 캐릭터, 보관함, 홈 화면 위젯, 기기 안의 알림, 초대한 사람과 캐릭터와 짧은 응원을 나누는 같이 방을 제공합니다. 일부 기능은 무료입니다. 선택 사항인 월간 구독은 광고를 없애고 프리미엄 문구와 캐릭터를 엽니다. 서비스의 구성은 운영상 바뀔 수 있습니다.',
    ),
    LegalBlock(
      '3. 계정',
      '문구, 보관함, 캐릭터, 위젯, 기기 안 알림은 로그인 없이 이용할 수 있습니다. 같이 방과 친구에게 보이는 닉네임에는 Google 로그인이 필요합니다. 본인 소유의 Google 계정만 사용해야 하며, 계정을 통해 이루어진 활동에 대한 책임은 이용자에게 있습니다.',
    ),
    LegalBlock(
      '4. 구독',
      '유료 상품은 월간 자동 갱신 구독입니다. Android에서는 Google Play, iPhone에서는 App Store가 판매합니다.\n'
          '• 가격, 결제 주기, 포함 내용은 결제 확인 전에 스토어 구매 화면에 표시됩니다.\n'
          '• 요금은 구매를 확인할 때 Google Play 계정 또는 Apple ID로 청구됩니다. 앱은 카드 번호를 직접 받지 않습니다.\n'
          '• 현재 기간이 끝나기 최소 24시간 전에 취소하지 않으면 매달 자동으로 갱신됩니다.\n'
          '• 해지와 관리는 Android에서는 Google Play의 결제 및 정기 결제, iPhone에서는 설정 > Apple ID > 구독에서 할 수 있습니다. 앱을 지우는 것만으로는 구독이 해지되지 않습니다.\n'
          '• 해지 후에도 이미 결제한 기간이 끝날 때까지 이용할 수 있습니다.\n'
          '• 환불은 Google Play 또는 Apple의 환불 정책과 관련 법령을 따릅니다. iPhone에서 결제한 구독의 환불은 Apple에 요청해야 합니다.\n'
          '• 앱을 다시 설치하면 설정의 구매 복원으로, 구매한 Google 계정 또는 Apple ID의 구독을 다시 불러올 수 있습니다.',
    ),
    LegalBlock(
      '5. 광고',
      '무료 이용 중에는 배너 광고가 보일 수 있습니다. 캐릭터를 여는 보상형 광고는 선택 사항입니다. 광고는 Google AdMob이 제공합니다. 구독 중에는 배너 광고를 보여 주지 않습니다.',
    ),
    LegalBlock(
      '6. 이용자가 올리는 내용',
      '같이 방에 적는 방 이름과 응원 문구는 그 방의 참여자에게 보입니다. 법령을 위반하거나, 타인을 괴롭히거나, 미성년자에게 성적인 내용을 보내거나, 위협하거나, 다른 사람의 권리를 침해하는 내용을 올리지 마세요. 이런 내용을 알게 되면 문구를 지우거나 방 이용을 제한할 수 있습니다. 방은 앱에서 나갈 수 있습니다.',
    ),
    LegalBlock(
      '7. 금지 행위',
      '서비스의 운영을 방해하는 행위, 다른 사람의 계정이나 초대 코드를 함부로 쓰는 행위, 앱을 무단으로 수집하는 행위, 법령을 위반하는 행위는 금지됩니다.',
    ),
    LegalBlock(
      '8. 지식재산권',
      '앱, 캐릭터, 화면 구성의 권리는 운영자 또는 정당한 권리자에게 있습니다. 문구는 개인적·비상업적 범위에서 저장하고 나눌 수 있습니다. 앱, 캐릭터, 문구 목록을 복제하여 경쟁 서비스에 사용할 수 없습니다.',
    ),
    LegalBlock(
      '9. 면책',
      '문구는 응원을 위한 것이며 의료, 법률, 금융, 심리 상담이 아닙니다. 서비스는 있는 그대로 제공됩니다. 문구를 근거로 한 판단, 서비스 중단, 다른 이용자가 작성한 내용으로 인한 손해에 대해 법령상 책임을 제한할 수 없는 경우를 제외하고 운영자는 책임을 지지 않습니다.',
    ),
    LegalBlock(
      '10. 변경과 종료',
      '약관과 서비스는 변경될 수 있습니다. 중요한 변경이 있으면 이 문서의 업데이트 날짜를 바꿉니다. 변경 이후에도 서비스를 계속 이용하면 변경된 약관에 동의한 것으로 봅니다. 가능한 경우 사전 안내 후 서비스를 중단할 수 있습니다.',
    ),
    LegalBlock(
      '11. 준거법',
      '이 약관은 대한민국 법을 따릅니다. 거주 국가의 소비자 보호 규정에서 보장하는 권리는 빼앗지 않습니다.',
    ),
    LegalBlock(
      '12. 문의',
      '이메일: ${LegalCopy.contact}',
    ),
  ],
  privacy: [
    LegalBlock(
      '1. 개요',
      'Dearly는 ${LegalCopy.contact} 으로 연락할 수 있는 운영자가 제공합니다. 이 방침은 어떤 정보를 왜 처리하는지 설명합니다.',
    ),
    LegalBlock(
      '2. 수집하는 정보',
      '로그인하지 않아도 문구, 보관함, 캐릭터, 위젯, 기기 안 알림을 쓸 수 있습니다. 그 선택은 기기에 저장됩니다.\n\n'
          'Google로 로그인하면 다음을 받아 저장할 수 있습니다.\n'
          '• 이메일 주소\n'
          '• Google이 제공하는 이름\n'
          '• 프로필 사진 주소(제공된 경우)\n'
          '• Google 계정 식별자\n'
          '• 이용자가 입력한 닉네임\n'
          '• 선택한 캐릭터\n\n'
          '같이 방을 쓰면 방 이름, 초대 코드, 참여 정보, 참여자가 적은 응원 문구, 방에 표시되는 캐릭터를 저장합니다.\n\n'
          '같이 방 알림을 허용하면 알림을 보내기 위한 Firebase Cloud Messaging 토큰을 저장합니다.\n\n'
          '구독하면 Google Play 또는 App Store와 구독 처리 파트너인 RevenueCat이 결제를 처리합니다. 운영자는 구독이 유효한지와 구매를 복원하는 데 쓰는 스토어 이용자 식별자를 받습니다. 카드 번호 전체는 받지 않습니다.\n\n'
          '광고가 표시되면 Google AdMob이 광고 식별자, IP 주소, 기기 정보를 광고 제공과 측정에 사용할 수 있습니다. 보상형 광고 시청은 선택입니다.\n\n'
          '전화번호, 정확한 위치, 연락처, 건강 정보는 요구하지 않습니다.',
    ),
    LegalBlock(
      '3. 이용 목적',
      '로그인 유지, 같이 방 참여자에게 닉네임과 캐릭터 표시, 방과 응원 문구 및 관련 알림 전달, 구독 확인과 복원, 구독자에게 배너 광고 숨김, 무료 이용 중 광고 표시, 이메일 문의 응답, 서비스 유지와 부정 이용 방지에 사용합니다. 아침 알림처럼 기기에 예약된 알림의 문구는 그 목적으로 서버에 보내지 않습니다.',
    ),
    LegalBlock(
      '4. 보유 기간',
      '계정과 방 정보는 계정 또는 방이 유지되는 동안 보관합니다. 삭제를 요청하면 법령, 분쟁, 보안상 보관이 필요한 항목을 제외하고 프로필, 참여 표시 이름, 알림 토큰을 삭제하거나 식별할 수 없게 합니다. 이용자가 적은 방 문구는 방이 지워지기 전까지 남을 수 있으며, 요청하면 이름 표시는 제거합니다. 결제 기록은 세금과 스토어 정책이 요구하는 기간 동안 보관될 수 있습니다. 기기에만 있는 보관함, 위젯, 언어 설정은 앱 데이터를 지우거나 앱을 삭제할 때까지 기기에 남습니다.',
    ),
    LegalBlock(
      '5. 제공과 처리 위탁',
      '개인정보를 판매하지 않습니다. 서비스 운영에 필요한 범위에서 다음 사업자가 처리합니다.\n'
          '• Google Firebase: 로그인, 데이터베이스, 클라우드 메시징\n'
          '• Google 로그인\n'
          '• Google Play 결제, Apple App Store 결제\n'
          '• RevenueCat: 구독 상태 확인\n'
          '• Google AdMob: 광고\n'
          '법령에 따르거나 이용자를 부정 이용으로부터 보호해야 할 때 정보를 공개할 수 있습니다.',
    ),
    LegalBlock(
      '6. 국외 이전',
      '위 사업자는 대한민국 밖의 서버, 특히 미국을 포함한 지역에서 정보를 처리할 수 있습니다. 이전은 이 방침에 적힌 서비스 제공을 위해서입니다.',
    ),
    LegalBlock(
      '7. 이용자의 권리와 삭제',
      '로그인 없이 앱을 이용할 수 있습니다. 설정의 로그아웃은 이 기기에서 Google 연결을 해제합니다. 알림은 기기 설정에서 끌 수 있습니다. 광고 맞춤설정은 기기의 광고 설정에서 제한할 수 있습니다.\n\n'
          '클라우드에 저장된 계정 정보의 열람 또는 삭제는 ${LegalCopy.contact} 으로 요청할 수 있습니다. 계정에 등록된 이메일로 보내 주거나, 다른 주소로 보낼 때는 어떤 계정을 지울지 알려 주세요. 합리적 기간 안에 해당 계정의 클라우드 프로필을 삭제하고, 법령상 남겨야 하는 항목이 있으면 알려 드립니다.\n\n'
          '앱을 삭제하면 그 기기의 로컬 데이터는 지워집니다. 앱 삭제만으로 구독이 해지되거나 클라우드 계정이 삭제되지는 않습니다. 구독은 Google Play 또는 iPhone 설정의 구독에서 해지하고, 계정 삭제는 이메일로 요청해 주세요.',
    ),
    LegalBlock(
      '8. 아동',
      'Dearly는 만 14세 미만 아동을 대상으로 하지 않으며, 아동의 개인정보를 고의로 수집하지 않습니다. 아동의 정보가 수집된 사실을 알게 되면 이메일로 알려 주세요. 삭제하겠습니다.',
    ),
    LegalBlock(
      '9. 안전조치',
      'Firebase와 Google 로그인의 접근 통제를 사용합니다. 어떤 저장 방법도 완벽한 안전을 보장하지는 않습니다.',
    ),
    LegalBlock(
      '10. 방침의 변경',
      '방침이 바뀌면 상단의 업데이트 날짜를 변경합니다. 변경 이후 서비스를 계속 이용하면 변경된 방침에 동의한 것으로 봅니다.',
    ),
    LegalBlock(
      '11. 문의',
      '이메일: ${LegalCopy.contact}',
    ),
  ],
);

const _english = LegalCopy(
  updated: 'Last updated: October 31, 2026 · App: Dearly',
  termsHeading: 'Terms of Use',
  privacyHeading: 'Privacy Policy',
  terms: [
    LegalBlock(
      '1. Agreement',
      'By installing or using Dearly (the “Service”), you agree to these terms and the privacy policy. If you do not agree, do not use the Service.',
    ),
    LegalBlock(
      '2. The Service',
      'Dearly offers encouraging quotes, characters, a personal archive, home-screen widgets, reminders scheduled on your device, and Together rooms where you share a character and short cheers with people you invite. Some features are free. An optional monthly subscription removes banner ads and unlocks premium quotes and characters. Features may change.',
    ),
    LegalBlock(
      '3. Accounts',
      'Quotes, the archive, characters, widgets, and on-device reminders work without an account. Google sign-in is required for Together rooms and for a nickname friends can see. Use only a Google account that belongs to you. You are responsible for activity under that account.',
    ),
    LegalBlock(
      '4. Subscriptions',
      'The paid plan is a monthly auto-renewing subscription, sold by Google Play on Android and by the App Store on iPhone.\n'
          '• The price, billing period, and what is included are shown on the store purchase screen before you confirm.\n'
          '• Payment is charged to your Google Play account or Apple ID when you confirm the purchase. The app does not receive your full card number.\n'
          '• The plan renews each month unless you cancel at least 24 hours before the current period ends.\n'
          '• Cancel or manage it in Google Play under Payments & subscriptions on Android, or in Settings > Apple ID > Subscriptions on iPhone. Uninstalling the app does not cancel the subscription.\n'
          '• After cancellation you can keep using the paid features until the period you already paid for ends.\n'
          '• Refunds follow Google Play’s or Apple’s refund rules and applicable law. Refunds for purchases made on iPhone are requested from Apple.\n'
          '• If you reinstall the app, use Restore purchases in Settings to bring back the plan bought with your Google account or Apple ID.',
    ),
    LegalBlock(
      '5. Ads',
      'The free experience may show a banner ad. Rewarded videos that unlock a character are optional. Ads are provided by Google AdMob. Banner ads are not shown while a subscription is active.',
    ),
    LegalBlock(
      '6. Content you submit',
      'Room names and cheers in a Together room are visible to members of that room. Do not post anything illegal, harassing, sexual involving a minor, threatening, or infringing someone else’s rights. We may remove that content or limit the room if we learn of it. You can leave a room in the app.',
    ),
    LegalBlock(
      '7. Prohibited use',
      'Do not disrupt the Service, misuse another person’s account or invite code, scrape the app, or use the Service in violation of law.',
    ),
    LegalBlock(
      '8. Intellectual property',
      'The app, characters, and presentation are owned by the operator or its licensors. You may save and share quotes for personal, non-commercial use. You may not copy the app, characters, or quote catalog for a competing service.',
    ),
    LegalBlock(
      '9. Disclaimer',
      'Quotes are for encouragement. They are not medical, legal, financial, or mental-health advice. The Service is provided as is. Except where liability cannot be limited by law, the operator is not liable for decisions you make from a quote, for interruptions, or for content other people write.',
    ),
    LegalBlock(
      '10. Changes and ending the Service',
      'These terms and the Service may change. Material changes update the date on this page. Continued use after a change means you accept the updated terms. The Service may be suspended with notice when practical.',
    ),
    LegalBlock(
      '11. Law',
      'These terms are governed by the laws of the Republic of Korea. This does not remove consumer protections that apply in your country of residence.',
    ),
    LegalBlock(
      '12. Contact',
      'Email: ${LegalCopy.contact}',
    ),
  ],
  privacy: [
    LegalBlock(
      '1. Overview',
      'Dearly is operated by the person you can reach at ${LegalCopy.contact}. This policy explains what information is processed and why.',
    ),
    LegalBlock(
      '2. Information we process',
      'You can use quotes, the archive, characters, widgets, and on-device reminders without an account. Those choices stay on your device.\n\n'
          'If you sign in with Google, we may receive and store:\n'
          '• email address\n'
          '• the name Google shares\n'
          '• profile photo URL, if Google provides one\n'
          '• Google account identifier\n'
          '• the nickname you enter\n'
          '• the character you select\n\n'
          'If you use Together, we store the room name, invite code, membership, cheers members write, and the character shown in the room.\n\n'
          'If you allow Together notifications, we store a Firebase Cloud Messaging token so the notice can be delivered.\n\n'
          'If you subscribe, Google Play or the App Store and our subscription partner RevenueCat process the payment. We receive whether the plan is active and a store user id used to restore the purchase. We do not receive your full card number.\n\n'
          'When an ad is shown, Google AdMob may use an advertising identifier, IP address, and device information to provide and measure ads. Watching a rewarded ad is optional.\n\n'
          'We do not ask for your phone number, precise location, contacts, or health information.',
    ),
    LegalBlock(
      '3. Why we use it',
      'We use this information to keep you signed in, show your nickname and character to room members, deliver rooms, cheers, and related notifications, confirm and restore a subscription, hide banner ads for subscribers, show ads in the free experience, answer email you send us, and keep the Service reliable and free of abuse. Text for reminders scheduled on the device, such as the morning notice, is not sent to our server for that purpose.',
    ),
    LegalBlock(
      '4. How long we keep it',
      'Account and room information is kept while the account or room exists. If you ask us to delete the account, we delete or de-identify the profile, membership display name, and messaging token, except for records we must keep for law, disputes, or security. Cheers you wrote may remain until the room is deleted. If you ask, we remove your name from them. Purchase records may be kept as required by tax rules and the store. Archive, widget, and language settings stored only on the device remain until you clear app data or uninstall.',
    ),
    LegalBlock(
      '5. Sharing',
      'We do not sell personal information. These providers process it only to run Dearly:\n'
          '• Google Firebase, for sign-in, the database, and cloud messaging\n'
          '• Google Sign-In\n'
          '• Google Play Billing and Apple App Store payments\n'
          '• RevenueCat, for subscription status\n'
          '• Google AdMob, for ads\n'
          'We may disclose information if the law requires it or to protect users from abuse.',
    ),
    LegalBlock(
      '6. International processing',
      'These providers may process information on servers outside your country, including in the United States. They do so to provide the Service described in this policy.',
    ),
    LegalBlock(
      '7. Your choices and deletion',
      'You can use the app without signing in. Sign-out in Settings disconnects Google on this device. You can turn notifications off in device settings and limit ad personalization in your device’s ad settings.\n\n'
          'To access or delete the account information stored in the cloud, email ${LegalCopy.contact}. Use the email on the account, or tell us which account to delete if you write from another address. Within a reasonable time we will delete the cloud profile tied to that account and tell you if a record must be kept by law.\n\n'
          'Uninstalling the app removes local data on that device. Uninstalling does not cancel a subscription or delete the cloud account. Cancel the subscription in Google Play or in iPhone Settings > Subscriptions, and email us to delete the account.',
    ),
    LegalBlock(
      '8. Children',
      'Dearly is not directed to children under 14, or under the higher age required in your country. We do not knowingly collect their personal information. If you believe a child has given us personal information, email us and we will delete it.',
    ),
    LegalBlock(
      '9. Security',
      'We rely on the access controls of Firebase and Google sign-in. No storage method is perfectly secure.',
    ),
    LegalBlock(
      '10. Changes',
      'When this policy changes, we update the date at the top. Continued use after the change means you accept the updated policy.',
    ),
    LegalBlock(
      '11. Contact',
      'Email: ${LegalCopy.contact}',
    ),
  ],
);

const _japanese = LegalCopy(
  updated: '最終更新: 2026年10月31日 · アプリ名: Dearly',
  termsHeading: '利用規約',
  privacyHeading: 'プライバシーポリシー',
  terms: [
    LegalBlock(
      '1. 適用',
      'Dearly（以下「本サービス」）をインストールまたは利用すると、本規約とプライバシーポリシーに同意したものとみなします。同意しない場合は利用しないでください。',
    ),
    LegalBlock(
      '2. サービス内容',
      'Dearlyは、応援の文章、キャラクター、保存庫、ホーム画面ウィジェット、端末内の通知、招待した人とキャラクターや短い応援を共有する一緒ルームを提供します。一部の機能は無料です。任意の月額登録では広告をなくし、プレミアムの文章とキャラクターを開けます。機能の内容は変わることがあります。',
    ),
    LegalBlock(
      '3. アカウント',
      '文章、保存庫、キャラクター、ウィジェット、端末内の通知はログインなしで利用できます。一緒ルームと、友だちに表示するニックネームにはGoogleログインが必要です。本人のGoogleアカウントだけを使い、そのアカウントでの行為について責任を負います。',
    ),
    LegalBlock(
      '4. 定期購入',
      '有料プランは毎月自動更新の定期購入です。AndroidではGoogle Play、iPhoneではApp Storeが販売します。\n'
          '• 料金、請求期間、含まれる内容は、確認する前にストアの購入画面に表示されます。\n'
          '• 料金は購入の確認時にGoogle PlayアカウントまたはApple IDに請求されます。アプリはカード番号の全体を受け取りません。\n'
          '• 現在の期間が終わる24時間前までに解約しない限り、毎月自動で更新されます。\n'
          '• 解約と管理は、AndroidではGoogle Playの「お支払いと定期購入」、iPhoneでは「設定 > Apple ID > サブスクリプション」で行います。アプリを削除しただけでは解約されません。\n'
          '• 解約後も、支払い済みの期間が終わるまでは有料機能を利用できます。\n'
          '• 返金はGoogle PlayまたはAppleの返金ルールと適用される法令に従います。iPhoneで購入した定期購入の返金はAppleに申請してください。\n'
          '• アプリを再インストールした場合、設定の「購入を復元」で、購入したGoogleアカウントまたはApple IDの定期購入を復元できます。',
    ),
    LegalBlock(
      '5. 広告',
      '無料利用中はバナー広告が表示されることがあります。キャラクターを開けるリワード広告の視聴は任意です。広告はGoogle AdMobが提供します。定期購入中はバナー広告を表示しません。',
    ),
    LegalBlock(
      '6. 利用者が投稿する内容',
      '一緒ルームの部屋名と応援メッセージは、その部屋の参加者に表示されます。法令に違反する内容、嫌がらせ、未成年者に関する性的な内容、脅迫、他人の権利を侵害する内容は投稿しないでください。そのような内容を知った場合、文章を削除し、または部屋の利用を制限することがあります。部屋はアプリ内で退出できます。',
    ),
    LegalBlock(
      '7. 禁止事項',
      '本サービスの運営を妨げる行為、他人のアカウントや招待コードの不正利用、アプリの無断収集、法令に違反する行為を禁止します。',
    ),
    LegalBlock(
      '8. 知的財産',
      'アプリ、キャラクター、画面構成の権利は運営者または正当な権利者にあります。文章は個人的・非営利の範囲で保存し、共有できます。アプリ、キャラクター、文章の一覧を複製して競合サービスに使うことはできません。',
    ),
    LegalBlock(
      '9. 免責',
      '文章は応援のためのものであり、医療、法律、金融、心理の助言ではありません。本サービスは現状のまま提供されます。文章に基づく判断、サービスの中断、他の利用者が書いた内容による損害について、法令上責任を制限できない場合を除き、運営者は責任を負いません。',
    ),
    LegalBlock(
      '10. 変更と終了',
      '本規約と本サービスは変更されることがあります。重要な変更がある場合は、この文書の更新日を改めます。変更後も利用を続けると、変更後の規約に同意したものとみなします。可能な場合は事前に知らせたうえでサービスを停止することがあります。',
    ),
    LegalBlock(
      '11. 準拠法',
      '本規約は大韓民国の法令に従います。お住まいの国の消費者保護で認められる権利を奪うものではありません。',
    ),
    LegalBlock(
      '12. お問い合わせ',
      'メール: ${LegalCopy.contact}',
    ),
  ],
  privacy: [
    LegalBlock(
      '1. 概要',
      'Dearlyは ${LegalCopy.contact} に連絡できる運営者が提供します。この方針は、どの情報をなぜ取り扱うかを説明します。',
    ),
    LegalBlock(
      '2. 取り扱う情報',
      'ログインしなくても、文章、保存庫、キャラクター、ウィジェット、端末内の通知を利用できます。その選択は端末に保存されます。\n\n'
          'Googleでログインすると、次の情報を受け取り保存することがあります。\n'
          '• メールアドレス\n'
          '• Googleが共有する名前\n'
          '• プロフィール写真のURL（提供された場合）\n'
          '• Googleアカウント識別子\n'
          '• 入力したニックネーム\n'
          '• 選択したキャラクター\n\n'
          '一緒ルームを使うと、部屋名、招待コード、参加情報、参加者が書いた応援、部屋に表示するキャラクターを保存します。\n\n'
          '一緒ルームの通知を許可すると、通知を届けるためのFirebase Cloud Messagingトークンを保存します。\n\n'
          '定期購入ではGoogle PlayまたはApp Storeと、購入処理の提携先であるRevenueCatが決済を処理します。運営者はプランが有効かどうかと、購入の復元に使うストア利用者識別子を受け取ります。カード番号の全体は受け取りません。\n\n'
          '広告が表示されるとき、Google AdMobは広告識別子、IPアドレス、端末情報を、広告の配信と測定に使うことがあります。リワード広告の視聴は任意です。\n\n'
          '電話番号、正確な位置情報、連絡先、健康情報は求めません。',
    ),
    LegalBlock(
      '3. 利用目的',
      'ログイン状態の維持、一緒ルームの参加者へのニックネームとキャラクターの表示、部屋・応援・関連通知の提供、定期購入の確認と復元、登録者へのバナー広告の非表示、無料利用中の広告表示、メールでの問い合わせへの回答、サービスの維持と不正利用の防止に使います。端末に予約された朝の通知などの文章は、その目的でサーバーへ送りません。',
    ),
    LegalBlock(
      '4. 保管期間',
      'アカウントと部屋の情報は、アカウントまたは部屋がある間保管します。削除を求められた場合、法令・紛争・安全のために残す必要があるものを除き、プロフィール、参加時の表示名、通知トークンを削除するか、識別できないようにします。利用者が書いた応援は部屋が削除されるまで残ることがあります。求めがあれば名前の表示は外します。購入記録は、税務とストアの規則が求める期間保管されることがあります。端末だけにある保存庫、ウィジェット、言語設定は、アプリデータを消すかアプリを削除するまで端末に残ります。',
    ),
    LegalBlock(
      '5. 提供と委託',
      '個人情報を販売しません。本サービスの運営に必要な範囲で、次の事業者が取り扱います。\n'
          '• Google Firebase: ログイン、データベース、クラウドメッセージング\n'
          '• Googleログイン\n'
          '• Google Playの決済、Apple App Storeの決済\n'
          '• RevenueCat: 定期購入の状態確認\n'
          '• Google AdMob: 広告\n'
          '法令に基づく場合、または利用者を不正利用から守る必要がある場合に情報を開示することがあります。',
    ),
    LegalBlock(
      '6. 国外での取り扱い',
      '上記の事業者は、お住まいの国の外、特に米国を含む地域のサーバーで情報を処理することがあります。処理はこの方針に書いたサービス提供のためです。',
    ),
    LegalBlock(
      '7. 利用者の選択と削除',
      'ログインなしでアプリを利用できます。設定のログアウトは、この端末でのGoogleとの接続を解除します。通知は端末の設定で止められます。広告のパーソナライズは端末の広告設定で制限できます。\n\n'
          'クラウドに保存されたアカウント情報の開示または削除は ${LegalCopy.contact} に依頼できます。アカウントのメールアドレスから送るか、別のアドレスから送る場合は削除するアカウントを知らせてください。合理的な期間内にそのアカウントのクラウド上のプロフィールを削除し、法令上残す必要があるものがあればお知らせします。\n\n'
          'アプリを削除すると、その端末のローカルデータは消えます。アプリの削除だけでは定期購入は解約されず、クラウドのアカウントも削除されません。定期購入はGoogle PlayまたはiPhoneの設定の「サブスクリプション」で解約し、アカウントの削除はメールで依頼してください。',
    ),
    LegalBlock(
      '8. 子ども',
      'Dearlyは14歳未満の子ども、またはお住まいの国でそれより高い年齢が定められている場合はその年齢未満の子どもを対象にしていません。子どもの個人情報を故意に収集しません。子どもが情報を提供したと思われる場合はメールで知らせてください。削除します。',
    ),
    LegalBlock(
      '9. 安全管理',
      'FirebaseとGoogleログインのアクセス制御を使います。どの保存方法も完全な安全を保証するものではありません。',
    ),
    LegalBlock(
      '10. 方針の変更',
      '方針が変わったときは、上部の更新日を変更します。変更後も利用を続けると、変更後の方針に同意したものとみなします。',
    ),
    LegalBlock(
      '11. お問い合わせ',
      'メール: ${LegalCopy.contact}',
    ),
  ],
);
