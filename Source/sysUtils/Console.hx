package sysUtils;

class Console {
	
	static public function printRaw(v:Dynamic){
		Sys.print(v);
	}

	static public function newLine() printRaw('\n');

	static public function print(v:Dynamic, newLine:Bool = true){
		var str:String = v;
		if(newLine)Sys.println(str);
		else Sys.print(str);
	}

	static public function printStatement(v:Dynamic, newLine:Bool = true){
		var str:String = BRIGHT_WHITE+BOLD+v+RESET;
		if(newLine)Sys.println(str);
		else Sys.print(str);
	}

	static public function printTitle(v:Dynamic, newLine:Bool = true){
		var str:String = BLUE+BOLD+'\t-- '+v+' --'+RESET+'\n';
		if(newLine)Sys.println(str);
		else Sys.print(str);
	}

	static public function printError(v:Dynamic, newLine:Bool = true){
		var str:String = RED+BOLD+"Error"+RESET+": "+v+RESET;
		if(newLine)Sys.println(str);
		else Sys.print(str);
	}

	static public function printConcern(v:Dynamic, newLine:Bool = true){
		var str:String = YELLOW+BOLD+v+RESET;
		if(newLine)Sys.println(str);
		else Sys.print(str);
	}

	static public function printSuccess(v:Dynamic, newLine:Bool = true){
		var str:String = BRIGHT_GREEN+BOLD+v+RESET;
		if(newLine)Sys.println(str);
		else Sys.print(str);
	}

	static public function printQuestion(v:Dynamic, newLine:Bool = true){
		var str:String = BRIGHT_WHITE+BOLD+v+RESET;
		if(newLine)Sys.println(str);
		else Sys.print(str);
	}

	static public function askYesNoQuestion(v, suffix:String = " (y/n)\n-> ", newLine:Bool = false):Bool{
		printQuestion(v+suffix, false);
		var char:Int = Sys.getChar(true);
		Console.newLine();
		return (String.fromCharCode(char).toLowerCase() == "y");
	}

	//Console format escape strings
	static public var BLACK_CODE = 0;
	static public var RED_CODE = 1;
	static public var GREEN_CODE = 2;
	static public var YELLOW_CODE = 3;
	static public var BLUE_CODE = 4;
	static public var MAGENTA_CODE = 5;
	static public var CYAN_CODE = 6;
	static public var WHITE_CODE = 7;
	static public var BRIGHT_BLACK_CODE = 8;
	static public var BRIGHT_RED_CODE = 9;
	static public var BRIGHT_GREEN_CODE = 10;
	static public var BRIGHT_YELLOW_CODE = 11;
	static public var BRIGHT_BLUE_CODE = 12;
	static public var BRIGHT_MAGENTA_CODE = 13;
	static public var BRIGHT_CYAN_CODE = 14;
	static public var BRIGHT_WHITE_CODE = 15;

	static public var BLACK = '\033[38;5;'+BLACK_CODE+'m';
	static public var RED = '\033[38;5;'+RED_CODE+'m';
	static public var GREEN = '\033[38;5;'+GREEN_CODE+'m';
	static public var YELLOW = '\033[38;5;'+YELLOW_CODE+'m';
	static public var BLUE = '\033[38;5;'+BLUE_CODE+'m';
	static public var MAGENTA = '\033[38;5;'+MAGENTA_CODE+'m';
	static public var CYAN = '\033[38;5;'+CYAN_CODE+'m';
	static public var WHITE = '\033[38;5;'+WHITE_CODE+'m';
	static public var BRIGHT_BLACK = '\033[38;5;'+BRIGHT_BLACK_CODE+'m';
	static public var BRIGHT_RED = '\033[38;5;'+BRIGHT_RED_CODE+'m';
	static public var BRIGHT_GREEN = '\033[38;5;'+BRIGHT_GREEN_CODE +'m';
	static public var BRIGHT_YELLOW = '\033[38;5;'+BRIGHT_YELLOW_CODE +'m';
	static public var BRIGHT_BLUE = '\033[38;5;'+BRIGHT_BLUE_CODE +'m';
	static public var BRIGHT_MAGENTA = '\033[38;5;'+BRIGHT_MAGENTA_CODE +'m';
	static public var BRIGHT_CYAN = '\033[38;5;'+BRIGHT_CYAN_CODE +'m';
	static public var BRIGHT_WHITE = '\033[38;5;'+BRIGHT_WHITE_CODE +'m';
	static public var BOLD = '\033[1m';
	static public var RESET = '\033[m';
}