# OrangeFox R12 — Lenovo Xiaoxin Pad Pro 12.7 2025 (TB375FC)

`vendor_boot` 式 recovery（设备没有独立 recovery 分区）。分支 `fox_16.0`。

这个仓库是**从官方 ZUXOS 1.1.04.287 的 vendor_boot 逆向出来重新写的**，没有复用任何现成移植树的配置文本。二进制只有两样来自官方包：`prebuilt/dtb`（411,876 B）和 `prebuilt/platform_ramdisk.lz4`（25,863,198 B，官方 platform 分片原样搬运）。

> **2026-11-26 修订**：本仓库原先把 TWRP 资源放进 vendor ramdisk（`BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true` 加 `TARGET_NO_RECOVERY := true`），编出来的包 platform 分片只有 4 字节、recovery 分片退化成 AOSP recovery，实刷必然进不了 recovery。这一版全部按“已实测能进 recovery 的官方 platform 包”对齐，改动清单见附录 A。

---

## 一、本机的真实参数（全部实测，不是抄来的）

| 项目 | 值 | 来源 |
|---|---|---|
| SoC | MT6897（天玑 8300） | `ro.board.platform=mt6897` |
| `ro.hardware` | **`mt8792`** | `ro.boot.hardware=mt8792` |
| 系统 | **Android 15**，ZUXOS 1.1.04.287 | `ro.build.version.release=15` |
| 安全补丁 | system `2025-09-05` / vendor `2024-10-05` | `ro.build.version.security_patch` |
| 加密 | `encrypted` / `file` 表示只有 FBE，没有 FDE | `ro.crypto.state` / `ro.crypto.type` |
| 分区 | 无独立 recovery，recovery 在 `vendor_boot` 的 fragment 里 | by-name 列表 |
| `vendor_boot_a` | `0x4000000` = 64 MiB | `fastboot getvar partition-size` |
| header | v4 / page 4096 / hdr_size 2128 | 官方镜像头 |
| kernel / ramdisk addr | `0x40000000` / `0x66f00000` | 官方镜像头 |
| tags / dtb addr | `0x47c80000` | 官方镜像头 |
| dtb_size | 411,876 | 官方镜像头 |
| cmdline | `bootopt=64S3,32N2,64N2` | 官方镜像头 |
| system / vendor | **logical（super 里的 dynamic partition）** | 官方 fstab 带 `logical` |
| `/data` | `/dev/block/by-name/userdata` f2fs | 官方 fstab |
| 加密参数 | `fileencryption=aes-256-xts:aes-256-cts:v2+inlinecrypt_optimized`，`keydirectory=/metadata/vold/metadata_encryption` | 官方 fstab |
| `/metadata` | 独立分区 `/dev/block/by-name/metadata` | 官方 fstab |
| `persist` | 正常挂载在 `/mnt/vendor/persist` | 官方 fstab |

---

## 二、这个仓库刻意修掉的三处错误

现成的 TB375FC 移植树（`etnperlong/orangefox_device_lenovo_TB375FC`）里有三处写法在这台机器的官方系统上必然失败，本仓库全部改掉：

1. **挂载 `/dev/block/by-name/system` 和 `/dev/block/by-name/vendor`**  
   本机 by-name 下只有 `super`，system/vendor 是 logical 分区，这两个节点不存在，挂载必败，后续“读 ROM build.prop 再 resetprop”整条链断掉。  
   本仓库不使用这条路径；解密所需属性由 recovery 侧按 fstab 已挂载的路径读取。

2. **`init.recovery.mt6897.rc`**  
   init 按 `init.recovery.${ro.hardware}.rc` 找文件，本机 `ro.hardware=mt8792`，所以文件名必须是 **`init.recovery.mt8792.rc`**。

3. **不挂 persist**  
   官方 fstab 明确挂载 `persist`（TEE 的 REE-FS 存储）。本仓库跟随官方，在 fstab 与 `init.recovery.mt8792.rc` 里都保留。

另外两条纪律：

- **不伪造安全补丁**。`PLATFORM_SECURITY_PATCH` 用真实值 `2025-09-05`，不用 `2099-31` 之类占位符。KeyMint 的密钥 blob 绑定真实版本号，伪造会让解密永远失败。
- **不做“关闭 AVB 校验”的 vbmeta**。只产出 `vendor_boot.img`，它必须能通过现有链校验。

> **AVB 备注（2026-11-26）**：设备实测能进 recovery 的那个包**没有 AVB footer**（末尾没有 `AVBf` 结构），`ro.boot.verifiedbootstate=orange` 也印证 bootloader 处于解锁容忍状态。本树现在给 vendor_boot 加了 AOSP test key 的 footer，如果新包刷进去出现“进 recovery 又退回系统”，第一件事是把 `BOARD_AVB_ENABLE` 关掉或让 vendor_boot 不落 footer，再对比。

