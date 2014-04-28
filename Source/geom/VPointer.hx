package geom;

using cpp.NativeArray;

typedef ArrayType = Array<Float>;

class VPointer implements ArrayAccess<Float>{
	public var index:Int;
	public var array:ArrayType;
	public function new(?array:ArrayType, index:Int = 0){
		this.array = array == null ? new ArrayType() : array;
		this.index = index;
	}

	inline function __get(i:Int):Float
		return array.unsafeGet(i+index);
	
	inline function __set(i:Int, value:Float):Float
		return array.unsafeSet(i+index, value);
}