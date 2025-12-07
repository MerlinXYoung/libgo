# libgo

[![Build Status](https://travis-ci.org/yyzybb537/libgo.svg?branch=master)](https://travis-ci.org/yyzybb537/libgo)

### libgo -- 协程库和并行编程库

libgo 是一个用 C++ 11 编写的支持协作调度的栈式协程库，同时也是一个强大且易于使用的并行编程库。

目前支持三个平台：

-   Linux
-   macOS
-   Windows（Win7 或更高版本，x86 或 x64，使用 VS2015/2017 编译）

使用 libgo 编写多线程程序，可以像 golang 和 Erlang 并发语言一样快速且逻辑清晰，同时具有 C++ 原生的性能优势。让你可以鱼与熊掌兼得。

## libgo 特性

1.  **提供类似 golang 的强大协议**：基于协程编写代码，可以用同步方式编写简单代码，同时实现异步性能。

2.  **支持海量协程**：创建 100 万个协程仅需 4.5GB 物理内存（来自真实测试数据，在无刻意压缩栈的情况下）。

3.  **支持多线程调度协议**：提供高效的负载均衡策略和同步机制，便于编写高效的多线程程序。

4.  **调度线程数量支持动态扩展**：不存在因调度缓慢而导致的头阻塞问题。

5.  **使用 hook 技术**：使链接进程中的同步第三方库变为异步调用，极大提升性能。无需担心某些数据库驱动不提供异步驱动，如 hiredis 和 mysqlclient，可以直接使用这些客户端驱动，并获得与异步驱动相当的性能。

6.  **同时支持动态链接和完全静态链接**：便于使用 C++ 11 静态链接生成可执行文件并部署到低层 Linux 系统。

7.  **提供 Channel、Co_mutex、Co_rwmutex、timer 等特性**：帮助用户更轻松地编写程序。

8.  **支持协程的局部变量（CLS）**：完全覆盖 TLS 的所有场景（详见教程代码 sample13_cls.cpp）。

## 解决阻塞问题

过去两年的用户反馈表明，许多开发者的项目采用异步非阻塞模型（可能基于 epoll、libuv 或 ASIO 网络库），然后需要访问如 MySQL 等不提供异步驱动的数据库。在高并发场景下，传统的连接池和线程池方案资源密集（每个连接对应一个线程以获得最佳性能。数千次线程上下文切换的指令周期密集，过多活跃线程将导致操作系统调度能力急剧下降，这对许多开发者来说是不可接受的）。

在这种情况下，如果我们想使用 libgo 解决非阻塞模型中的阻塞操作问题，无需重构现有代码。新的 libgo 3.0 为此场景创建了三个特殊工具，可以无侵入性地解决这个问题：具有隔离运行环境和易于交互的多调度器（详见教程代码 sample1_go.cpp），libgo 可以替代传统的线程池方案（详见教程代码 sample10_co_pool.cpp 和 sample11_connection_pool.cpp）。

**教程目录包含许多教程代码，包括详细说明，让开发者可以逐步学习 libgo 库。**

## 编译和使用 libgo

### 方式一：Vcpkg

如果已安装 vcpkg，可以直接使用 vcpkg 安装：
```bash
$ vcpkg install libgo
```

### 方式二：Linux

#### 1. 使用 cmake 编译安装：
```bash
$ mkdir build
$ cd build
$ cmake ..
$ make debug     # 如果不需要调试版本，可跳过此步骤
$ sudo make uninstall
$ sudo make install
```

#### 2. 动态链接到 glibc：（将 libgo 放在链接列表前面）
```bash
g++ -std=c++11 test.cpp -llibgo -ldl [-lother_libs]
```

#### 3. 完全静态链接：（将 libgo 放在链接列表前面）
```bash
g++ -std=c++11 test.cpp -llibgo -Wl,--whole-archive -lstatic_hook -lc -lpthread -Wl,--no-whole-archive [-lother_libs] -static
```

### 方式三：Windows（3.0 兼容 Windows，直接使用 master 分支！）

0. 在 Windows 上使用 GitHub 下载代码时，必须注意换行符问题。请正确安装 git（使用默认选项）并使用 git clone 下载源代码（不要下载压缩包）。

1. 使用 CMake 构建项目：
```bash
# 例如 vs2015(x64)：
$ cmake .. -G"Visual Studio 14 2015 Win64"

# 例如 vs2015(x86)：
$ cmake .. -G"Visual Studio 14 2015"
```

2. 如果要执行测试代码，请链接 boost 库。并在 cmake 参数中设置 BOOST_ROOT：
```bash
# 例如：
$ cmake .. -G"Visual Studio 14 2015 Win64" -DBOOST_ROOT="e:\\boost_1_69_0"
```

---

## 🚀 XMake 构建方式（推荐）

XMake 提供了更简洁高效的构建方式，完全兼容 CMake 的所有功能。

### 基本用法

```bash
# 默认构建（静态库，Release模式）
xmake

# 构建动态库
xmake config --build_dynamic=y && xmake

# 启用调试器支持
xmake config --enable_debugger=y && xmake

# 禁用网络Hook
xmake config --disable_hook=y && xmake
```

### 🎯 库大小优化（新特性）

XMake 现在支持灵活的 static_hook 配置：

```bash
# 默认配置：包含 static_hook（推荐大多数用户）
xmake f --include_static_hook=y
xmake

# 优化配置：不包含 static_hook（推荐对大小敏感的项目）
xmake f --include_static_hook=n  
xmake
```

#### 优化效果对比

| 配置 | 主库大小 | 适用场景 | 使用建议 |
|------|----------|----------|----------|
| `--include_static_hook=y` | ~14M | 大多数应用、快速开发 | ✅ 默认推荐 |
| `--include_static_hook=n` | ~13M | 嵌入式、内存敏感应用 | ⚡ 优化推荐 |

### 构建模式切换

```bash
xmake f -m debug    # Debug模式
xmake f -m release  # Release模式
xmake f -m profile  # Profile模式
```

### 自定义任务

```bash
xmake debug     # 切换到debug模式并构建
xmake release   # 切换到release模式并构建
xmake profile   # 切换到profile模式并构建
```

### 生成的库文件

#### Linux/macOS
- `build/linux/x86_64/release/liblibgo.a` - 主静态库
- `build/linux/x86_64/release/libstatic_hook.a` - 静态Hook库（可选）
- `build/linux/x86_64/release/liblibgo.so` - 动态库（如果启用）

### 编译选项
- **C++标准**: C++11
- **编译标志**: `-fPIC -fno-strict-aliasing -Wall -Wno-nonnull-compare`
- **链接库**: `pthread`, `dl`

### 使用示例

编译使用libgo的程序：
```bash
g++ -std=c++11 your_program.cpp -Lbuild/linux/x86_64/release -llibgo -lpthread -ldl -I.
```

完整静态链接：
```bash
g++ -std=c++11 your_program.cpp -Lbuild/linux/x86_64/release -llibgo -Wl,--whole-archive -lstatic_hook -lc -lpthread -Wl,--no-whole-archive -static
```

### 清理和安装

```bash
xmake clean    # 清理构建文件
xmake clean --all  # 清理所有文件
sudo xmake install  # 安装到系统目录
```

## 性能表现

像 golang 一样，libgo 实现了完整的调度器（用户只需创建协程，无需关心协程的执行、挂起和资源回收）。因此，libgo 有资格在单线程性能方面与 golang 进行比较（在不同能力的场景下不适合进行性能比较）。

<img width="400" src="imgs/switch_cost.png"/>

测试环境：
2018 年 13 英寸 MAC 笔记本（CPU 最低功耗）
操作系统：Mac OSX
CPU：2.3 GHz Intel Core i5（4 核 8 线程）
测试脚本：`$test/golang/test.sh thread_number`

<img width="600" src="imgs/switch_speed.png"/>

## 注意事项（WARNING）

应尽可能避免依赖 TLS 实现的 TLS 或非重入库函数。如果不可避免地要使用，我们应该注意在协程切换后停止访问切换前生成的 TLS 数据。

## 可能导致协程切换的几种行为

- 用户调用 `co_yield` 主动放弃 CPU 时间片
- 竞争协同锁、Channel 读写
- Sleep 系列系统调用
- 等待事件触发的系统调用，如 `poll`、`select`、`epoll_wait`
- DNS 相关系统调用（`gethostbyname` 系列）
- 阻塞套接字上的 `connect`、`accept`、数据读写操作
- 管道上的数据读写操作

## Linux 系统上的 Hook 系统调用列表

### 阻塞系统调用
以下系统调用都是可能导致阻塞的系统调用。在协程中，整个线程不再被阻塞。在阻塞等待期间，CPU 可以切换到其他协程执行。通过 HOOK 在原生线程中执行的系统调用与原始系统调用的行为 100% 一致，没有任何变化。

```
connect
read
readv
recv
recvfrom
recvmsg
write
writev
send
sendto
sendmsg
poll
__poll
select
accept
sleep
usleep
nanosleep
gethostbyname
gethostbyname2
gethostbyname_r
gethostbyname2_r
gethostbyaddr
gethostbyaddr_r
```

### 非阻塞系统调用
以下系统调用不会导致阻塞，虽然也被 Hook，但不会完全改变其行为，仅用于跟踪套接字选项和状态。

```
socket
socketpair
pipe
pipe2
close
__close
fcntl
ioctl
getsockopt
setsockopt
dup
dup2
dup3
```

## Windows 系统上的 Hook 系统调用列表

```
ioctlsocket
WSAIoctl
select
connect
WSAConnect
accept
WSAAccept
WSARecv
recv
recvfrom
WSARecvFrom
WSARecvMsg
WSASend
send
sendto
WSASendTo
WSASendMsg
```

## 贡献和反馈

如果你发现任何 bug、好的建议或使用歧义，可以提交 issue 或直接联系作者：

邮箱：289633152@qq.com

## 许可证

MIT License

---

*libgo 项目持续维护中，欢迎提交 PR 和 Issue！*