---

## 三、vendor_boot 的两片结构（理解本仓库的前提）

本机 `vendor_boot` 是 AOSP v4 格式，`vendor_ramdisk` 里放**两个分片**；分片表在 dtb 之后一个 page 起始处，长度、数量、条目大小写在头部 2112 / 2116 / 2120，条目 108 字节、无表头。

| # | 类型 | 内容 | 说明 |
|---|---|---|---|
| 0 | `type=1` platform | `first_stage_ramdisk/` 加 `lib/modules/`（222 个 6.1.138 `.ko`） | **只能来自官方 vendor_boot**，本树编不出来 |
| 1 | `type=2` recovery | TWRP/OrangeFox 根文件系统（`twres`、`FFiles`、`sbin`、`system/bin/twrp` …） | 本树产出，编码为 `0000+zstd` |

两片相加必须不超过 64 MiB。实测可用包：platform 25,863,198 + recovery 30,573,748 = vrs 56,436,946 B。

---

## 四、目录

```
BoardConfig.mk                       镜像几何、分区、crypto、UI、AB
device.mk                            故意留空（recovery/root 自动打包）
AndroidProducts.mk                   lunch 入口
twrp_tb375fc.mk                      产品定义
vendorsetup.sh                       FOX_* 环境变量
system.prop                          TWRP 目标设备标识
prebuilt/dtb                         官方 dtb，411,876 B
prebuilt/platform_ramdisk.lz4        官方 platform 分片，25,863,198 B（type=1）
scripts/splice_platform.py           把官方 platform 分片拼进 OF 编出的 vendor_boot
recovery/root/init.recovery.mt8792.rc        完整 USB gadget / keyring / pstore（4,445 B）
recovery/root/init.recovery.microtrust.rc    TEE 相关（3,064 B）
recovery/root/system/etc/recovery.fstab      2,827 B，logical,first_stage_mount,check
recovery/root/system/etc/twrp.flags           3,929 B，设备专属分区表（usb_otg / external_sd / boot / …）
recovery/root/system/bin/tb373fu_usb_storage.sh   U 盘挂载
recovery/root/system/bin/tb373fu_wait_tee.sh      TEE 等待
recovery/root/system/bin/tb373fu_prepare_multiboot.sh
recovery/root/vendor/                teei_daemon、keymint/gatekeeper(beanpod)、lib64、novatek 触摸固件、thh TA（53 文件 / 13.3 MB）
vendor_fbe.zip                       解密相关附加包（保留资产）
.github/workflows/build.yml          CI：fox_16.0 — mka vendorbootimage — 拼接
```

**recovery 分片里不再放 `lib/modules`**：222 个模块由 platform 分片提供，文件名、大小、vermagic 已逐一对齐；塞进 recovery 只会让该片从约 30 MB 涨到约 45 MB，64 MiB 装不下。

---

## 五、构建

### 本地

```sh
repo init --depth=1 -u https://gitlab.com/OrangeFox/Manifest.git -b fox_16.0
repo sync -c -j8 --force-sync --no-clone-bundle --no-tags
cp -a 本仓库目录 device/lenovo/tb375fc
source build/envsetup.sh
. device/lenovo/tb375fc/vendorsetup.sh
lunch twrp_tb375fc-bp2a-eng
mka vendorbootimage

# 必须做：把官方 platform 分片拼回去
python3 device/lenovo/tb375fc/scripts/splice_platform.py \
    --input out/target/product/tb375fc/vendor_boot.img \
    --platform device/lenovo/tb375fc/prebuilt/platform_ramdisk.lz4 \
    --output vendor_boot_TWRP_64MB.img
```

`mka vendorbootimage` 单独产出的 `vendor_boot.img` **不能直接刷**，它的 platform 分片是空的。必须过一遍 `splice_platform.py`，它做三件事：塞入官方 platform、把 recovery 分片重编码成 `0000+zstd`、按 v4 规则重写分片表（platform `type=1`、recovery `type=2`）。

### CI

推送后手动触发 `Build OrangeFox TB375FC`，artifact 里直接给 `vendor_boot_TWRP_64MB.img`（已拼接）。

> `fox_16.0` 全量 `repo sync` 约 85 GB，GitHub 托管 runner 磁盘可能不够。`Repo sync` 报 `No space left on device` 是磁盘问题，不是配置问题。

---

## 六、刷写与回滚

