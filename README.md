# matiapu iOS

U22プログラミングコンテスト向けの iOS アプリです。地域の投稿をマップ上で共有し、スワイプで共感・スキップできるソーシャルアプリを目指しています。

リポジトリ: [matiapu/matiapu-iOS](https://github.com/matiapu/matiapu-iOS)

## 主な機能

| タブ | 説明 |
|------|------|
| **Map** | カテゴリ別ピン表示、フィルター、投稿詳細 |
| **Post** | 投稿カードのスワイプ（共感 / スキップ）、新規投稿 |
| **Match** | 議員・政策カードのスワイプ |
| **Account** | プロフィール、自分の投稿一覧 |

## 必要環境

| 項目 | バージョン |
|------|-----------|
| macOS | 最新版推奨 |
| Xcode | 26 以降 |
| iOS Deployment Target | 26.0 |
| Swift | 6 |

実機での動作確認を推奨する機能:

- カメラによる投稿撮影
- 位置情報の取得

## セットアップ手順

### 1. リポジトリをクローン

```bash
git clone https://github.com/matiapu/matiapu-iOS.git
cd matiapu-iOS
```

### 2. Xcode でプロジェクトを開く

```bash
open matiapu.xcodeproj
```

初回起動時、Swift Package Manager が依存関係を自動取得します。  
**File → Packages → Resolve Package Versions** で解決できない場合は、ネットワーク接続を確認してください。

### 3. シークレットファイルを用意

このプロジェクトでは API キーなどを Git に含めません。各自でローカルに設定してください。

#### `Secrets.xcconfig`（Google Maps API キー / チャット暗号化ソルト）

```bash
cp Secrets.xcconfig.example Secrets.xcconfig
```

`Secrets.xcconfig` を編集し、以下を設定します。

```
GOOGLE_MAPS_API_KEY = あなたのAPIキー
CHAT_SALT = Webアプリと同じチャット暗号化ソルト
```

> `Secrets.xcconfig` は `.gitignore` に含まれているため、コミットされません。

#### `GoogleService-Info.plist`（Firebase）

Firebase Console から iOS 用の `GoogleService-Info.plist` をダウンロードし、`matiapu/` ディレクトリに配置してください。

```
matiapu/
└── GoogleService-Info.plist  ← ここに配置
```

> このファイルも `.gitignore` に含まれています。チームメンバーには Firebase プロジェクトの管理者から共有してもらってください。

### 4. Google Maps API キーの取得

1. [Google Cloud Console](https://console.cloud.google.com/) でプロジェクトを作成
2. **Maps SDK for iOS** を有効化
3. API キーを作成し、`Secrets.xcconfig` に設定

API キーが未設定の場合、マップ画面は表示されません（アプリ自体は起動します）。

### 5. Firebase の設定

プロジェクトでは以下の Firebase 製品を利用予定です。

- Firebase Auth（メール / Google / Apple サインイン）
- Cloud Firestore
- Firebase Storage
- Google Sign-In

`GoogleService-Info.plist` がない場合でも、Firebase の初期化はスキップされ、モックデータで UI の開発・確認が可能です（認証画面はスキップされます）。

#### Google サインインの URL スキーム

`GoogleService-Info.plist` 内の `REVERSED_CLIENT_ID` を Xcode の **Info → URL Types** に追加してください。

例: `com.googleusercontent.apps.1234567890-abcdef`

#### Apple サインイン

`matiapu.entitlements` に Sign in with Apple を設定済みです。Apple Developer で App ID に Sign in with Apple を有効化してください。

### 6. ビルドと実行

1. Xcode でターゲット `matiapu` を選択
2. シミュレータまたは実機を選択
3. **⌘R** でビルド・実行

## プロジェクト構成

```
matiapu/
├── matiapuApp.swift          # エントリポイント（Firebase / Google Maps 初期化）
├── ContentView.swift         # ルート View
├── Core/
│   ├── AppDependencies.swift # 依存性の組み立て
│   ├── AppViewModels.swift   # タブ共通 ViewModel
│   ├── Models/               # Post, UserProfile など
│   ├── Repositories/         # データ取得層（Mock / Firebase）
│   ├── Firebase/             # Firestore マッパー・暗号化・共通サービス
│   ├── Preview/              # プレビュー用モックデータ
│   └── Shared/
│       ├── Components/       # 共通 UI コンポーネント
│       ├── DesignSystem/     # 色・タイポグラフィ・余白
│       └── Utilities/        # 位置情報・写真 EXIF など
└── Features/
    ├── Map/                  # マップ画面
    ├── Post/                 # 投稿フィード・作成
    ├── Match/                # マッチ画面
    └── Profile/              # アカウント画面
```

## アーキテクチャ

**MVVM + Repository パターン** を採用しています。

```
View → ViewModel → Repository →（Firebase / Mock）
```

- `AppDependencies` で Repository を注入
- `AppViewModels` でタブごとの ViewModel を一元管理
- 現状は `GoogleService-Info.plist` がない場合、Mock Repository で UI 開発が可能
- `GoogleService-Info.plist` がある場合、`AppDependencies.live` が Firestore 連携実装に自動切り替え

### Firestore 連携モジュール

| モジュール | Swift 実装 | 用途 |
|-----------|-----------|------|
| users | `FirebaseAuthRepository` | プロフィール取得・更新 |
| posts / likes | `FirebasePostRepository` | 投稿 CRUD・いいね・フィード |
| matches | `FirebaseMatchRepository` | 議員と市民の相互いいねマッチング |
| chat_rooms | `FirebaseChatRepository` | 暗号化チャット（AES-GCM） |
| comments | `FirebaseCommentRepository` | 投稿コメント（フラット構造） |
| shelters | `FirebaseShelterRepository` | 避難所情報 |
| disasters | `FirebaseDisasterRepository` | 災害情報 |
| qa_questions | `FirebaseQARepository` | 地域別 Q&A |

本番 API へ切り替える際は、`GoogleService-Info.plist` と `CHAT_SALT` を設定してください。

## 共同開発の進め方

### ブランチ運用（推奨）

```bash
# 最新の main を取得
git checkout main
git pull origin main

# 作業用ブランチを作成
git checkout -b feature/機能名

# 作業後に push
git push -u origin feature/機能名
```

GitHub 上で Pull Request を作成し、レビュー後に `main` へマージしてください。

### コミットメッセージ

[Conventional Commits](https://www.conventionalcommits.org/) 形式を推奨します。

```
feat: マップに投稿ボタンを追加
fix: プロフィール画面のレイアウト崩れを修正
refactor: PostCardView の表示ロジックを整理
```

### コミットしてはいけないもの

以下は **絶対にコミットしない** でください（`.gitignore` で除外済み）。

- `Secrets.xcconfig`
- `GoogleService-Info.plist`
- 証明書（`.p12`, `.cer`, `.mobileprovision`）
- `.env` などの環境変数ファイル

### 新メンバーへの共有事項

チームリーダーまたは Firebase / Google Cloud の管理者から、以下を安全な経路で共有してもらってください。

1. `Secrets.xcconfig` の API キー（または各自でキー発行）
2. `GoogleService-Info.plist`
3. Apple Developer Program への参加情報（実機配布が必要な場合）

## トラブルシューティング

### パッケージの解決に失敗する

```bash
# DerivedData を削除してから Xcode を再起動
rm -rf ~/Library/Developer/Xcode/DerivedData
```

Xcode で **File → Packages → Reset Package Caches** を実行してください。

### マップが真っ白 / 表示されない

- `Secrets.xcconfig` に正しい API キーが設定されているか確認
- Google Cloud Console で **Maps SDK for iOS** が有効か確認
- API キーの制限（Bundle ID など）が開発環境と一致しているか確認

### カメラが起動しない

シミュレータではカメラが使えません。**実機**で確認してください。

### ビルドエラー `Couldn't create workspace arena folder`

ディスク容量不足の可能性があります。DerivedData を削除して空き容量を確保してください。

```bash
rm -rf ~/Library/Developer/Xcode/DerivedData
```

## ライセンス

未定（チーム内で決定してください）。

## 問い合わせ

プロジェクトに関する質問は [matiapu/matiapu-iOS](https://github.com/matiapu/matiapu-iOS) の Issues またはチーム内チャットで共有してください。
