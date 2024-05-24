#!/bin/bash

# 默认值设置
API_LEVEL=21
STL=c++_shared
BUILD_DIR=build
OUTPUT_DIR=output
LIB_NAME=spdlog
CMAKE_OPTIONS=""

# 解析命令行参数
while [ "$#" -gt 0 ]; do
    case "$1" in
        -a=*|--api-level=*)
        API_LEVEL="${1#*=}"
        ;;
        -s=*|--stl=*)
        STL="${1#*=}"
        ;;
        -b=*|--build-dir=*)
        BUILD_DIR="${1#*=}"
        ;;
        -o=*|--output-dir=*)
        OUTPUT_DIR="${1#*=}"
        ;;
        -l=*|--lib-name=*)
        LIB_NAME="${1#*=}"
        ;;
        -D*)
        CMAKE_OPTIONS+=" ${1} "
        ;;
        *)
        echo "警告: 不支持的参数 $1"
        ;;
    esac
    shift
done

# 清理并创建构建目录
rm -rf ${BUILD_DIR}
mkdir -p ${BUILD_DIR}/${BUILD_DIR}/armeabi-v7a
mkdir -p ${BUILD_DIR}/${BUILD_DIR}/arm64-v8a

# 创建输出目录
mkdir -p ${OUTPUT_DIR}/armeabi-v7a
mkdir -p ${OUTPUT_DIR}/arm64-v8a

# 检查 ANDROID_NDK_HOME 环境变量
if [ -z "$ANDROID_NDK_HOME" ]; then
    echo "请设置 ANDROID_NDK_HOME 环境变量指向你的 Android NDK 路径"
    exit 1
fi

# 构建函数
build() {
    ABI=$1
    TOOLCHAIN=$2

    # 调用 CMake 进行构建
    cmake -H. -B${BUILD_DIR}/${ABI} \
        -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake \
        -DANDROID_ABI=${ABI} \
        -DANDROID_PLATFORM=android-${API_LEVEL} \
        -DANDROID_STL=${STL} \
        ${CMAKE_OPTIONS} \
        -DCMAKE_BUILD_TYPE=Release

    cmake --build ${BUILD_DIR}/${ABI} -- -j$(nproc)

    cp ${BUILD_DIR}/${ABI}/lib${LIB_NAME}.so ${OUTPUT_DIR}/${ABI}/lib${LIB_NAME}.so
    cp ${BUILD_DIR}/${ABI}/lib${LIB_NAME}.so ${OUTPUT_DIR}/${ABI}/lib${LIB_NAME}_unstriped.so

#    ${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin/${TOOLCHAIN}-strip --strip-unneeded ${OUTPUT_DIR}/${ABI}/lib${LIB_NAME}.so
}

# 开始构建不同的架构
build armeabi-v7a arm-linux-androideabi
build arm64-v8a aarch64-linux-android

# 打包构建结果
tar -cvzf ${OUTPUT_DIR}/lib${LIB_NAME}_armv7_arm64-v8a.tar.gz -C ${OUTPUT_DIR} armv7 arm64-v8a

echo "编译和打包完成，输出目录为：${OUTPUT_DIR}"