package simulator;

import geom.Vec3;
import simulator.Body;
import Constants;

class NBodySimulator {

	public var bodies:Array<Body>;
	public var onBodyAdded:Body->Void;

	public function new(){
		poolInitialization();
		bodies = new Array<Body>();
	}

	public inline function addBody(b:Body):Body{
		bodies.push(b);
		if(onBodyAdded != null)onBodyAdded(b);
		return b;
	}

	public inline function step(dt:Float){
		var fc:Float, d:Float, dSq:Float, aA:Float, aB:Float;
		
		for(i in 0...bodies.length){
			A = bodies[i];

			for(j in i+1...bodies.length){
				B = bodies[j];	

				//Distance vector
				Vec3.difference(A.p, B.p, r);
				
				dSq = r.lengthSqr();
				d = Math.sqrt(dSq);

				//Normalize r
				rNorm.x = r.x/d;
				rNorm.y = r.y/d;
				rNorm.z = r.z/d;

				if(d<5)continue;//ignore tiny distances
				
				// ---- Attraction ---- 
				//Force constant
				fc = 2 * Constants.G / dSq; //2 since each pair is visited just once

				// ---- Repulsion ---- 
				fc += - 2 * 500000 / (dSq*dSq);

				//Acceleration 
				aA = fc*B.m*dt;
				aB = -fc*A.m*dt;

				//exit if acceleration is too large
				if(Math.abs( aA )>10)continue;
				if(Math.abs( aB )>10)continue;

				//Apply acceleration
				A.vx += rNorm.x*aA;
				A.vy += rNorm.y*aA;
				A.vz += rNorm.z*aA;
				B.vx += rNorm.x*aB;
				B.vy += rNorm.y*aB;
				B.vz += rNorm.z*aB;
			}

			//Apply velocity
			A.x += A.vx;
			A.y += A.vy;
			A.z += A.vz;

			A.x *= 0.995;
			A.y *= 0.995;
			A.z *= 0.995;
		}
	}

	//Variable pool
	var A:Body;var B:Body;
	var r:Vec3;var rNorm:Vec3;
	private function poolInitialization(){
		r = new Vec3();
		rNorm = new Vec3();
	}

}