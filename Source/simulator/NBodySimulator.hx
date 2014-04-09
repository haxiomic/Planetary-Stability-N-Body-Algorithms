package simulator;

import Constants;
import geom.Vec3;
import simulator.Body;

class NBodySimulator {
	static inline public var G = Constants.G_AU_kg_D;

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

				//Acceleration 
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
	}

	public inline function computeTotalEnergy():Float{
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

	//Variable pool
	var A:Body;var B:Body;
	var r:Vec3;var rNorm:Vec3;
	@:noStack private function poolInitialization(){
		r = new Vec3();
		rNorm = new Vec3();
	}

}