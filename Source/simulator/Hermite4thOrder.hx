package simulator;

import geom.VPointer;
import simulator.Body;
import simulator.NBodySimulator;
import geom.Vec3;
import geom.FlatVec3Array;
import haxe.ds.Vector;

class Hermite4thOrder extends NBodySimulator{
	public var dt:Float;

	var acceleration    : FlatVec3Array;
	var jerk            : FlatVec3Array;
	var oldPosition     : FlatVec3Array;
	var oldVelocity     : FlatVec3Array;
	var oldAcceleration : FlatVec3Array;
	var oldJerk         : FlatVec3Array;

	public function new(G:Float, dt:Float){
		super(G);
		this.algorithmName = "Hermite 4th Order";
		this.algorithmDetails = "P(EC)^2, two iterations of evaluate and correct";
		this.dt = dt;
	}

	@:noStack
	override public function prepare(){
		super.prepare();
		acceleration   	= new FlatVec3Array(this.bodies.length);
		jerk           	= new FlatVec3Array(this.bodies.length);
		oldPosition    	= new FlatVec3Array(this.bodies.length);
		oldVelocity    	= new FlatVec3Array(this.bodies.length);
		oldAcceleration	= new FlatVec3Array(this.bodies.length);
		oldJerk        	= new FlatVec3Array(this.bodies.length);

		evaluate();
	}

	@:noStack 
	override public function step(){
		for(i in 0...bodyCount*3){
			oldPosition[i] = position[i];
			oldVelocity[i] = velocity[i];
			oldAcceleration[i] = acceleration[i];
			oldJerk[i] = jerk[i];
		}

		predict();
		for(i in 0...2){
			evaluate();
			correct();
		}

		time+=dt; 
	}
	
	@:noStack
	inline function predict(){
			for (i in 0...bodyCount){
				//x1 = x0 + v*dt + (1/2)a*dt^2 + (1/6)j*dt^3
				position.addFn(i, inline function(k) return
					velocity.get(i, k)*dt +
					acceleration.get(i, k)*dt*dt/2 + 
					jerk.get(i, k)*dt*dt*dt/6
				);
				//v1 = v0 + a*dt + (1/2)j*dt^2
				velocity.addFn(i, inline function(k) return
					acceleration.get(i, k)*dt +
					jerk.get(i, k)*dt*dt/2
				);
			}
	}
	
	@:noStack
	inline function correct(){
		for (i in 0...bodyCount){
			velocity.setFn(i, inline function(k) return
				oldVelocity.get(i, k) + 
				(oldAcceleration.get(i, k) + acceleration.get(i, k))*dt/2 +
				(oldJerk.get(i, k) - jerk.get(i, k))*dt*dt/12
			);

			position.setFn(i, inline function(k) return
				oldPosition.get(i, k) + 
				(oldVelocity.get(i, k) + velocity.get(i, k))*dt/2 + 
				(oldAcceleration.get(i, k) - acceleration.get(i, k))*dt*dt/12
			);
		}
	}

	
	@:noStack//compute acceleration and jerk
	inline function evaluate(){
		var d          : Float;
		var dSq        : Float;
		var dvDotR_dSq : Float;
		var fc         : Float;
		var fcj        : Float;
		//reset accelerations and jerks
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

				//Force factor
				fc  = G / dSq;
				fcj = fc / d;

				jerk.addFn(i, inline function(k) return
					fcj*mass[j]*((dv[k] - 3*dvDotR_dSq*r[k]))
				);
				jerk.addFn(j, inline function(k) return
					-fcj*mass[i]*((dv[k] - 3*dvDotR_dSq*r[k]))
				);

				//Normalize r
				r *= 1/d;
				acceleration.addProductVec3(i, r, fc*mass[j]);
				acceleration.addProductVec3(j, r, -fc*mass[i]);
			}
		}
	}
	//Object pool
	var dv:Vec3 = new Vec3();


	override function get_params():Dynamic{
		return {dt:dt};
	}	
}