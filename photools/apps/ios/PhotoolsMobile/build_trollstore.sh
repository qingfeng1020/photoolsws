#!/bin/bash
# =============================================================================
#  NikonGPS (PhotoolsMobile) — iOS 15 巨魔(TrollStore)侧载构建脚本
#  在 macOS 上运行，一条命令编译打包出可安装到 iOS 15.8.x (iPhone 6s) 的 .ipa
# =============================================================================
#
# 使用方法:
#   1. 确保已安装 Xcode (含 Command Line Tools) 与 xcodegen:
#        brew install xcodegen
#   2. 在本目录执行:
#        chmod +x build_trollstore.sh
#        ./build_trollstore.sh
#   3. 生成的 ipa 位于 ./dist/NikonGPS-15.8.ipa
#
# 注意:
#   - 本脚本产出「无签名 / 自签名」ipa，供巨魔(TrollStore)侧载。
#   - 如需正常 App Store 或 TestFlight 分发，请改用你自己的开发者证书，
#     并把下面的 CODE_SIGN 相关变量替换为你团队的签名配置。
# =============================================================================

set -euo pipefail

# ------------------------- 可配置项 -------------------------
APP_NAME="PhotoolsMobile"
DISPLAY_NAME="NikonGPS"
BUNDLE_ID="com.vincentchyu.photools.mobile"
DEPLOYMENT_TARGET="15.0"
SCHEME="PhotoolsMobile"
CONFIGURATION="Release"
OUTPUT_DIR="dist"
# 巨魔侧载无需开发者证书，使用空签名 + ad-hoc
CODE_SIGN_IDENTITY=""              # 留空表示不签名 (TrollStore 会自行处理)
DEVELOPMENT_TEAM=""                # 留空
PROVISIONING_PROFILE=""            # 留空
# ------------------------------------------------------------

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

echo "=============================================================="
echo "  NikonGPS for iOS 15 巨魔侧载构建"
echo "  部署目标: iOS ${DEPLOYMENT_TARGET}  (支持 iPhone 6s / iOS 15.8.x)"
echo "=============================================================="

# 1. 检查工具链
if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "❌ 未找到 xcodebuild，请先安装 Xcode 及 Command Line Tools。"
  exit 1
fi
if ! command -v xcodegen >/dev/null 2>&1; then
  echo "❌ 未找到 xcodegen，请先执行: brew install xcodegen"
  exit 1
fi

XCODE_VERSION=$(xcodebuild -version | head -n1)
echo "✅ 工具链: ${XCODE_VERSION}"
echo "✅ xcodegen: $(xcodegen --version)"

# 2. 生成 Xcode 工程 (基于 project.yml)
echo ""
echo "▶ 正在根据 project.yml 生成 Xcode 工程..."
xcodegen generate

# 3. 编译 (Release, 无签名, 目标 iOS 15)
echo ""
echo "▶ 正在编译 ${SCHEME} (${CONFIGURATION}, iOS ${DEPLOYMENT_TARGET})..."

xcodebuild \
  -project "${APP_NAME}.xcodeproj" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -destination "generic/platform=iOS" \
  -derivedDataPath "./build" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGN_IDENTITY="" \
  DEVELOPMENT_TEAM="" \
  IPHONEOS_DEPLOYMENT_TARGET="${DEPLOYMENT_TARGET}" \
  clean build

# 4. 定位编译产物 .app
APP_PATH=$(find "./build/Build/Products/${CONFIGURATION}-iphoneos" -maxdepth 1 -name "*.app" | head -n1)
if [ -z "$APP_PATH" ]; then
  echo "❌ 未找到编译产物 .app，构建可能失败。"
  exit 1
fi
echo ""
echo "✅ 编译产物: ${APP_PATH}"

# 5. 打包为 .ipa (创建 Payload 目录并 zip)
mkdir -p "${OUTPUT_DIR}"
STAGING="${OUTPUT_DIR}/Payload"
rm -rf "${STAGING}"
mkdir -p "${STAGING}"
cp -R "${APP_PATH}" "${STAGING}/"

IPA_PATH="${OUTPUT_DIR}/${DISPLAY_NAME}-iOS${DEPLOYMENT_TARGET}.ipa"
rm -f "${IPA_PATH}"
(
  cd "${OUTPUT_DIR}"
  # 使用 ditto 保持符号链接与资源完整
  zip -qry "../${DISPLAY_NAME}-iOS${DEPLOYMENT_TARGET}.ipa" "Payload"
)

# 修正路径 (zip 在子目录内生成，移到 dist 下)
mv -f "${DISPLAY_NAME}-iOS${DEPLOYMENT_TARGET}.ipa" "${OUTPUT_DIR}/${DISPLAY_NAME}-iOS${DEPLOYMENT_TARGET}.ipa" 2>/dev/null || true

echo ""
echo "=============================================================="
echo "  ✅ 打包完成！"
echo "  产物: ${ROOT_DIR}/${OUTPUT_DIR}/${DISPLAY_NAME}-iOS${DEPLOYMENT_TARGET}.ipa"
echo ""
echo "  安装方法 (巨魔 TrollStore):"
echo "    1. 将 .ipa 通过 AirDrop / 微信 / 网盘传到 iPhone"
echo "    2. 在 iPhone 上用「文件」App 找到该 .ipa"
echo "    3. 点击分享 -> 选择「TrollStore」即可安装"
echo "=============================================================="
