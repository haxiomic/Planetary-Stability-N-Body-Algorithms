package geom;

//typedef Vec2 = de.polygonal.core.math.Vec2;

/* could use faster data storage with x/y getter setters and a big Array2F managed by Vec2 */

class Vec2{
	public var x:Float;
	public var y:Float;

	public function new(x:Float = 0, y:Float = 0){
		this.x = x;
		this.y = y;
	}

	public inline function lengthSqr():Float{
		return x*x + y*y;
	}

	public inline function length():Float{
		return Math.sqrt(lengthSqr());
	}

	public inline function normalize():Void{
		var d:Float = length();
		this.x /= d;
		this.y /= d;
	}

	public inline function zero():Void{
		this.x = 0;
		this.y = 0;
	}

	public inline function toString() {
	    return "Vec2("+x+","+y+")";
	}

	// Static Functions
	static public inline function add(a:Vec2, b:Vec2, r:Vec2):Vec2{//store result in r
		r.x = b.x + a.x;
		r.y = b.y + a.y;
		return r;
	}

	static public inline function difference(a:Vec2, b:Vec2, r:Vec2):Vec2{//store result in r
		r.x = b.x - a.x;
		r.y = b.y - a.y;
		return r;
	}

	static public inline function dist(a:Vec2, b:Vec2):Float{
		return length2(b.x - a.x, b.y - a.y);
	}

	static public inline function length2Sqr(x:Float, y:Float){
		return x*x + y*y;
	}

	static public inline function length2(x:Float, y:Float){
		return Math.sqrt(length2Sqr(x,y));
	}
}