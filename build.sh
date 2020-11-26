#!/bin/bash
echo "开始构建"

#scl enable devtoolset-7 llvm-toolset-7 bash
#export CC=/usr/bin/clang
#export CXX=/usr/bin/clang++
#export CC=/opt/rh/llvm-toolset-7/root/usr/bin/clang
#export CXX=/opt/rh/llvm-toolset-7/root/usr/bin/clang++

#设置编译线程数
export BUILDTHREAD=2

#设置环境变量
export Build_PATH=$(pwd)
export QT_HOME=/home/southgis/Qt/Qt5.12.9/5.12.9/gcc_64
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
export CLASSPATH=.:${JAVA_HOME}/jre/lib:${JAVA_HOME}/lib:${JAVA_HOME}/lib/tools.jar

export PATH=${QT_HOME}/bin:${JAVA_HOME}/bin:${PATH}

echo "当前工作目录：${Build_PATH}"
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

#检测g++
g++ -v
funCheckIsOk $? "g++ 无法执行" "g++ 正常."

#检测CMake
cmake --version
funCheckIsOk $? "CMake 无法执行" "CMake 正常."

#编译Zlib
if [ -d ${Build_PATH}/3rdparty_unix/zlib ]; then
    echo -e "\033[32m OK: zlib已经存在，跳过构建 \033[0m"
else
    funCheck3rdparty ${Build_PATH}/src/zlib-1.2.5.3.tar.gz
    mkdir -p ${Build_PATH}/build
    cp -r ${Build_PATH}/src/zlib-1.2.5.3.tar.gz ${Build_PATH}/build/
    cd ${Build_PATH}/build/
    tar -zxvf zlib-1.2.5.3.tar.gz
    cd zlib-1.2.5.3/
    CFLAGS="-O3 -fPIC" ./configure --prefix=${Build_PATH}/3rdparty_unix/zlib
    make -j${BUILDTHREAD} && make install
    funCheckIsOk $? "Zlib 构建失败" "Zlib 构建完成."
    CFLAGS=""
fi

#编译OpenSSL
if [ -d ${Build_PATH}/3rdparty_unix/openssl ]; then
    echo -e "\033[32m OK: OpenSSL已经存在，跳过构建 \033[0m"
else
    funCheck3rdparty ${Build_PATH}/src/openssl-1.1.1g.tar.gz
    mkdir -p ${Build_PATH}/build
    cp -r ${Build_PATH}/src/openssl-1.1.1g.tar.gz ${Build_PATH}/build/
    cd ${Build_PATH}/build/
    tar -zxvf openssl-1.1.1g.tar.gz
    cd openssl-1.1.1g/
    ./config enable-shared -Wl,-rpath=\\\$\$ORIGIN:. --prefix=${Build_PATH}/3rdparty_unix/openssl/ --openssldir=${Build_PATH}/3rdparty_unix/openssl/
    make -j${BUILDTHREAD} && make install
    funCheckIsOk $? "OpenSSL 构建失败" "OpenSSL 构建完成."
fi

#编译Curl
if [ -d ${Build_PATH}/3rdparty_unix/curl ]; then
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
    cmake -G"Unix Makefiles" .. -DCMAKE_INSTALL_PREFIX="${Build_PATH}/3rdparty_unix/curl" -DCMAKE_BUILD_TYPE="Release" -DCMAKE_C_FLAGS="-fPIC" -Dpkgcfg_lib__OPENSSL_ssl="${Build_PATH}/3rdparty_unix/openssl/lib/libssl.so" -Dpkgcfg_lib__OPENSSL_crypto="${Build_PATH}/3rdparty_unix/openssl/lib/libcrypto.so" -DCURL_ZLIB=ON -DBUILD_TESTING=OFF -DZLIB_INCLUDE_DIR="${Build_PATH}/3rdparty_unix/zlib/include" -DZLIB_LIBRARY_RELEASE="${Build_PATH}/3rdparty_unix/zlib/lib/libz.so" -DCMAKE_MODULE_LINKER_FLAGS:STRING="-Wl,-rpath=\$ORIGIN:." -DCMAKE_SHARED_LINKER_FLAGS:STRING="-Wl,-rpath=\$ORIGIN:." -DCMAKE_EXE_LINKER_FLAGS:STRING="-Wl,-rpath=\$ORIGIN:\$ORIGIN/../lib:."
    funCheckIsOk $? "Curl cmake失败" "Curl cmake完成."
    make -j${BUILDTHREAD} && make install
    funCheckIsOk $? "Curl 构建失败" "Curl 构建完成."
fi

