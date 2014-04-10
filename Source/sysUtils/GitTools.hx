package sysUtils;

import sys.io.Process;

class GitTools{

	public static function lastCommit():String{
		//git log -n 1 --pretty=medium
		return executeGitLog1("medium");
	}

	public static function lastCommitMessage():String{
		//git log -n 1 --pretty=format:"%s"
		return executeGitLog1('format:"%s"');
	}

	public static function lastCommitHash():String{
		//git log -n 1 --pretty=format:"%H"	
		return executeGitLog1('format:"%H"');
	}


	// --- Private Methods ---
	private static function executeGitLog1(format:String):String{
		var p:Process = new Process("git", ["log", "-n 1", "--pretty=medium"]);
		if(p.exitCode()!=0){
			//process failed!
			return null;			
		}
		var result = p.stdout.readAll().toString();
		p.close();
		return result;
	}
}