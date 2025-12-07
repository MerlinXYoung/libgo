# libgo 详细文档

## 概述

libgo 是一个用 C++11 编写的支持协作调度的栈式协程库，同时也是一个强大且易于使用的并行编程库。它提供了类似 golang 的协程编程体验，同时保持 C++ 原生性能优势。

### 项目基本信息
- **版本**: 3.2.4
- **许可证**: MIT License
- **语言**: C++11
- **支持平台**: Linux、macOS、Windows (Win7+)
- **GitHub**: https://github.com/yyzybb537/libgo

## 核心特性

### 1. 协程支持
- **海量协程**: 支持 100 万个协程仅需 4.5GB 物理内存
- **栈式协程**: 基于栈的协程实现，支持完整函数调用链
- **调度策略**: 多线程调度，支持负载均衡
- **动态扩展**: 调度线程数量支持动态扩展，避免阻塞

### 2. 网络Hook技术
- **同步转异步**: 通过Hook技术使同步第三方库变为异步调用
- **系统调用覆盖**: 覆盖常见的阻塞系统调用
- **无侵入性**: 无需修改现有代码即可获得异步性能

### 3. 并发原语
- **Channel**: 类似 golang 的协程间通信机制
- **协程锁**: Co_mutex、Co_rwmutex 等协程友好锁
- **定时器**: 高精度协程定时器
- **条件变量**: 协程专用条件变量

### 4. 高级功能
- **协程局部存储(CLS)**: 完全覆盖TLS场景
- **延迟执行**: defer 机制
- **连接池**: 高效的协程连接池
- **调试支持**: 协程调试和监听器

## 架构设计

### 核心组件架构

```
libgo/
├── scheduler/          # 调度器模块
│   ├── scheduler.h/cpp     # 主调度器
│   ├── processer.h/cpp     # 协程处理器
│   └── ref.h              # 引用管理
├── context/            # 上下文切换
│   ├── context.h/cpp       # 协程上下文
│   ├── fcontext.h/cpp      # 底层上下文切换
│   └── [汇编文件]          # 平台相关汇编代码
├── routine_sync/       # 协程同步原语
│   ├── channel.h           # Channel实现
│   ├── mutex.h             # 协程互斥锁
│   ├── shared_mutex.h      # 协程读写锁
│   ├── condition_variable.h # 条件变量
│   └── timer.h             # 定时器
├── netio/              # 网络IO Hook
│   ├── unix/               # Unix/Linux平台实现
│   ├── windows/            # Windows平台实现
│   └── disable_hook/       # 无Hook版本
├── sync/               # 简化的同步接口
├── timer/              # 定时器模块
├── cls/                # 协程局部存储
├── defer/              # 延迟执行
├── pool/               # 连接池和协程池
├── debug/              # 调试模块
└── common/             # 公共组件
```

### 调度器设计

#### Scheduler (调度器)
- **职责**: 管理多个调度线程，负责协程的创建、调度和销毁
- **特性**: 
  - 支持1到N个调度线程
  - 负载均衡和协程窃取
  - 动态线程扩展
  - 阻塞检测和处理

#### Processer (处理器)
- **职责**: 执行具体的协程任务
- **特性**:
  - 每个处理器运行独立线程
  - 维护协程执行队列
  - 处理协程切换和调度

#### Context (上下文)
- **职责**: 管理协程的执行上下文
- **实现**: 基于Boost.Context的优化版本
- **特性**:
  - 栈内存管理
  - 上下文快速切换
  - 栈保护机制

## API参考

### 基础API

#### 协程创建
```cpp
// 基本创建
go []{
    // 协程执行代码
};

// 带栈大小
go_stack(1024*1024) []{
    // 1MB栈大小
};

// 带调度器
co_scheduler(pScheduler) []{
    // 指定调度器
};
```

#### 协程控制
```cpp
// 让出CPU
co_yield;

// 协程睡眠
co_sleep(1000);  // 1秒

// 检查是否在协程中
bool isInCoroutine = co_sched.IsCoroutine();
```

### 同步原语

#### Channel (通道)
```cpp
// 创建channel
co_chan<int> ch;          // 无缓冲
co_chan<int> ch(10);     // 缓冲大小10

// 写入
ch << 42;

// 读取
int value;
ch >> value;

// select操作 (伪代码)
// select {
//   case ch << value:
//     // 写入成功
//   case ch >> value:
//     // 读取成功
// }
```

#### 协程锁
```cpp
co_mutex mtx;           // 协程互斥锁
co_rwmutex rwmtx;       // 协程读写锁

// 使用
std::lock_guard<co_mutex> lock(mtx);
```

#### 定时器
```cpp
co_timer timer;

// 一次性定时器
auto timerId = timer.ExpireAt(std::chrono::seconds(5), []{
    printf("Timer fired!\n");
});

// 取消定时器
timerId.StopTimer();
```

### 网络Hook

libgo自动Hook以下系统调用:

#### Linux/Unix
**阻塞调用**:
- `connect/read/write/send/recv`
- `poll/select/epoll_wait`
- `sleep/usleep/nanosleep`
- `gethostbyname*` 系列DNS调用

