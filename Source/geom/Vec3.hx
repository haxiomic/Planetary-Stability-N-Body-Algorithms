package geom;

//typedef Vec3 = de.polygonal.core.math.Vec3;


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