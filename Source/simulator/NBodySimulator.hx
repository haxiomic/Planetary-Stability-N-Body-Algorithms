package simulator;

import geom.Vec3;
import simulator.Body;

class NBodySimulator {
	public var algorithmName(default, null):String = "";
	public var algorithmDetails(default, null):String = "";
	public var bodies:Array<Body>;
	public var params(get, null):Dynamic;

	public var time(default, null):Float;

	public var G:Float;

	public function new(G:Float){
		initalize();
		this.G = G;
	}

	public function addBody(b:Body):Body{
		bodies.push(b);
		return b;
	}

	public function step(){}

	public function clear(){
		initalize();
	}

	@:noStack
	public inline function totalEnergy():Float{
		var E:Float = 0, d:Float;
		var k:Float = 0;
		var p:Float = 0;
		for(i in 0...bodies.length){
			A = bodies[i];
			E += 0.5*A.m*A.v.lengthSquared();//kinetic energy

			for(j in i+1...bodies.length){
				B = bodies[j];	

				Vec3.difference(A.p, B.p, r);
				d = r.length();
				
				E -= G*A.m*B.m/d;//potential energy
			}

		}
		return E;
	}

	//Private

	private function get_params():Dynamic{
		return {};
	}

	private function initalize(){
		time = 0;
		poolInitialization();
		bodies = new Array<Body>();
	}

	//Variable pool
	var A:Body;var B:Body;
	var r:Vec3;var rNorm:Vec3;
	private function poolInitialization(){
		r = new Vec3();
		rNorm = new Vec3();
	}

}