#编译GEOS
if [ -d ${Build_PATH}/3rdparty_unix/geos-3.6 ]; then
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
    cmake -G"Unix Makefiles" .. -DCMAKE_INSTALL_PREFIX="${Build_PATH}/3rdparty_unix/geos-3.6" -DCMAKE_BUILD_TYPE="Release" -DCMAKE_C_FLAGS="-fPIC" -DCMAKE_CXX_FLAGS="-fPIC" -DGEOS_ENABLE_INLINE=OFF -DGEOS_ENABLE_TESTS=OFF -DCMAKE_MODULE_LINKER_FLAGS:STRING="-Wl,-rpath=\$ORIGIN:." -DCMAKE_SHARED_LINKER_FLAGS:STRING="-Wl,-rpath=\$ORIGIN:." -DCMAKE_EXE_LINKER_FLAGS:STRING="-Wl,-rpath=\$ORIGIN/../lib:." 
    funCheckIsOk $? "GEOS cmake失败" "GEOS cmake完成."
    make -j${BUILDTHREAD} && make install
    funCheckIsOk $? "GEOS 构建失败" "GEOS 构建完成."
fi

#编译proj
if [ -d ${Build_PATH}/3rdparty_unix/proj ]; then
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
    cmake -G"Unix Makefiles" .. -DCMAKE_INSTALL_PREFIX="${Build_PATH}/3rdparty_unix/proj" -DCMAKE_BUILD_TYPE="Release" -DCMAKE_C_FLAGS="-fPIC" -DCMAKE_CXX_FLAGS="-fPIC" -DBUILD_TESTING=OFF -DPROJ4_TESTS=OFF -DCMAKE_MODULE_LINKER_FLAGS:STRING="-Wl,-rpath=\$ORIGIN:." -DCMAKE_SHARED_LINKER_FLAGS:STRING="-Wl,-rpath=\$ORIGIN:." -DCMAKE_EXE_LINKER_FLAGS:STRING="-Wl,-rpath=\$ORIGIN/../lib:." 
    funCheckIsOk $? "proj cmake失败" "proj cmake完成."
    make -j${BUILDTHREAD} && make install
    funCheckIsOk $? "proj 构建失败" "proj 构建完成."
fi

#编译GDAL
if [ -d ${Build_PATH}/3rdparty_unix/gdal244 ]; then
    echo -e "\033[32m OK: GDAL已经存在，跳过构建 \033[0m"
