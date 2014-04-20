package sysUtils;

class Escape{
	//Escapes " and ' with \", ignores already escaped quotes
	static public function escapeQuotes(str:String):String{
		var reg:EReg = ~/(["'])/g;
		var resultStr = "";
		while(reg.match(str)){
			var quote = reg.matched(0);
			var leftChar = str.charAt(reg.matchedPos().pos-1);
			resultStr+=reg.matchedLeft()+(leftChar != "\\" ? "\\" : "" )+quote;
			str = reg.matchedRight();
		}
		resultStr+=str;
		return resultStr;
	}
	
	//Linebreak characters are replaced with '\n'
	static public function escapeNewlines(str:String):String{
		var reg:EReg = ~/([\n])/g;
		var resultStr = "";
		while(reg.match(str)){
			var leftChar = str.charAt(reg.matchedPos().pos-1);
			resultStr+=reg.matchedLeft()+(leftChar != "\\" ? "\\" : "" )+"n";
			str = reg.matchedRight();
		}
		resultStr+=str;
		return resultStr;
	}
}