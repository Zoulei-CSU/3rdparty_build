# 部分第三方开源库的编译脚本

## 1.简介

这里记录的一些第三方开源库的编译脚本，主要是在Linux下编译Linux和Android上使用的库，有：

- Curl：7.72.0
- GDAL：2.4.4
- GEOS：3.6.4
- Proj4：4.9.3
- Snappy：1.1.8
- Python：3.6.8
- quazip

脚本中有说明可以按照需要修改。

直接运行脚本肯定是会失败的，需要打开脚本文件，将其中设置路径的部分修改为自己机器上的路径。



## 2.编译环境说明

### 编译环境（待补充）



### 常用编译参数说明（个人理解，不一定准确）

`-fPIC` 编译连接都要带上这个，否则不能连接到动态库，只能连接到可执行程序。

`-flto -fno-fat-lto-objects` 开启连接时优化。当使用Clang编译Qt时，不能带这个，貌似带上后信号槽就失效了。

`-Wl,-rpath=\$ORIGIN:.` 设置rpath，把当前目录加入搜索路径，Linux上执行的时候就可以从本地加载动态库了。但是在Android上无效。

`-Wl,-Bsymbolic -Wl,-Bsymbolic-functions` 优先使用模块内的全局符号定义。由于Linux默认全局共享符号，导致一个应用程序下多个模块间不能有相同的变量名或者类名，否则会导致混乱。例如 libA.so模块定义了func函数，libB.so模块也定义了一个func函数，这个两个函数不一样，即使他们都没有导出，当加载到同一个应用程序下，不管在什么地方调用func，指不定运行的是哪个。不过，优先使用本地貌似还不保险，最好用`-fvisibility=hidden -fvisibility-inlines-hidden`把默认导出关掉，需要导出的自己加导出符号。

`-fvisibility=hidden -fvisibility-inlines-hidden` 同上所述。

`-Wl,--enable-new-dtags`  貌似加了这个，上面设置了rpath的话，rpath依然能被LD_LIBRARY_PATH覆盖。

`-fuse-ld=gold`  没搞明白啥意思，但Linux上用Clang编译都带了。



## 3.源码说明

[src](./src)文件夹下存放了开源库的源码压缩包，目的是可以不用导出去下载源码包了。

非开源文件的源码没有上传，太大的源码包也没有上传，比如Python。

Python源码包可以去官网下载，脚本中用的是[Python-3.8.6.tar.xz](https://www.python.org/ftp/python/3.8.6/Python-3.8.6.tar.xz)，可以按照需求修改。

源码包`zlib-android.tar.gz`其实是从NDK中提取出来的，`openssl-android.tar.gz`源码包是从[android_openssl](https://github.com/KDAB/android_openssl)项目里编译出来的。





## 4.其他

[Linux下的Qt编译](./Linux下的Qt编译.md)

