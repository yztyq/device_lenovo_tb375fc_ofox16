#!/usr/bin/env bash
# Device-tree validator for TB375FC / OrangeFox fox_16.0.
# Pure static checks: no AOSP sync, runs in seconds, works on Linux CI and in
# Git-Bash on Windows.
set -u

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)
cd "$ROOT" || exit 2

FAIL=0
WARN=0
pass() { printf '  PASS  %s\n' "$1"; }
fail() { printf '  FAIL  %s\n' "$1"; FAIL=$((FAIL+1)); }
warn() { printf '  WARN  %s\n' "$1"; WARN=$((WARN+1)); }
sect() { printf '\n== %s ==\n' "$1"; }

need_file() {
  if [ -f "$1" ]; then pass "exists: $1"; else fail "missing: $1"; fi
}
has_var() { # file var expected_regex
  if grep -Eq "^[[:space:]]*$2[[:space:]]*:?=" "$1" 2>/dev/null; then
    if grep -Eq "$3" "$1" 2>/dev/null; then pass "$2 = $3"; else fail "$2 does not match $3"; fi
  else
    fail "$2 not found in $1"
  fi
}
has_flag() { # file token
  if grep -q -- "$2" "$1" 2>/dev/null; then pass "flag $2 in $1"; else fail "flag $2 missing in $1"; fi
}

# config files only; never scan this script or the docs, otherwise the check
# strings in here trip their own checks.
CFGS=$(find . -type f \( -name '*.mk' -o -name '*.prop' -o -name '*.yml' \) \
        -not -path './.git/*' -not -path './scripts/*')
SHCFG="./vendorsetup.sh"

sect "required files"
for f in \
  BoardConfig.mk device.mk AndroidProducts.mk twrp_tb375fc.mk \
  vendorsetup.sh system.prop README.md \
  prebuilt/dtb \
  prebuilt/dtb_dir/tb375fc.dtb \
  prebuilt/platform_ramdisk.lz4 \
  scripts/splice_platform.py \
  recovery/root/system/etc/recovery.fstab \
  recovery/root/system/etc/twrp.flags \
  recovery/root/init.recovery.mt8792.rc \
  recovery/root/init.recovery.microtrust.rc \
  .github/workflows/build.yml .github/workflows/validate.yml
do
  need_file "$f"
done

sect "boot image geometry (must equal the stock vendor_boot header)"
has_var BoardConfig.mk TARGET_NO_KERNEL 'true'
has_var BoardConfig.mk BOARD_BOOT_HEADER_VERSION '4'
has_var BoardConfig.mk BOARD_KERNEL_PAGESIZE '4096'
has_var BoardConfig.mk BOARD_HEADER_SIZE '2128'
has_var BoardConfig.mk BOARD_KERNEL_BASE '0x3fff8000'
has_var BoardConfig.mk BOARD_RAMDISK_OFFSET '0x26f08000'
has_var BoardConfig.mk BOARD_TAGS_OFFSET '0x07c88000'
has_var BoardConfig.mk BOARD_DTB_OFFSET '0x07c88000'
has_var BoardConfig.mk BOARD_DTB_SIZE '411876'
has_var BoardConfig.mk BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE '67108864'
has_var BoardConfig.mk BOARD_KERNEL_CMDLINE 'bootopt=64S3,32N2,64N2'
has_var BoardConfig.mk BOARD_RAMDISK_USE_LZ4 'true'
has_var BoardConfig.mk BOARD_PREBUILT_DTBIMAGE_DIR 'prebuilt/dtb_dir'
# 2026-11-26：vendor_boot 必须是「两片」才进得了 recovery（device 上唯一验证过
# 的结构）。AOSP 16 只接受 MOVE + INCLUDE 同时为 true：只开 INCLUDE 会在 lunch 阶段
# 被 board_config.mk:1069-1074 直接 $(error)（CI run 45793799376 就是这么死的），
# 只开 MOVE 则是单流（recovery 资源并进默认 vendor ramdisk，platform 片退化成 4 字节）。
if grep -Eq '^[[:space:]]*BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT[[:space:]]*:?=[[:space:]]*true' BoardConfig.mk; then
  pass "BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT = true（两片结构）"
else
  fail "BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT must be true (two-fragment vendor_boot)"
fi
if grep -Eq '^[[:space:]]*BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT[[:space:]]*:?=[[:space:]]*true' BoardConfig.mk; then
  pass "BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT = true（INCLUDE 的成对条件）"
else
  fail "BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT must be true, INCLUDE is rejected by board_config.mk without it"
