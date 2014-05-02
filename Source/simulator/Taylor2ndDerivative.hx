package simulator;

import geom.Vec3;
import geom.FlatVec3Array;
import simulator.Simulator;

class Taylor2ndDerivative extends Simulator {
	public var dt:Float;

	var acceleration:FlatVec3Array;

	public function new(G:Float, dt:Float){
		super(G);
		this.algorithmName = "Taylor Expansion to 2nd Term";
		this.algorithmDetails = "First two terms of Taylor expansion (up to acceleration)";
		this.dt = dt;
	}

	override function prepare(){
		super.prepare();
		acceleration = new FlatVec3Array(this.bodies.length);
	}

	@:noStack
	override public inline function step(){
		var dSq : Float;
		var fc  : Float;

		//Reset accelerations 
		for (i in 0...bodyCount) acceleration.zero(i); 

		for (i in 0...bodyCount) {
			//Pairwise interaction a & a dot
			for(j in i+1...bodyCount){
				position.difference(i, j, r);
				dSq  = r.lengthSquared();
				fc   = G / dSq;
				r *= 1/Math.sqrt(dSq);//normalize

				acceleration.addProductVec3(i, r, fc*mass[j]);
				acceleration.addProductVec3(j, r, -fc*mass[i]);
			}

			//Update x & v
			position.addFn(i, inline function(k) return
				velocity.get(i,k)*dt
				+ acceleration.get(i,k)*dt*dt/2
			);

			velocity.addFn(i, inline function(k) return 
				acceleration.get(i,k)*dt
			);
		}

		time+=dt;
	}

	override function get_params():Dynamic return {dt:dt};
}