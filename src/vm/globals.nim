######################################################
# Arturo
# Programming Language + Bytecode VM compiler
# (c) 2019-2022 Yanis Zafirópulos
#
# @file: vm/globals.nim
######################################################

#=======================================
# Libraries
#=======================================

import std/editdistance, sequtils, tables

import vm/[errors, profiler, values/value]

#=======================================
# Globals
#=======================================

# TODO(VM/globals) Is there any way to actually avoid them altogether?
#  Having all these global variables is practical, but it actually causes problems when we end up wanting to work with multiple threads. An idea would be to add them as fields in a VM object, and pass this object around. But it would still need to be properly benchmark as it would - undoubtedly - add some serious overhead.
#  labels: vm, enhancement, benchmark, open discussion

var
    # symbols
    Syms* {.global.}      : ValueDict

    # symbol aliases
    Aliases* {.global.}   : SymbolDict

    # function arity reference
    Arities* {.global.}   : Table[string,int]

    # libraries 
    Libraries* {.global.} : seq[BuiltinAction]

#=======================================
# Methods
#=======================================

func suggestAlternative*(s: string, reference: ValueDict = Syms): seq[string] {.inline.} =
    var levs = initOrderedTable[string,int]()

    for k,v in pairs(reference):
        levs[k] = editDistance(s,k)

    proc cmper (x, y: (string, int)): int {.closure.} = cmp(x[1], y[1])
    levs.sort(cmper)

    if levs.len > 3: result = toSeq(levs.keys)[0..2]
    else: result = toSeq(levs.keys)

#=======================================
# Methods
#=======================================

template GetKey*(dict: ValueDict, key: string): untyped =
    let toRet = dict.getOrDefault(key, nil)
    if unlikely(toRet.isNil):
        RuntimeError_KeyNotFound(key, suggestAlternative(key, reference=dict))
    toRet

template GetArrayIndex*(arr: ValueArray, indx: int): untyped =
    if unlikely(indx < 0 or indx > (arr.len)-1):
        RuntimeError_OutOfBounds(indx, arr.len-1)
    arr[indx]

template SetArrayIndex*(arr: ValueArray, indx: int, v: Value): untyped =
    if unlikely(indx < 0 or indx > (arr.len)-1):
        RuntimeError_OutOfBounds(indx, arr.len-1)
    arr[indx] = v

template InPlace*(): untyped =
    when defined(PROFILER):
        hookProcProfiler("globals/InPlace"):
            if unlikely(not Syms.hasKey(x.s)):
                RuntimeError_SymbolNotFound(x.s, suggestAlternative(x.s))
            discard Syms[x.s]
        Syms[x.s]
    else:
        if unlikely(not Syms.hasKey(x.s)):
            RuntimeError_SymbolNotFound(x.s, suggestAlternative(x.s))
        Syms[x.s]

template InPlaced*(): untyped =
    Syms[x.s]

template SetInPlace*(v: Value): untyped =
    Syms[x.s] = v

template SymExists*(s: string): untyped =
    Syms.hasKey(s)

proc GetSym*(s: string, unsafe: static bool = false): Value {.inline.} =
    when not unsafe:
        if (result = Syms.getOrDefault(s, nil); unlikely(result.isNil)):
            RuntimeError_SymbolNotFound(s, suggestAlternative(s))
    else:
        Syms[s]

template SetSym*(s: string, v: Value): untyped =
    Syms[s] = v