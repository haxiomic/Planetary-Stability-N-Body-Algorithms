package simulator;

import geom.Vec3;
import simulator.Body;
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
		var fc:Float, d:Float, dSq:Float, aA:Float, aB:Float;
		var E:Float = 0;

		for(i in 0...bodies.length){
			A = bodies[i];

			for(j in i+1...bodies.length){
				B = bodies[j];	

				//Distance vector
				Vec3.difference(A.p, B.p, r);
				
				dSq = r.lengthSquared();
				d = Math.sqrt(dSq);

				//Normalize r
				rNorm.x = r.x/d;
				rNorm.y = r.y/d;
				rNorm.z = r.z/d;
				
				// ---- Attraction ---- 
				//Force constant
				fc = 1 * G / dSq; //2 since each pair is visited just once

				//Acceleration * dt
				aA = fc*B.m*dt;
				aB = -fc*A.m*dt;

				//Apply acceleration
				A.v.x += rNorm.x*aA;
				A.v.y += rNorm.y*aA;
				A.v.z += rNorm.z*aA;
				B.v.x += rNorm.x*aB;
				B.v.y += rNorm.y*aB;
				B.v.z += rNorm.z*aB;
			}

			//Apply velocity
			A.x += A.v.x*dt;
			A.y += A.v.y*dt;
			A.z += A.v.z*dt;
		}

		time+=dt;
	}

	override function get_params():Dynamic{
		return {dt:dt};
	}
}