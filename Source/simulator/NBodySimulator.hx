package simulator;

import Constants;
import geom.Vec3;
import simulator.Body;

class NBodySimulator {

	public var bodies:Array<Body>;
	public var onBodyAdded:Body->Void;

	@:noStack public function new(){
		poolInitialization();
		bodies = new Array<Body>();
	}

	@:noStack public inline function addBody(b:Body):Body{
		bodies.push(b);
		if(onBodyAdded != null)onBodyAdded(b);
		return b;
	}

	@:noStack public inline function step(dt:Float){
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
				fc += - 2 * 10000 / (dSq*dSq);

				//Acceleration 
				aA = fc*B.m*dt;
				aB = -fc*A.m*dt;

				//exit if acceleration is too large
				if(Math.abs( aA )>10)continue;
				if(Math.abs( aB )>10)continue;

				//Apply acceleration
				A.v.x += rNorm.x*aA;
				A.v.y += rNorm.y*aA;
				A.v.z += rNorm.z*aA;
				B.v.x += rNorm.x*aB;
				B.v.y += rNorm.y*aB;
				B.v.z += rNorm.z*aB;
			}

			//Apply velocity
			A.x += A.v.x;
			A.y += A.v.y;
			A.z += A.v.z;
			//dampen
			A.x *= 0.997;
			A.y *= 0.997;
			A.z *= 0.997;
		}
	}

	//Variable pool
	var A:Body;var B:Body;
	var r:Vec3;var rNorm:Vec3;
	@:noStack private function poolInitialization(){
		r = new Vec3();
		rNorm = new Vec3();
	}

}