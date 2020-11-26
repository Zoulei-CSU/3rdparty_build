#!/bin/bash
echo "开始构建"

#设置编译线程数
export BUILDTHREAD=1

#设置环境变量
export Build_PATH=$(pwd)
export QT_HOME=/home/southgis/Qt/Qt5.12.9/5.12.9/android_arm64_v8a
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
export CLASSPATH=.:${JAVA_HOME}/jre/lib:${JAVA_HOME}/lib:${JAVA_HOME}/lib/tools.jar

#设置编译的架构
export BUILD_ARCH_ABI=arm64-v8a
#export BUILD_ARCH_ABI=armeabi-v7a
#export BUILD_ARCH_ABI=x86
#export BUILD_ARCH_ABI=x86_64

#编译用的Android都API版本
export BUILD_ANDROID_VERSION=26

#设置SDK、NDK目录
export SDK_ROOT=/home/southgis/android/sdk
export NDK_ROOT=/home/southgis/android/ndk/android-ndk-r19c

export HOST_TAG=linux-x86_64    #设置编译机器架构
export TOOLCHAIN=${NDK_ROOT}/toolchains/llvm/prebuilt/${HOST_TAG}

export ARCH=arm64   #架构
export BUILD_HOST=aarch64-linux-android #交叉编译host
export CC=${TOOLCHAIN}/bin/aarch64-linux-android${BUILD_ANDROID_VERSION}-clang
export CXX=${TOOLCHAIN}/bin/aarch64-linux-android${BUILD_ANDROID_VERSION}-clang++
export AR=${TOOLCHAIN}/bin/aarch64-linux-android-ar
export AS=${TOOLCHAIN}/bin/aarch64-linux-android-as
export RANLIB=${TOOLCHAIN}/bin/aarch64-linux-android-ranlib
export LD=${TOOLCHAIN}/bin/aarch64-linux-android-ld
export STRIP=${TOOLCHAIN}/bin/aarch64-linux-android-strip
export READELF=${TOOLCHAIN}/bin/aarch64-linux-android-readelf

#如果是其他架构，就换架构参数
if [ "$BUILD_ARCH_ABI" = "armeabi-v7a" ]; then
    export ARCH=arm
    export BUILD_HOST=arm-linux-androideabi
    export CC=${TOOLCHAIN}/bin/armv7a-linux-androideabi${BUILD_ANDROID_VERSION}-clang
    export CXX=${TOOLCHAIN}/bin/armv7a-linux-androideabi${BUILD_ANDROID_VERSION}-clang++
    export AR=${TOOLCHAIN}/bin/arm-linux-androideabi-ar
    export AS=${TOOLCHAIN}/bin/arm-linux-androideabi-as
    export RANLIB=${TOOLCHAIN}/bin/arm-linux-androideabi-ranlib
    export LD=${TOOLCHAIN}/bin/arm-linux-androideabi-ld
    export STRIP=${TOOLCHAIN}/bin/arm-linux-androideabi-strip
    export READELF=${TOOLCHAIN}/bin/arm-linux-androideabi-readelf
elif [ "$BUILD_ARCH_ABI" = "x86" ]; then
    export ARCH=x86
    export BUILD_HOST=i686-linux-android
    export CC=${TOOLCHAIN}/bin/i686-linux-android${BUILD_ANDROID_VERSION}-clang
    export CXX=${TOOLCHAIN}/bin/i686-linux-android${BUILD_ANDROID_VERSION}-clang++
    export AR=${TOOLCHAIN}/bin/i686-linux-android-ar
    export AS=${TOOLCHAIN}/bin/i686-linux-android-as
    export RANLIB=${TOOLCHAIN}/bin/i686-linux-android-ranlib
    export LD=${TOOLCHAIN}/bin/i686-linux-android-ld
    export STRIP=${TOOLCHAIN}/bin/i686-linux-android-strip
    export READELF=${TOOLCHAIN}/bin/i686-linux-android-readelf