**非阻塞调用**:
- `socket/socketpair/pipe`
- `close/fcntl/ioctl`
- `getsockopt/setsockopt`

#### Windows
- `WSAConnect/WSAAccept`
- `WSARecv/WSASend`
- `select/WSAIoctl`

### 高级功能

#### 协程局部存储(CLS)
```cpp
// 定义CLS变量
co_cls(MyType, initialValue);

// 访问CLS
auto& cls = co_cls_ref(MyType);
```

#### 延迟执行
```cpp
co_defer {
    printf("This will be executed when function exits\n");
};
```

#### 连接池
```cpp
// 创建连接池
ConnectionPool<DatabaseConnection> pool;
pool.Init(10, []{ 
    return std::make_shared<DatabaseConnection>(); 
});

// 使用连接
auto conn = pool.GetConnection();
// 使用连接...
```

## 编译和构建

### CMake构建
```bash
mkdir build && cd build
cmake ..
make

# 调试版本
make debug

# 安装
sudo make install
```

### XMake构建 (推荐)
```bash
# 基本构建
xmake

# 选项配置
xmake config --build_dynamic=y    # 构建动态库
xmake config --enable_debugger=y  # 启用调试器
xmake config --disable_hook=y     # 禁用网络Hook
xmake config --include_static_hook=n  # 优化库大小

# 构建模式
xmake debug    # Debug模式
xmake release  # Release模式
xmake profile  # Profile模式
```

### 编译选项
- **C++标准**: C++11
- **编译标志**: `-fPIC -fno-strict-aliasing -Wall`
- **链接库**: `pthread`, `dl`

## 使用示例

### 基本协程使用
```cpp
#include "coroutine.h"

int main() {
    // 创建协程
    go [] {
        printf("Hello from coroutine 1\n");
    };
    
    go [] {
        printf("Hello from coroutine 2\n");
    };
    
    // 启动调度器
    co_sched.Start();
    return 0;
}
```

### Channel通信
```cpp
#include "coroutine.h"

int main() {
    co_chan<int> ch;
    
    go [=] {
        ch << 42;  // 发送数据
    };
    
    go [=] {
        int value;
        ch >> value;  // 接收数据
        printf("Received: %d\n", value);
    };
    
    co_sched.Start();
    return 0;
}
```

### 网络服务器示例
```cpp
#include "coroutine.h"

void handle_client(int fd) {
    char buf[1024];
    while (true) {
        int n = read(fd, buf, sizeof(buf));
        if (n <= 0) break;
        write(fd, buf, n);
    }
    close(fd);
}

int main() {
    int listen_fd = socket(AF_INET, SOCK_STREAM, 0);
    // ... 绑定和监听
    
    while (true) {
        int client_fd = accept(listen_fd, nullptr, nullptr);
        go handle_client(client_fd);  // 为每个客户端创建协程
    }
    
    return 0;
}
```

## 性能特性

### 内存使用
- **100万协程**: 约4.5GB物理内存
- **默认栈大小**: 128KB (可配置)
- **栈保护**: 支持保护页机制

### 调度性能
- **切换开销**: 与golang相当
- **负载均衡**: 智能协程窃取
- **阻塞检测**: 自动检测和处理协程阻塞

### Hook性能
- **零拷贝**: 直接操作系统调用
- **透明转换**: 同步代码异步执行
- **兼容性**: 与原生API行为一致

## 最佳实践

### 1. 协程创建
- 优先使用lambda表达式
- 避免创建过多小协程
- 合理设置栈大小

### 2. 同步原语
- 优先使用Channel进行协程间通信
- 避免在协程中使用阻塞锁
- 合理使用定时器

### 3. 网络编程
- 充分利用Hook特性
- 避免混合使用异步和同步IO
- 注意DNS解析的阻塞行为

### 4. 错误处理
- 使用try-catch处理异常
- 注意协程间异常传播
- 合理使用defer进行清理

## 调试和诊断

### 调试器支持
```cpp
co_debugger.SetCurrentTaskDebugInfo("task description");
```

### 性能分析
- 使用Profile模式编译
- 利用协程ID进行追踪
- 监控协程切换次数

### 常见问题

1. **栈溢出**: 调整栈大小或优化递归深度
2. **死锁**: 检查锁的使用顺序
3. **性能问题**: 分析协程切换频率和阻塞时间

## 兼容性说明

### 平台差异
- **Linux**: 完整功能支持
- **macOS**: 支持kqueue事件模型
- **Windows**: 基于Fiber实现

### 编译器支持
- **GCC**: 4.8+
- **Clang**: 3.4+
- **MSVC**: 2015+

### 第三方依赖
- **Boost.Context**: 底层上下文切换
- **CMake**: 构建系统
- **XMake**: 推荐构建系统

## 路线图

### 当前版本 (3.2.4)
- 稳定的协程调度
- 完整的网络Hook
- 丰富的同步原语

### 未来计划
- 更多平台支持
- 性能优化
- 更多调试工具

## 社区和支持

- **GitHub Issues**: 报告bug和功能请求
- **邮件**: 289633152@qq.com
- **文档**: 参考tutorial目录下的示例代码

---

*本文档基于libgo 3.2.4版本编写，如有更新请参考最新源码。*