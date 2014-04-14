package sysUtils.compileTime;

import haxe.macro.Context;

class Build{
	macro public static function date(format:String = "%Y-%m-%d %H:%M:%S") {
	    var date = DateTools.format(Date.now(), format);
	    return Context.makeExpr(date, Context.currentPos());
	}

	macro public static function dir() {
	    var cwd = Sys.getCwd();
	    return Context.makeExpr(cwd, Context.currentPos());
	}
}