package sysUtils.compileTime;

import haxe.macro.Context;
import sys.io.Process;

class Git{

	macro public static function lastCommit(){
	    return Context.makeExpr(executeGitLog1("medium"), Context.currentPos());
	}

	macro public static function lastCommitHash(){
		//git log -n 1 --pretty=format:"%H"	
		return Context.makeExpr(executeGitLog1("format:%H"), Context.currentPos());
	}

	macro public static function lastCommitMessage(){
		//git log -n 1 --pretty=format:"%s"	
		return Context.makeExpr(executeGitLog1("format:%s"), Context.currentPos());
	}

	private static function executeGitLog1(format:String):String{
		var p:Process = new Process("git", ["log", "-n 1", "--pretty="+format]);
		if(p.exitCode()!=0){
			//process failed!
			return null;			
		}
		var result = p.stdout.readAll().toString();
		p.close();
		return result;
	}
}