elif [ "$BUILD_ARCH_ABI" = "x86_64" ]; then
    export ARCH=x86_64
    export BUILD_HOST=x86_64-linux-android
    export CC=${TOOLCHAIN}/bin/x86_64-linux-android${BUILD_ANDROID_VERSION}-clang
    export CXX=${TOOLCHAIN}/bin/x86_64-linux-android${BUILD_ANDROID_VERSION}-clang++
    export AR=${TOOLCHAIN}/bin/x86_64-linux-android-ar
    export AS=${TOOLCHAIN}/bin/x86_64-linux-android-as
    export RANLIB=${TOOLCHAIN}/bin/x86_64-linux-android-ranlib
    export LD=${TOOLCHAIN}/bin/x86_64-linux-android-ld
    export STRIP=${TOOLCHAIN}/bin/x86_64-linux-android-strip
    export READELF=${TOOLCHAIN}/bin/x86_64-linux-android-readelf
fi

#设置额外编译参数
#export LD_LIBRARY_PATH=/home/southgis/code/others-build/release
export EXT_CFLAGS="-DANDROID -fPIC"
export EXT_CXXFLAGS="${EXT_CFLAGS}"
export EXT_LDFLAGS="-Wl,-rpath-link=.:${Build_PATH}/release/${BUILD_ARCH_ABI}"
export EXT_MODULE_LINKER_FLAGS="${EXT_LDFLAGS}"
export EXT_EXE_LINKER_FLAGS="${EXT_LDFLAGS}"

#设置CMake参数
export CMAKE_AR=$AR
export CMAKE_LINKER=$LD
export CMAKE_NM=$NM
export CMAKE_OBJDUMP=$OBJDUMP
export CMAKE_RANLIB=$RANLIB

#其他架构换QT版本
if [ "$BUILD_ARCH_ABI" = "armeabi-v7a" ]; then
    export QT_HOME=/home/southgis/Qt/Qt5.12.9/5.12.9/android_armv7
elif [ "$BUILD_ARCH_ABI" = "x86" ]; then
    export QT_HOME=/home/southgis/Qt/Qt5.12.9/5.12.9/android_x86
elif [ "$BUILD_ARCH_ABI" = "x86_64" ]; then
    export QT_HOME=/home/southgis/Qt/Qt5.12.9/5.12.9/android_x86_64
fi

export ANDROID_NDK_HOME=${NDK_ROOT}
export ANDROID_TOOLCHAIN="${TOOLCHAIN}/bin"
export ANDROID_API=${BUILD_ANDROID_VERSION}

export PATH=${ANDROID_TOOLCHAIN}/bin:${QT_HOME}/bin:${JAVA_HOME}/bin:${PATH}

echo "当前工作目录：${Build_PATH}"
echo "构建架构：${ARCH}，ABI：${BUILD_ARCH_ABI}"
echo "CC：$CC"
echo "CXX：$CXX"
#由于编译过程中，少数工程设置静态C++库后依然会链接动态C++库，比如gdal，隐藏全部编译过程都换成了c++_shared而不是c++_static

start_time=$(date +%s)

#检查程序返回值是否正常
funCheckIsOk(){
    if test $1 -ne 0 
    then 
        #echo "Error: $2"
        echo -e "\033[1;41;33m Error: $2 \033[0m"
        end_time=$(date +%s)
        cost_time=$[ $end_time-$start_time ]
        echo "构建没有完成，${BUILDTHREAD}线程编译，已耗时 $(($cost_time/60))min $(($cost_time%60))s"
        exit 1
    else
        #echo "OK: $3"
        echo -e "\033[32m OK: $3 \033[0m"
    fi
}

#检查文件是否存在
funCheck3rdparty(){
    if [ -e $1 ]; then
        echo "找到文件：" 
        ls -l $1
    else
        echo -e "\033[1;41;33m 编译编译无法继续，未发现文件: $1 \033[0m"
        exit 1
    fi
}

#检测编译器
${CXX} -v
funCheckIsOk $? "C++编译器 无法执行" "C++编译器 正常."

#检测CMake
cmake --version
funCheckIsOk $? "CMake 无法执行" "CMake 正常."

#编译Zlib，其实是直接拷贝解压
if [ -d ${Build_PATH}/3rdparty_android/zlib ]; then
    echo -e "\033[32m OK: zlib已经存在，跳过构建 \033[0m"
else
    funCheck3rdparty ${Build_PATH}/src/zlib-android.tar.xz
    mkdir -p ${Build_PATH}/3rdparty_android
    cp -r ${Build_PATH}/src/zlib-android.tar.xz ${Build_PATH}/3rdparty_android/
    cd ${Build_PATH}/3rdparty_android/
    tar -xvJf zlib-android.tar.xz
    mv zlib-android zlib
    funCheckIsOk $? "Zlib 构建失败" "Zlib 构建完成."
    rm -f zlib-android.tar.xz
    #mkdir -p ${Build_PATH}/release/${BUILD_ARCH_ABI}
    #cp -r ${Build_PATH}/3rdparty_android/zlib/lib/${BUILD_ARCH_ABI}/*.so ${Build_PATH}/release/${BUILD_ARCH_ABI}/
    #funCheckIsOk $? "Zlib 动态库拷贝失败" "Zlib 动态库拷贝完成."
