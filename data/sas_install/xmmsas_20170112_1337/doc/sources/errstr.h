// (c) 1997 European Space Agency - written by Marco Beijersbergen
//
// See Stroustrup, The C++ programming language, 3rd ed, 21.4.6.1

#ifndef errstr_h
#define errstr_h

#include <Error.h>

extern std::ostream& errstr;

class Sas {
  
 public:

  struct _fatal {
    _fatal(ErrorHandler::Code c) : code(c) {}
    ErrorHandler::Code code;
  };
  
  static inline _fatal fatal(ErrorHandler::Code code) { return _fatal(code); }
  
  static inline void fatal(ErrorHandler::Code code, const std::string& message)
    { errstr << message; errHandler.fatal(code); }
  
  
  struct _error {
    _error(ErrorHandler::Code c) : code(c) {}
    ErrorHandler::Code code;
  };
  
  static inline _error error(ErrorHandler::Code code) { return _error(code); }
  
  static inline void error(ErrorHandler::Code code, const std::string& message)
    { errstr << message; errHandler.error(code); }
  
  struct _warning {
    _warning(ErrorHandler::Code c) : code(c) {}
    ErrorHandler::Code code;
  };
  
  static inline _warning warning(ErrorHandler::Code code) { return _warning(code); }
  
  static inline void warning(ErrorHandler::Code code, const std::string& message)
    { errstr << message; errHandler.warning(code); }
  
  
  struct _msg : public Msg {
    _msg(Layer l, Verbosity v) : layer(l), level(v) {}
    _msg(Verbosity v) : layer(App), level(v) {} // Backwards compat.
    Layer layer;
    Verbosity level;
  };
  
  
  static inline _msg message(Msg::Layer layer, Msg::Verbosity level)
    { return _msg(layer,level); }
  
  static inline void message(Msg::Layer layer, Msg::Verbosity level, const std::string& message)
    { errstr << message; errHandler.message(layer,level); }
  
};


inline std::ostream& operator<<(std::ostream& os, const Sas::_fatal m)
{ errHandler.fatal(m.code); return os; }
  
inline std::ostream& operator<<(std::ostream& os, const Sas::_error e)
{ errHandler.error(e.code); return os; }
  
inline std::ostream& operator<<(std::ostream& os, const Sas::_warning e)
{ errHandler.warning(e.code); return os; }

inline std::ostream& operator<<(std::ostream& os, const Sas::_msg m)
{ errHandler.message(m.layer,m.level); return os; }

#endif

