# Linux系统下的Qt的编译



## Linux下编译Qt

首先，linux下编译Qt需要先安装开发开发环境和编译过程中的开发库。开发库apt安装代码如下（其他包管理器请自行搜索包安装）：

```bash
#先装开发环境
sudo apt-get install build-essential
sudo apt-get install cmake cmake-qt-gui
#如果不用Clang编译，可以不装下面的llvm和clang
sudo apt-get install llvm clang
sudo apt-get install libclang-dev

#安装xcb及其开发库，这个很重要
sudo apt-get install libxcb-xkb-dev libxcb-xkb1 libxcb-util0 libxcb-glx0 libxcb-glx0-dev libx11-xcb1 libx11-xcb-dev 
#安装xkbcommon及其开发库
sudo apt-get install libxkbcommon-dev libxkbcommon-x11-dev libxkbcommon-x11-0 libxkbcommon0
#安装opengl开发库
sudo apt-get install libgl1-mesa-dev
#安装fontconfig开发库
sudo apt-get install fontconfig fontconfig-config libfontconfig1 libfontconfig1-dev
```

Linux下编译Qt，有几个非常重要的依赖：

- xcb：这个必须有，否则编译出来的Qt跑不起来

- fontconfig：这样也必须有，否则编译出来的Qt会缺少字体，必须自己带上字体文件并指定字体路径的环境变量，不能直接用系统字体。

- opengl：这个可以有。如果不需要opengl，可以在configure的时候显式指定不用OpenGL。

  

然后，下载源码，比如`qt-everywhere-src-5.12.10.tar.xz`，解压源码，并进入源码目录开始configure。

- -prefix：指定安装位置，改成自己电脑上的位置
- -release：只编译release版本
- -opengl desktop：使用桌面版的OpenGL
- -fontconfig：启用fontconfig，否则不能使用系统字体
- -xcb -xkbcommon：Linux下必须带，否则无法启动
- -ltcg：启用lto，GCC编译可以开启lto，但Clang编译不能带此参数

```bash
#设置自己机器上的LLVM位置，当然不设置也不会有问题，最多只是个警告而已
export LLVM_INSTALL_DIR=/usr/lib/llvm-7

#开始configure，使用GCC编译（linux-g++）
./configure -confirm-license -opensource -platform linux-g++ -release -ltcg -prefix "/home/xxx/Qt/Qt5.12.10/gcc_64" -qt-sqlite -qt-pcre  -plugin-sql-sqlite -qt-zlib -qt-libpng -qt-libjpeg -opengl desktop -qt-freetype -feature-freetype -fontconfig -qt-harfbuzz -no-qml-debug -no-angle -no-compile-examples -nomake tests -nomake examples -skip qtwebengine -skip qtwebview -xcb -xkbcommon
```



最后，当configure提示没有错误的时候，执行编译即可。

```
make
make install
```

*提示：*  很多文档都使用-j参数多线程编译，速度快很多。但是我发现多线程编译的时候，貌似pch相关的内容会出错，还找不到原因。所以还是单线程慢慢编译吧，稳定。



**注意：**  如果使用Clang编译Qt，有些问题需要注意，开始configure前，先要设置好CC和CXX环境变量为clang所在位置，然后在开始configure。

```bash
#设置CC和CXX位置，根据自己机器的情况设置
export CC=/usr/bin/clang
export CXX=/usr/bin/clang++
export LLVM_INSTALL_DIR=/usr/lib/llvm-7
```

configure的时候跟GCC基本一样，但是-platform换成了linux-clang。同时需要注意的是，跟GCC编辑的configure参数相比，没有了-ltcg。

**注意：**  我发现用Clang编译Qt时，不能用lto，否则信号槽会在连接的时候被lto优化掉，导致信号槽完全没有效果。-ltcg参数就是开启lto的。这一点在GCC上没有问题，因此编译的时候默认带上了-ltcg，Clang编译就要去掉。

```bash
./configure -confirm-license -opensource -platform linux-clang -release -ltcg -prefix "/home/xxx/Qt/Qt5.12.10/clang_64" -qt-sqlite -qt-pcre  -plugin-sql-sqlite -qt-zlib -qt-libpng -qt-libjpeg -opengl desktop -qt-freetype -feature-freetype -fontconfig -qt-harfbuzz -no-qml-debug -no-angle -no-compile-examples -nomake tests -nomake examples -skip qtwebengine -skip qtwebview -xcb -xkbcommon
```



