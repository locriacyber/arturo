/*****************************************************************
 * Arturo
 * 
 * Programming Language + Interpreter
 * (c) 2019 Yanis Zafirópulos (aka Dr.Kameleon)
 *
 * @file: context.d
 *****************************************************************/

module context;

// Imports

import std.algorithm;
import std.array;
import std.conv;
import std.stdio;
import std.string;
import std.typetuple;

import parser.statements;

import value;

import env;
import func;
import var;

import panic;

import globals;

// Definitions

enum ContextType : string
{
    blockContext = "block",
    dictionaryContext = "dictionary",
    functionContext = "function"
}

// Functions

class Context {
    Func[string] functions;
    Var[string] variables;
    ContextType type;
    Env env;

    this(ContextType xctype=ContextType.blockContext) {
        env = new Env();
        type = xctype;
    }

    Context dup() {
        Context ret = new Context(type);
        ret.functions = functions.dup;
        ret.variables = variables.dup;
        return ret;
    }

    void  _varUnset(string n) {
        if (_varExists(n))  {
            variables.remove(n);
        }
    }

    void _varSet(string n, Value v, bool immut = false) {
        //writeln("in _varSet: before");
        variables[n] = new Var(n,v,immut);
        //writeln("in _varSet: after");
    }

    Var _varGet(string n) {
        return variables[n];
    }

    bool _varExists(string n) {
        return ((n in variables)!=null);
    }

    const bool _varExistsImmut(string n) {
        return ((n in variables)!=null);
    }

    void funcSet(Func f) {
        functions[f.getFullName()] = f;
    }

    void funcSet(string n, Statements s = null) {
        Func f = new Func(n,s);
        funcSet(f);
    }

    Func funcGet(string n) {
        if (funcExists(n)) {
            if ((n in functions)!=null) return functions[n];
            else {
                foreach (Func f; functions) {
                    if (f.name==n) return  f;
                }
            }
        }

        throw new ERR_FunctionNotFound(n);
    }

    bool funcExists(string n) {
        bool fullNameExists = ((n in functions)!=null);

        if (fullNameExists) return true;
        else {
            foreach (Func f; functions) {
                if (f.name==n) return  true;
            }
        }
        
        return false;
    }

    string inspectVars() {
        string[] ret;
        foreach (string name, Var v; variables) {
            //writeln("name=" ~ name);
            //if (name!="this") {
                ret ~= "\t" ~ name ~ ": (0x" ~ to!string(cast(void*)v) ~ "|0x" ~ to!string(cast(void*)v.value) ~ ") = " ~ v.value.stringify();
            //}
        }

        return ret.join("\n");
    }

    void _inspect() {
        env.inspect();
        foreach (string name, Var v; variables) {
            v.inspect();
        }
        string[] s = [];
        foreach (string name, Func f; functions) {
            if (f.type==FuncType.systemFunc) s ~= name;

            f.inspect();
        }

        // For sublime-syntax (system functions scope)
        writeln(s.sort().join("|"));
    }
}