else
    funCheck3rdparty ${Build_PATH}/src/gdal-2.4.4.tar.gz
    mkdir -p ${Build_PATH}/build
    cp -r ${Build_PATH}/src/gdal-2.4.4.tar.gz ${Build_PATH}/build/
    cd ${Build_PATH}/build/
    tar -zxvf gdal-2.4.4.tar.gz
    cd gdal-2.4.4
    #先复制依赖库，否则配置或者编译容易出错
    mkdir -p .libs
    cp -r ${Build_PATH}/3rdparty_unix/proj/lib/* ${Build_PATH}/build/proj-4.9.3/src/
    cp -r ${Build_PATH}/3rdparty_unix/proj/lib/* .libs/
    cp -r ${Build_PATH}/3rdparty_unix/proj/lib/* apps/
    cp -r ${Build_PATH}/3rdparty_unix/geos-3.6/lib/* .libs/
    cp -r ${Build_PATH}/3rdparty_unix/geos-3.6/lib/* apps/
    cp -r ${Build_PATH}/3rdparty_unix/curl/lib/*.so .libs/
    cp -r ${Build_PATH}/3rdparty_unix/curl/lib/*.so apps/
    #开始构建
    ./configure --prefix=${Build_PATH}/3rdparty_unix/gdal244 --with-geos=${Build_PATH}/3rdparty_unix/geos-3.6/bin/geos-config --with-curl=${Build_PATH}/3rdparty_unix/curl/bin/curl-config --with-proj=${Build_PATH}/build/proj-4.9.3/src --with-png=internal --with-jpeg=internal --with-geotiff=internal --with-libtiff=internal --with-sqlite3=yes --with-pcre --without-python --without-java
    funCheckIsOk $? "GDAL 编译配置失败" "GDAL 编译配置完成."
    make LDFLAGS="-Wl,-rpath=\$\$ORIGIN:." -j${BUILDTHREAD} && make install
    funCheckIsOk $? "GDAL 构建失败" "GDAL 构建完成."
fi

#编译sanppy
if [ -d ${Build_PATH}/3rdparty_unix/sanppy ]; then
    echo -e "\033[32m OK: sanppy已经存在，跳过构建 \033[0m"
else
    funCheck3rdparty ${Build_PATH}/src/sanppy-1.1.8.tar.gz
    mkdir -p ${Build_PATH}/build
    cp -r ${Build_PATH}/src/sanppy-1.1.8.tar.gz ${Build_PATH}/build/
    cd ${Build_PATH}/build/
    tar -zxvf sanppy-1.1.8.tar.gz
    cd snappy-1.1.8
    mkdir build/
    cd build/
    cmake -G"Unix Makefiles" .. -DCMAKE_INSTALL_PREFIX="${Build_PATH}/3rdparty_unix/sanppy" -DCMAKE_BUILD_TYPE="Release" -DCMAKE_C_FLAGS="-fPIC" -DCMAKE_CXX_FLAGS="-fPIC" -DSNAPPY_BUILD_TESTS=OFF -DCMAKE_MODULE_LINKER_FLAGS:STRING="-Wl,-rpath=\$ORIGIN:." -DCMAKE_SHARED_LINKER_FLAGS:STRING="-Wl,-rpath=\$ORIGIN:." -DCMAKE_EXE_LINKER_FLAGS:STRING="-Wl,-rpath=\$ORIGIN/../lib:." 
    funCheckIsOk $? "sanppy cmake失败" "sanppy cmake完成."
    make -j${BUILDTHREAD} && make install
    funCheckIsOk $? "sanppy 构建失败" "sanppy 构建完成."
fi

#编译freetype
if [ -d ${Build_PATH}/3rdparty_unix/freetype ]; then
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
    #cmake -G"Unix Makefiles" .. -DCMAKE_INSTALL_PREFIX="${Build_PATH}/3rdparty_unix/freetype" -DCMAKE_BUILD_TYPE="Release" -DCMAKE_C_FLAGS="-fPIC" -DCMAKE_CXX_FLAGS="-fPIC" -DFT_WITH_ZLIB=ON -DZLIB_INCLUDE_DIR="${Build_PATH}/3rdparty_unix/zlib/include" -DZLIB_LIBRARY_RELEASE="${Build_PATH}/3rdparty_unix/zlib/lib/libz.so" -DCMAKE_MODULE_LINKER_FLAGS:STRING="-Wl,-rpath=\$ORIGIN:." -DCMAKE_SHARED_LINKER_FLAGS:STRING="-Wl,-rpath=\$ORIGIN:." -DCMAKE_EXE_LINKER_FLAGS:STRING="-Wl,-rpath=\$ORIGIN/../lib:." 
    cmake -G"Unix Makefiles" .. -DCMAKE_INSTALL_PREFIX="${Build_PATH}/3rdparty_unix/freetype" -DCMAKE_BUILD_TYPE="Release" -DCMAKE_C_FLAGS="-fPIC" -DCMAKE_CXX_FLAGS="-fPIC" -DFT_WITH_ZLIB=OFF -DCMAKE_MODULE_LINKER_FLAGS:STRING="-Wl,-rpath=\$ORIGIN:." -DCMAKE_SHARED_LINKER_FLAGS:STRING="-Wl,-rpath=\$ORIGIN:." -DCMAKE_EXE_LINKER_FLAGS:STRING="-Wl,-rpath=\$ORIGIN/../lib:." 
    funCheckIsOk $? "freetype cmake失败" "freetype cmake完成."
    make -j${BUILDTHREAD} && make install
    funCheckIsOk $? "freetype 构建失败" "freetype 构建完成."
fi

#编译Python
if [ -d ${Build_PATH}/3rdparty_unix/python ]; then
    echo -e "\033[32m OK: Python已经存在，跳过构建 \033[0m"
else
    funCheck3rdparty ${Build_PATH}/src/Python-3.8.6.tar.xz
    mkdir -p ${Build_PATH}/build
    cp -r ${Build_PATH}/src/Python-3.8.6.tar.xz ${Build_PATH}/build/
    cd ${Build_PATH}/build/
    tar -xvJf Python-3.8.6.tar.xz
    cd Python-3.8.6
    ./configure --enable-optimizations --enable-shared --prefix=${Build_PATH}/3rdparty_unix/python LDFLAGS="-Wl,-rpath=\$\$ORIGIN:\$\$ORIGIN/lib:.:../lib"
    funCheckIsOk $? "GDAL 编译配置失败" "GDAL 编译配置完成."
    make -j${BUILDTHREAD} && make install
    funCheckIsOk $? "GDAL 构建失败" "GDAL 构建完成."
fi

end_time=$(date +%s)
cost_time=$[ $end_time-$start_time ]
echo "全部工程构建完成，${BUILDTHREAD}线程编译，共耗时 $(($cost_time/60))min $(($cost_time%60))s"