fi
if grep -Eq '^[[:space:]]*TARGET_NO_RECOVERY[[:space:]]*:?=[[:space:]]*true' BoardConfig.mk; then
  fail "TARGET_NO_RECOVERY must be off (it drops the recovery fragment entirely)"
else
  pass "TARGET_NO_RECOVERY off"
fi
# AOSP 没有 BOARD_PREBUILT_PLATFORM_RAMDISK 这个变量；写了也不会生效，只会误导。
if grep -Eq '^[[:space:]]*BOARD_PREBUILT_PLATFORM_RAMDISK[[:space:]]*:?=' BoardConfig.mk; then
  fail "BOARD_PREBUILT_PLATFORM_RAMDISK is not an AOSP variable - remove it (splice script does the platform fragment)"
else
  pass "no bogus BOARD_PREBUILT_PLATFORM_RAMDISK"
fi
for v in BOARD_AVB_ENABLE BOARD_AVB_ALGORITHM BOARD_AVB_KEY_PATH BOARD_AVB_VENDOR_BOOT_KEY_PATH BOARD_AVB_VENDOR_BOOT_ALGORITHM BOARD_AVB_VENDOR_BOOT_ROLLBACK_INDEX BOARD_AVB_VENDOR_BOOT_ROLLBACK_INDEX_LOCATION BOARD_AVB_VENDOR_BOOTIMAGE_KEY_PATH; do
  if grep -Eq "^[[:space:]]*$v[[:space:]]*:?=" BoardConfig.mk; then pass "$v set"; else fail "$v missing (avbtool would run with no --algorithm/--key)"; fi
done

sect "dtb size matches BOARD_DTB_SIZE"
DTB=$(stat -c%s prebuilt/dtb 2>/dev/null || echo 0)
if [ "$DTB" = "411876" ]; then pass "prebuilt/dtb = $DTB bytes"; else fail "prebuilt/dtb = $DTB, expected 411876"; fi

sect "crypto / FBE"
has_var BoardConfig.mk TW_INCLUDE_CRYPTO 'true'
has_var BoardConfig.mk TW_INCLUDE_CRYPTO_FBE 'true'
has_var BoardConfig.mk TW_INCLUDE_FBE_METADATA_DECRYPT 'true'
has_var BoardConfig.mk TW_USE_FSCRYPT_POLICY '2'
has_var BoardConfig.mk BOARD_USES_METADATA_PARTITION 'true'
has_var BoardConfig.mk TW_SKIP_ADDITIONAL_FSTAB 'true'
has_var BoardConfig.mk TW_INCLUDE_EROFS 'true'

sect "real security patch, no faked values"
has_var BoardConfig.mk PLATFORM_SECURITY_PATCH '2025-09-05'
has_var BoardConfig.mk PLATFORM_VERSION '15'
PLACEHOLDER=0
for f in $CFGS $SHCFG; do
  grep -q '2099' "$f" 2>/dev/null && { warn "2099 placeholder in $f"; PLACEHOLDER=1; }
done
[ "$PLACEHOLDER" = "0" ] && pass "no 2099 placeholder in config files"
PLACEHOLDER2=0
for f in $CFGS $SHCFG; do
  grep -q '99\.87\.36' "$f" 2>/dev/null && { warn "99.87.36 placeholder in $f"; PLACEHOLDER2=1; }
done
[ "$PLACEHOLDER2" = "0" ] && pass "no 99.87.36 placeholder in config files"
if for f in $CFGS; do grep -qi 'disable-verity\|verifyoff' "$f" 2>/dev/null && echo "$f"; done | grep -q .; then
  fail "a config file mentions disabling verify"
else
  pass "no verify-disabling config"
fi

sect "hardware naming (ro.hardware=mt8792, SoC=mt6897)"
if [ -f recovery/root/init.recovery.mt8792.rc ]; then pass "init.recovery.mt8792.rc present"; else fail "init.recovery.mt8792.rc missing"; fi
if [ -f recovery/root/init.recovery.mt6897.rc ]; then fail "stale init.recovery.mt6897.rc must be renamed to mt8792"; else pass "no mt6897 rc file"; fi
if [ -s recovery/root/init.recovery.mt8792.rc ]; then pass "rc is non-empty"; else fail "rc is empty"; fi
if grep -q 'on init' recovery/root/init.recovery.mt8792.rc 2>/dev/null; then pass "rc has an 'on init' trigger"; else warn "rc has no 'on init' trigger"; fi
has_var twrp_tb375fc.mk ro.hardware 'mt8792'
has_var twrp_tb375fc.mk ro.board.platform 'mt6897'
grep -q 'PRODUCT_NAME := twrp_tb375fc' twrp_tb375fc.mk && pass "PRODUCT_NAME is twrp_tb375fc" || fail "PRODUCT_NAME mismatch"
grep -q 'twrp_tb375fc.mk' AndroidProducts.mk && pass "AndroidProducts.mk references the product" || fail "AndroidProducts.mk does not reference twrp_tb375fc.mk"
has_var BoardConfig.mk TW_EXCLUDE_TWRPAPP 'true'

