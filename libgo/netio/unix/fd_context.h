#pragma once
#include "../../common/config.h"
#include "reactor_element.h"

namespace co {

class FdContext;
typedef std::shared_ptr<FdContext> FdContextPtr;

enum class eFdType : uint8_t {
    eSocket,
    ePipe,
};
const char *FdType2Str(eFdType fdType);

struct SocketAttribute {
    int domain_ = -1;
    int type_ = -1;
    int protocol_ = -1;

    SocketAttribute() {}
    SocketAttribute(int domain, int type, int protocol)
        : domain_(domain), type_(type), protocol_(protocol) {}
    bool Initialized() const noexcept { return domain_ != -1; }
};

template <typename R, typename F, typename... Args>
static R CallWithoutINTR(F f, Args &&...args) {
retry:
    R res = f(std::forward<Args>(args)...);
    if (res == -1 && errno == EINTR) goto retry;
    return res;
}

class FdContext : public ReactorElement {
  public:
    explicit FdContext(int fd, eFdType fdType, bool isNonBlocking, SocketAttribute sockAttr);

    bool IsTcpSocket() const noexcept;

    // bool IsSocket() const noexcept;
    ALWAYS_INLINE bool IsSocket() const noexcept { return fdType_ == eFdType::eSocket; }

    // bool IsNonBlocking() const noexcept;
    ALWAYS_INLINE bool IsNonBlocking() const noexcept { return isNonBlocking_; }

    // void SetTcpConnectTimeout(int milliseconds);
    ALWAYS_INLINE void SetTcpConnectTimeout(int milliseconds) { tcpConnectTimeout_ = milliseconds; }

    // int GetTcpConnectTimeout();
    ALWAYS_INLINE int GetTcpConnectTimeout() { return tcpConnectTimeout_; }

    long GetSocketTimeoutMicroSeconds(int timeoutType);

    ALWAYS_INLINE SocketAttribute GetSocketAttribute() const { return sockAttr_; }

  public:
    void OnSetNonBlocking(bool isNonBlocking);

    void OnSetSocketTimeout(int timeoutType, int microseconds);

    FdContextPtr Clone(int newFd);

    void OnClose();

  public:
    bool SetNonBlocking(bool isNonBlocking);

  private:
    int fd_;
    eFdType fdType_;
    SocketAttribute sockAttr_;
    bool isNonBlocking_;
    int tcpConnectTimeout_;
    long recvTimeout_;
    long sendTimeout_;
};

}  // namespace co
