package simulator;

import geom.Vec3;
import simulator.NBodySimulator;

class EulerMethod extends NBodySimulator {
	public var dt:Float;

	public function new(G:Float, dt:Float){
		super(G);
		this.algorithmName = "Euler Method";
		this.algorithmDetails = "First pass, no optimizations.";
		this.dt = dt;
	}

	@:noStack
	override public inline function step(){
		for(i in 0...bodies.length){
			A = bodies[i];

			for(j in i+1...bodies.length){
				B = bodies[j];	

				accelerationsDueToGravity(A,B);

				//Apply acceleration
				accelA*=dt;
				accelB*=dt;

				A.v.addProduct(r, accelA);
				B.v.addProduct(r, accelB);
			}

			//Apply velocity
			A.p.addProduct(A.v, dt);
		}

		time+=dt;
	}

	override function get_params():Dynamic{
		return {dt:dt};
	}
}