sect "recovery.fstab"
FST=recovery/root/system/etc/recovery.fstab
BODY=$(grep -v '^#' "$FST" 2>/dev/null)
COUNT_DATA=$(printf '%s\n' "$BODY" | grep -cE '^\S+[[:space:]]+/data[[:space:]]')
[ "$COUNT_DATA" = "1" ] && pass "/data declared exactly once" || fail "/data declared $COUNT_DATA times (must be exactly 1)"
printf '%s\n' "$BODY" | grep -qE '^/dev/block/by-name/userdata[[:space:]]+/data' && pass "/data -> by-name/userdata" || fail "/data not mapped to by-name/userdata"
printf '%s\n' "$BODY" | grep -qE '^\S+[[:space:]]+/metadata[[:space:]]' && pass "/metadata present" || fail "/metadata missing"
printf '%s\n' "$BODY" | grep -qE '^\S+[[:space:]]+/mnt/vendor/persist[[:space:]]' \
  && pass "persist mounted in fstab" \
  || { grep -qE '^/persist_image[[:space:]]' recovery/root/system/etc/twrp.flags 2>/dev/null \
        && pass "persist exposed through twrp.flags as /persist_image (stock fstab has no /persist mount)" \
        || fail "persist neither mounted in fstab nor exposed in twrp.flags"; }
printf '%s\n' "$BODY" | grep -q 'fileencryption=' && pass "fileencryption flag preserved" || fail "fileencryption flag stripped"
printf '%s\n' "$BODY" | grep -q 'aes-256-xts:aes-256-cts:v2' && pass "FBE v2 cipher set present" || fail "FBE v2 cipher set missing"
printf '%s\n' "$BODY" | grep -q 'keydirectory=/metadata/vold/metadata_encryption' && pass "metadata keydirectory present" || fail "metadata keydirectory missing"
printf '%s\n' "$BODY" | grep -q 'avb' && fail "avb token still present in fstab body" || pass "no avb token in fstab body"
# 这份 fstab 是可用 recovery ramdisk 里的原件（LineageOS fstab.mt6897 派生），
# logical 分区必须带 first_stage_mount，这里改为“必须有”，不再是“不许有”。
printf '%s\n' "$BODY" | grep -qE 'system[[:space:]]+/system[[:space:]]+erofs.*logical,first_stage_mount' \
  && pass "logical partitions carry logical,first_stage_mount" \
  || fail "logical,first_stage_mount missing from the system line"
printf '%s\n' "$BODY" | grep -q 'slotselect_keys' && fail "corrupted slotselect_keys token present (bad regex substitution)" || pass "no corrupted slotselect_keys token"
printf '%s\n' "$BODY" | grep -q 'dm-userdata' && fail "duplicate dm-userdata /data entry present" || pass "no dm-userdata duplicate"

sect "twrp.flags (partition manager / flash targets)"
FLAGS=recovery/root/system/etc/twrp.flags
need_file "$FLAGS"
for p in '/vendor_boot' '/boot' '/init_boot' '/dtbo' '/vbmeta' '/persist_image' '/usb_otg' '/external_sd'; do
  if grep -qE "^[[:space:]]*$p[[:space:]]" "$FLAGS" 2>/dev/null; then pass "twrp.flags has $p"; else fail "twrp.flags missing $p"; fi
done
grep -qE '^/vendor_boot[[:space:]]+emmc[[:space:]]+/dev/block/by-name/vendor_boot' "$FLAGS" \
  && pass "/vendor_boot points at by-name/vendor_boot" || fail "/vendor_boot device path wrong"
if grep -qE '^/vendor_boot[[:space:]].*flashimg=1' "$FLAGS"; then pass "/vendor_boot is flashable"; else fail "/vendor_boot not flashable (no flashimg=1)"; fi

