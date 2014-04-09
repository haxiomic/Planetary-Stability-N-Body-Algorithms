package simulator;

import geom.Vec3;

class Body{
	public var m:Float;
	public var p:Vec3;
	public var v:Vec3;

	//For convenience:
	//Position
	public var x(get, set):Float;
	public var y(get, set):Float;
	public var z(get, set):Float;
	//Velocity
	public var vx(get, set):Float;
	public var vy(get, set):Float;
	public var vz(get, set):Float;

	public function new(?position:Vec3, ?velocity:Vec3, mass:Float = 1){
		if(position == null)position = new Vec3(0,0,0);
		if(velocity == null)velocity = new Vec3(0,0,0);
		this.p = position;
		this.v = velocity;
		this.m = mass;
	}

	//position
	public inline function get_x():Float{return p.x;}
	public inline function set_x(value:Float):Float{return p.x = value;}
	public inline function get_y():Float{return p.y;}
	public inline function set_y(value:Float):Float{return p.y = value;}
	public inline function get_z():Float{return p.z;}
	public inline function set_z(value:Float):Float{return p.z = value;}

	//velocity
	public inline function get_vx():Float{return v.x;}
	public inline function set_vx(value:Float):Float{return v.x = value;}
	public inline function get_vy():Float{return v.y;}
	public inline function set_vy(value:Float):Float{return v.y = value;}
	public inline function get_vz():Float{return v.z;}
	public inline function set_vz(value:Float):Float{return v.z = value;}
}