# Pinky作业打卡

面向家长和小朋友的作业打卡 App（Flutter，先发布 Android 版）。

## 功能

- **隐私声明**：首次打开展示隐私声明，同意后才能进入；不同意可退出。数据只保存在手机本地，不联网、无第三方 SDK。
- **多个小朋友**：可创建/编辑/删除小朋友（昵称、动物头像、喜欢的颜色），颜色会成为 App 主题色，点击顶部头像快速切换。
- **每日作业**：按日期（周视图）添加、编辑、删除作业，选择科目、常用作业一键填写、设置奖励星星数；左滑删除可撤销；勾选完成；空白日可一键复制上次作业。
- **激励体系**
  - ⭐ 星星：每完成一项获得 1~3 颗，当天全部完成额外 +3 颗
  - 🔥 连续打卡：当天作业全部完成即打卡成功，记录连续天数和最长连续
  - 🌱 成长小树：星星越多，小树从种子长成魔法森林（8 个等级）
  - 🏅 徽章墙：15 枚成就徽章（初次打卡、一周之星、百项达人、效率闪电侠……）
  - 📅 打卡日历：每月完美打卡日贴上星星
  - 🎁 奖励商店：家长自定义奖励，孩子用星星兑换，保留兑换记录
  - 🎉 彩带动画、鼓励语、全部完成/升级/获得徽章庆祝弹窗

## 开发

需要 Flutter 3.50+（stable）与 Android SDK。

```bash
flutter pub get
flutter test
flutter run                 # 连接真机或模拟器
flutter build apk --release # 输出 build/app/outputs/flutter-apk/app-release.apk
```

> 注意：发布到应用商店前需要在 `android/app/build.gradle.kts` 配置正式签名，并修改 `applicationId`。

## 目录

- `lib/models.dart` 数据模型
- `lib/stats.dart` 星星、连续打卡、等级、徽章计算
- `lib/store.dart` 状态与本地存储（shared_preferences）
- `lib/screens/` 页面：隐私、小朋友编辑、作业、成长、奖励、家长中心
- `lib/widgets/celebrate.dart` 彩带与庆祝弹窗
