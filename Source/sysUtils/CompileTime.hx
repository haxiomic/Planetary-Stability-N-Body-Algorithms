package sysUtils;

import haxe.macro.Context;

class CompileTime{
	macro public static function buildDate(format:String = "%Y-%M-%D %H:%M:%S") {
	    var date = DateTools.format(Date.now(), format);
	    return Context.makeExpr(date, Context.currentPos());
	}

	macro public static function buildDir() {
	    var cwd = Sys.getCwd();
	    return Context.makeExpr(cwd, Context.currentPos());
	}
}