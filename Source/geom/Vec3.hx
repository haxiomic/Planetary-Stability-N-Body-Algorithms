package geom;

import haxe.ds.Vector;

typedef Data = Vector<Float>;

abstract Vec3(Data) from Data to Data{
	public inline function new(x:Float = 0, y:Float = 0, z:Float = 0) {
		this = new Vector<Float>(3);
		//this = new Data();

		this[0] = x;
		this[1] = y;
		this[2] = z;
	}

	public var x(get, set):Float;
	public var y(get, set):Float;
	public var z(get, set):Float;

	@:arrayAccess public inline function arrayRead(index:Int):Float return this[index];
	@:arrayAccess public inline function arrayWrite(index:Int, v:Float):Float return this[index] = v;

	public inline function get_x():Float return this[0];
	public inline function get_y():Float return this[1];
	public inline function get_z():Float return this[2];
	public inline function set_x(v:Float):Float return this[0] = v;
	public inline function set_y(v:Float):Float return this[1] = v;
	public inline function set_z(v:Float):Float return this[2] = v;

	public inline function iterator():VecIterator{
		return new VecIterator(3);
	}

	@:from inline static public function fromFloat(v:Float) {
		return new Vec3(v,v,v);
	}

	@:from inline static public function fromArray(arr:Array<Null<Float>>) {
		return new Vec3(
			null == arr[0] ? 0 : arr[0],
			null == arr[1] ? 0 : arr[1],
			null == arr[2] ? 0 : arr[2]
		);
	}

	@:from inline static public function fromTypedef(o:{x:Dynamic, y:Dynamic, z:Dynamic}) {
		return new Vec3(o.x, o.y, o.z);
	}

	public inline function toString() {
	    return "Vec3("+x+","+y+","+z+")";
	}

	//------- Class Methods -------//
	public inline function length():Float
		return Math.sqrt(dot(this));

	public inline function lengthSquared():Float
		return dot(this);

	public inline function dot(prod:Vec3):Float
		return x * prod.x + y * prod.y + z * prod.z;

	public inline function normalize():Vec3{
		var d:Float = length();
		x /= d;
		y /= d;
		z /= d;
		return this;
	}

	public inline function zero():Vec3{
		x = 0;
		y = 0;
		z = 0;
		return this;
	}

	public inline function setProduct(v:Vec3, mul:Float){
		x = mul*v.x;
		y = mul*v.y;
		z = mul*v.z;
	}

	public inline function addProduct(v:Vec3, mul:Float){
		x += mul*v.x;
		y += mul*v.y;
		z += mul*v.z;
	}

	public inline function setFn(fn:Int->Float){
		x = fn(0);
		y = fn(1);
		z = fn(2);
	}

	public inline function addFn(fn:Int->Float){
		x += fn(0);
		y += fn(1);
		z += fn(2);
	}

	public inline function clone():Vec3{
		return new Vec3(x,y,z);
	}

	//------- Operator Overloads -------//
	//Order of definition is important
	@:op(A += B)
	static public inline function addAssign(a:Vec3, b:Vec3){
		a.x += b.x;
		a.y += b.y;
		a.z += b.z;
		return a;
	}

	@:op(A -= B)
	static public inline function subtractAssign(a:Vec3, b:Vec3){
		a.x -= b.x;
		a.y -= b.y;
		a.z -= b.z;
		return a;
	}

	@:op(A *= B)
	static public inline function multiplyIntAssign(a:Vec3, multiplier:Int){
		a.x *= multiplier;
		a.y *= multiplier;
		a.z *= multiplier;
		return a;
	}
	@:op(A *= B)
	static public inline function multiplyFloatAssign(a:Vec3, multiplier:Float){
		a.x *= multiplier;
		a.y *= multiplier;
		a.z *= multiplier;
		return a;
	}
	@:op(A *= B)
	static public inline function multiplyVec3Assign(a:Vec3, b:Vec3){
		a.x *= b.x;
		a.y *= b.y;
		a.z *= b.z;
		return a;
	}

	@:op(A /= B)
	static public inline function divideIntAssign(a:Vec3, scaler:Int){
		a.x /= scaler;
		a.y /= scaler;
		a.z /= scaler;
		return a;
	}
	@:op(A /= B)
	static public inline function divideFloatAssign(a:Vec3, scaler:Float){
		a.x /= scaler;
		a.y /= scaler;
		a.z /= scaler;
		return a;
	}
	@:op(A /= B)
	static public inline function divideVec3Assign(a:Vec3, b:Vec3){
		a.x /= b.x;
		a.y /= b.y;
		a.z /= b.z;
		return a;
	}

	@:op(A + B)
	static public inline function addVec3(a:Vec3, b:Vec3):Vec3
		return new Vec3(a.x + b.x, a.y + b.y, a.z + b.z);

	@:op(A - B)
	static public inline function subtractVec3(a:Vec3, b:Vec3):Vec3
		return new Vec3(a.x - b.x, a.y - b.y, a.z - b.z);

	@:op(A * B)
	static public inline function multiplyInt(a:Vec3, B:Int):Vec3
		return new Vec3(a.x*B, a.y*B, a.z*B);
	@:op(A * B)
	static public inline function multiplyFloat(a:Vec3, B:Float):Vec3
		return new Vec3(a.x*B, a.y*B, a.z*B);
	@:op(A * B)
	static public inline function multiplyVec3(a:Vec3, b:Vec3):Vec3
		return new Vec3(a.x*b.x, a.y*b.y, a.z*b.z);

	@:op(A / B)
	static public inline function divideInt(a:Vec3, B:Int):Vec3
		return new Vec3(a.x/B, a.y/B, a.z/B);
	@:op(A / B)
	static public inline function divideFloat(a:Vec3, B:Float):Vec3
		return new Vec3(a.x/B, a.y/B, a.z/B);
	@:op(A / B)
	static public inline function divideVec3(a:Vec3, b:Vec3):Vec3
		return new Vec3(a.x/b.x, a.y/b.y, a.z/b.z);

	@:op(-A)
	static public inline function invert(a:Vec3):Vec3
		return new Vec3(-a.x, -a.y, -a.z);

	@:op(A == B)
	static public inline function equalsDynamic(a:Vec3, b:Dynamic)
		return false;
	@:op(A == B)
	static public inline function equalsVec3(a:Vec3, b:Vec3)
		return (a.x == b.x) && (a.y == b.y) && (a.z == b.z);

	
	//------- Static Methods -------//
	static public inline function difference(a:Vec3, b:Vec3, R:Vec3):Vec3{//store result in r
		R.x = b.x - a.x;
		R.y = b.y - a.y;
		R.z = b.z - a.z;
		return R;
	}

	static public inline function distance(a:Vec3, b:Vec3):Float{
		return Math.sqrt(distanceSquared(a,b));
	}

	static public inline function distanceSquared(a:Vec3, b:Vec3):Float{
		return length3Squared(b.x - a.x, b.y - a.y, b.z - a.z);
	}

	// * private *
	static private inline function length3Squared(x:Float, y:Float, z:Float):Float{
		return x*x + y*y + z*z;
	}
}

class VecIterator {
	var size:Int;
	var i:Int;

	public inline function new(size:Int) {
		this.i = 0;
		this.size = size;
	}
	public inline function hasNext() return i < size;
	public inline function next() return i++;
}
