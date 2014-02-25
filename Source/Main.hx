package;

import geom.Vec3;
import renderer.NBodyRenderer;
import simulator.Body;
import simulator.NBodySimulator;

class Main {

	var renderer:NBodyRenderer;
	var simulator:NBodySimulator;

	public function new () {
		simulator = new NBodySimulator();

		//Create bodies 
		var b:Body;
		for (i in 0...10) {
			b = simulator.addBody(new Body(new Vec3( Math.random() * 300 + 100 , Math.random() * 300 + 100 )));
			b.vx = Math.random()*1-0.5;
			b.vy = Math.random()*1-0.5;
			b.vz = Math.random()*1-0.5;
		}

		renderer = new NBodyRenderer(simulator, flash.Lib.current);

		renderer.beforeDraw = function(){
			simulator.step(1);
		}
	}

}

/*abstract Vec3(de.polygonal.core.math.Vec3){
	public var x(get,set):Float;
	public var y(get,set):Float;

	public inline function new(?x:Float, ?y:Float){
		this = new de.polygonal.core.math.Vec3(x, y);
	}

	@:op(A+B) static public inline function add(lhs:Vec3, rhs:Vec3):Vec3{
		return new Vec3(lhs.x + rhs.x, lhs.y+rhs.y);
	}

	public function get_x():Float{
		return this.x;
	}
	public function get_y():Float{
		return this.y;
	}
	public function set_x(v:Float):Float{
		return this.x = v;
	}
	public function set_y(v:Float):Float{
		return this.y = v;
	}
}*/