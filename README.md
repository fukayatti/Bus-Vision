# Bus Vision

<div align="center">
  <img src="https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white" alt="macOS">
  <img src="https://img.shields.io/badge/Swift-FA7343?style=for-the-badge&logo=swift&logoColor=white" alt="Swift">
  <img src="https://img.shields.io/badge/SwiftUI-2396F3?style=for-the-badge&logo=swift&logoColor=white" alt="SwiftUI">
</div>

## 概要

Bus Vision は、茨城高専前から勝田駅前へのバス接近情報をリアルタイムで監視する macOS メニューバーアプリケーションです。バス接近情報サイトから自動的にデータを取得し、見やすいインターフェースで表示します。

![alt text](image.png)

## 主な機能

### 🚌 リアルタイムバス情報

- **接近状況**: 「あと ○ 分で到着予定」などの接近情報を表示
- **路線情報**: バスの路線名と行き先を表示
- **発着時刻**: バスの発着予定時刻を表示
- **現在位置**: バスの現在地と相対位置を表示
- **遅延情報**: 運行遅延の状況を表示

### 📱 直感的なユーザーインターフェース

- **メニューバー統合**: システムメニューバーからすぐにアクセス可能
- **色分け表示**: 接近状況に応じた色分けで視認性を向上
- **自動更新**: 15 秒間隔で自動的にデータを更新
- **手動更新**: リフレッシュボタンで即座に最新データを取得

### ⚙️ システム統合機能

- **ログイン時自動起動**: システム起動時に自動でアプリを開始
- **ブラウザ連携**: ワンクリックで公式サイトをブラウザで開く
- **エラーハンドリング**: 接続エラーや データなしの状況を適切に表示

## システム要件

- **OS**: macOS 13.0 (Ventura) 以降
- **開発環境**: Xcode 14.0 以降
- **Swift**: Swift 5.0 以降

## インストール方法

### 開発者向け

1. **リポジトリをクローン**:

   ```bash
   git clone https://github.com/your-username/Bus-Vision.git
   cd Bus-Vision
   ```

2. **Xcode でプロジェクトを開く**:

   ```bash
   open "Bus Vision.xcodeproj"
   ```

3. **ビルドと実行**:
   - Xcode でプロジェクトを開く
   - ターゲットを選択してビルド
   - 実行してメニューバーにアイコンが表示されることを確認

## 使用方法

### 基本操作

1. **アプリケーション起動**:
   - メニューバーにバスアイコンが表示されます
2. **情報確認**:
   - メニューバーのバスアイコンをクリックしてポップアップを表示
3. **データ更新**:
   - 自動更新（15 秒間隔）または手動更新ボタンをクリック

### 表示される情報

- **更新時刻**: データの最終更新時刻
- **停留所情報**: 出発地（茨城高専前）→ 到着地（勝田駅前）
- **接近状況**: バスの到着予定時刻
- **路線・行き先**: バスの路線名と最終目的地
- **現在位置**: バスの現在地と出発地からの相対位置

## 技術仕様

### アーキテクチャ

```
Bus Vision/
├── Bus_VisionApp.swift      # アプリケーションのメインエントリーポイント
├── BusDataModel.swift       # データモデルとWebスクレイピング処理
├── MenuBarView.swift        # メニューバーUI実装
├── ContentView.swift        # メインビュー（使用されていない）
└── Assets.xcassets/         # アプリアイコンとリソース
```

### 主要コンポーネント

#### `BusDataModel`

- **役割**: バス接近情報の取得と管理
- **機能**:
  - HTML スクレイピングによるデータ抽出
  - 15 秒間隔での自動更新
  - エラーハンドリング

#### `MenuBarView`

- **役割**: ユーザーインターフェースの提供
- **機能**:
  - 情報の表示とフォーマット
  - ユーザー操作への応答
  - 設定管理

#### `Bus_VisionApp`

- **役割**: アプリケーションの初期化と設定
- **機能**:
  - ログイン時自動起動の設定
  - メニューバー統合

### データフロー

1. **データ取得**: `BusDataModel`が指定 URL から HTML を取得
2. **データ解析**: 正規表現を使用してバス情報を抽出
3. **UI 更新**: `@Published`プロパティ経由で自動的に UI を更新
4. **エラー処理**: 接続エラーやデータなしの状況を適切に処理

## 設定とカスタマイズ

### 自動起動設定

```swift
@AppStorage("launchAtLogin") private var launchAtLogin = true
```

### 更新間隔の変更

```swift
// BusDataModel.swift内で変更可能
timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true)
```

### 対象路線の変更

```swift
// BusDataModel.swift内のURLを変更
private let busURL = "https://mc.bus-vision.jp/ibako/view/approach.html?stopCdFrom=69&stopCdTo=76"
```

## 開発

### プロジェクト構成

```
Bus Vision.xcodeproj/
├── Bus Vision/              # メインアプリケーション
├── Bus VisionTests/         # ユニットテスト
└── Bus VisionUITests/       # UIテスト
```

### 開発のポイント

1. **SwiftUI**: 現代的な UI 実装
2. **Combine**: リアクティブプログラミング
3. **ServiceManagement**: ログイン時自動起動
4. **URLSession**: 非同期データ取得
5. **正規表現**: HTML パースィング

## トラブルシューティング

### よくある問題

**Q: バス情報が表示されない**
A: インターネット接続を確認し、手動更新ボタンを試してください。

**Q: アプリが自動起動しない**
A: システム環境設定 > ユーザとグループ > ログイン項目を確認してください。

**Q: データの更新が遅い**
A: ネットワーク状況を確認し、必要に応じて手動更新を実行してください。

## 今後の計画

- [ ] **複数路線対応**: 他の路線の情報も表示
- [ ] **通知機能**: バス接近時のプッシュ通知
- [ ] **履歴機能**: 過去の運行データ表示
- [ ] **ウィジェット対応**: macOS 通知センターウィジェット
- [ ] **設定画面**: より詳細な設定オプション

## 貢献

プロジェクトへの貢献を歓迎します！

1. フォークを作成
2. フィーチャーブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m 'Add amazing feature'`)
4. ブランチにプッシュ (`git push origin feature/amazing-feature`)
5. プルリクエストを作成

## ライセンス

このプロジェクトは MIT ライセンスの下で公開されています。詳細は[LICENSE](LICENSE)ファイルを参照してください。

## 作者

**深谷悠喜** - 2025 年 6 月 6 日作成

---

<div align="center">
  <p>🚌 安全で快適な通学・通勤をサポート 🚌</p>
</div>
