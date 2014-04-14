package;

import geom.Vec3;

typedef BodyDatum = {
	var name:String;
	var position:Vec3;
	var velocity:Vec3;
	var mass:Float;
	@:optional var radius:Float;
}