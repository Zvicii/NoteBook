# 交叉编译 Linux ARM64

## 背景介绍

Linux 全称 GNU/Linux，是一个开源的操作系统，一个基于 POSIX 的多用户环境，一个基于 UNIX 的类 UNIX 系统。

ARM Holdings 是位于英国的全球领先的半导体知识产权(IP)提供商。他们不直接生产和销售实际的芯片，主要通过向合作伙伴授权 IP 许可证盈利。我们常见的各种移动智能设备、智能消费电子产品的 CPU 一般都是采用 ARM 架构，目前 PC 市场上，Apple 自研的 M1 芯片也是基于 ARM 架构的。ARM64 处理器体系结构指的是运行在 AArch64 状态下的处理器体系结构。

目前在各个行业都在推进国产化，而大部分国产操作系统都是基于 Linux 内核开发，比如中标麒麟、银河麒麟、深度、UOS 等。大量国产芯片是 ARM 架构的，比如华为鲲鹏、飞腾等。这进一步加大了市场对 Linux ARM64 架构软件的需求。

而假如你需要为外部设备构建软件，比如没有操作系统或可用编译器的嵌入式设备、较低性能的设备(Raspberry Pi)或单纯是手头没有的设备，那这时候你就需要交叉编译。 交叉编译指在一个平台编译一个可执行文件或者一个库，然后在另一个平台上使用。

## 交叉编译原理

在开发过程中，我们使用高级语言比如 C++编写的代码被称为源代码，而源代码是无法直接运行的，必须通过如 msvc、gcc、clang 等编译器编译并链接成机器代码才能运行。

由于 CPU 架构、字节序、浮点数支持、ABI 接口等方面的差异，不同平台间的产物不能通用，也就是 native 语言为什么会有 write once, compile everywhere 这种说法了。

交叉编译本身的开发流程与本地编译基本没有区别，都是编写代码、编译、链接、输出产物。唯一的区别就是交叉编译生成的机器码并不能在编译平台执行，而是运行在另一个不同架构的平台上。我们称这种运行在平台 A 上而生成对应平台 B 产物的编译器为交叉编译器，即 cross compiler。

## 交叉编译工具链

