package simulator;

import geom.Vec3;
import simulator.Body;
import simulator.Constants;

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

				if(d<1)continue;
				
				// ---- Attraction ---- 
				//Force constant
				fc = 2 * Constants.G / dSq; //2 since each pair is visited just once

				//Apply acceleration
				A.vx += rNorm.x*fc*B.m*dt;
				A.vy += rNorm.y*fc*B.m*dt;
				A.vz += rNorm.z*fc*B.m*dt;
				B.vx -= rNorm.x*fc*A.m*dt;
				B.vy -= rNorm.y*fc*A.m*dt;
				B.vz -= rNorm.z*fc*A.m*dt;

				// ---- Repulsion ----
				fc = - 2 * 100000 / (dSq*dSq);
				//Apply acceleration
				A.vx += rNorm.x*fc*B.m*dt;
				A.vy += rNorm.y*fc*B.m*dt;
				A.vz += rNorm.z*fc*B.m*dt;
				B.vx -= rNorm.x*fc*A.m*dt;
				B.vy -= rNorm.y*fc*A.m*dt;
				B.vz -= rNorm.z*fc*A.m*dt;
			}

			//Apply velocity
			A.x += A.vx;
			A.y += A.vy;
			A.z += A.vz;
		}
	}

	//Variable pool
	var A:Body;var B:Body;
	var fc:Float;var d:Float;var dSq:Float;var r:Vec3;var rNorm:Vec3;
	private function poolInitialization(){
		r = new Vec3();
		rNorm = new Vec3();
	}

}