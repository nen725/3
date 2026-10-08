# 三角洲特勤处助手

一个用于「三角洲行动」特勤处制造提醒的 iOS / iPadOS App，苹果原生 SwiftUI 风格。

## 功能

- 单条制造倒计时：选一个物品（自动带出时长）或自定义时长，到点弹系统通知提醒。
- 通知带三个按钮：完成、完成并重新开始、稍后提醒。
- 完成历史：记录每次完成的物品和时间，并统计次数。
- 多账号：自由增删、命名、切换。
- 每个账号可手动记录任意货币（如哈夫币、三角卷、三角币），数量用 k / m 显示；输入时也支持 `1.2m`、`350k` 这类写法。
- 每个账号单独记录出租日期、出租时哈夫币数量、出租收入。
- 数据备份：一键把全部数据导出成文件（可存到「文件」或隔空投送），也能从备份文件恢复，重装、换机都不怕丢数据。
- 收益查询：可配置一个网页入口（在 App 内用系统网页弹层打开）和一个 API 入口。
- 一键跳转三角洲行动 App（可配置 URL Scheme，失败自动回退 App Store 链接）。
- 最低 iOS 26，中文界面，iPhone 竖屏、iPad 横屏均适配。

## 目录结构

```
DeltaCraft/
├── project.yml                 # XcodeGen 工程配置
├── .github/workflows/build.yml # GitHub Actions 云端构建脚本
├── DeltaCraft/                 # 全部 Swift 源码
│   ├── App/
│   ├── Models/
│   ├── Support/
│   └── Views/
└── README.md
```

## 怎么得到一个可安装的 App

因为 iOS 的 App 必须在 macOS 上编译，而你没有 Mac，所以走 GitHub Actions 云端构建，产出一个未签名的 `.ipa`，你再自己签名安装。

### 第一步：上传到 GitHub

1. 注册并登录 [GitHub](https://github.com)。
2. 新建一个仓库（Repository），名字随意，比如 `DeltaCraft`，选择 **Private（私有）** 即可。
3. 把本目录里的所有文件和文件夹原样上传到仓库根目录（直接拖拽上传，或按 GitHub 网页提示操作）。注意要保留 `.github` 这个隐藏文件夹。

### 第二步：触发云端构建

1. 在仓库页面点顶部 **Actions** 标签。
2. 左侧找到 **Build unsigned IPA** 这个工作流。
3. 点右侧 **Run workflow** 按钮，再点一次确认，等待运行。
4. 构建完成后，进到这个运行记录里，最下方 **Artifacts** 会有一个 `DeltaCraft-unsigned`，下载它并解压，得到 `DeltaCraft.ipa`。

### 第三步：签名并安装到设备

用你习惯的侧载工具，把 `DeltaCraft.ipa` 安装到 iPhone / iPad。常用工具（任选其一）：

- 爱思助手（Windows，个人签名）
- AltStore / SideStore
- Sideloadly

这些工具会用你的免费 Apple ID 给 App 签名并安装。安装后到「设置 → 通用 → VPN 与设备管理」里信任这个描述文件即可使用。

## 几个注意事项

- **免费 Apple ID 签名的 App 只有 7 天有效期**，到期需要在侧载工具里重新签名一次。这是苹果的限制，和本 App 无关。
- 如果安装时提示 Bundle ID 冲突，把 `project.yml` 里的 `com.deltacraft.app` 改成一个更独特的名字（比如 `com.你的名字.deltacraft`），重新构建即可。
- 「跳转三角洲行动」默认会打开 App Store 搜索页；如果你知道它的 URL Scheme，填进「设置」里就能直接拉起 App。
- 收益查询的网页和 API 地址在「收益」页里自行填写并保存。
- 跨设备同步本版未开启，数据只存在当前设备本地；数据层的同步接口已经预留好，以后可以接入 iCloud 或云端。

## 常见问题

**构建失败了怎么办？** 打开那次失败的 Actions 运行记录，把红色的错误日志发给我，我来修。

**想改 App 名字？** 改 `DeltaCraft/Info.plist` 里的 `CFBundleDisplayName`（当前是「特勤处助手」），重新构建。
# 3
