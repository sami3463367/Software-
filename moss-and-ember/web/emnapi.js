var __require = /* @__PURE__ */ ((x) => typeof require !== "undefined" ? require : typeof Proxy !== "undefined" ? new Proxy(x, {
  get: (a, b) => (typeof require !== "undefined" ? require : a)[b]
}) : x)(function(x) {
  if (typeof require !== "undefined") return require.apply(this, arguments);
  throw Error('Dynamic require of "' + x + '" is not supported');
});

// ../../../../tmp/browsertest/node_modules/tslib/tslib.es6.mjs
var extendStatics = function(d, b) {
  extendStatics = Object.setPrototypeOf || { __proto__: [] } instanceof Array && function(d2, b2) {
    d2.__proto__ = b2;
  } || function(d2, b2) {
    for (var p in b2) if (Object.prototype.hasOwnProperty.call(b2, p)) d2[p] = b2[p];
  };
  return extendStatics(d, b);
};
function __extends(d, b) {
  if (typeof b !== "function" && b !== null)
    throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
  extendStatics(d, b);
  function __() {
    this.constructor = d;
  }
  d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
}

// web/emnapi.vendor.js
var externalValue = /* @__PURE__ */ new WeakMap();
function isExternal(object) {
  return externalValue.has(object);
}
var External = (function() {
  function External2(value) {
    Object.setPrototypeOf(this, null);
    externalValue.set(this, value);
  }
  External2.prototype = null;
  return External2;
})();
function getExternalValue(external) {
  if (!isExternal(external)) {
    throw new TypeError("not external");
  }
  return externalValue.get(external);
}
var supportNewFunction = /* @__PURE__ */ (function() {
  var f;
  try {
    f = new Function();
  } catch (_) {
    return false;
  }
  return typeof f === "function";
})();
var _global = /* @__PURE__ */ (function() {
  if (typeof globalThis !== "undefined")
    return globalThis;
  var g = /* @__PURE__ */ (function() {
    return this;
  })();
  if (!g && supportNewFunction) {
    try {
      g = new Function("return this")();
    } catch (_) {
    }
  }
  if (!g) {
    if (typeof __webpack_public_path__ === "undefined") {
      if (typeof global !== "undefined")
        return global;
    }
    if (typeof window !== "undefined")
      return window;
    if (typeof self !== "undefined")
      return self;
  }
  return g;
})();
var TryCatch = /* @__PURE__ */ (function() {
  function TryCatch2() {
    this._exception = void 0;
    this._caught = false;
  }
  TryCatch2.prototype.isEmpty = function() {
    return !this._caught;
  };
  TryCatch2.prototype.hasCaught = function() {
    return this._caught;
  };
  TryCatch2.prototype.exception = function() {
    return this._exception;
  };
  TryCatch2.prototype.setError = function(err) {
    this._caught = true;
    this._exception = err;
  };
  TryCatch2.prototype.reset = function() {
    this._caught = false;
    this._exception = void 0;
  };
  TryCatch2.prototype.extractException = function() {
    var e = this._exception;
    this.reset();
    return e;
  };
  return TryCatch2;
})();
var canSetFunctionName = /* @__PURE__ */ (function() {
  var _a;
  try {
    return Boolean((_a = Object.getOwnPropertyDescriptor(Function.prototype, "name")) === null || _a === void 0 ? void 0 : _a.configurable);
  } catch (_) {
    return false;
  }
})();
var supportReflect = typeof Reflect === "object";
var supportFinalizer = typeof FinalizationRegistry !== "undefined" && typeof WeakRef !== "undefined";
var supportWeakSymbol = /* @__PURE__ */ (function() {
  try {
    var sym = /* @__PURE__ */ Symbol();
    new WeakRef(sym);
    (/* @__PURE__ */ new WeakMap()).set(sym, void 0);
  } catch (_) {
    return false;
  }
  return true;
})();
var supportBigInt = typeof BigInt !== "undefined";
function isReferenceType(v) {
  return typeof v === "object" && v !== null || typeof v === "function";
}
var _require = /* @__PURE__ */ (function() {
  var nativeRequire;
  if (typeof __webpack_public_path__ !== "undefined") {
    nativeRequire = /* @__PURE__ */ (function() {
      return typeof __non_webpack_require__ !== "undefined" ? __non_webpack_require__ : void 0;
    })();
  } else {
    nativeRequire = /* @__PURE__ */ (function() {
      return typeof __webpack_public_path__ !== "undefined" ? typeof __non_webpack_require__ !== "undefined" ? __non_webpack_require__ : void 0 : typeof __require !== "undefined" ? __require : void 0;
    })();
  }
  return nativeRequire;
})();
var _MessageChannel = typeof MessageChannel === "function" ? MessageChannel : /* @__PURE__ */ (function() {
  try {
    return _require("worker_threads").MessageChannel;
  } catch (_) {
  }
  return void 0;
})();
var _setImmediate = typeof setImmediate === "function" ? setImmediate.bind(_global) : function(callback) {
  if (typeof callback !== "function") {
    throw new TypeError('The "callback" argument must be of type function');
  }
  if (_MessageChannel) {
    var channel_1 = new _MessageChannel();
    channel_1.port1.onmessage = function() {
      channel_1.port1.onmessage = null;
      channel_1 = void 0;
      callback();
    };
    channel_1.port2.postMessage(null);
  } else {
    setTimeout(callback, 0);
  }
};
var _Buffer = typeof Buffer === "function" ? Buffer : /* @__PURE__ */ (function() {
  try {
    return _require("buffer").Buffer;
  } catch (_) {
  }
  return void 0;
})();
var version = "1.11.3";
var NODE_API_SUPPORTED_VERSION_MIN = 1;
var NODE_API_SUPPORTED_VERSION_MAX = 10;
var NAPI_VERSION_EXPERIMENTAL = 2147483647;
var NODE_API_DEFAULT_MODULE_API_VERSION = 8;
var Handle = /* @__PURE__ */ (function() {
  function Handle2(id, value) {
    this.id = id;
    this.value = value;
  }
  Handle2.prototype.data = function() {
    return getExternalValue(this.value);
  };
  Handle2.prototype.isNumber = function() {
    return typeof this.value === "number";
  };
  Handle2.prototype.isBigInt = function() {
    return typeof this.value === "bigint";
  };
  Handle2.prototype.isString = function() {
    return typeof this.value === "string";
  };
  Handle2.prototype.isFunction = function() {
    return typeof this.value === "function";
  };
  Handle2.prototype.isExternal = function() {
    return isExternal(this.value);
  };
  Handle2.prototype.isObject = function() {
    return typeof this.value === "object" && this.value !== null;
  };
  Handle2.prototype.isArray = function() {
    return Array.isArray(this.value);
  };
  Handle2.prototype.isArrayBuffer = function() {
    return this.value instanceof ArrayBuffer;
  };
  Handle2.prototype.isTypedArray = function() {
    return ArrayBuffer.isView(this.value) && !(this.value instanceof DataView);
  };
  Handle2.prototype.isBuffer = function(BufferConstructor) {
    if (ArrayBuffer.isView(this.value))
      return true;
    BufferConstructor !== null && BufferConstructor !== void 0 ? BufferConstructor : BufferConstructor = _Buffer;
    return typeof BufferConstructor === "function" && BufferConstructor.isBuffer(this.value);
  };
  Handle2.prototype.isDataView = function() {
    return this.value instanceof DataView;
  };
  Handle2.prototype.isDate = function() {
    return this.value instanceof Date;
  };
  Handle2.prototype.isPromise = function() {
    return this.value instanceof Promise;
  };
  Handle2.prototype.isBoolean = function() {
    return typeof this.value === "boolean";
  };
  Handle2.prototype.isUndefined = function() {
    return this.value === void 0;
  };
  Handle2.prototype.isSymbol = function() {
    return typeof this.value === "symbol";
  };
  Handle2.prototype.isNull = function() {
    return this.value === null;
  };
  Handle2.prototype.dispose = function() {
    this.value = void 0;
  };
  return Handle2;
})();
var ConstHandle = /* @__PURE__ */ (function(_super) {
  __extends(ConstHandle2, _super);
  function ConstHandle2(id, value) {
    return _super.call(this, id, value) || this;
  }
  ConstHandle2.prototype.dispose = function() {
  };
  return ConstHandle2;
})(Handle);
var HandleStore = /* @__PURE__ */ (function() {
  function HandleStore2() {
    this._values = [
      void 0,
      HandleStore2.UNDEFINED,
      HandleStore2.NULL,
      HandleStore2.FALSE,
      HandleStore2.TRUE,
      HandleStore2.GLOBAL
    ];
    this._next = HandleStore2.MIN_ID;
  }
  HandleStore2.prototype.push = function(value) {
    var h;
    var next = this._next;
    var values = this._values;
    if (next < values.length) {
      h = values[next];
      h.value = value;
    } else {
      h = new Handle(next, value);
      values[next] = h;
    }
    this._next++;
    return h;
  };
  HandleStore2.prototype.erase = function(start, end) {
    this._next = start;
    var values = this._values;
    for (var i = start; i < end; ++i) {
      values[i].dispose();
    }
  };
  HandleStore2.prototype.get = function(id) {
    return this._values[id];
  };
  HandleStore2.prototype.swap = function(a, b) {
    var values = this._values;
    var h = values[a];
    values[a] = values[b];
    values[a].id = Number(a);
    values[b] = h;
    h.id = Number(b);
  };
  HandleStore2.prototype.dispose = function() {
    this._values.length = HandleStore2.MIN_ID;
    this._next = HandleStore2.MIN_ID;
  };
  HandleStore2.UNDEFINED = new ConstHandle(1, void 0);
  HandleStore2.NULL = new ConstHandle(2, null);
  HandleStore2.FALSE = new ConstHandle(3, false);
  HandleStore2.TRUE = new ConstHandle(4, true);
  HandleStore2.GLOBAL = new ConstHandle(5, _global);
  HandleStore2.MIN_ID = 6;
  return HandleStore2;
})();
var HandleScope = /* @__PURE__ */ (function() {
  function HandleScope2(handleStore, id, parentScope, start, end) {
    if (end === void 0) {
      end = start;
    }
    this.handleStore = handleStore;
    this.id = id;
    this.parent = parentScope;
    this.child = null;
    if (parentScope !== null)
      parentScope.child = this;
    this.start = start;
    this.end = end;
    this._escapeCalled = false;
    this.callbackInfo = {
      thiz: void 0,
      data: 0,
      args: void 0,
      fn: void 0
    };
  }
  HandleScope2.prototype.add = function(value) {
    var h = this.handleStore.push(value);
    this.end++;
    return h;
  };
  HandleScope2.prototype.addExternal = function(data) {
    return this.add(new External(data));
  };
  HandleScope2.prototype.dispose = function() {
    if (this._escapeCalled)
      this._escapeCalled = false;
    if (this.start === this.end)
      return;
    this.handleStore.erase(this.start, this.end);
  };
  HandleScope2.prototype.escape = function(handle) {
    if (this._escapeCalled)
      return null;
    this._escapeCalled = true;
    if (handle < this.start || handle >= this.end) {
      return null;
    }
    this.handleStore.swap(handle, this.start);
    var h = this.handleStore.get(this.start);
    this.start++;
    this.parent.end++;
    return h;
  };
  HandleScope2.prototype.escapeCalled = function() {
    return this._escapeCalled;
  };
  return HandleScope2;
})();
var ScopeStore = /* @__PURE__ */ (function() {
  function ScopeStore2() {
    this._rootScope = new HandleScope(null, 0, null, 1, HandleStore.MIN_ID);
    this.currentScope = this._rootScope;
    this._values = [void 0];
  }
  ScopeStore2.prototype.get = function(id) {
    return this._values[id];
  };
  ScopeStore2.prototype.openScope = function(handleStore) {
    var currentScope = this.currentScope;
    var scope = currentScope.child;
    if (scope !== null) {
      scope.start = scope.end = currentScope.end;
    } else {
      var id = currentScope.id + 1;
      scope = new HandleScope(handleStore, id, currentScope, currentScope.end);
      this._values[id] = scope;
    }
    this.currentScope = scope;
    return scope;
  };
  ScopeStore2.prototype.closeScope = function() {
    var scope = this.currentScope;
    this.currentScope = scope.parent;
    scope.dispose();
  };
  ScopeStore2.prototype.dispose = function() {
    this.currentScope = this._rootScope;
    this._values.length = 1;
  };
  return ScopeStore2;
})();
var RefTracker = /* @__PURE__ */ (function() {
  function RefTracker2() {
    this._next = null;
    this._prev = null;
  }
  RefTracker2.prototype.dispose = function() {
  };
  RefTracker2.prototype.finalize = function() {
  };
  RefTracker2.prototype.link = function(list) {
    this._prev = list;
    this._next = list._next;
    if (this._next !== null) {
      this._next._prev = this;
    }
    list._next = this;
  };
  RefTracker2.prototype.unlink = function() {
    if (this._prev !== null) {
      this._prev._next = this._next;
    }
    if (this._next !== null) {
      this._next._prev = this._prev;
    }
    this._prev = null;
    this._next = null;
  };
  RefTracker2.finalizeAll = function(list) {
    while (list._next !== null) {
      list._next.finalize();
    }
  };
  return RefTracker2;
})();
var Finalizer = /* @__PURE__ */ (function() {
  function Finalizer2(envObject, _finalizeCallback, _finalizeData, _finalizeHint) {
    if (_finalizeCallback === void 0) {
      _finalizeCallback = 0;
    }
    if (_finalizeData === void 0) {
      _finalizeData = 0;
    }
    if (_finalizeHint === void 0) {
      _finalizeHint = 0;
    }
    this.envObject = envObject;
    this._finalizeCallback = _finalizeCallback;
    this._finalizeData = _finalizeData;
    this._finalizeHint = _finalizeHint;
    this._makeDynCall_vppp = envObject.makeDynCall_vppp;
  }
  Finalizer2.prototype.callback = function() {
    return this._finalizeCallback;
  };
  Finalizer2.prototype.data = function() {
    return this._finalizeData;
  };
  Finalizer2.prototype.hint = function() {
    return this._finalizeHint;
  };
  Finalizer2.prototype.resetEnv = function() {
    this.envObject = void 0;
  };
  Finalizer2.prototype.resetFinalizer = function() {
    this._finalizeCallback = 0;
    this._finalizeData = 0;
    this._finalizeHint = 0;
  };
  Finalizer2.prototype.callFinalizer = function() {
    var finalize_callback = this._finalizeCallback;
    var finalize_data = this._finalizeData;
    var finalize_hint = this._finalizeHint;
    this.resetFinalizer();
    if (!finalize_callback)
      return;
    var fini = Number(finalize_callback);
    if (!this.envObject) {
      this._makeDynCall_vppp(fini)(0, finalize_data, finalize_hint);
    } else {
      this.envObject.callFinalizer(fini, finalize_data, finalize_hint);
    }
  };
  Finalizer2.prototype.dispose = function() {
    this.envObject = void 0;
    this._makeDynCall_vppp = void 0;
  };
  return Finalizer2;
})();
var TrackedFinalizer = /* @__PURE__ */ (function(_super) {
  __extends(TrackedFinalizer2, _super);
  function TrackedFinalizer2(envObject, finalize_callback, finalize_data, finalize_hint) {
    var _this = _super.call(this) || this;
    _this._finalizer = new Finalizer(envObject, finalize_callback, finalize_data, finalize_hint);
    return _this;
  }
  TrackedFinalizer2.create = function(envObject, finalize_callback, finalize_data, finalize_hint) {
    var finalizer = new TrackedFinalizer2(envObject, finalize_callback, finalize_data, finalize_hint);
    finalizer.link(envObject.finalizing_reflist);
    return finalizer;
  };
  TrackedFinalizer2.prototype.data = function() {
    return this._finalizer.data();
  };
  TrackedFinalizer2.prototype.dispose = function() {
    if (!this._finalizer)
      return;
    this.unlink();
    this._finalizer.envObject.dequeueFinalizer(this);
    this._finalizer.dispose();
    this._finalizer = void 0;
    _super.prototype.dispose.call(this);
  };
  TrackedFinalizer2.prototype.finalize = function() {
    this.unlink();
    var error;
    var caught = false;
    try {
      this._finalizer.callFinalizer();
    } catch (err) {
      caught = true;
      error = err;
    }
    this.dispose();
    if (caught) {
      throw error;
    }
  };
  return TrackedFinalizer2;
})(RefTracker);
function throwNodeApiVersionError(moduleName, moduleApiVersion) {
  var errorMessage = "".concat(moduleName, " requires Node-API version ").concat(moduleApiVersion, ", but this version of Node.js only supports version ").concat(NODE_API_SUPPORTED_VERSION_MAX, " add-ons.");
  throw new Error(errorMessage);
}
function handleThrow(envObject, value) {
  if (envObject.terminatedOrTerminating()) {
    return;
  }
  throw value;
}
var Env = /* @__PURE__ */ (function() {
  function Env2(ctx, moduleApiVersion, makeDynCall_vppp, makeDynCall_vp, abort) {
    this.ctx = ctx;
    this.moduleApiVersion = moduleApiVersion;
    this.makeDynCall_vppp = makeDynCall_vppp;
    this.makeDynCall_vp = makeDynCall_vp;
    this.abort = abort;
    this.openHandleScopes = 0;
    this.instanceData = null;
    this.tryCatch = new TryCatch();
    this.refs = 1;
    this.reflist = new RefTracker();
    this.finalizing_reflist = new RefTracker();
    this.pendingFinalizers = [];
    this.lastError = {
      errorCode: 0,
      engineErrorCode: 0,
      engineReserved: 0
    };
    this.inGcFinalizer = false;
    this._bindingMap = /* @__PURE__ */ new WeakMap();
    this.id = 0;
  }
  Env2.prototype.canCallIntoJs = function() {
    return true;
  };
  Env2.prototype.terminatedOrTerminating = function() {
    return !this.canCallIntoJs();
  };
  Env2.prototype.ref = function() {
    this.refs++;
  };
  Env2.prototype.unref = function() {
    this.refs--;
    if (this.refs === 0) {
      this.dispose();
    }
  };
  Env2.prototype.ensureHandle = function(value) {
    return this.ctx.ensureHandle(value);
  };
  Env2.prototype.ensureHandleId = function(value) {
    return this.ensureHandle(value).id;
  };
  Env2.prototype.clearLastError = function() {
    var lastError = this.lastError;
    if (lastError.errorCode !== 0)
      lastError.errorCode = 0;
    if (lastError.engineErrorCode !== 0)
      lastError.engineErrorCode = 0;
    if (lastError.engineReserved !== 0)
      lastError.engineReserved = 0;
    return 0;
  };
  Env2.prototype.setLastError = function(error_code, engine_error_code, engine_reserved) {
    if (engine_error_code === void 0) {
      engine_error_code = 0;
    }
    if (engine_reserved === void 0) {
      engine_reserved = 0;
    }
    var lastError = this.lastError;
    if (lastError.errorCode !== error_code)
      lastError.errorCode = error_code;
    if (lastError.engineErrorCode !== engine_error_code)
      lastError.engineErrorCode = engine_error_code;
    if (lastError.engineReserved !== engine_reserved)
      lastError.engineReserved = engine_reserved;
    return error_code;
  };
  Env2.prototype.getReturnStatus = function() {
    return !this.tryCatch.hasCaught() ? 0 : this.setLastError(
      10
      /* napi_status.napi_pending_exception */
    );
  };
  Env2.prototype.callIntoModule = function(fn, handleException) {
    if (handleException === void 0) {
      handleException = handleThrow;
    }
    var openHandleScopesBefore = this.openHandleScopes;
    this.clearLastError();
    var r = fn(this);
    if (openHandleScopesBefore !== this.openHandleScopes) {
      this.abort("open_handle_scopes != open_handle_scopes_before");
    }
    if (this.tryCatch.hasCaught()) {
      var err = this.tryCatch.extractException();
      handleException(this, err);
    }
    return r;
  };
  Env2.prototype.invokeFinalizerFromGC = function(finalizer) {
    if (this.moduleApiVersion !== NAPI_VERSION_EXPERIMENTAL) {
      this.enqueueFinalizer(finalizer);
    } else {
      var saved = this.inGcFinalizer;
      this.inGcFinalizer = true;
      try {
        finalizer.finalize();
      } finally {
        this.inGcFinalizer = saved;
      }
    }
  };
  Env2.prototype.checkGCAccess = function() {
    if (this.moduleApiVersion === NAPI_VERSION_EXPERIMENTAL && this.inGcFinalizer) {
      this.abort("Finalizer is calling a function that may affect GC state.\nThe finalizers are run directly from GC and must not affect GC state.\nUse `node_api_post_finalizer` from inside of the finalizer to work around this issue.\nIt schedules the call as a new task in the event loop.");
    }
  };
  Env2.prototype.enqueueFinalizer = function(finalizer) {
    if (this.pendingFinalizers.indexOf(finalizer) === -1) {
      this.pendingFinalizers.push(finalizer);
    }
  };
  Env2.prototype.dequeueFinalizer = function(finalizer) {
    var index = this.pendingFinalizers.indexOf(finalizer);
    if (index !== -1) {
      this.pendingFinalizers.splice(index, 1);
    }
  };
  Env2.prototype.deleteMe = function() {
    RefTracker.finalizeAll(this.finalizing_reflist);
    RefTracker.finalizeAll(this.reflist);
    this.tryCatch.extractException();
    this.ctx.envStore.remove(this.id);
  };
  Env2.prototype.dispose = function() {
    if (this.id === 0)
      return;
    this.deleteMe();
    this.finalizing_reflist.dispose();
    this.reflist.dispose();
    this.id = 0;
  };
  Env2.prototype.initObjectBinding = function(value) {
    var binding = {
      wrapped: 0,
      tag: null
    };
    this._bindingMap.set(value, binding);
    return binding;
  };
  Env2.prototype.getObjectBinding = function(value) {
    if (this._bindingMap.has(value)) {
      return this._bindingMap.get(value);
    }
    return this.initObjectBinding(value);
  };
  Env2.prototype.setInstanceData = function(data, finalize_cb, finalize_hint) {
    if (this.instanceData) {
      this.instanceData.dispose();
    }
    this.instanceData = TrackedFinalizer.create(this, finalize_cb, data, finalize_hint);
  };
  Env2.prototype.getInstanceData = function() {
    return this.instanceData ? this.instanceData.data() : 0;
  };
  return Env2;
})();
var NodeEnv = /* @__PURE__ */ (function(_super) {
  __extends(NodeEnv2, _super);
  function NodeEnv2(ctx, filename, moduleApiVersion, makeDynCall_vppp, makeDynCall_vp, abort, nodeBinding) {
    var _this = _super.call(this, ctx, moduleApiVersion, makeDynCall_vppp, makeDynCall_vp, abort) || this;
    _this.filename = filename;
    _this.nodeBinding = nodeBinding;
    _this.destructing = false;
    _this.finalizationScheduled = false;
    return _this;
  }
  NodeEnv2.prototype.deleteMe = function() {
    this.destructing = true;
    this.drainFinalizerQueue();
    _super.prototype.deleteMe.call(this);
  };
  NodeEnv2.prototype.canCallIntoJs = function() {
    return _super.prototype.canCallIntoJs.call(this) && this.ctx.canCallIntoJs();
  };
  NodeEnv2.prototype.triggerFatalException = function(err) {
    if (this.nodeBinding) {
      this.nodeBinding.napi.fatalException(err);
    } else {
      if (typeof process === "object" && process !== null && typeof process._fatalException === "function") {
        var handled = process._fatalException(err);
        if (!handled) {
          console.error(err);
          process.exit(1);
        }
      } else {
        throw err;
      }
    }
  };
  NodeEnv2.prototype.callbackIntoModule = function(enforceUncaughtExceptionPolicy, fn) {
    return this.callIntoModule(fn, function(envObject, err) {
      if (envObject.terminatedOrTerminating()) {
        return;
      }
      var hasProcess = typeof process === "object" && process !== null;
      var hasForceFlag = hasProcess ? Boolean(process.execArgv && process.execArgv.indexOf("--force-node-api-uncaught-exceptions-policy") !== -1) : false;
      if (envObject.moduleApiVersion < 10 && !hasForceFlag && !enforceUncaughtExceptionPolicy) {
        var warn = hasProcess && typeof process.emitWarning === "function" ? process.emitWarning : function(warning, type, code) {
          if (warning instanceof Error) {
            console.warn(warning.toString());
          } else {
            var prefix = code ? "[".concat(code, "] ") : "";
            console.warn("".concat(prefix).concat(type || "Warning", ": ").concat(warning));
          }
        };
        warn("Uncaught Node-API callback exception detected, please run node with option --force-node-api-uncaught-exceptions-policy=true to handle those exceptions properly.", "DeprecationWarning", "DEP0168");
        return;
      }
      envObject.triggerFatalException(err);
    });
  };
  NodeEnv2.prototype.callFinalizer = function(cb, data, hint) {
    this.callFinalizerInternal(1, cb, data, hint);
  };
  NodeEnv2.prototype.callFinalizerInternal = function(forceUncaught, cb, data, hint) {
    var f = this.makeDynCall_vppp(cb);
    var env = this.id;
    var scope = this.ctx.openScope(this);
    try {
      this.callbackIntoModule(Boolean(forceUncaught), function() {
        f(env, data, hint);
      });
    } finally {
      this.ctx.closeScope(this, scope);
    }
  };
  NodeEnv2.prototype.enqueueFinalizer = function(finalizer) {
    var _this = this;
    _super.prototype.enqueueFinalizer.call(this, finalizer);
    if (!this.finalizationScheduled && !this.destructing) {
      this.finalizationScheduled = true;
      this.ref();
      _setImmediate(function() {
        _this.finalizationScheduled = false;
        _this.unref();
        _this.drainFinalizerQueue();
      });
    }
  };
  NodeEnv2.prototype.drainFinalizerQueue = function() {
    while (this.pendingFinalizers.length > 0) {
      var refTracker = this.pendingFinalizers.shift();
      refTracker.finalize();
    }
  };
  return NodeEnv2;
})(Env);
function newEnv(ctx, filename, moduleApiVersion, makeDynCall_vppp, makeDynCall_vp, abort, nodeBinding) {
  moduleApiVersion = typeof moduleApiVersion !== "number" ? NODE_API_DEFAULT_MODULE_API_VERSION : moduleApiVersion;
  if (moduleApiVersion < NODE_API_DEFAULT_MODULE_API_VERSION) {
    moduleApiVersion = NODE_API_DEFAULT_MODULE_API_VERSION;
  } else if (moduleApiVersion > NODE_API_SUPPORTED_VERSION_MAX && moduleApiVersion !== NAPI_VERSION_EXPERIMENTAL) {
    throwNodeApiVersionError(filename, moduleApiVersion);
  }
  var env = new NodeEnv(ctx, filename, moduleApiVersion, makeDynCall_vppp, makeDynCall_vp, abort, nodeBinding);
  ctx.envStore.add(env);
  ctx.addCleanupHook(env, function() {
    env.unref();
  }, 0);
  return env;
}
var EmnapiError = /* @__PURE__ */ (function(_super) {
  __extends(EmnapiError2, _super);
  function EmnapiError2(message) {
    var _newTarget = this.constructor;
    var _this = _super.call(this, message) || this;
    var ErrorConstructor = _newTarget;
    var proto = ErrorConstructor.prototype;
    if (!(_this instanceof EmnapiError2)) {
      var setPrototypeOf = Object.setPrototypeOf;
      if (typeof setPrototypeOf === "function") {
        setPrototypeOf.call(Object, _this, proto);
      } else {
        _this.__proto__ = proto;
      }
      if (typeof Error.captureStackTrace === "function") {
        Error.captureStackTrace(_this, ErrorConstructor);
      }
    }
    return _this;
  }
  return EmnapiError2;
})(Error);
Object.defineProperty(EmnapiError.prototype, "name", {
  configurable: true,
  writable: true,
  value: "EmnapiError"
});
var NotSupportWeakRefError = /* @__PURE__ */ (function(_super) {
  __extends(NotSupportWeakRefError2, _super);
  function NotSupportWeakRefError2(api, message) {
    return _super.call(this, "".concat(api, ': The current runtime does not support "FinalizationRegistry" and "WeakRef".').concat(message ? " ".concat(message) : "")) || this;
  }
  return NotSupportWeakRefError2;
})(EmnapiError);
Object.defineProperty(NotSupportWeakRefError.prototype, "name", {
  configurable: true,
  writable: true,
  value: "NotSupportWeakRefError"
});
var NotSupportBufferError = /* @__PURE__ */ (function(_super) {
  __extends(NotSupportBufferError2, _super);
  function NotSupportBufferError2(api, message) {
    return _super.call(this, "".concat(api, ': The current runtime does not support "Buffer". Consider using buffer polyfill to make sure `globalThis.Buffer` is defined.').concat(message ? " ".concat(message) : "")) || this;
  }
  return NotSupportBufferError2;
})(EmnapiError);
Object.defineProperty(NotSupportBufferError.prototype, "name", {
  configurable: true,
  writable: true,
  value: "NotSupportBufferError"
});
var StrongRef = /* @__PURE__ */ (function() {
  function StrongRef2(value) {
    this._value = value;
  }
  StrongRef2.prototype.deref = function() {
    return this._value;
  };
  StrongRef2.prototype.dispose = function() {
    this._value = void 0;
  };
  return StrongRef2;
})();
var Persistent = /* @__PURE__ */ (function() {
  function Persistent2(value) {
    this._ref = new StrongRef(value);
  }
  Persistent2.prototype.setWeak = function(param, callback) {
    if (!supportFinalizer || this._ref === void 0 || this._ref instanceof WeakRef)
      return;
    var value = this._ref.deref();
    try {
      Persistent2._registry.register(value, this, this);
      var weakRef = new WeakRef(value);
      this._ref.dispose();
      this._ref = weakRef;
      this._param = param;
      this._callback = callback;
    } catch (err) {
      if (typeof value === "symbol") ;
      else {
        throw err;
      }
    }
  };
  Persistent2.prototype.clearWeak = function() {
    if (!supportFinalizer || this._ref === void 0)
      return;
    if (this._ref instanceof WeakRef) {
      try {
        Persistent2._registry.unregister(this);
      } catch (_) {
      }
      this._param = void 0;
      this._callback = void 0;
      var value = this._ref.deref();
      if (value === void 0) {
        this._ref = value;
      } else {
        this._ref = new StrongRef(value);
      }
    }
  };
  Persistent2.prototype.reset = function() {
    if (supportFinalizer) {
      try {
        Persistent2._registry.unregister(this);
      } catch (_) {
      }
    }
    this._param = void 0;
    this._callback = void 0;
    if (this._ref instanceof StrongRef) {
      this._ref.dispose();
    }
    this._ref = void 0;
  };
  Persistent2.prototype.isEmpty = function() {
    return this._ref === void 0;
  };
  Persistent2.prototype.deref = function() {
    if (this._ref === void 0)
      return void 0;
    return this._ref.deref();
  };
  Persistent2._registry = supportFinalizer ? new FinalizationRegistry(function(value) {
    value._ref = void 0;
    var callback = value._callback;
    var param = value._param;
    value._callback = void 0;
    value._param = void 0;
    if (typeof callback === "function") {
      callback(param);
    }
  }) : void 0;
  return Persistent2;
})();
var ReferenceOwnership;
(function(ReferenceOwnership2) {
  ReferenceOwnership2[ReferenceOwnership2["kRuntime"] = 0] = "kRuntime";
  ReferenceOwnership2[ReferenceOwnership2["kUserland"] = 1] = "kUserland";
})(ReferenceOwnership || (ReferenceOwnership = {}));
function canBeHeldWeakly(value) {
  return value.isObject() || value.isFunction() || value.isSymbol();
}
var Reference = /* @__PURE__ */ (function(_super) {
  __extends(Reference2, _super);
  function Reference2(envObject, handle_id, initialRefcount, ownership) {
    var _this = _super.call(this) || this;
    _this.envObject = envObject;
    _this._refcount = initialRefcount;
    _this._ownership = ownership;
    var handle = envObject.ctx.handleStore.get(handle_id);
    _this.canBeWeak = canBeHeldWeakly(handle);
    _this.persistent = new Persistent(handle.value);
    _this.id = 0;
    if (initialRefcount === 0) {
      _this._setWeak();
    }
    return _this;
  }
  Reference2.weakCallback = function(ref) {
    ref.persistent.reset();
    ref.invokeFinalizerFromGC();
  };
  Reference2.create = function(envObject, handle_id, initialRefcount, ownership, _unused1, _unused2, _unused3) {
    var ref = new Reference2(envObject, handle_id, initialRefcount, ownership);
    envObject.ctx.refStore.add(ref);
    ref.link(envObject.reflist);
    return ref;
  };
  Reference2.prototype.ref = function() {
    if (this.persistent.isEmpty()) {
      return 0;
    }
    if (++this._refcount === 1 && this.canBeWeak) {
      this.persistent.clearWeak();
    }
    return this._refcount;
  };
  Reference2.prototype.unref = function() {
    if (this.persistent.isEmpty() || this._refcount === 0) {
      return 0;
    }
    if (--this._refcount === 0) {
      this._setWeak();
    }
    return this._refcount;
  };
  Reference2.prototype.get = function(envObject) {
    if (envObject === void 0) {
      envObject = this.envObject;
    }
    if (this.persistent.isEmpty()) {
      return 0;
    }
    var obj = this.persistent.deref();
    var handle = envObject.ensureHandle(obj);
    return handle.id;
  };
  Reference2.prototype.resetFinalizer = function() {
  };
  Reference2.prototype.data = function() {
    return 0;
  };
  Reference2.prototype.refcount = function() {
    return this._refcount;
  };
  Reference2.prototype.ownership = function() {
    return this._ownership;
  };
  Reference2.prototype.callUserFinalizer = function() {
  };
  Reference2.prototype.invokeFinalizerFromGC = function() {
    this.finalize();
  };
  Reference2.prototype._setWeak = function() {
    if (this.canBeWeak) {
      this.persistent.setWeak(this, Reference2.weakCallback);
    } else {
      this.persistent.reset();
    }
  };
  Reference2.prototype.finalize = function() {
    this.persistent.reset();
    var deleteMe = this._ownership === ReferenceOwnership.kRuntime;
    this.unlink();
    this.callUserFinalizer();
    if (deleteMe) {
      this.dispose();
    }
  };
  Reference2.prototype.dispose = function() {
    if (this.id === 0)
      return;
    this.unlink();
    this.persistent.reset();
    this.envObject.ctx.refStore.remove(this.id);
    _super.prototype.dispose.call(this);
    this.envObject = void 0;
    this.id = 0;
  };
  return Reference2;
})(RefTracker);
var ReferenceWithData = /* @__PURE__ */ (function(_super) {
  __extends(ReferenceWithData2, _super);
  function ReferenceWithData2(envObject, value, initialRefcount, ownership, _data) {
    var _this = _super.call(this, envObject, value, initialRefcount, ownership) || this;
    _this._data = _data;
    return _this;
  }
  ReferenceWithData2.create = function(envObject, value, initialRefcount, ownership, data) {
    var reference = new ReferenceWithData2(envObject, value, initialRefcount, ownership, data);
    envObject.ctx.refStore.add(reference);
    reference.link(envObject.reflist);
    return reference;
  };
  ReferenceWithData2.prototype.data = function() {
    return this._data;
  };
  return ReferenceWithData2;
})(Reference);
var ReferenceWithFinalizer = /* @__PURE__ */ (function(_super) {
  __extends(ReferenceWithFinalizer2, _super);
  function ReferenceWithFinalizer2(envObject, value, initialRefcount, ownership, finalize_callback, finalize_data, finalize_hint) {
    var _this = _super.call(this, envObject, value, initialRefcount, ownership) || this;
    _this._finalizer = new Finalizer(envObject, finalize_callback, finalize_data, finalize_hint);
    return _this;
  }
  ReferenceWithFinalizer2.create = function(envObject, value, initialRefcount, ownership, finalize_callback, finalize_data, finalize_hint) {
    var reference = new ReferenceWithFinalizer2(envObject, value, initialRefcount, ownership, finalize_callback, finalize_data, finalize_hint);
    envObject.ctx.refStore.add(reference);
    reference.link(envObject.finalizing_reflist);
    return reference;
  };
  ReferenceWithFinalizer2.prototype.resetFinalizer = function() {
    this._finalizer.resetFinalizer();
  };
  ReferenceWithFinalizer2.prototype.data = function() {
    return this._finalizer.data();
  };
  ReferenceWithFinalizer2.prototype.callUserFinalizer = function() {
    this._finalizer.callFinalizer();
  };
  ReferenceWithFinalizer2.prototype.invokeFinalizerFromGC = function() {
    this._finalizer.envObject.invokeFinalizerFromGC(this);
  };
  ReferenceWithFinalizer2.prototype.dispose = function() {
    if (!this._finalizer)
      return;
    this._finalizer.envObject.dequeueFinalizer(this);
    this._finalizer.dispose();
    _super.prototype.dispose.call(this);
    this._finalizer = void 0;
  };
  return ReferenceWithFinalizer2;
})(Reference);
var Deferred = /* @__PURE__ */ (function() {
  function Deferred2(ctx, value) {
    Object.defineProperties(this, {
      id: {
        configurable: true,
        enumerable: true,
        value: 0,
        writable: true
      },
      ctx: {
        configurable: true,
        enumerable: true,
        value: ctx,
        writable: true
      },
      value: {
        configurable: true,
        enumerable: true,
        value,
        writable: true
      }
    });
  }
  Deferred2.create = function(ctx, value) {
    var deferred = new Deferred2(ctx, value);
    ctx.deferredStore.add(deferred);
    return deferred;
  };
  Deferred2.prototype.resolve = function(value) {
    this.value.resolve(value);
    this.dispose();
  };
  Deferred2.prototype.reject = function(reason) {
    this.value.reject(reason);
    this.dispose();
  };
  Deferred2.prototype.dispose = function() {
    this.ctx.deferredStore.remove(this.id);
    this.id = 0;
    this.value = null;
    this.ctx = null;
  };
  return Deferred2;
})();
var Store = /* @__PURE__ */ (function() {
  function Store2() {
    this._values = [void 0];
    this._values.length = 4;
    this._size = 1;
    this._freeList = [];
  }
  Store2.prototype.add = function(value) {
    var id;
    if (this._freeList.length) {
      id = this._freeList.shift();
    } else {
      id = this._size;
      this._size++;
      var capacity = this._values.length;
      if (id >= capacity) {
        this._values.length = capacity + (capacity >> 1) + 16;
      }
    }
    value.id = id;
    this._values[id] = value;
  };
  Store2.prototype.get = function(id) {
    return this._values[id];
  };
  Store2.prototype.has = function(id) {
    return this._values[id] !== void 0;
  };
  Store2.prototype.remove = function(id) {
    var value = this._values[id];
    if (value) {
      value.id = 0;
      this._values[id] = void 0;
      this._freeList.push(Number(id));
    }
  };
  Store2.prototype.dispose = function() {
    for (var i = 1; i < this._size; ++i) {
      var value = this._values[i];
      value === null || value === void 0 ? void 0 : value.dispose();
    }
    this._values = [void 0];
    this._size = 1;
    this._freeList = [];
  };
  return Store2;
})();
var kMaxReasonableBytes = BigInt(1) << BigInt(60);
var kMinReasonableBytes = -kMaxReasonableBytes;
var ExternalMemory = /* @__PURE__ */ (function() {
  function ExternalMemory2(onChange) {
    this.total = BigInt(0);
    this.onChange = onChange !== null && onChange !== void 0 ? onChange : null;
  }
  ExternalMemory2.prototype.adjust = function(changeInBytes) {
    changeInBytes = BigInt(changeInBytes);
    if (!(kMinReasonableBytes <= changeInBytes && changeInBytes < kMaxReasonableBytes)) {
      throw new RangeError("changeInBytes ".concat(changeInBytes, " is out of reasonable range"));
    }
    var old = this.total;
    this.total += changeInBytes;
    var amount = this.total;
    var onChange = this.onChange;
    if (changeInBytes) {
      onChange === null || onChange === void 0 ? void 0 : onChange(amount, old, changeInBytes);
    }
    return amount;
  };
  return ExternalMemory2;
})();
var CleanupHookCallback = /* @__PURE__ */ (function() {
  function CleanupHookCallback2(envObject, fn, arg, order) {
    this.envObject = envObject;
    this.fn = fn;
    this.arg = arg;
    this.order = order;
  }
  return CleanupHookCallback2;
})();
var CleanupQueue = /* @__PURE__ */ (function() {
  function CleanupQueue2() {
    this._cleanupHooks = [];
    this._cleanupHookCounter = 0;
  }
  CleanupQueue2.prototype.empty = function() {
    return this._cleanupHooks.length === 0;
  };
  CleanupQueue2.prototype.add = function(envObject, fn, arg) {
    if (this._cleanupHooks.filter(function(hook) {
      return hook.envObject === envObject && hook.fn === fn && hook.arg === arg;
    }).length > 0) {
      throw new Error("Can not add same fn and arg twice");
    }
    this._cleanupHooks.push(new CleanupHookCallback(envObject, fn, arg, this._cleanupHookCounter++));
  };
  CleanupQueue2.prototype.remove = function(envObject, fn, arg) {
    for (var i = 0; i < this._cleanupHooks.length; ++i) {
      var hook = this._cleanupHooks[i];
      if (hook.envObject === envObject && hook.fn === fn && hook.arg === arg) {
        this._cleanupHooks.splice(i, 1);
        return;
      }
    }
  };
  CleanupQueue2.prototype.drain = function() {
    var hooks = this._cleanupHooks.slice();
    hooks.sort(function(a, b) {
      return b.order - a.order;
    });
    for (var i = 0; i < hooks.length; ++i) {
      var cb = hooks[i];
      if (typeof cb.fn === "number") {
        cb.envObject.makeDynCall_vp(cb.fn)(cb.arg);
      } else {
        cb.fn(cb.arg);
      }
      this._cleanupHooks.splice(this._cleanupHooks.indexOf(cb), 1);
    }
  };
  CleanupQueue2.prototype.dispose = function() {
    this._cleanupHooks.length = 0;
    this._cleanupHookCounter = 0;
  };
  return CleanupQueue2;
})();
var NodejsWaitingRequestCounter = /* @__PURE__ */ (function() {
  function NodejsWaitingRequestCounter2() {
    this.refHandle = new _MessageChannel().port1;
    this.count = 0;
  }
  NodejsWaitingRequestCounter2.prototype.increase = function() {
    if (this.count === 0) {
      if (this.refHandle.ref) {
        this.refHandle.ref();
      }
    }
    this.count++;
  };
  NodejsWaitingRequestCounter2.prototype.decrease = function() {
    if (this.count === 0)
      return;
    if (this.count === 1) {
      if (this.refHandle.unref) {
        this.refHandle.unref();
      }
    }
    this.count--;
  };
  return NodejsWaitingRequestCounter2;
})();
var Context = /* @__PURE__ */ (function() {
  function Context2(options) {
    var _this = this;
    this._isStopping = false;
    this._canCallIntoJs = true;
    this._suppressDestroy = false;
    this.envStore = new Store();
    this.scopeStore = new ScopeStore();
    this.refStore = new Store();
    this.deferredStore = new Store();
    this.handleStore = new HandleStore();
    this.feature = {
      supportReflect,
      supportFinalizer,
      supportWeakSymbol,
      supportBigInt,
      supportNewFunction,
      canSetFunctionName,
      setImmediate: _setImmediate,
      Buffer: _Buffer,
      MessageChannel: _MessageChannel
    };
    this.cleanupQueue = new CleanupQueue();
    this._externalMemory = new ExternalMemory(options === null || options === void 0 ? void 0 : options.onExternalMemoryChange);
    if (typeof process === "object" && process !== null && typeof process.once === "function") {
      this.refCounter = new NodejsWaitingRequestCounter();
      process.once("beforeExit", function() {
        if (!_this._suppressDestroy) {
          _this.destroy();
        }
      });
    }
  }
  Context2.prototype.suppressDestroy = function() {
    this._suppressDestroy = true;
  };
  Context2.prototype.getRuntimeVersions = function() {
    return {
      version,
      NODE_API_SUPPORTED_VERSION_MAX,
      NAPI_VERSION_EXPERIMENTAL,
      NODE_API_DEFAULT_MODULE_API_VERSION
    };
  };
  Context2.prototype.createNotSupportWeakRefError = function(api, message) {
    return new NotSupportWeakRefError(api, message);
  };
  Context2.prototype.createNotSupportBufferError = function(api, message) {
    return new NotSupportBufferError(api, message);
  };
  Context2.prototype.createReference = function(envObject, handle_id, initialRefcount, ownership) {
    return Reference.create(envObject, handle_id, initialRefcount, ownership);
  };
  Context2.prototype.createReferenceWithData = function(envObject, handle_id, initialRefcount, ownership, data) {
    return ReferenceWithData.create(envObject, handle_id, initialRefcount, ownership, data);
  };
  Context2.prototype.createReferenceWithFinalizer = function(envObject, handle_id, initialRefcount, ownership, finalize_callback, finalize_data, finalize_hint) {
    if (finalize_callback === void 0) {
      finalize_callback = 0;
    }
    if (finalize_data === void 0) {
      finalize_data = 0;
    }
    if (finalize_hint === void 0) {
      finalize_hint = 0;
    }
    return ReferenceWithFinalizer.create(envObject, handle_id, initialRefcount, ownership, finalize_callback, finalize_data, finalize_hint);
  };
  Context2.prototype.createDeferred = function(value) {
    return Deferred.create(this, value);
  };
  Context2.prototype.adjustAmountOfExternalAllocatedMemory = function(changeInBytes) {
    return this._externalMemory.adjust(changeInBytes);
  };
  Context2.prototype.createEnv = function(filename, moduleApiVersion, makeDynCall_vppp, makeDynCall_vp, abort, nodeBinding) {
    return newEnv(this, filename, moduleApiVersion, makeDynCall_vppp, makeDynCall_vp, abort, nodeBinding);
  };
  Context2.prototype.createTrackedFinalizer = function(envObject, finalize_callback, finalize_data, finalize_hint) {
    return TrackedFinalizer.create(envObject, finalize_callback, finalize_data, finalize_hint);
  };
  Context2.prototype.getCurrentScope = function() {
    return this.scopeStore.currentScope;
  };
  Context2.prototype.addToCurrentScope = function(value) {
    return this.scopeStore.currentScope.add(value);
  };
  Context2.prototype.openScope = function(envObject) {
    var scope = this.scopeStore.openScope(this.handleStore);
    if (envObject)
      envObject.openHandleScopes++;
    return scope;
  };
  Context2.prototype.closeScope = function(envObject, _scope) {
    if (envObject && envObject.openHandleScopes === 0)
      return;
    this.scopeStore.closeScope();
    if (envObject)
      envObject.openHandleScopes--;
  };
  Context2.prototype.ensureHandle = function(value) {
    switch (value) {
      case void 0:
        return HandleStore.UNDEFINED;
      case null:
        return HandleStore.NULL;
      case true:
        return HandleStore.TRUE;
      case false:
        return HandleStore.FALSE;
      case _global:
        return HandleStore.GLOBAL;
    }
    return this.addToCurrentScope(value);
  };
  Context2.prototype.addCleanupHook = function(envObject, fn, arg) {
    this.cleanupQueue.add(envObject, fn, arg);
  };
  Context2.prototype.removeCleanupHook = function(envObject, fn, arg) {
    this.cleanupQueue.remove(envObject, fn, arg);
  };
  Context2.prototype.runCleanup = function() {
    while (!this.cleanupQueue.empty()) {
      this.cleanupQueue.drain();
    }
  };
  Context2.prototype.increaseWaitingRequestCounter = function() {
    var _a;
    (_a = this.refCounter) === null || _a === void 0 ? void 0 : _a.increase();
  };
  Context2.prototype.decreaseWaitingRequestCounter = function() {
    var _a;
    (_a = this.refCounter) === null || _a === void 0 ? void 0 : _a.decrease();
  };
  Context2.prototype.setCanCallIntoJs = function(value) {
    this._canCallIntoJs = value;
  };
  Context2.prototype.setStopping = function(value) {
    this._isStopping = value;
  };
  Context2.prototype.canCallIntoJs = function() {
    return this._canCallIntoJs && !this._isStopping;
  };
  Context2.prototype.destroy = function() {
    this.setStopping(true);
    this.setCanCallIntoJs(false);
    this.runCleanup();
  };
  return Context2;
})();
var defaultContext;
function createContext(options) {
  return new Context(options);
}
function getDefaultContext() {
  if (!defaultContext) {
    defaultContext = createContext();
  }
  return defaultContext;
}
export {
  ConstHandle,
  Context,
  Deferred,
  EmnapiError,
  Env,
  External,
  Finalizer,
  Handle,
  HandleScope,
  HandleStore,
  NAPI_VERSION_EXPERIMENTAL,
  NODE_API_DEFAULT_MODULE_API_VERSION,
  NODE_API_SUPPORTED_VERSION_MAX,
  NODE_API_SUPPORTED_VERSION_MIN,
  NodeEnv,
  NotSupportBufferError,
  NotSupportWeakRefError,
  Persistent,
  RefTracker,
  Reference,
  ReferenceOwnership,
  ReferenceWithData,
  ReferenceWithFinalizer,
  ScopeStore,
  Store,
  TrackedFinalizer,
  TryCatch,
  createContext,
  getDefaultContext,
  getExternalValue,
  isExternal,
  isReferenceType,
  version
};