fi

#编译OpenSSL，其实是直接拷贝解压
if [ -d ${Build_PATH}/3rdparty_android/openssl ]; then
    echo -e "\033[32m OK: OpenSSL已经存在，跳过构建 \033[0m"
else
    funCheck3rdparty ${Build_PATH}/src/openssl-android.tar.xz
    mkdir -p ${Build_PATH}/3rdparty_android
    cp -r ${Build_PATH}/src/openssl-android.tar.xz ${Build_PATH}/3rdparty_android/
    cd ${Build_PATH}/3rdparty_android/
    tar -xvJf openssl-android.tar.xz
    mv openssl-android openssl
    funCheckIsOk $? "OpenSSL 构建失败" "OpenSSL 构建完成."
    rm -f openssl-android.tar.xz
    mkdir -p ${Build_PATH}/release/${BUILD_ARCH_ABI}
    cp -r ${Build_PATH}/3rdparty_android/openssl/lib/${BUILD_ARCH_ABI}/*.so ${Build_PATH}/release/${BUILD_ARCH_ABI}/
    funCheckIsOk $? "OpenSSL 动态库拷贝失败" "OpenSSL 动态库拷贝完成."
fi

#编译Curl
if [ -d ${Build_PATH}/3rdparty_android/curl ]; then
    echo -e "\033[32m OK: Curl已经存在，跳过构建 \033[0m"
else
    funCheck3rdparty ${Build_PATH}/src/curl-7.72.0.tar.xz
    mkdir -p ${Build_PATH}/build
    cp -r ${Build_PATH}/src/curl-7.72.0.tar.xz ${Build_PATH}/build/
    cd ${Build_PATH}/build/
    tar -xvJf curl-7.72.0.tar.xz
    cd curl-7.72.0
    mkdir build/
    cd build/
    cmake -G"Unix Makefiles" .. -DCMAKE_TOOLCHAIN_FILE=${NDK_ROOT}/build/cmake/android.toolchain.cmake -DANDROID_STL=c++_shared -DANDROID_TOOLCHAIN=clang -DANDROID_PLATFORM=android-${BUILD_ANDROID_VERSION} -DANDROID_ABI=${BUILD_ARCH_ABI} -DCMAKE_INSTALL_PREFIX="${Build_PATH}/3rdparty_android/curl" -DCMAKE_BUILD_TYPE="Release" -DCMAKE_C_FLAGS="${EXT_CFLAGS}" -Dpkgcfg_lib__OPENSSL_ssl="${Build_PATH}/3rdparty_android/openssl/lib/${BUILD_ARCH_ABI}/libssl_1_1.so" -Dpkgcfg_lib__OPENSSL_crypto="${Build_PATH}/3rdparty_android/openssl/lib/${BUILD_ARCH_ABI}/libcrypto_1_1.so" -DOPENSSL_INCLUDE_DIR="${Build_PATH}/3rdparty_android/openssl/include" -DOPENSSL_CRYPTO_LIBRARY="${Build_PATH}/3rdparty_android/openssl/lib/${BUILD_ARCH_ABI}/libcrypto_1_1.so" -DOPENSSL_SSL_LIBRARY="${Build_PATH}/3rdparty_android/openssl/lib/${BUILD_ARCH_ABI}/libssl_1_1.so" -DCURL_ZLIB=ON -DBUILD_TESTING=OFF -DZLIB_INCLUDE_DIR="${Build_PATH}/3rdparty_android/zlib/include" -DZLIB_LIBRARY_RELEASE="${Build_PATH}/3rdparty_android/zlib/lib/${BUILD_ARCH_ABI}/libz.a" -DCMAKE_MODULE_LINKER_FLAGS:STRING="${EXT_MODULE_LINKER_FLAGS}" -DCMAKE_SHARED_LINKER_FLAGS:STRING="${EXT_MODULE_LINKER_FLAGS}" -DCMAKE_EXE_LINKER_FLAGS:STRING="${EXT_EXE_LINKER_FLAGS}"
    funCheckIsOk $? "Curl cmake失败" "Curl cmake完成."
    make -j${BUILDTHREAD} && make install
    funCheckIsOk $? "Curl 构建失败" "Curl 构建完成."
    mkdir -p ${Build_PATH}/release/${BUILD_ARCH_ABI}
    cp -r ${Build_PATH}/3rdparty_android/curl/lib/*.so ${Build_PATH}/release/${BUILD_ARCH_ABI}/
    funCheckIsOk $? "Curl 动态库拷贝失败" "Curl 动态库拷贝完成."
fi

#编译GEOS
if [ -d ${Build_PATH}/3rdparty_android/geos-3.6 ]; then
    echo -e "\033[32m OK: GEOS已经存在，跳过构建 \033[0m"
else
    funCheck3rdparty ${Build_PATH}/src/geos-3.6.4.tar.xz
    mkdir -p ${Build_PATH}/build
    cp -r ${Build_PATH}/src/geos-3.6.4.tar.xz ${Build_PATH}/build/
    cd ${Build_PATH}/build/
    tar -xvJf geos-3.6.4.tar.xz
    cd geos-3.6.4
    mkdir build/
    cd build/
    cmake -G"Unix Makefiles" .. -DCMAKE_TOOLCHAIN_FILE=${NDK_ROOT}/build/cmake/android.toolchain.cmake -DANDROID_STL=c++_shared -DANDROID_TOOLCHAIN=clang -DANDROID_PLATFORM=android-${BUILD_ANDROID_VERSION} -DANDROID_ABI=${BUILD_ARCH_ABI} -DCMAKE_INSTALL_PREFIX="${Build_PATH}/3rdparty_android/geos-3.6" -DCMAKE_BUILD_TYPE="Release" -DCMAKE_C_FLAGS="${EXT_CFLAGS}" -DCMAKE_CXX_FLAGS="${EXT_CXXFLAGS}" -DGEOS_ENABLE_INLINE=OFF -DGEOS_ENABLE_TESTS=OFF -DCMAKE_MODULE_LINKER_FLAGS:STRING="${EXT_MODULE_LINKER_FLAGS}" -DCMAKE_SHARED_LINKER_FLAGS:STRING="${EXT_MODULE_LINKER_FLAGS}" -DCMAKE_EXE_LINKER_FLAGS:STRING="${EXT_EXE_LINKER_FLAGS}" 
    funCheckIsOk $? "GEOS cmake失败" "GEOS cmake完成."
    make -j${BUILDTHREAD} && make install
    funCheckIsOk $? "GEOS 构建失败" "GEOS 构建完成."
    mkdir -p ${Build_PATH}/release/${BUILD_ARCH_ABI}
    cp -r ${Build_PATH}/3rdparty_android/geos-3.6/lib/*.so ${Build_PATH}/release/${BUILD_ARCH_ABI}/
    funCheckIsOk $? "GEOS 动态库拷贝失败" "GEOS 动态库拷贝完成."
fi

#编译proj
if [ -d ${Build_PATH}/3rdparty_android/proj ]; then
    echo -e "\033[32m OK: proj已经存在，跳过构建 \033[0m"
else
    funCheck3rdparty ${Build_PATH}/src/proj-4.9.3.tar.gz
    mkdir -p ${Build_PATH}/build
    cp -r ${Build_PATH}/src/proj-4.9.3.tar.gz ${Build_PATH}/build/
    cd ${Build_PATH}/build/
    tar -zxvf proj-4.9.3.tar.gz
    cd proj-4.9.3
    mkdir build/
    cd build/
    cmake -G"Unix Makefiles" .. -DCMAKE_TOOLCHAIN_FILE=${NDK_ROOT}/build/cmake/android.toolchain.cmake -DANDROID_STL=c++_shared -DANDROID_TOOLCHAIN=clang -DANDROID_PLATFORM=android-${BUILD_ANDROID_VERSION} -DANDROID_ABI=${BUILD_ARCH_ABI} -DCMAKE_INSTALL_PREFIX="${Build_PATH}/3rdparty_android/proj" -DCMAKE_BUILD_TYPE="Release" -DCMAKE_C_FLAGS="${EXT_CFLAGS}" -DCMAKE_CXX_FLAGS="${EXT_CXXFLAGS}" -DBUILD_TESTING=OFF -DPROJ4_TESTS=OFF -DCMAKE_MODULE_LINKER_FLAGS:STRING="${EXT_MODULE_LINKER_FLAGS}" -DCMAKE_SHARED_LINKER_FLAGS:STRING="${EXT_MODULE_LINKER_FLAGS}" -DCMAKE_EXE_LINKER_FLAGS:STRING="${EXT_EXE_LINKER_FLAGS}" 
    funCheckIsOk $? "proj cmake失败" "proj cmake完成."
    make -j${BUILDTHREAD} && make install
    funCheckIsOk $? "proj 构建失败" "proj 构建完成."
    mkdir -p ${Build_PATH}/release/${BUILD_ARCH_ABI}
    cp -r ${Build_PATH}/3rdparty_android/proj/lib/*.so ${Build_PATH}/release/${BUILD_ARCH_ABI}/
    funCheckIsOk $? "proj 动态库拷贝失败" "proj 动态库拷贝完成."
fi

#编译GDAL
if [ -d ${Build_PATH}/3rdparty_android/gdal244 ]; then
    echo -e "\033[32m OK: GDAL已经存在，跳过构建 \033[0m"
else
    funCheck3rdparty ${Build_PATH}/src/gdal-2.4.4.tar.gz
    mkdir -p ${Build_PATH}/build
    cp -r ${Build_PATH}/src/gdal-2.4.4.tar.gz ${Build_PATH}/build/
    cd ${Build_PATH}/build/
    tar -zxvf gdal-2.4.4.tar.gz
    cd gdal-2.4.4
    #源代码有bug，构建sigdem找不到头文件，先复制一个
    cp frmts/raw/rawdataset.h frmts/sigdem/
    #先复制依赖库，否则配置或者编译容易出错
    mkdir -p .libs
    cp -r ${Build_PATH}/3rdparty_android/proj/lib/* ${Build_PATH}/build/proj-4.9.3/src/
    cp -r ${Build_PATH}/3rdparty_android/proj/lib/* .libs/
    cp -r ${Build_PATH}/3rdparty_android/proj/lib/* apps/
    cp -r ${Build_PATH}/3rdparty_android/geos-3.6/lib/* .libs/
    cp -r ${Build_PATH}/3rdparty_android/geos-3.6/lib/* apps/
    cp -r ${Build_PATH}/3rdparty_android/curl/lib/*.so .libs/
    cp -r ${Build_PATH}/3rdparty_android/curl/lib/*.so apps/
    cp -r ${Build_PATH}/3rdparty_android/openssl/lib/${BUILD_ARCH_ABI}/*.so .libs/
    cp -r ${Build_PATH}/3rdparty_android/openssl/lib/${BUILD_ARCH_ABI}/*.so apps/
    #开始构建，带上后面的一堆without编译出来的库小一些
    #Android不支持rpath和rpath-link，编译的时候总是找不到需要链接的so依赖的so，从而报错，因此需要在链接的时候显示的把so依赖的so都加进去。
    #geos-config文件的--ldflags部分，需要加上-lgeos -lm，curl-config文件需要修改-lcurl后面的内容，把crypto、ssl、z都带上
    ./configure --host=${BUILD_HOST} --with-sysroot=${TOOLCHAIN}/sysroot --prefix=${Build_PATH}/3rdparty_android/gdal244 --enable-shared=yes --enable-static=no --with-geos=${Build_PATH}/3rdparty_android/geos-3.6/bin/geos-config --with-curl=${Build_PATH}/3rdparty_android/curl/bin/curl-config --with-proj=${Build_PATH}/build/proj-4.9.3/src --with-libz=internal --with-cpp14 --with-png=internal --with-jpeg=internal --with-geotiff=internal --with-libtiff=internal --with-sqlite3=internal --without-python --without-java --without-bsb --without-cfitsio --without-ecw --without-expat --without-fme --without-freexl --without-gif --without-gif --without-gnm --without-grass --without-grib --without-hdf4 --without-hdf5 --without-idb --without-ingres --without-kakadu --without-libgrass --without-libtool --without-mrf --without-mrsid --without-mysql --without-netcdf --without-odbc --without-ogdi --without-pcidsk --without-pcraster --without-pcre --without-perl --without-pg --without-python --without-qhull --without-sde --without-webp --without-xerces
    funCheckIsOk $? "GDAL 编译配置失败" "GDAL 编译配置完成."
    make CFLAGS="${EXT_CFLAGS}" CXXFLAGS="${EXT_CXXFLAGS}" LD_SHARED="$CXX -fPIC -shared" LDFLAGS="${EXT_LDFLAGS} -L${Build_PATH}/release/${BUILD_ARCH_ABI}" LIBS="-lssl_1_1 -lcrypto_1_1 -lcurl -lgeos -lgeos_c -lproj -lz -lc++_shared" -j${BUILDTHREAD} && make install
    funCheckIsOk $? "GDAL 构建失败" "GDAL 构建完成."
    #貌似还有个bug，生成的动态库install时候没拷贝，需要手动拷贝（make的时候不带LD_SHARED貌似也不生产动态库so，加上--enable-shared=yes也不行）
    cp libgdal.so ${Build_PATH}/3rdparty_android/gdal244/lib/
    funCheckIsOk $? "GDAL 动态库 构建失败" "GDAL 动态库 构建完成."
    cd swig
    make ANDROID=yes    #构建Java外包，需要安装swig
    #构建Android的外包动态库。由于脚本里会构建app，但app不是为Android设计的，一定会失败，但可以先生成so
    cd java
    make ANDROID=yes CFLAGS="${EXT_CFLAGS}" CXXFLAGS="${EXT_CXXFLAGS}" LD_SHARED="$CXX -fPIC -shared" LDFLAGS="${EXT_LDFLAGS} -L${Build_PATH}/release/${BUILD_ARCH_ABI}" LIBS="-lssl_1_1 -lcrypto_1_1 -lcurl -lgeos -lgeos_c -lproj -lz -lc++_shared" -j${BUILDTHREAD}
    mkdir -p ${Build_PATH}/3rdparty_android/gdal244/jni/${BUILD_ARCH_ABI}/bin
    cp libgdalalljni.so ${Build_PATH}/3rdparty_android/gdal244/jni/${BUILD_ARCH_ABI}/bin/
    funCheckIsOk $? "GDAL Jni 构建失败(如果不需要，可屏蔽掉Jni构建)" "GDAL Jni 构建完成(上面如有错误信息可以忽略)."
    cp gdal.jar ${Build_PATH}/3rdparty_android/gdal244/jni/${BUILD_ARCH_ABI}/bin/
    mkdir -p ${Build_PATH}/3rdparty_android/gdal244/jni/${BUILD_ARCH_ABI}/src
    cp -r org ${Build_PATH}/3rdparty_android/gdal244/jni/${BUILD_ARCH_ABI}/src/
    cp *.cpp ${Build_PATH}/3rdparty_android/gdal244/jni/${BUILD_ARCH_ABI}/src/
    cp *.c ${Build_PATH}/3rdparty_android/gdal244/jni/${BUILD_ARCH_ABI}/src/

    mkdir -p ${Build_PATH}/release/${BUILD_ARCH_ABI}
    cp -r ${Build_PATH}/3rdparty_android/gdal244/lib/*.so ${Build_PATH}/release/${BUILD_ARCH_ABI}/
    cp -r ${Build_PATH}/3rdparty_android/gdal244/jni/${BUILD_ARCH_ABI}/bin/*.so ${Build_PATH}/release/${BUILD_ARCH_ABI}/
    funCheckIsOk $? "GDAL 动态库拷贝失败" "GDAL 动态库拷贝完成."
fi

#编译snappy
if [ -d ${Build_PATH}/3rdparty_android/snappy ]; then
    echo -e "\033[32m OK: snappy已经存在，跳过构建 \033[0m"
else
    funCheck3rdparty ${Build_PATH}/src/snappy-1.1.8.tar.gz
    mkdir -p ${Build_PATH}/build
    cp -r ${Build_PATH}/src/snappy-1.1.8.tar.gz ${Build_PATH}/build/
    cd ${Build_PATH}/build/
    tar -zxvf snappy-1.1.8.tar.gz
    cd snappy-1.1.8
    mkdir build/
    cd build/
    cmake -G"Unix Makefiles" .. -DCMAKE_TOOLCHAIN_FILE=${NDK_ROOT}/build/cmake/android.toolchain.cmake -DANDROID_STL=c++_shared -DANDROID_TOOLCHAIN=clang -DANDROID_PLATFORM=android-${BUILD_ANDROID_VERSION} -DANDROID_ABI=${BUILD_ARCH_ABI} -DCMAKE_INSTALL_PREFIX="${Build_PATH}/3rdparty_android/snappy" -DCMAKE_BUILD_TYPE="Release" -DCMAKE_C_FLAGS="${EXT_CFLAGS}" -DCMAKE_CXX_FLAGS="${EXT_CXXFLAGS}" -DSNAPPY_BUILD_TESTS=OFF -DCMAKE_MODULE_LINKER_FLAGS:STRING="${EXT_MODULE_LINKER_FLAGS}" -DCMAKE_SHARED_LINKER_FLAGS:STRING="${EXT_MODULE_LINKER_FLAGS}" -DCMAKE_EXE_LINKER_FLAGS:STRING="${EXT_EXE_LINKER_FLAGS}" 
    funCheckIsOk $? "snappy cmake失败" "snappy cmake完成."
    make -j${BUILDTHREAD} && make install
    funCheckIsOk $? "snappy 构建失败" "snappy 构建完成."
    mkdir -p ${Build_PATH}/release/${BUILD_ARCH_ABI}
    cp -r ${Build_PATH}/3rdparty_android/snappy/lib/*.a ${Build_PATH}/release/${BUILD_ARCH_ABI}/
    funCheckIsOk $? "snappy 静态库拷贝失败" "snappy 静态库拷贝完成."
fi

#编译freetype
if [ -d ${Build_PATH}/3rdparty_android/freetype ]; then
    echo -e "\033[32m OK: freetype已经存在，跳过构建 \033[0m"
else
    funCheck3rdparty ${Build_PATH}/src/freetype-2.9.1.tar.gz
    mkdir -p ${Build_PATH}/build
    cp -r ${Build_PATH}/src/freetype-2.9.1.tar.gz ${Build_PATH}/build/
    cd ${Build_PATH}/build/
    tar -zxvf freetype-2.9.1.tar.gz
    cd freetype-2.9.1
    mkdir build/
    cd build/
    cmake -G"Unix Makefiles" .. -DCMAKE_TOOLCHAIN_FILE=${NDK_ROOT}/build/cmake/android.toolchain.cmake -DANDROID_STL=c++_shared -DANDROID_TOOLCHAIN=clang -DANDROID_PLATFORM=android-${BUILD_ANDROID_VERSION} -DANDROID_ABI=${BUILD_ARCH_ABI} -DCMAKE_INSTALL_PREFIX="${Build_PATH}/3rdparty_android/freetype" -DCMAKE_BUILD_TYPE="Release" -DCMAKE_C_FLAGS="${EXT_CFLAGS}" -DCMAKE_CXX_FLAGS="${EXT_CXXFLAGS}" -DFT_WITH_ZLIB=ON -DZLIB_INCLUDE_DIR="${Build_PATH}/3rdparty_android/zlib/include" -DZLIB_LIBRARY_RELEASE="${Build_PATH}/3rdparty_android/zlib/lib/${BUILD_ARCH_ABI}/libz.a" -DCMAKE_MODULE_LINKER_FLAGS:STRING="${EXT_MODULE_LINKER_FLAGS}" -DCMAKE_SHARED_LINKER_FLAGS:STRING="${EXT_MODULE_LINKER_FLAGS}" -DCMAKE_EXE_LINKER_FLAGS:STRING="${EXT_EXE_LINKER_FLAGS}" 
    funCheckIsOk $? "freetype cmake失败" "freetype cmake完成."
    make -j${BUILDTHREAD} && make install
    funCheckIsOk $? "freetype 构建失败" "freetype 构建完成."
    cp -r ${Build_PATH}/3rdparty_android/freetype/lib/*.a ${Build_PATH}/release/${BUILD_ARCH_ABI}/
    funCheckIsOk $? "snappy 静态库拷贝失败" "snappy 静态库拷贝完成."
fi

#接下来的编译需要用到Qt，检测QMake
qmake -v
funCheckIsOk $? "QMake 无法执行" "QMake 正常."

#修改编译参数
export EXT_CFLAGS="-DANDROID -fPIC -fvisibility=hidden "
export EXT_CXXFLAGS="${EXT_CFLAGS} -fvisibility-inlines-hidden"
export EXT_LDFLAGS="-Wl,--enable-new-dtags -Wl,--gc-sections -Wl,-rpath-link=.:${Build_PATH}/release/${BUILD_ARCH_ABI} -fvisibility=hidden -fvisibility-inlines-hidden -Wl,-Bsymbolic -Wl,-Bsymbolic-functions"
export EXT_MODULE_LINKER_FLAGS="${EXT_LDFLAGS}"
export EXT_EXE_LINKER_FLAGS="${EXT_LDFLAGS}"

#设置Qt编译Android需要的变量
export ANDROID_HOME=${SDK_ROOT}
export ANDROID_SDK_ROOT=${SDK_ROOT}
export ANDROID_NDK_ROOT=${NDK_ROOT}
export ANDROID_NDK_HOST=${HOST_TAG}
export ANDROID_NDK_PLATFORM=android-${BUILD_ANDROID_VERSION}
export ANDROID_NDK_TOOLCHAIN_PREFIX=${BUILD_HOST}
export ANDROID_NDK_TOOLS_PREFIX=${BUILD_HOST}

export AR="${AR} cqs "

#编译quazip
if [ -d ${Build_PATH}/3rdparty_android/quazip ]; then
    echo -e "\033[32m OK: quazip已经存在，跳过构建 \033[0m"
else
    funCheck3rdparty ${Build_PATH}/src/quazip.tar.xz
    mkdir -p ${Build_PATH}/build
    cp -r ${Build_PATH}/src/quazip.tar.xz ${Build_PATH}/3rdparty_android/
    cd ${Build_PATH}/3rdparty_android/
    tar -xvJf quazip.tar.xz
    cd quazip/
    mkdir -p build_temp
    cd build_temp/
    qmake -o Makefile ../src/libquazip.pro
    funCheckIsOk $? "quazip 编译配置失败" "quazip 编译配置完成."
    make -j${BUILDTHREAD}
    funCheckIsOk $? "quazip 构建失败" "quazip 构建完成."
    cd ..
    rm -rf build_temp/
    cd ..
    rm -f quazip.tar.xz
    cp -r ${Build_PATH}/3rdparty_android/quazip/lib/android/${BUILD_ARCH_ABI}/*.a ${Build_PATH}/release/${BUILD_ARCH_ABI}/
    funCheckIsOk $? "quazip 静态库拷贝失败" "quazip 静态库拷贝完成."
fi

#编译QtToolCollection
if [ -d ${Build_PATH}/3rdparty_android/qttoolcollection ]; then
    echo -e "\033[32m OK: qttoolcollection已经存在，跳过构建 \033[0m"
else
    funCheck3rdparty ${Build_PATH}/src/qttoolcollection.tar.xz
    mkdir -p ${Build_PATH}/build
    cp -r ${Build_PATH}/src/qttoolcollection.tar.xz ${Build_PATH}/3rdparty_android/
    cd ${Build_PATH}/3rdparty_android/
    tar -xvJf qttoolcollection.tar.xz
    cd qttoolcollection/
    mkdir -p build_temp
    cd build_temp/
    qmake -o Makefile ../QtToolCollection/QtToolCollection.pro
    funCheckIsOk $? "qttoolcollection 编译配置失败" "qttoolcollection 编译配置完成."
    make -j${BUILDTHREAD}
    funCheckIsOk $? "qttoolcollection 构建失败" "qttoolcollection 构建完成."
    cd ..
    rm -rf build_temp/
    cd ..
    rm -f qttoolcollection.tar.xz
    cp -r ${Build_PATH}/3rdparty_android/qttoolcollection/bin/android/${BUILD_ARCH_ABI}/*.so ${Build_PATH}/release/${BUILD_ARCH_ABI}/
    funCheckIsOk $? "qttoolcollection 动态库拷贝失败" "qttoolcollection 动态库拷贝完成."
fi

#不需要调试，裁剪so动态库，使其体积更小
echo "正在裁剪目标so动态库：${Build_PATH}/release/${BUILD_ARCH_ABI}"
${STRIP} --strip-all ${Build_PATH}/release/${BUILD_ARCH_ABI}/*.so

echo -e "\033[32m \nlibgdal.so: \033[0m"
${READELF} -d ${Build_PATH}/release/${BUILD_ARCH_ABI}/libgdal.so

echo -e "\033[32m \nlibQtToolCollection.so: \033[0m"
${READELF} -d ${Build_PATH}/release/${BUILD_ARCH_ABI}/libQtToolCollection.so

end_time=$(date +%s)
cost_time=$[ $end_time-$start_time ]
echo "全部工程构建完成，${BUILDTHREAD}线程编译，共耗时 $(($cost_time/60))min $(($cost_time%60))s"
