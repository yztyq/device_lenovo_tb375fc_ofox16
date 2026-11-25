# OrangeFox R12 — Lenovo Xiaoxin Pad Pro 12.7 2025 (TB375FC)

`vendor_boot` 式 recovery（设备没有独立 recovery 分区）。分支 `fox_16.0`。

这个仓库是**从官方 ZUXOS 1.1.04.287 的 vendor_boot 逆向出来重新写的**，没有复用任何现成移植树的配置文本。二进制只有两样来自官方包：`prebuilt/dtb`（411,876 B）和 `recovery/root/lib/modules`（222 个 `.ko`）。

---

## 一、本机的真实参数（全部实测，不是抄来的）

| 项目 | 值 | 来源 |
|---|---|---|
| SoC | MT6897（天玑 8300） | `ro.board.platform=mt6897` |
| `ro.hardware` | **`mt8792`** | `ro.boot.hardware=mt8792` |
| 系统 | **Android 15**，ZUXOS 1.1.04.287 | `ro.build.version.release=15` |
| 安全补丁 | system `2025-09-05` / vendor `2024-10-05` | `ro.build.version.security_patch` |
| 加密 | `encrypted` / `file` → **只有 FBE，没有 FDE** | `ro.crypto.state` / `ro.crypto.type` |
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
| `persist` | **正常挂载在 `/mnt/vendor/persist`** | 官方 fstab |

---

## 二、这个仓库刻意修掉的三处错误

现成的 TB375FC 移植树（`etnperlong/orangefox_device_lenovo_TB375FC`）里有三处写法在**这台机器的官方系统上必然失败**，本仓库全部改掉：

1. **挂载 `/dev/block/by-name/system` 和 `/dev/block/by-name/vendor`**  
   本机 by-name 下只有 `super`，system/vendor 是 logical 分区 → 这两个节点不存在，挂载必败 → 后续“读 ROM build.prop → resetprop”整条链断掉。  
   本仓库不使用这条路径；解密所需的属性由 recovery 侧按 fstab 已挂载的路径读取。

2. **`init.recovery.mt6897.rc`**  
   init 按 `init.recovery.${ro.hardware}.rc` 找文件，本机 `ro.hardware=mt8792`，所以文件名必须是 **`init.recovery.mt8792.rc`**。

3. **不挂 persist**  
   官方 fstab 明确挂载 `persist`（TEE 的 REE-FS 存储）。本仓库跟随官方，在 fstab 与 `init.recovery.mt8792.rc` 里都保留。

另外两条纪律：

- **不伪造安全补丁**。`PLATFORM_SECURITY_PATCH` 用真实值 `2025-09-05`，不用 `2099-31` 之类的占位符。KeyMint 的密钥 blob 是绑定真实版本号的，伪造会让解密永远失败。
- **不做“关闭 AVB 校验”的 vbmeta**。只产出 `vendor_boot.img`，它必须能通过现有链校验。

---

## 三、目录

```
BoardConfig.mk                     镜像几何、分区、crypto、UI、AB
device.mk                          故意留空（recovery/root 自动打包）
AndroidProducts.mk                 lunch 入口
twrp_tb375fc.mk                    产品定义
vendorsetup.sh                     FOX_* 环境变量
system.prop                        TWRP 目标设备标识
prebuilt/dtb                       官方 dtb，411,876 B
recovery/root/init.recovery.mt8792.rc
recovery/root/system/etc/recovery.fstab   由官方 first-stage fstab 生成，保留加密标志
recovery/root/lib/modules/         222 个 .ko（6.1.138）
vendor_fbe.zip                     解密相关附加包（保留资产）
.github/workflows/build.yml        CI：fox_16.0 → mka vendorbootimage
```

---

## 四、构建

### CI（推荐）

推送后手动触发 `Build OrangeFox TB375FC`。产物在 Actions 的 artifact 里，文件名 `vendor_boot*.img`。

> 注意：`fox_16.0` 全量 `repo sync` 约 85 GB，GitHub 托管 runner 的可用磁盘可能不够。如果 `Repo sync` 这一步因 `No space left on device` 失败，就是磁盘问题，不是配置问题——这种情况下改用本地构建或只同步必要 project。

### 本地

```sh
repo init --depth=1 -u https://gitlab.com/OrangeFox/Manifest.git -b fox_16.0
repo sync -c -j8 --force-sync --no-clone-bundle --no-tags
cp -a <本仓库> device/lenovo/tb375fc
source build/envsetup.sh
. device/lenovo/tb375fc/vendorsetup.sh
lunch twrp_tb375fc-bp2a-eng
mka vendorbootimage
```

产物：`out/target/product/tb375fc/vendor_boot.img`（必须 ≤ 64 MiB）。

---

## 五、刷写与回滚

```sh
# 刷入
fastboot flash vendor_boot_a out/target/product/tb375fc/vendor_boot.img
fastboot reboot recovery

# 回滚（官方件，务必先确认路径存在）
fastboot flash vendor_boot_a "F:\YX\TB375FC_ZUX_1.1.04.287_Tool\image\vendor_boot.img"
fastboot reboot
```

设备不支持 `fastboot fetch`，无法从设备备份 `vendor_boot`，回滚只能靠本地官方件。**刷之前先确认官方 `vendor_boot.img` 在位**（67,108,864 B，MD5 `E60D9F853E08CDE9D099EA1143D760F8`）。

进 bootloader：关机后按住【音量下 + 电源】约 10 秒。

---

## 六、尚存的已知风险

- **无限重启的根因在这台机器上还没有被日志证实**。此前用别人的镜像时，init 和 adbd 确实起来过（`adb devices` 出现过 `recovery`），但 `adb shell` 全部 `Could not set SELinux context for subprocess` → SIGABRT，`/tmp/recovery.log` 拿不到。三条候选：recovery 进程崩溃后 init 重启 / sepolicy 域不匹配 / 模块与 ROM 不符。本仓库按官方布局重写，属于针对性排除，但第一次编译产物仍需实测验证。
- 解密链路（TEE / KeyMint）需要在 ROM 侧 `vendor` 挂载成功后才有意义。本仓库先把“能稳定进界面 + 能挂 `/data` `/metadata` `/persist`”做扎实，再叠解密。
- 222 个模块全部塞进 recovery ramdisk 会显著增大 frag1，压缩后需确认 `vendor_boot` 总量不超 64 MiB。