```sh
# 刷入（约 205 s，USB 慢是正常的）
fastboot flash vendor_boot_a vendor_boot_TWRP_64MB.img
fastboot reboot recovery

# 回滚（官方件，务必先确认路径存在）
fastboot flash vendor_boot_a "F:\YX\TB375FC_ZUX_1.1.04.287_Tool\image\vendor_boot.img"
fastboot reboot
```

设备不支持 `fastboot fetch`，无法从设备备份 `vendor_boot`，回滚只能靠本地官方件。**刷之前先确认官方 `vendor_boot.img` 在位**（67,108,864 B，MD5 `E60D9F853E08CDE9D099EA1143D760F8`）。

进 bootloader：关机后按住【音量下 + 电源】约 10 秒。

---

## 七、已知风险

- 解密链路（TEE / KeyMint）要在 ROM 侧挂载成功之后才有意义；先把“稳定进界面、能挂 `/data` `/metadata` `/persist`”做实。
- recovery 分片的压缩方式（lz4 / gzip / zstd）与分片类型位都影响 bootloader 解析。可用包已证明 `0000+zstd` 加 `type=2` 这条路径可行，不要随意换。
- `recovery/root/vendor/` 里的 TA 与 keymint 库取自可用包的 recovery ramdisk（原始构建产物），换 ROM 版本时需要重新取。

---

## 附录 A：2026-11-26 修订清单（按“能进 recovery 的可用包”逐项对齐）

### BoardConfig.mk

| 原 | 改为 | 原因 |
|---|---|---|
| `BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true` | 注释掉 | 打开后 twres / FFiles / sbin 被塞进 vendor ramdisk，而该目录并不生成（`mkbootfs: cannot open directory`），platform 只剩 4 B，recovery 分片退化成 AOSP recovery |
| `TARGET_NO_RECOVERY := true` | 注释掉 | 直接导致 recovery 分片不生成 |
| `TW_LOAD_VENDOR_BOOT_MODULES := true` | 删除 | 非标准变量（标准是 `TW_LOAD_VENDOR_MODULES`），且文件底部已有一份 |
| `BOARD_PAGE_SIZE := 4096` / `BOARD_HEADER_SIZE := 2128` | `BOARD_KERNEL_PAGESIZE := 4096` | `mkbootimg` 只认 `BOARD_KERNEL_PAGESIZE`，另两个是无效变量，header_size 由工具自算 |
| （无） | 新增 `BOARD_PREBUILT_PLATFORM_RAMDISK` | 指向 `prebuilt/platform_ramdisk.lz4` |

`BOARD_KERNEL_BASE 0x3fff8000` 及各 offset、`BOARD_DTB_SIZE 411876`、`BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE 67108864`、`BOARD_BOOT_HEADER_VERSION 4`、cmdline 原本就是对的，未动。

### recovery/root

| 文件 | 原状态 | 现状 |
|---|---|---|
| `system/etc/recovery.fstab` | 5,951 B，用 `slotselect_keys=/avb/q-gsi.avbpubkey:...` 这类**非法 fs_mgr flag** | 2,827 B，`wait,slotselect,logical,first_stage_mount`，与可用包一致 |
| `init.recovery.mt8792.rc` | 1,065 B 极简版，没有 USB gadget | 4,445 B 完整版：`11201000.usb0`、ffs mtp/adb/fastboot、`sys.usb.ffs.mtp.ready`、idProduct 0x4EE2 / 0xD001 / 0x4EE0、`install_keyring`、pstore、dvfsrc |
| `init.recovery.microtrust.rc` | 缺失 | 补入（3,064 B） |
| `system/bin/tb373fu_*.sh` 三个 | 缺失 | 补入（1,869 / 1,903 / 594 B） |
| `system/etc/twrp.flags` | 缺失 | 补入（3,929 B），含 `/usb_otg`、`/external_sd` 与 boot / init_boot / vendor_boot / dtbo / vbmeta 的 slotselect、backup、flashimg |
| `vendor/`（53 文件 / 13.3 MB） | 缺失 | 补入 `teei_daemon`、`gatekeeper` / `keymint`（beanpod）、`lib64`（keymaster_portable / libkeymint / rkp / secureclock …）、`firmware/novatek_ts_fw_*.bin`、`thh/ta/*.ta` |
| `lib/modules/`（227 文件，27.2 MB） | 在库内 | 删除（platform 分片已提供同名、同大小、同 vermagic 的模块） |

### 构建

- 新增 `scripts/splice_platform.py`：lz4 / gzip / zstd 解码，`0000+zstd` 编码，v4 分片表重写，64 MiB 对齐，超容量时报警。
- `build.yml`：增加 `Splice official platform ramdisk` 步骤和 `pip3 install zstandard`，artifact 直接产出可刷的 `vendor_boot_TWRP_64MB.img`。
