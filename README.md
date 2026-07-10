# rules-builder —— 云端每日生成 mosdns 规则

用 GitHub Actions 每天在云端把 MetaCubeX / v2fly / Loyalsoldier 的源**下载并转换成 mosdns 原生格式**,
发布到本仓库 `release` 分支。各设备(RouterOS、axt1800、任何站点)只需 `/tool fetch` / `curl` 拉取,**零转换**。

产物(release 分支根目录):
`cn-domains.txt` `gfw.txt` `ai.txt` `stream.txt` `noncn.txt` `cn.cidr`

数据源与 axt1800 一致:MetaCubeX 主源(去 `+.`)+ v2fly 辅源;gfw 辅源 Loyalsoldier;cn.cidr 三源优先级(iwik→Loyalsoldier→gaoyifan,仅 IPv4)。任一类别全失败则**不发布**,设备继续用上一版。

## 一次性搭建

1. 新建一个 **public** GitHub 仓库(例如 `mosdns-rules`)。
2. 把本目录的 `build.sh` 与 `.github/workflows/build-mosdns-rules.yml` 放到该仓库**根目录**,push。
3. 仓库 Settings → Actions → General → Workflow permissions 选 **Read and write**。
4. Actions 页面手动运行一次 `build-mosdns-rules`(workflow_dispatch),生成 `release` 分支。
5. 之后每天 **北京时间 03:00**(UTC 19:00)自动构建;构建后自动刷新 jsdelivr 缓存。

## 拉取地址(jsdelivr 镜像,国内可直连)

```
https://testingcf.jsdelivr.net/gh/<USER>/<REPO>@release/cn-domains.txt
https://testingcf.jsdelivr.net/gh/<USER>/<REPO>@release/gfw.txt
https://testingcf.jsdelivr.net/gh/<USER>/<REPO>@release/ai.txt
https://testingcf.jsdelivr.net/gh/<USER>/<REPO>@release/stream.txt
https://testingcf.jsdelivr.net/gh/<USER>/<REPO>@release/noncn.txt
https://testingcf.jsdelivr.net/gh/<USER>/<REPO>@release/cn.cidr
```
（raw 直连:`https://raw.githubusercontent.com/<USER>/<REPO>/release/<file>`,需设备能直连 github）

## 接入设备

- **RouterOS**:用 `routeros/mosdns_update.rsc`,把顶部 `ghRepo` 改成 `<USER>/<REPO>`,设备侧 04:00 计划任务拉取 + 重启容器。
- **axt1800(可选统一)**:可把 `mosdns-rules-update.sh` 改成直接 fetch 这 6 个文件(免本地下载/转换);
  或保持现状(本地自转换,更独立,不依赖本仓库)。二选一。

## 时序

云端 03:00 构建 → 刷新 jsdelivr → 设备 04:00 拉取。留 1 小时余量,避开 Actions 排队延迟。
