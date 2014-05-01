package simulator;

import geom.Vec3;
import geom.FlatVec3Array;
import simulator.NBodySimulator;

class Taylor3rdDerivative extends NBodySimulator {
	public var dt:Float;

	var acceleration : FlatVec3Array;
	var jerk         : FlatVec3Array;

	public function new(G:Float, dt:Float){
		super(G);
		this.algorithmName = "Taylor Expansion to 3rd Term";
		this.algorithmDetails = "First 3 terms of Taylor expansion (up to jerk)";
		this.dt = dt;
	}

	override function prepare(){
		super.prepare();
		acceleration = new FlatVec3Array(this.bodies.length);
		jerk         = new FlatVec3Array(this.bodies.length);
	}

	@:noStack
	override public inline function step(){
		var d          : Float;
		var dSq        : Float;
		var dvDotR_dSq : Float;
		var fc         : Float;
		var fcj        : Float;

		//Reset accelerations and jerks
		for (i in 0...bodyCount){
			acceleration.zero(i); 
			jerk.zero(i);
		}

		//Pairwise interaction a & a dot
		for (i in 0...bodyCount) {
			for(j in i+1...bodyCount){
				position.difference(i, j, r);
				velocity.difference(i, j, dv);

				dSq  = r.lengthSquared();
				d    = Math.sqrt(dSq);

				dvDotR_dSq = dv.dot(r)/dSq;

				//force factor
				fc  = G / dSq;
				fcj = fc / d;

				jerk.addFn(i, inline function(k) return
					fcj*mass[j]*((dv[k] - 3*dvDotR_dSq*r[k]))
				);
				jerk.addFn(j, inline function(k) return
					-fcj*mass[i]*((dv[k] - 3*dvDotR_dSq*r[k]))
				);

				r *= 1/d;//normalize

				acceleration.addProductVec3(i, r, fc*mass[j]);
				acceleration.addProductVec3(j, r, -fc*mass[i]);
			}
		}

		//Update x & v
		for (i in 0...bodyCount) {
			position.addFn(i, inline function(k) return
				velocity.get(i,k)*dt
				+ acceleration.get(i,k)*dt*dt/2
				+ jerk.get(i,k)*dt*dt*dt/6
			);

			velocity.addFn(i, inline function(k) return 
				acceleration.get(i,k)*dt
				+ jerk.get(i,k)*dt*dt/2
			);
		}

		time+=dt;
	}var dv:Vec3 = new Vec3();//Object pool

	override function get_params():Dynamic return {dt:dt};
}