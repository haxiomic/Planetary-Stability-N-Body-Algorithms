package geom;

//AVec3 is a flexible Vec3 
//	it'll automatically assign a Vec3 from anything that supports the fields x,y,z. However, it'll create a new object in doing so! So it's not complete
abstract AVec3(Vec3) from Vec3{
	inline function new(x:Float, y:Float, z:Float){
		this = new Vec3(x,y,z);
	}

	@:from static public inline function fromTVec3(v:{x:Dynamic,y:Dynamic,z:Dynamic}){
		return new Vec3(v.x,v.y,v.z);
	}

	@:to public inline function toVec3():Vec3{
		return this;
	}
}

class Vec3{
	public var x:Float;
	public var y:Float;
	public var z:Float;

	public function new(x:Float = 0, y:Float = 0, z:Float = 0){
		this.x = x;
		this.y = y;
		this.z = z;
	}

	public inline function lengthSqr():Float{
		return x*x + y*y + z*z;
	}

	public inline function length():Float{
		return Math.sqrt(lengthSqr());
	}

	public inline function normalize():Void{
		var d:Float = length();
		this.x /= d;
		this.y /= d;
		this.z /= d;
	}

	public inline function zero():Void{
		this.x = 0;
		this.y = 0;
		this.z = 0;
	}

	public inline function toString() {
	    return "Vec3("+x+","+y+","+z+")";
	}
	
	// Static Functions
	static public inline function add(a:Vec3, b:Vec3, r:Vec3):Vec3{//store result in r
		r.x = b.x + a.x;
		r.y = b.y + a.y;
		r.z = b.z + a.z;
		return r;
	}

	static public inline function difference(a:Vec3, b:Vec3, r:Vec3):Vec3{//store result in r
		r.x = b.x - a.x;
		r.y = b.y - a.y;
		r.z = b.z - a.z;
		return r;
	}

	static public inline function dist(a:Vec3, b:Vec3):Float{
		return length3(b.x - a.x, b.y - a.y, b.z - a.z);
	}

	static public inline function length3Sqr(x:Float, y:Float, z:Float):Float{
		return x*x + y*y + z*z;
	}

	static public inline function length3(x:Float, y:Float, z:Float){
		return Math.sqrt(length3Sqr(x,y,z));
	}
}