sect "platform fragment (官方 vendor_boot 原片)"
PLAT=prebuilt/platform_ramdisk.lz4
if [ -f "$PLAT" ]; then
  PLAT_BYTES=$(stat -c%s "$PLAT" 2>/dev/null || echo 0)
  if [ "$PLAT_BYTES" = "25863198" ]; then
    pass "platform_ramdisk.lz4 = $PLAT_BYTES bytes (与官方 vendor_boot 一致)"
  else
    fail "platform_ramdisk.lz4 = $PLAT_BYTES bytes, expected 25,863,198"
  fi
  # 官方 platform 片是 lz4 legacy frame，magic 0x184C2102
  MAGIC=$(od -An -tx1 -N4 "$PLAT" 2>/dev/null | tr -d ' \n')
  if [ "$MAGIC" = "02214c18" ]; then pass "platform fragment starts with lz4 legacy magic"; else fail "platform fragment magic = $MAGIC, expected 02214c18"; fi
else
  PLAT_BYTES=0
fi
"${PYTHON:-python3}" -c "import zstandard" 2>/dev/null \
  && pass "python zstandard available (splice_platform.py can encode 0000+zstd)" \
  || warn "python zstandard missing: CI installs it, local builds need pip install zstandard"
if [ -d recovery/root/lib/modules ] && [ -n "$(ls -A recovery/root/lib/modules 2>/dev/null)" ]; then
  fail "recovery/root/lib/modules must stay empty: modules come from the platform fragment"
else
  pass "no duplicated modules inside recovery root"
fi

sect "64 MiB budget"
if [ "${PLAT_BYTES:-0}" -gt 0 ]; then
  # 可用包实测：platform 25,863,198 + recovery 30,573,748 = vrs 56,436,946 B
  EST=$(( PLAT_BYTES + 30573748 ))
  LIMIT=67108864
  if [ "$EST" -lt "$LIMIT" ]; then
    pass "estimated vrs $EST B < $LIMIT B (余量 $((LIMIT - EST)) B)"
  else
    fail "estimated vrs $EST B >= $LIMIT B"
  fi
  if [ $(( LIMIT - EST )) -lt $((4*1048576)) ]; then warn "head-room under 4 MiB"; fi
fi

sect "shell syntax"
if command -v bash >/dev/null 2>&1; then
  bash -n vendorsetup.sh 2>/dev/null && pass "vendorsetup.sh syntax" || fail "vendorsetup.sh syntax error"
  bash -n scripts/validate.sh 2>/dev/null && pass "validate.sh syntax" || fail "validate.sh syntax error"
else
  warn "bash not available, skipped shell syntax"
fi

sect "workflow sanity"
for w in .github/workflows/build.yml .github/workflows/validate.yml; do
  grep -q 'runs-on:' "$w" 2>/dev/null && pass "$w has runs-on" || fail "$w has no runs-on"
  grep -q 'actions/checkout@v4' "$w" 2>/dev/null && pass "$w checks out the tree" || fail "$w missing checkout"
done
grep -q 'mka vendorbootimage' .github/workflows/build.yml && pass "build.yml builds vendorbootimage" || fail "build.yml does not build vendorbootimage"
grep -q 'TS=$(date -u +%Y%m%d_%H%M%S)' .github/workflows/build.yml && pass "build.yml stamps artifacts with UTC time" || fail "build.yml has no timestamp stamping"
grep -q '_tb375fc_${TS}_${SHA7}.img' .github/workflows/build.yml && pass "artifact name pattern includes time + sha" || fail "artifact name pattern missing"
grep -q 'validate.sh' .github/workflows/validate.yml && pass "validate workflow runs the script" || fail "validate workflow does not run the script"
# 产物要能直接下载：Release 发布 + contents: write 必须成对，缺一个就会 403。
grep -q 'softprops/action-gh-release' .github/workflows/build.yml && pass "build.yml publishes a release" || fail "build.yml does not publish a release"
grep -q 'contents: write' .github/workflows/build.yml && pass "build.yml grants contents: write" || fail "release needs 'permissions: contents: write'"

sect "fox build variables"
has_flag vendorsetup.sh FOX_VENDOR_BOOT_RECOVERY
has_flag vendorsetup.sh FOX_AB_DEVICE
has_flag vendorsetup.sh FOX_VIRTUAL_AB_DEVICE
has_var BoardConfig.mk OF_LANDSCAPE_MODE '1'
has_var BoardConfig.mk OF_SCREEN_H '2304'
has_var BoardConfig.mk TW_NO_HAPTICS 'true'

sect "summary"
printf 'FAIL=%d  WARN=%d\n' "$FAIL" "$WARN"
if [ "$FAIL" -gt 0 ]; then
  printf 'RESULT: FAILED\n'
  exit 1
fi
printf 'RESULT: OK\n'
exit 0
