// 搬家到了JS，因为没警告（虽然目前qmlls也没给补全）

// mock
const backend = typeof Backend !== 'undefined' ? Backend : {
  callLuaFunction: (fn, params) => {
    console.log(`Lua.call: ${fn} ${params}`);
  },
  evalLuaExp: (exp) => {
    console.log(`Lua.evaluate: ${exp}`);
  },
  translate: (src) => {
    return src;
  },
};

function call(funcName, ...params) {
  return backend.callLuaFunction(funcName, [...params]);
}

function evaluate(lua) {
  return backend.evalLuaExp(`return ${lua}`);
}

function tr(src) {
  return backend.translate(src);
}
