// Generated by LiveScript 1.4.0
(function(){
  var MultiArrayExplorer, id, version, $typeof, lits, modifiers, orHelper, andHelper, Cuffs, toString$ = {}.toString, slice$ = [].slice;
  MultiArrayExplorer = require('./multi-array-explorer').MultiArrayExplorer;
  id = function(it){
    return it;
  };
  version = '0.0.3';
  $typeof = function(a){
    var that, mat;
    if (!(a != null && a.constructor != null)) {
      return toString$.call(a).slice(8, -1);
    }
    if (that = a.constructor.name) {
      return that;
    } else if (a.constructor.toString != null) {
      mat = a.constructor.toString().match(/^function\s*(\w+)\(/);
      if (mat && mat.length === 2) {
        return mat[1];
      }
    }
    return toString$.call(a).slice(8, -1);
  };
  lits = {
    Integer: function(err){
      return function(it){
        if ($typeof(it) === 'Number' && Math.floor(it) === it) {
          return it;
        } else {
          return err('Not an Integer');
        }
      };
    },
    NaN: function(err){
      return function(it){
        if (isNaN(it)) {
          return it;
        } else {
          return err('Not a Not a Number');
        }
      };
    },
    Truthy: function(err){
      return function(it){
        if (!!it) {
          return it;
        } else {
          return err('Not Truthy');
        }
      };
    },
    Untruthy: function(err){
      return function(it){
        if (!it) {
          return it;
        } else {
          return err('Not Untruthy');
        }
      };
    },
    Existent: function(err){
      return function(it){
        if (it != null) {
          return it;
        } else {
          return err('Not Existent');
        }
      };
    },
    Inexistent: function(err){
      return function(it){
        if (it == null) {
          return it;
        } else {
          return err('Not Inexistent');
        }
      };
    },
    '*': function(err){
      return function(it){
        return it;
      };
    },
    All: function(err){
      return function(it){
        return it;
      };
    },
    '!Number': function(err){
      return function(it){
        if (!isNaN(it)) {
          return +it;
        } else {
          return err('Not a !Number');
        }
      };
    },
    '!String': function(err){
      return function(it){
        return '' + it;
      };
    },
    '!Integer': function(err){
      return function(it){
        if (!isNaN(it)) {
          return Math.round(+it);
        } else {
          return err('Not an !Integer');
        }
      };
    },
    '!Boolean': function(err){
      return function(it){
        return !!it;
      };
    },
    '!Date': function(err){
      return function(it){
        return new Date(+it || it);
      };
    }
  };
  modifiers = {
    Maybe: function(a, err){
      return function(v){
        var e;
        try {
          return lits.Inexistent(err)(v);
        } catch (e$) {
          e = e$;
          return a(v);
        }
      };
    },
    Not: function(a, err){
      return function(v){
        var av, e;
        try {
          av = a(v);
        } catch (e$) {
          e = e$;
          return v;
        }
        return err('Not Not');
      };
    }
  };
  orHelper = function(e, A, B){
    return function(){
      var Af, message, m1, _Af, Bf, m2, _Bf;
      try {
        Af = A.apply(this, arguments);
      } catch (e$) {
        message = e$.message;
        m1 = message;
        _Af = false;
      }
      try {
        Bf = B.apply(this, arguments);
      } catch (e$) {
        message = e$.message;
        m2 = message;
        _Bf = false;
      }
      if (_Af === false && _Bf === false) {
        throw new Error(m1 + ' And ' + m2);
      } else if (_Af === false && _Bf !== false) {
        return Bf;
      } else if (_Bf === false && _Af !== false) {
        return Af;
      } else if ($typeof(Af) === 'Function' && $typeof(Bf) === 'Function') {
        return orHelper(e, Af, Bf);
      } else {
        return Af || Bf;
      }
    };
  };
  andHelper = function(e, A, B){
    return function(){
      return B(A.apply(this, arguments));
    };
  };
  Cuffs = function(arg$){
    var ref$, customTypes, ref1$, useProxies, onError, modes, literals, prox, _up, openTag, goDown, OOError, processCustomTypes, parseToArray, parseToFunction, x$, y$, k, z$, z1$, z2$, mt, OO;
    ref$ = arg$ != null
      ? arg$
      : {}, customTypes = (ref1$ = ref$.customTypes) != null
      ? ref1$
      : {}, useProxies = (ref1$ = ref$.useProxies) != null ? ref1$ : false, onError = ref$.onError;
    modes = {};
    literals = lits;
    prox = Proxy;
    _up = function(it){
      useProxies = it;
      if (useProxies && typeof window === 'undefined') {
        prox = require('harmony-proxy');
      }
      if (useProxies && typeof prox === 'undefined') {
        useProxies = false;
      }
      return useProxies;
    };
    _up(useProxies);
    openTag = function(t){
      if (t === 'array') {
        return '[';
      } else if (t === 'object') {
        return '{';
      } else {
        return '(';
      }
    };
    goDown = function(arr, pos, u){
      u == null && (u = ['parenthesis', 'tuple', 'object', 'array']);
      arr.down();
      arr.prop('closePos', pos);
      if (in$(arr.prop('type'), u)) {
        throw new Error("Cuffs Syntax Error - Unclosed " + openTag(arr.prop('type')) + " tag");
      }
    };
    OOError = curry$(function(str, openPos, closePos, message){
      throw new Error("Cuffs Error - " + message + " - From position " + openPos + " to position " + closePos + " of " + str);
    });
    processCustomTypes = function(o){
      var O, i$;
      O = {};
      for (i$ in o) {
        (fn$.call(this, i$, o[i$]));
      }
      return O;
      function fn$(k, v){
        var p;
        switch ($typeof(v)) {
        case 'String':
          p = parseToFunction(parseToArray(v), OOError(v));
          O[k] = function(err){
            return p;
          };
          break;
        case 'Function':
          if (v.length === 2) {
            O[k] = function(err){
              return function(w){
                return v(err, w);
              };
            };
          } else {
            O[k] = v;
          }
          break;
        case 'Boolean':
        case 'Null':
          if (!v) {
            O[k] = null;
          }
          break;
        default:
          throw new Error("Cuffs Parse Error - Can't parse the custom type " + k);
        }
      }
    };
    parseToArray = function(str){
      var modus, a, arr, L, SL, f, rec;
      modus = 'normal';
      a = [];
      a.type = 'parenthesis';
      a.mode = 'normal';
      arr = new MultiArrayExplorer(a, [0]);
      L = 0;
      SL = str.length;
      f = function(s, listenTo, mode){
        var m, i$, len$, l, fr;
        switch ($typeof(listenTo)) {
        case 'String':
          if (!s.indexOf(listenTo)) {
            if (false !== mode(arr, L)) {
              return s.slice(listenTo.length);
            }
          }
          break;
        case 'RegExp':
          if (!s.search(listenTo)) {
            m = s.match(listenTo);
            if (false !== mode(arr, m, L)) {
              return s.slice(m[0].length);
            }
          }
          break;
        case 'Array':
          for (i$ = 0, len$ = listenTo.length; i$ < len$; ++i$) {
            l = listenTo[i$];
            fr = f(s, l, partialize$.apply(this, [mode, [void 8, l, void 8], [0, 2]]));
            if (fr !== false) {
              return fr;
            }
          }
          break;
        default:
          throw new Error("Cuffs Parse Error - Mode key '" + s.toString() + "' of type " + $typeof(s) + " is not supported");
        }
        return false;
      };
      rec = function(s){
        var m, i$, len$, ref$, listenTo, mode, r;
        m = modes[arr.getInheritedParentProp('mode')];
        for (i$ = 0, len$ = m.length; i$ < len$; ++i$) {
          ref$ = m[i$], listenTo = ref$[0], mode = ref$[1];
          r = f(s, listenTo, mode);
          if (r !== false) {
            return r;
          }
        }
      };
      while (str.length) {
        L = SL - str.length;
        str = rec(str);
      }
      if (arr.index.length === 0) {
        throw new Error("Cuffs Syntax Error - You closed too many parentheses");
      }
      while (arr.index.length > 1) {
        goDown(arr, SL - 1);
      }
      return arr.arr;
    };
    parseToFunction = function(arr, err){
      var e, sf, g, prelimCheck, na, ks, typed, ellipsis, i$, len$, a, ellipsii, j, fa, la, to$, i, ell, u, ref$, ret, base, arity, fs, res$, _curryHelper, that, k, v, r, that$, vt, tf, cf;
      e = err(arr.pos || 0, arr.closePos || arr.pos || 0);
      sf = function(u){
        switch ($typeof(u)) {
        case 'Array':
          return parseToFunction(u, err);
        case 'Function':
          return u(e);
        default:
          return lits.Inexistent(e);
        }
      };
      switch (arr.type) {
      case 'parenthesis':
        if (arr.length === 0) {
          return function(it){
            if ($typeof(it === 'Array') && it.length === 0) {
              return it;
            } else {
              return e('Not an empty Tuple');
            }
          };
        }
        return sf(arr[0]);
      case 'array':
        g = sf(arr[0]);
        prelimCheck = function(v){
          var i$, x$, len$, results$ = [];
          if (!(v instanceof Array)) {
            e('Not an Array');
          }
          for (i$ = 0, len$ = v.length; i$ < len$; ++i$) {
            x$ = v[i$];
            results$.push(g(x$));
          }
          return results$;
        };
        if (!useProxies) {
          return prelimCheck;
        }
        return function(o){
          var O;
          O = prelimCheck(o);
          return new prox(O, {
            set: function(target, prop, val, recv){
              if (isNaN(prop) || +prop < 0 || (+prop) % 1 !== 0) {
                target[prop] = val;
                return true;
              }
              target[prop] = g(val);
              return true;
            }
          });
        };
      case 'object':
        na = {};
        ks = [];
        typed = sf(lits['*']);
        ellipsis = false;
        for (i$ = 0, len$ = arr.length; i$ < len$; ++i$) {
          a = arr[i$];
          if ($typeof(a) === 'String') {
            (fn$.call(this, a));
            continue;
          }
          switch (a.type) {
          case 'property':
            (fn1$.call(this, a[0], a[1]));
            break;
          case 'object-type':
            typed = sf(a[0]);
            break;
          case 'ellipsis':
            if (a.length === 0) {
              ellipsis = id;
            } else {
              ellipsis = sf(a[0]);
            }
          }
        }
        prelimCheck = function(o){
          var O, k, ref$, n;
          O = typed(o);
          for (k in ref$ = na) {
            n = ref$[k];
            O[k] = n(o[k]);
          }
          if (ellipsis !== false) {
            for (k in o) {
              if (!in$(k, ks)) {
                O[k] = ellipsis(o[k]);
              }
            }
          } else {
            for (k in o) {
              if (!in$(k, ks)) {
                e("Didn't expect the key " + k + " inside the object");
              }
            }
          }
          return O;
        };
        if (!useProxies) {
          return prelimCheck;
        }
        return function(o){
          var O;
          O = prelimCheck(o);
          return new prox(O, {
            set: function(target, prop, val, recv){
              var that;
              if ((that = na[prop]) != null) {
                target[prop] = that(val);
              } else if (ellipsis !== false) {
                target[prop] = ellipsis(val);
              } else {
                e("Key can't be inside this object");
              }
              return true;
            },
            deleteProperty: function(target, prop){
              var that, tv;
              if ((that = na[prop]) != null) {
                tv = that(void 8);
                if ((that = tv) != null) {
                  target[prop] = that;
                } else {
                  delete target[prop];
                }
              } else {
                delete target[prop];
              }
              return true;
            }
          });
        };
      case 'tuple':
        prelimCheck = function(v){
          var i$, to$, i, results$ = [];
          if (!(v instanceof Array)) {
            e('Not an Array');
          }
          if (v.length !== arr.length) {
            e("Tuple length doesn't match");
          }
          for (i$ = 0, to$ = v.length; i$ < to$; ++i$) {
            i = i$;
            results$.push(sf(arr[i])(v[i]));
          }
          return results$;
        };
        if (!useProxies) {
          return prelimCheck;
        }
        return function(o){
          var O;
          O = prelimCheck(o);
          return new prox(O, {
            set: function(target, prop, val, recv){
              if (prop === 'length') {
                if (val !== arr.length) {
                  e("Tuple length doesn't match");
                }
                target[prop] = val;
                return true;
              }
              if (isNaN(prop) || +prop < 0 || (+prop) % 1 !== 0) {
                target[prop] = val;
                return true;
              }
              target[prop] = sf(arr[prop])(val);
              return true;
            },
            deleteProperty: function(target, prop){
              if (isNaN(prop) || +prop < 0 || (+prop) % 1 !== 0) {
                delete target[prop];
                return true;
              }
              target[prop] = sf(arr[prop])(void 8);
              return true;
            }
          });
        };
      case 'argument-tuple':
        if (arr.length === 0) {
          return function(it){
            if ($typeof(it) === 'Array' && it.length === 0) {
              return it;
            } else {
              return e('Arguments should be an empty tuple');
            }
          };
        } else {
          ellipsii = (function(){
            var i$, ref$, len$, results$ = [];
            for (i$ = 0, len$ = (ref$ = arr).length; i$ < len$; ++i$) {
              a = ref$[i$];
              if (a != null && a.type === 'ellipsis') {
                results$.push(a);
              }
            }
            return results$;
          }()).length;
          if (ellipsii === 0) {
            return function(v){
              var i$, to$, i, results$ = [];
              if (v.length !== arr.length) {
                e("Argument Tuple length doesn't match");
              }
              for (i$ = 0, to$ = arr.length; i$ < to$; ++i$) {
                i = i$;
                results$.push(sf(arr[i])(v[i]));
              }
              return results$;
            };
          } else if (ellipsii === 1) {
            j = 0;
            fa = [];
            la = [];
            for (i$ = 0, to$ = arr.length; i$ < to$; ++i$) {
              i = i$;
              a = arr[i];
              if (a != null && a.type === 'ellipsis') {
                j = i;
                break;
              }
              fa.push(sf(a));
            }
            for (i$ = j + 1, to$ = arr.length; i$ < to$; ++i$) {
              i = i$;
              a = arr[i];
              la.push(sf(a));
            }
            if (arr[j].length === 0) {
              ell = sf(lits['*']);
            } else {
              ell = sf(arr[j][0]);
            }
            return function(v){
              var fp, res$, i$, to$, i, lp, mp;
              if (v.length < arr.length - 1) {
                e("Argument tuple length doesn't match");
              }
              res$ = [];
              for (i$ = 0, to$ = j; i$ < to$; ++i$) {
                i = i$;
                res$.push(fa[i](v[i]));
              }
              fp = res$;
              res$ = [];
              for (i$ = 0, to$ = arr.length - j - 1; i$ < to$; ++i$) {
                i = i$;
                res$.push(la[i](v[i + v.length - arr.length + j + 1]));
              }
              lp = res$;
              res$ = [];
              for (i$ = j, to$ = v.length - arr.length + j + 1; i$ < to$; ++i$) {
                i = i$;
                res$.push(ell(v[i]));
              }
              mp = res$;
              return fp.concat(mp, lp);
            };
          } else {
            throw new Error('An argument tuple can only hold at most one ellipsis');
          }
        }
        break;
      case 'arrow':
        u = [];
        if (arr[0] != null && ((ref$ = arr[0].type) === 'tuple' || ref$ === 'parenthesis')) {
          u = arr[0];
        } else if (arr[0] != null) {
          u = [arr[0]];
        }
        ret = sf(arr[1]);
        base = function(fun, g){
          return function(){
            var b;
            b = slice$.call(arguments);
            b = g(b);
            return ret(fun.apply(this, b));
          };
        };
        switch (arr.arrowType) {
        case '-->':
        case '!-->':
          if (u.length > 1) {
            u.type = 'tuple';
            arity = u.length;
            res$ = [];
            for (i$ = 0; i$ < arity; ++i$) {
              i = i$;
              res$.push(sf(u[i]));
            }
            fs = res$;
            _curryHelper = function(params){
              return function(fun){
                if ($typeof(fun) !== 'Function') {
                  e("Not a Function");
                }
                return function(){
                  var args, i$, to$, i, ps, narg, res$, this$ = this;
                  args = slice$.call(arguments);
                  if (args.length === 0) {
                    for (i$ = 0, to$ = arity; i$ < to$; ++i$) {
                      i = i$;
                      fs[i](params[i]);
                    }
                    return ret(fun.apply(this));
                  } else {
                    ps = params.concat(args);
                    if (ps.length > arity) {
                      e('Incorrect arity of curried arrow, received #{params.length} arguments and should be #{arity} arguments');
                    }
                    res$ = [];
                    for (i$ = 0, to$ = ps.length; i$ < to$; ++i$) {
                      i = i$;
                      res$.push(fs[i](ps[i]));
                    }
                    narg = res$;
                    if (ps.length < arity) {
                      return function(){
                        return _curryHelper(ps)(fun.apply(this$, narg.slice(params.length, ps.length))).apply(this$, arguments);
                      };
                    } else {
                      return ret(fun.apply(this, narg.slice(params.length, ps.length)));
                    }
                  }
                };
              };
            };
            if (arr.arrowType === '-->') {
              return _curryHelper([]);
            } else {
              return function(fun){
                return _curryHelper([])(curry$(fun));
              };
            }
            break;
          }
          // fallthrough
        default:
          u.type = 'argument-tuple';
          g = sf(u);
          return function(fun){
            if ($typeof(fun) !== 'Function') {
              e("Not a Function");
            }
            return base(fun, g);
          };
        }
        break;
      case 'or':
        return orHelper(e, sf(arr[0]), sf(arr[1]));
      case 'and':
        return andHelper(e, sf(arr[0]), sf(arr[1]));
      case 'modifier':
        if (arr.length === 1) {
          arr[1] = lits['*'];
        }
        return arr[0](sf(arr[1]), e);
      case 'literal':
        if (arr.length === 0) {
          throw new Error("Can't process empty literals");
        }
        a = arr[0];
        if ((that = literals[a]) != null) {
          return sf(that);
        } else {
          for (k in ref$ = literals) {
            v = ref$[k];
            if (that = /^\/([\s\S]*)\/([gimy]*)$/.exec(k)) {
              r = new RegExp(that[1], that[2]);
              if (that$ = r.exec(a)) {
                vt = v(that$);
                return sf(vt.length === 2 ? fn2$ : vt);
              }
            }
          }
          return function(it){
            var ref$;
            if ($typeof(it) === a) {
              return it;
            } else {
              return e("Not a" + ((ref$ = a.toLowerCase()) === 'a' || ref$ === 'e' || ref$ === 'o' || ref$ === 'u' || ref$ === 'i' ? 'n' : '') + " " + a);
            }
          };
        }
        break;
      case 'this-binding':
        tf = sf(arr[0]);
        cf = sf(arr[1]);
        return function(fun){
          var h;
          h = cf(fun);
          return function(){
            var b;
            b = slice$.call(arguments);
            return h.apply(tf(this), b);
          };
        };
      case 'string':
      case 'number':
        return function(it){
          if (it === arr[0]) {
            return it;
          } else {
            return e("The " + arr.type + " " + it + " is unequal to " + arr[0]);
          }
        };
      default:
        throw new Error("Can't parse type " + arr.type + " in this context");
      }
      function fn$(k){
        ks.push(k);
        na[k] = sf(lits.Existent);
      }
      function fn1$(k, v){
        ks.push(k);
        if (v == null) {
          na[k] = sf(lits.Existent);
        } else {
          na[k] = sf(v);
        }
      }
      function fn2$(err){
        return function(v){
          return vt(err, v);
        };
      }
    };
    x$ = curry$(function(m, k, f){
      if (modes[m] == null) {
        modes[m] = [];
      }
      return modes[m].push([k, f]);
    });
    y$ = x$('normal');
    y$('(', function(arr, pos){
      return arr.set([]).prop('type', 'parenthesis').prop('pos', pos).up();
    });
    y$(')', function(arr, pos){
      var ref$;
      do {
        goDown(arr, pos + 1, ['array', 'object']);
      } while ((ref$ = arr.prop('type')) !== 'parenthesis' && ref$ !== 'tuple');
      return true;
    });
    y$('[', function(arr, pos){
      return arr.set([]).prop('type', 'array').prop('pos', pos).up();
    });
    y$(']', function(arr, pos){
      do {
        goDown(arr, pos + 1, ['parenthesis', 'tuple', 'object']);
      } while (arr.prop('type') !== 'array');
      return true;
    });
    y$('{', function(arr, pos){
      if (arr.get() != null) {
        return arr.wrap().prop('type', 'object').prop('mode', 'object').prop('pos', pos).up().wrap().prop('type', 'object-type').right();
      } else {
        return arr.set([]).prop('type', 'object').prop('mode', 'object').prop('pos', pos).up();
      }
    });
    y$('}', function(arr, pos){
      do {
        goDown(arr, pos + 1, ['parenthesis', 'tuple', 'array']);
      } while (arr.prop('type') !== 'object');
      return true;
    });
    y$('<', function(arr, pos){
      return arr.set([]).prop('type', 'literal').prop('mode', 'literal').prop('pos', pos).up();
    });
    y$(',', function(arr, pos){
      var ref$;
      while ((ref$ = arr.parentProp('type')) !== 'parenthesis' && ref$ !== 'object' && ref$ !== 'tuple') {
        goDown(arr, pos);
      }
      if (arr.parentProp('type') === 'parenthesis') {
        arr.parentProp('type', 'tuple');
      }
      return arr.right();
    });
    y$('@', function(arr, pos){
      return arr.wrap().prop('type', 'this-binding').prop('pos', pos).up().right();
    });
    y$(/(?:\!?\-)?\->/, function(arr, mat, pos){
      var ref$;
      while ((ref$ = arr.parentProp('type')) === 'modifier' || ref$ === 'and' || ref$ === 'or') {
        goDown(arr, pos);
      }
      return arr.wrap().prop('type', 'arrow').prop('arrowType', mat[0]).prop('pos', pos).up().right();
    });
    y$('|', function(arr, pos){
      while (arr.parentProp('type') === 'modifier') {
        goDown(arr, pos);
      }
      return arr.wrap().prop('type', 'or').prop('pos', pos).up().right();
    });
    y$('&', function(arr, pos){
      while (arr.parentProp('type') === 'modifier') {
        goDown(arr, pos);
      }
      return arr.wrap().prop('type', 'and').prop('pos', pos).up().right();
    });
    y$('"', function(arr, pos){
      return arr.set([]).prop('type', 'string').prop('mode', 'string').prop('stringType', '"').prop('pos', pos).up();
    });
    y$('\'', function(arr, pos){
      return arr.set([]).prop('type', 'string').prop('mode', 'string').prop('stringType', '\'').prop('pos', pos).up();
    });
    y$(/\d+(?:\,\d+)?|\-?Infinity/, function(arr, mat, pos){
      return arr.set([+mat[0]]).prop('type', 'number').prop('pos', pos).prop('closePos', pos + mat[0].length);
    });
    y$('...', function(arr, pos){
      return arr.set([]).prop('type', 'ellipsis').prop('pos', pos).up();
    });
    y$((function(){
      var results$ = [];
      for (k in modifiers) {
        results$.push(k);
      }
      return results$;
    }()), function(arr, val, pos){
      return arr.set([]).prop('type', 'modifier').prop('pos', pos).up().set(modifiers[val]).right();
    });
    y$('*', function(arr, pos){
      return arr.set(['*']).prop('type', 'literal').prop('pos', pos).prop('closePos', pos + 1);
    });
    y$(/[!\?$_\w]+\b/, function(arr, val, pos){
      return arr.set([val[0]]).prop('type', 'literal').prop('pos', pos).prop('closePos', pos + val[0].length);
    });
    y$(/#\w+\b/, function(arr){
      return arr;
    });
    y$(/\/\*[\w\"!\?$_\'\s\r\n\*]*\*\//, function(arr){
      return arr;
    });
    y$(/[\s\S]/, function(arr){
      return arr;
    });
    z$ = x$('object');
    z$(/\\(\:|\}|\,|\.\.\.)/, function(arr, mat){
      return arr.set((arr.get() || '') + mat[1]);
    });
    z$(':', function(arr, pos){
      return arr.wrap().prop('type', 'property').prop('mode', 'normal').prop('pos', pos).up().right();
    });
    z$('}', function(arr, pos){
      return goDown(arr, pos + 1, ['parenthesis', 'tuple', 'array']);
    });
    z$(',', function(arr){
      return arr.right();
    });
    z$('...', function(arr, pos){
      return arr.set([]).prop('type', 'ellipsis').prop('mode', 'normal').prop('pos', pos).up();
    });
    z$(/[\r\n\t\s]/, function(arr){
      return arr;
    });
    z$(/[\s\S]/, function(arr, mat){
      return arr.set((arr.get() || '') + mat[0]);
    });
    z1$ = x$('string');
    z1$("\\\"", function(arr){
      return arr.set((arr.get() || '') + '"');
    });
    z1$("\\'", function(arr){
      return arr.set((arr.get() || '') + '\'');
    });
    z1$('\'', function(arr, pos){
      if ('\'' === arr.parentProp('stringType')) {
        return goDown(arr, pos + 1);
      } else {
        return false;
      }
    });
    z1$('"', function(arr, pos){
      if ('"' === arr.parentProp('stringType')) {
        return goDown(arr, pos + 1);
      } else {
        return false;
      }
    });
    z1$(/[\s\S]/, function(arr, mat){
      return arr.set((arr.get() || '') + mat[0]);
    });
    z2$ = x$('literal');
    z2$("\\>", function(arr){
      return arr.set((arr.get() || '') + '>');
    });
    z2$('>', function(arr, pos){
      return goDown(arr, pos + 1);
    });
    z2$(/[\s\S]/, function(arr, mat){
      return arr.set((arr.get() || '') + mat[0]);
    });
    mt = function(customTypes){
      var i$, len$, ct, results$ = [];
      if ($typeof(customTypes) === 'Array') {
        for (i$ = 0, len$ = customTypes.length; i$ < len$; ++i$) {
          ct = customTypes[i$];
          results$.push(literals = import$(clone$(literals), processCustomTypes(ct)));
        }
        return results$;
      } else {
        return literals = import$(clone$(literals), processCustomTypes(customTypes));
      }
    };
    mt(customTypes);
    OO = function(str){
      var err, A, F;
      if ($typeof(str) !== 'String') {
        throw new Error("Cuffs Error - Cuffs requires the first argument to be a string");
      }
      err = OOError(str);
      A = parseToArray(str);
      F = parseToFunction(A, err);
      if (arguments.length === 1) {
        return F;
      } else {
        return F(arguments[1]);
      }
    };
    OO.version = version;
    OO.modifyTypes = mt;
    OO.useProxies = _up;
    return OO;
  };
  Cuffs.version = version;
  module.exports = Cuffs;
  function in$(x, xs){
    var i = -1, l = xs.length >>> 0;
    while (++i < l) if (x === xs[i]) return true;
    return false;
  }
  function curry$(f, bound){
    var context,
    _curry = function(args) {
      return f.length > 1 ? function(){
        var params = args ? args.concat() : [];
        context = bound ? context || this : this;
        return params.push.apply(params, arguments) <
            f.length && arguments.length ?
          _curry.call(context, params) : f.apply(context, params);
      } : f;
    };
    return _curry();
  }
  function partialize$(f, args, where){
    var context = this;
    return function(){
      var params = slice$.call(arguments), i,
          len = params.length, wlen = where.length,
          ta = args ? args.concat() : [], tw = where ? where.concat() : [];
      for(i = 0; i < len; ++i) { ta[tw[0]] = params[i]; tw.shift(); }
      return len < wlen && len ?
        partialize$.apply(context, [f, ta, tw]) : f.apply(context, ta);
    };
  }
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
  function clone$(it){
    function fun(){} fun.prototype = it;
    return new fun;
  }
}).call(this);
