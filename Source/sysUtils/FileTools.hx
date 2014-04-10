package sysUtils;

class FileTools{
	//Recursively search for a free file path by appending numerical extension in the form -xx
	static public function findFreeFile(path:String){
		if(!sys.FileSystem.exists(path))return path;//no file exists here, we're good

		//Append number to filename
		//get filename and directory
		var explodedPath = path.split("/");
		var filename = explodedPath.pop();
		var dir = explodedPath.join("/");

		var explodedFilename = filename.split(".");
		var ext = explodedFilename.pop();
		var filenameWOExt = explodedFilename.join(".");

		//get last digit -xx
		var lastDigitReg:EReg = ~/\s\((\d+)\)$/;
		if(lastDigitReg.match(filenameWOExt)){
			//file has suffix -xx, increment by 1
			var n = Std.parseInt(lastDigitReg.matched(1));
			n++;
			filenameWOExt = lastDigitReg.replace(filenameWOExt, " ("+Std.string(n)+")");
		}else{
			//append suffix -1
			filenameWOExt += " (1)";
		}

		var filenameNew = filenameWOExt+"."+ext;
		var pathNew = dir+"/"+filenameNew;

		return findFreeFile(pathNew);
	}
}