目前 ARM 平台使用最广泛的工具链是由[Linaro](http://releases.linaro.org/components/toolchain/binaries/)发布的，可以看到该链接中包含了从 gcc4.9 到 gcc8 的交叉编译工具链。

同时他们声明后续的工具链将会通过[ARM 官方](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads)发布，最新的工具链都已经支持到了 gcc11.3。

## 环境配置

### Docker 安装

我们将使用 Docker 来搭建交叉编译环境，所以主机的操作系统可以是 Windows/Linux/MacOS 中的任意一个。如果您的操作系统是 Linux，且不介意修改环境配置，那可以跳过该步骤。

- 参考官方文档[安装 Docker Desktop](https://docs.docker.com/get-docker/)。
- 执行 `docker --help` 验证 docker 已经安装成功。
- 执行 `docker pull ubuntu:xenial` 安装 Ubuntu 16.04 容器。
  - 使用 ubuntu 16.04 的好处在于编译出的产物依赖的 glibc 版本较低(GLIBC2.23)，这样可以在在市面上绝大部分的 Linux 系统上运行。
- 执行 `docker run -it ubuntu:xenial` 启动容器。

### 工具链安装

- 更新软件源。

  ```bash
  > apt-get update
  ```

- 安装 cmake wget

  ```bash
  > apt-get install -y cmake wget
  ```

- 安装交叉编译工具链

  ```bash
  # 下载工具链，此处以gcc7.5版本为例
  > wget -c https://releases.linaro.org/components/toolchain/binaries/7.5-2019.12/aarch64-linux-gnu/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu.tar.xz
  # 安装到 /usr/local/toolchain/ 目录下，当然也可以放在其他任何你喜欢的地方
  > mkdir -p /usr/local/toolchain
  # 解压工具链
  > tar -xvf gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu.tar.xz -C /usr/local/toolchain
  # 查看是否安装成功
  > ls /usr/local/toolchain
  ```

- 配置工具链到环境变量
  如果您不想修改环境变量，可以跳过此步骤，通过 [CMAKE_TOOLCHAIN_FILE](https://cmake.org/cmake/help/latest/manual/cmake-toolchains.7.html#:~:text=In%20normal%20builds%2C%20CMake%20automatically%20determines%20the%20toolchain,Languages%20are%20enabled%20by%20the%20project%20%28%29%20command.) 指定工具链路径。

```bash
  > update-alternatives --install /usr/bin/aarch64-linux-gnu-gcc aarch64-linux-gnu-gcc /usr/local/toolchain/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-gcc 100
  > update-alternatives --install /usr/bin/aarch64-linux-gnu-g++ aarch64-linux-gnu-g++ /usr/local/toolchain/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-g++ 100
  > update-alternatives --install /usr/bin/aarch64-linux-gnu-gcov aarch64-linux-gnu-gcov /usr/local/toolchain/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-gcov 100
  > update-alternatives --install /usr/bin/aarch64-linux-gnu-gcov-dump aarch64-linux-gnu-gcov-dump /usr/local/toolchain/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-gcov-dump 100
  > update-alternatives --install /usr/bin/aarch64-linux-gnu-gcov-tool aarch64-linux-gnu-gcov-tool /usr/local/toolchain/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-gcov-tool 100
  > update-alternatives --install /usr/bin/aarch64-linux-gnu-ar aarch64-linux-gnu-ar /usr/local/toolchain/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-ar 100
  > update-alternatives --install /usr/bin/aarch64-linux-gnu-as aarch64-linux-gnu-as /usr/local/toolchain/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-as 100
  > update-alternatives --install /usr/bin/aarch64-linux-gnu-ld aarch64-linux-gnu-ld /usr/local/toolchain/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-ld 100
  > update-alternatives --install /usr/bin/aarch64-linux-gnu-ranlib aarch64-linux-gnu-ranlib /usr/local/toolchain/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-ranlib 100
  > update-alternatives --install /usr/bin/aarch64-linux-gnu-gfortran aarch64-linux-gnu-gfortran /usr/local/toolchain/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-gfortran 100
  > update-alternatives --install /usr/bin/aarch64-linux-gnu-strip aarch64-linux-gnu-strip /usr/local/toolchain/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-strip 100
  # check gcc&g++ version
  > aarch64-linux-gnu-gcc -v
  > aarch64-linux-gnu-g++ -v
  ```

- 使用 update-alternatives 可以很轻松的在不同的工具链间切换, 比如在 gcc7/8/9 之间切换:

  ```bash
  > apt install build-essential
  > apt -y install gcc-7 g++-7 gcc-8 g++-8 gcc-9 g++-9
  > update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 7
  > update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-7 7
  > update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 8
  > update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-8 8
  > update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 9
  > update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 9
  > update-alternatives --config gcc
  There are 3 choices for the alternative gcc (providing /usr/bin/gcc).

    Selection    Path            Priority   Status
  ------------------------------------------------------------
    0            /usr/bin/gcc-9   9         auto mode
    1            /usr/bin/gcc-7   7         manual mode
    2            /usr/bin/gcc-8   8         manual mode
  * 3            /usr/bin/gcc-9   9         manual mode
  Press <enter> to keep the current choice[*], or type selection number:
  ```
  
 ## 使用现成的 Conan docker 镜像

```bash
#run x86_64 docker image
docker run -d zvicii/gcc7-x86_64-ubuntu16.04-jenkins -url jenkins_url_here jenkins_agent_token Linux-x86_64-agent

#run ARM64 docker image
docker run -d zvicii/gcc7-arm64-ubuntu16.04-jenkins -url jenkins_url_here jenkins_agent_token Linux-arm64-agent
```

[gcc7-x86_64-ubuntu16.04-jenkins](https://hub.docker.com/repository/docker/zvicii/gcc7-x86_64-ubuntu16.04-jenkins)

- os: ubuntu16.04
- compiler: gcc7.5
- glibc: 2.23

```dockerfile
FROM conanio/gcc7-ubuntu16.04-jenkins

RUN sudo pip3 install --upgrade cmake
RUN sudo apt-get -q update
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
RUN sudo apt-get -q -y install nodejs openssh-client
RUN sudo apt-get -q -y install libgl1-mesa-dev libx11-dev libx11-xcb-dev libfontenc-dev libice-dev libsm-dev libxau-dev libxaw7-dev libxcomposite-dev libxcursor-dev libxdamage-dev libxdmcp-dev libxext-dev libxfixes-dev libxi-dev libxinerama-dev libxkbfile-dev libxmu-dev libxmuu-dev libxpm-dev libxrandr-dev libxrender-dev libxres-dev libxss-dev libxt-dev libxtst-dev libxv-dev libxvmc-dev libxxf86vm-dev xtrans-dev libxcb-render0-dev libxcb-render-util0-dev libxcb-xkb-dev libxcb-icccm4-dev libxcb-image0-dev libxcb-keysyms1-dev libxcb-randr0-dev libxcb-shape0-dev libxcb-sync-dev libxcb-xfixes0-dev libxcb-xinerama0-dev xkb-data libxcb-dri3-dev uuid-dev libxcb-util-dev
RUN mkdir ~/workspace
RUN sudo npm install @yxfe/nepublisher -g --registry=http://npm.netease.im/
RUN conan remote add NetEaseConan http://yunxin-conan.netease.im:8082/artifactory/api/conan/NetEaseConan

CMD sudo chown -R conan ~/workspace ~/.conan
```

[gcc7-arm64-ubuntu16.04-jenkins](https://hub.docker.com/repository/docker/zvicii/gcc7-arm64-ubuntu16.04-jenkins)

- os: ubuntu16.04
- compiler: linaro aarch64-linux-gnu gcc 7.5
- glibc: 2.23

```dockerfile
FROM conanio/gcc7-ubuntu16.04-jenkins

LABEL maintainer="zvicii@qq.com"

ENV CC=aarch64-linux-gnu-gcc \
    CXX=aarch64-linux-gnu-g++ \
    CMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
    CMAKE_CXX_COMPILER=aarch64-linux-gnu-g++ \
    STRIP=aarch64-linux-gnu-strip \
    RANLIB=aarch64-linux-gnu-ranlib \
    AS=aarch64-linux-gnu-as \
    AR=aarch64-linux-gnu-ar \
    LD=aarch64-linux-gnu-ld \
    FC=aarch64-linux-gnu-gfortran

RUN mkdir ~/aarch64-linux-gnu ~/workspace
RUN sudo wget -c https://releases.linaro.org/components/toolchain/binaries/7.5-2019.12/aarch64-linux-gnu/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu.tar.xz -O ~/aarch64-linux-gnu/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu.tar.xz
RUN sudo tar -xf ~/aarch64-linux-gnu/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu.tar.xz -C ~/aarch64-linux-gnu
RUN sudo wget -c https://releases.linaro.org/components/toolchain/binaries/6.5-2018.12/aarch64-linux-gnu/gcc-linaro-6.5.0-2018.12-x86_64_aarch64-linux-gnu.tar.xz -O ~/aarch64-linux-gnu/gcc-linaro-6.5.0-2018.12-x86_64_aarch64-linux-gnu.tar.xz
RUN sudo tar -xf ~/aarch64-linux-gnu/gcc-linaro-6.5.0-2018.12-x86_64_aarch64-linux-gnu.tar.xz -C ~/aarch64-linux-gnu
RUN sudo rm -rf /home/conan/aarch64-linux-gnu/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/aarch64-linux-gnu/libc
RUN sudo cp -r /home/conan/aarch64-linux-gnu/gcc-linaro-6.5.0-2018.12-x86_64_aarch64-linux-gnu/aarch64-linux-gnu/libc /home/conan/aarch64-linux-gnu/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/aarch64-linux-gnu
RUN sudo rm -rf /home/conan/aarch64-linux-gnu/gcc-linaro-6.5.0-2018.12-x86_64_aarch64-linux-gnu
RUN sudo update-alternatives --install /usr/bin/aarch64-linux-gnu-gcc aarch64-linux-gnu-gcc ~/aarch64-linux-gnu/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-gcc 100
RUN sudo update-alternatives --install /usr/bin/aarch64-linux-gnu-g++ aarch64-linux-gnu-g++ ~/aarch64-linux-gnu/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-g++ 100
RUN sudo update-alternatives --install /usr/bin/aarch64-linux-gnu-gcov aarch64-linux-gnu-gcov ~/aarch64-linux-gnu/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-gcov 100
RUN sudo update-alternatives --install /usr/bin/aarch64-linux-gnu-gcov-dump aarch64-linux-gnu-gcov-dump ~/aarch64-linux-gnu/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-gcov-dump 100
RUN sudo update-alternatives --install /usr/bin/aarch64-linux-gnu-gcov-tool aarch64-linux-gnu-gcov-tool ~/aarch64-linux-gnu/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-gcov-tool 100
RUN sudo update-alternatives --install /usr/bin/aarch64-linux-gnu-ar aarch64-linux-gnu-ar ~/aarch64-linux-gnu/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-ar 100
RUN sudo update-alternatives --install /usr/bin/aarch64-linux-gnu-as aarch64-linux-gnu-as ~/aarch64-linux-gnu/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-as 100
RUN sudo update-alternatives --install /usr/bin/aarch64-linux-gnu-ld aarch64-linux-gnu-ld ~/aarch64-linux-gnu/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-ld 100
RUN sudo update-alternatives --install /usr/bin/aarch64-linux-gnu-ranlib aarch64-linux-gnu-ranlib ~/aarch64-linux-gnu/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-ranlib 100
RUN sudo update-alternatives --install /usr/bin/aarch64-linux-gnu-gfortran aarch64-linux-gnu-gfortran ~/aarch64-linux-gnu/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-gfortran 100
RUN sudo update-alternatives --install /usr/bin/aarch64-linux-gnu-strip aarch64-linux-gnu-strip ~/aarch64-linux-gnu/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-strip 100
RUN conan profile new default --detect --force
RUN conan profile update settings.arch=armv8 default
RUN sudo pip3 install --upgrade cmake
RUN sudo apt-get -q update
RUN sudo curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
RUN sudo apt-get -q -y install nodejs openssh-client
RUN sudo apt-get -q -y install libgl1-mesa-dev libx11-dev libx11-xcb-dev libfontenc-dev libice-dev libsm-dev libxau-dev libxaw7-dev libxcomposite-dev libxcursor-dev libxdamage-dev libxdmcp-dev libxext-dev libxfixes-dev libxi-dev libxinerama-dev libxkbfile-dev libxmu-dev libxmuu-dev libxpm-dev libxrandr-dev libxrender-dev libxres-dev libxss-dev libxt-dev libxtst-dev libxv-dev libxvmc-dev libxxf86vm-dev xtrans-dev libxcb-render0-dev libxcb-render-util0-dev libxcb-xkb-dev libxcb-icccm4-dev libxcb-image0-dev libxcb-keysyms1-dev libxcb-randr0-dev libxcb-shape0-dev libxcb-sync-dev libxcb-xfixes0-dev libxcb-xinerama0-dev xkb-data libxcb-dri3-dev uuid-dev libxcb-util-dev
RUN sudo npm install @yxfe/nepublisher -g --registry=http://npm.netease.im/
RUN conan remote add NetEaseConan http://yunxin-conan.netease.im:8082/artifactory/api/conan/NetEaseConan

CMD sudo chown -R conan ~/workspace ~/.conan
```

## 交叉编译

- 创建 CMakeLists.txt 文件

  ```cmake
  cmake_minimum_required(VERSION 2.4)

  project(hello_world)

  add_executable(hello_world main.cpp)
  ```

- 创建 main.cpp 文件

  ```cpp
  #include <iostream>

  int main()
  {
      std::cout << "Hello World!\n";
      return 0;
  }
  ```

- 编译

  - 如果交叉编译工具链已经配置到环境变量，则可以直接执行 cmake 命令进行交叉编译

    ```bash
    > mkdir build
    > cd build
    > cmake -DCMAKE_BUILD_TYPE=Release ..
    > cmake --build . --config Release
    ```

  - 如果交叉编译工具链没有配置到环境变量，则需要通过 CMAKE_TOOLCHAIN_FILE 指定工具链路径

    - 创建 toolchain.cmake 文件

      ```cmake
      set(CMAKE_SYSTEM_NAME Linux)
      set(CMAKE_SYSTEM_PROCESSOR arm)

      set(TOOLCHAIN_PATH /usr/local/toolchain/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu)
      set(TOOLCHAIN_HOST_PREFIX ${TOOLCHAIN_PATH}/bin/aarch64-linux-gnu)

      set(CMAKE_C_COMPILER ${TOOLCHAIN_HOST_PREFIX}-gcc)
      set(CMAKE_CXX_COMPILER ${TOOLCHAIN_HOST_PREFIX}-g++)

      set(CMAKE_FIND_ROOT_PATH ${TOOLCHAIN_PATH})

      set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
      set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
      set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
      set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
      ```

    - 执行 cmake 命令

      ```bash
      > mkdir build
      > cd build
      > cmake -DCMAKE_TOOLCHAIN_FILE=../toolchain.cmake -DCMAKE_BUILD_TYPE=Release ..
      > cmake --build . --config Release
      ```

- 使用`file`或者`readelf`命令查看产物架构，可以看到 ARM aarch64 字样，说明交叉编译成功了

  ```bash
  > file build/hello_world
  build/hello_world: ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-aarch64.so.1, for GNU/Linux 3.7.0, BuildID[sha1]=e85c7d1533b88cc889cbba2b643628a52f164a3b, not stripped
  ```

  ```bash
  > readelf -h build/hello_world
  ELF Header:
    Magic:   7f 45 4c 46 02 01 01 00 00 00 00 00 00 00 00 00
    Class:                             ELF64
    Data:                              2's complement, little endian
    Version:                           1 (current)
    OS/ABI:                            UNIX - System V
    ABI Version:                       0
    Type:                              EXEC (Executable file)
    Machine:                           AArch64
    Version:                           0x1
    Entry point address:               0x4009d8
    Start of program headers:          64 (bytes into file)
    Start of section headers:          12248 (bytes into file)
    Flags:                             0x0
    Size of this header:               64 (bytes)
    Size of program headers:           56 (bytes)
    Number of program headers:         9
    Size of section headers:           64 (bytes)
    Number of section headers:         37
    Section header string table index: 36
  ```
