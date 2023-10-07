#pragma once
#include <exception>
#include <string>
#include <system_error>

namespace co {

enum class eCoErrorCode : int {
  ec_ok = 0,
  ec_mutex_double_unlock,
  ec_block_object_locked,
  ec_block_object_waiting,
  ec_yield_failed,
  ec_swapcontext_failed,
  ec_makecontext_failed,
  ec_iocpinit_failed,
  ec_protect_stack_failed,
  ec_std_thread_link_error,
  ec_disabled_multi_thread,
};

class co_error_category : public std::error_category {
public:
  virtual const char *name() const noexcept override;

  virtual std::string message(int) const override;
};

const std::error_category &GetCoErrorCategory();

std::error_code MakeCoErrorCode(eCoErrorCode code);

void ThrowError(eCoErrorCode code);

class co_exception : public std::exception {
public:
  co_exception();
  explicit co_exception(std::string const &errMsg);

  const char *what() const noexcept override { return errMsg_.c_str(); }

private:
  std::string errMsg_;
};

void ThrowException(std::string const &errMsg);

} // namespace co
