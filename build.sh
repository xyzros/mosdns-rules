#!/usr/bin/env bash
# 在 GitHub Actions(ubuntu)上生成 mosdns 原生格式规则文件(供各设备直接 fetch,零转换)。
# 逻辑与 axt1800 的 mosdns-rules-update.sh 一致:MetaCubeX 主源 + v2fly/Loyalsoldier 辅源 + 格式转换。
# 产物写入 $1(默认 public):cn-domains.txt gfw.txt ai.txt stream.txt noncn.txt cn.cidr
# 任一类别所有源都失败则退出非 0 → 工作流不发布 → 设备继续用上一版(旧 release)。
set -uo pipefail
OUT="${1:-public}"; mkdir -p "$OUT"

META=https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite
V2=https://raw.githubusercontent.com/v2fly/domain-list-community/master/data
LOYAL=https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release
CIDR_SRCS="https://www.iwik.org/ipcountry/CN.cidr
https://raw.githubusercontent.com/Loyalsoldier/geoip/release/text/cn.txt
https://raw.githubusercontent.com/gaoyifan/china-operator-ip/ip-lists/china.txt"

conv_meta()  { sed -E 's/^\+\.//; /^[#!]/d; /^[[:space:]]*$/d'; }                                                   # MetaCubeX:去 "+."
conv_v2()    { sed -E '/^include:/d; s/[[:space:]]*#.*$//; s/[[:space:]]*@[^[:space:]]*//g; /^[#!]/d; /^[[:space:]]*$/d'; }  # v2fly:去 include/@属性
conv_loyal() { sed -E '/^[#!]/d; /^[[:space:]]*$/d'; }                                                              # Loyalsoldier:原生

dl() { curl -fsSL --connect-timeout 15 --max-time 180 --retry 3 --retry-delay 3 --retry-all-errors "$1"; }

fail=0
update_cat() {  # 输出文件 MetaCubeX名 辅源URL 辅源转换器 最少行数
	local out=$1 meta=$2 faburl=$3 fabconv=$4 min=$5 tmp; tmp=$(mktemp)
	if dl "$META/$meta.list" 2>/dev/null | conv_meta > "$tmp" && [ "$(wc -l <"$tmp")" -ge "$min" ]; then
		mv "$tmp" "$OUT/$out"; echo "$out <- MetaCubeX/$meta ($(wc -l <"$OUT/$out"))"; return 0
	fi
	if [ -n "$faburl" ] && dl "$faburl" 2>/dev/null | "$fabconv" > "$tmp" && [ "$(wc -l <"$tmp")" -ge "$min" ]; then
		mv "$tmp" "$OUT/$out"; echo "$out <- 辅源 ($(wc -l <"$OUT/$out"))"; return 0
	fi
	rm -f "$tmp"; echo "ERROR: $out 全部源失败" >&2; fail=1; return 1
}

#          输出文件        MetaCubeX               辅源URL                       辅源转换器  min
update_cat cn-domains.txt  cn                      "$V2/cn"                      conv_v2     10000
update_cat gfw.txt         gfw                     "$LOYAL/gfw.txt"              conv_loyal  1000
update_cat ai.txt          category-ai-!cn         "$V2/category-ai-!cn"         conv_v2     50
update_cat stream.txt      category-entertainment  "$V2/category-entertainment"  conv_v2     200
update_cat noncn.txt       geolocation-!cn         "$V2/geolocation-!cn"         conv_v2     5000

# cn.cidr(仅 IPv4,三源优先级)
cidr_ok=0
for u in $CIDR_SRCS; do
	if dl "$u" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$' > "$OUT/cn.cidr.tmp" && [ "$(wc -l <"$OUT/cn.cidr.tmp")" -ge 1000 ]; then
		mv "$OUT/cn.cidr.tmp" "$OUT/cn.cidr"; echo "cn.cidr <- $u ($(wc -l <"$OUT/cn.cidr"))"; cidr_ok=1; break
	fi
done
rm -f "$OUT/cn.cidr.tmp"
[ "$cidr_ok" = 1 ] || { echo "ERROR: cn.cidr 全部源失败" >&2; fail=1; }

echo "--- 产物 ---"; ls -l "$OUT"
exit $fail
