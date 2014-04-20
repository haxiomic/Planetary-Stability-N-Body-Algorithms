package sysUtils;

using sysUtils.Escape;

class HackyCSV {
	public var rowCount(default, null):Int = 0;

	var columns:Array<Column>;
	var separator:String;

	public function new(separator:String = ","){
		this.separator = separator;
		columns = new Array<Column>();
	}

	public function addColumn(data:Array<Dynamic>, ?header:String){
		var c = new Column(data, header);

		if(c.rowCount>rowCount)rowCount = c.rowCount;
		else c.padWithBlanks(rowCount);	//not enough rows supplied

		columns.push(c);
	}

	public function toString():String{
		var csvStr:String = "";
		for(r in 0...rowCount){
			for(c in 0...columns.length){
				csvStr += stringify(columns[c].row(r));
				if(c < columns.length-1)csvStr += separator;
			}
			if(r < rowCount-1)csvStr += "\n";
		}
		return csvStr;
	}

	/*
	*	leaves numbers as they are
	*	null and bools are written as words true/false without quotes
	*	strings are encased in double quotes " ", the strings themselves have their quotes escaped
	*	everything else is written blank
	*/
	static function stringify(item:Dynamic):String{
		var str = "";

		var type:Type.ValueType = Type.typeof(item);
		if(
			type.equals(Type.ValueType.TInt) 	||
		  	type.equals(Type.ValueType.TFloat)	||
		  	type.equals(Type.ValueType.TBool) 	||
		  	type.equals(Type.ValueType.TNull)
		)
			str = Std.string(item);
		else if(
		  	type.equals(Type.typeof("_"))
		)
			str = "\""+sysUtils.Escape.escapeQuotes(sysUtils.Escape.escapeNewlines(item))+"\"";
		else
			str = "";
		
		return str;
	}
}

class Column{
	public var header(default, null):String = null;
	public var hasHeader(get, null):Bool;
	public var rowCount(get, null):Int;

	var data:Array<Dynamic>;//includes header

	public function new(data:Array<Dynamic>, ?header:String){
		this.header = header;
		this.data = new Array<Dynamic>();
		for(d in data){
			this.data.push(d);
		}
		//add header
		if(this.header!=null)this.data.unshift(header);
	}

	public function padWithBlanks(desiredLength:Int){
		var dl = desiredLength-this.rowCount;
		if(dl<=0)return;
		for(i in 0...dl){
			data.push("");
		}
	}

	public function row(index:Int):Dynamic{
		return data[index];
	}

	function get_hasHeader():Bool{
		return (header != null);
	}

	function get_rowCount():Int{
		return data.length;
	}
}