**注意：**  对于使用`Fcitx`输入法的系统，编译出来的Qt可能不能输入中文（缺少一个插件）。如果需要输入中文，应该自行下载编译[fcitx-qt5]( https://github.com/fcitx/fcitx-qt5 )项目。

 fcitx-qt5使用CMake编译即可，编译前需要安装其开发库`sudo apt-get install libfcitx-qt5-dev`。

这个工程make完了不需要install，直接在编译目录下找到文件`platforminputcontext/libfcitxplatforminputcontextplugin.so`，将这个so库拷贝到Qt的`plugins/platforminputcontexts`下就可以了。



## Linux下编译Qt Creator

Qt Creator的编译相较Qt的编译简单多了，可以参考其[官方说明文档](https://wiki.qt.io/Building_Qt_Creator_from_Git)。

不管用GCC还是Clang编译Qt Creator，貌似都需要安装llvm、clang、libclang-dev等开发库，并且对版本还是有要求的。我的机器上clang版本是7.0，只能编译`qt-creator-opensource-src-4.9.2.tar.xz`，再高的版本就需要clang 8.0以上版本了。

编译Qt Creator的Qt需要有script 库，即lib文件夹下有`libQt5Script.so`文件。这个库在Qt里被标记为了废弃，但Qt Creator的编译还要用到。

先设置编译环境：

```bash
#先将Qt加入环境变量
export PATH=/home/xxx/Qt/Qt5.12.10/clang_64/bin:$PATH

#设置LLVM的位置，这个必须根据自己机器情况设置
export LLVM_INSTALL_DIR=/usr/lib/llvm-7

#如果使用Clang编译，要设置CC和CXX。GCC编译不用设置
export CC=/usr/bin/clang
export CXX=/usr/bin/clang++
```

解压源码，编译。将源代码解压到目录`qt-creator-opensource-src-4.9.2`，然后在其同级建立build文件夹

```bash
mkdir -p build
cd build
qmake ../qt-creator-opensource-src-4.9.2/qtcreator.pro

make qmake_all #配置makefile
make  #开始漫长的编译过程
```

编译完毕后，可以安装到指定的路径下：

```bash
#设置自己的Qt Creator的安装路径
export INSTALL_DIRECTORY=/home/uos/Qt/Qt5.12.10/QtCreator
make install INSTALL_ROOT=$INSTALL_DIRECTORY
```

安装完毕后，share目录下有desktop文件和图标，可自行修改后放到系统路径下，就可以在应用程序列表里启动Qt Creator了。



## Linux下编译PySide2

PySide2的编译比较简单，文档也比较详细。下载源码PySide2的源码，例如`pyside-setup-opensource-src-5.14.2.3.tar.xz`，解压后会看到一个setup.py文件，全部的编译说明都在这个文件当中，可以打开文件查看其英文的编译说明。

设置Python环境。这里我用的是自己编译的Python，如果使用系统Python，需要自行安装Python的开发库。

```bash
#设置自定义的Python环境，如果不需要自定义的Python环境，则不需要下面的配置
export MY_PTHON_PATH=/home/xxx/code/others/3rdparty_unix/python
export LD_LIBRARY_PATH=${MY_PTHON_PATH}/lib:$LD_LIBRARY_PATH
export PATH=${MY_PTHON_PATH}/bin:$PATH
```

设置编译器环境

```bash
#如果使用Clang编译，需设置CC和CXX，如果GCC编译则不需要设置
export CC=/usr/bin/clang
export CXX=/usr/bin/clang++

#设置LLVM_INSTALL_DIR路径，这个必须有
export LLVM_INSTALL_DIR=/usr/lib/llvm-7
```



开始编译PySide2。

- --qmake：指定qmake路径，必须
- --cmake：指定cmake路径，必须
- --openssl：指定OpenSSL路径，也可以使用系统的
- --ignore-git：忽略git，我下载的是源码，不需要git下载源码
- --module-subset：明确指定需要编译哪些Qt子模块，没列出来的不编译出来
- --skip-modules：明确指定不编译的模块
- --rpath：指定运行时的搜索路径

```bash
python3 setup.py build --qmake=/home/xxx/Qt/Qt5.12.10/clang_64/bin/qmake --cmake=/usr/bin/cmake --openssl=/home/xxx/code/others/3rdparty_unix/openssl/bin --ignore-git --module-subset=Core,Gui,Widgets,Sql,Xml --skip-docs --skip-modules=3DAnimation,3DCore,3DExtras,3DInput,3DLogic,3DRender,WebEngine,WebChannel,WebEngineCore,WebEngineWidgets,QtWebKit,QtWebKitWidgets,QtWebSockets  --rpath=\$ORIGIN:\$ORIGIN/../lib
```



编译完成后，可以安装文档里说的install到Python环境中，也可以自行拷贝到自己的Python中。

因为我需要自定义，所以用的是自行拷贝的办法。编译完成后，会有个pyside3_install目录，目录下面有个按照编译环境命令的文件夹，里面还有个lib文件夹，可看到几个so文件和site-packages文件加，这些拷贝到Python对应的目录下即可。



