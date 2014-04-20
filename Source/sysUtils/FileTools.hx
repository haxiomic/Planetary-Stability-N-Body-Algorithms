package sysUtils;

class FileTools{
	//createDirectoryBool can be a boolean or a function, dir:String -> Bool
	static public function save(path:String, data:String, createDirectoryBool:Dynamic = true, overwrite:Bool = true):Bool{
		var hxPath = new haxe.io.Path(path);

		var filename = hxPath.file;
		//Assess file out directory
		var outDir = haxe.io.Path.normalize(hxPath.dir);

		//Check if out directory exists
		if(!sys.FileSystem.exists(outDir)){
			var r = Reflect.isFunction(createDirectoryBool) ? createDirectoryBool(outDir) : createDirectoryBool;//check if function or boolean

			if(r==true){
				sys.FileSystem.createDirectory(outDir);
			}else{
				throw "cannot save data";
				return false;
				//create out directory
			}
		}

		//Check the file doesn't already exist, if it does, find a free suffix -xx
		var filePath = overwrite ? hxPath.toString() : FileTools.findFreeFile(hxPath.toString());
		filePath = haxe.io.Path.normalize(filePath);//normalize path for readability

		sys.io.File.saveContent(filePath, data);

		Console.printSuccess("Data saved to "+Console.BRIGHT_WHITE+filePath+Console.RESET);

		return true;
	}

	//Recursively search for a free file path by appending numerical extension in the form (x)
	static public function findFreeFile(path:String){
		if(!sys.FileSystem.exists(path))return path;//no file exists here, we're good

		var hxPath = new haxe.io.Path(path);

		var filenameWOExt = hxPath.file;
		var ext = hxPath.ext;
		var dir = hxPath.dir;
	
		//get last digit (x)
		var lastDigitReg:EReg = ~/\s\((\d+)\)$/;
		if(lastDigitReg.match(filenameWOExt)){
			//file has suffix (x), increment by 1
			var n = Std.parseInt(lastDigitReg.matched(1));
			n++;
			filenameWOExt = lastDigitReg.replace(filenameWOExt, " ("+Std.string(n)+")");
		}else{
			//append suffix (1)
			filenameWOExt += " (1)";
		}

		var filenameNew = filenameWOExt+"."+ext;
		var pathNew = haxe.io.Path.join([dir, filenameNew]);//dir/filenameNew;

		return findFreeFile(pathNew);
	}
}