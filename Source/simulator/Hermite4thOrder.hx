//Pre-step jerk and acceleration

package simulator;

import simulator.NBodySimulator;
import geom.Vec3;

class Hermite4thOrder extends NBodySimulator{
	public var dt:Float;

	var bodyCount:Int = 0;

	var position        : Array<Vec3>;
	var velocity        : Array<Vec3>;
	var acceleration    : Array<Vec3>;
	var jerk            : Array<Vec3>;
	var mass            : Array<Float>;
	
	var oldPosition     : Array<Vec3>;
	var oldVelocity     : Array<Vec3>;
	var oldAcceleration : Array<Vec3>;
	var oldJerk         : Array<Vec3>;

	public function new(G:Float, dt:Float){
		super(G);
		this.algorithmName = "Hermite 4th Order";
		this.algorithmDetails = "";
		this.dt = dt;
	}

	override public function addBody(b:Body):Body{
		super.addBody(b);

		position.push(b.p);
		velocity.push(b.v);
		acceleration.push(new Vec3());
		jerk.push(new Vec3());
		mass.push(b.m);

		evaluate();

		oldPosition.push(b.p.clone());
		oldVelocity.push(b.v.clone());
		oldAcceleration.push(new Vec3());
		oldJerk.push(new Vec3());

		bodyCount++;
		return b;
	}

	@:noStack 
	override function step(){
		for(i in 0...bodyCount){
			for(k in 0...3){
				oldPosition[i][k]     = position[i][k];
				oldVelocity[i][k]     = velocity[i][k];
				oldAcceleration[i][k] = acceleration[i][k];
				oldJerk[i][k]         = jerk[i][k];
			}
		}

		predict();
		for(i in 0...2){
			evaluate();
			correct();
		}

		time+=dt; 
	}

	inline function predict(){
		for (i in 0...bodyCount){
			//x1 = x0 + v*dt + (1/2)a*dt^2 + (1/6)j*dt^3
			position[i].addFn(inline function(k) return
				velocity[i][k]*dt +
				acceleration[i][k]*dt*dt/2 + 
				jerk[i][k]*dt*dt*dt/6
			);
			//v1 = v0 + a*dt + (1/2)j*dt^2
			velocity[i].addFn(inline function(k) return
				acceleration[i][k]*dt +
				jerk[i][k]*dt*dt/2
			);
		}
	}

	inline function correct(){
		for (i in 0...bodyCount){
			velocity[i].setFn(inline function(k) return
				oldVelocity[i][k] + 
				(oldAcceleration[i][k] + acceleration[i][k])*dt/2 +
				(oldJerk[i][k] - jerk[i][k])*dt*dt/12
			);

			position[i].setFn(inline function(k) return
				oldPosition[i][k] + 
				(oldVelocity[i][k] + velocity[i][k])*dt/2 + 
				(oldAcceleration[i][k] - acceleration[i][k])*dt*dt/12
			);
		}
	}

	//compute acceleration and jerk
	inline function evaluate(){
		var d          : Float;
		var dSq        : Float;
		var dCu        : Float;
		var dvDotR_dSq : Float;
		var fcj        : Float;
		//reset accelerations and jerks
		for (i in 0...bodyCount){
			acceleration[i].zero(); 
			jerk[i].zero();
		}

		//Pairwise interaction a & a dot
		for (i in 0...bodyCount) {
			for(j in i+1...bodyCount){
				Vec3.difference(position[i], position[j], r);
				Vec3.difference(velocity[i], velocity[j], dv);

				dSq  = r.lengthSquared();
				d    = Math.sqrt(dSq);
				dCu  = d*dSq;

				dvDotR_dSq = dv.dot(r)/dSq;

				//Force factor
				fc  = G / dSq;
				fcj = G / dCu;

				jerk[i].addFn(inline function(k) return
					fcj*mass[j]*((dv[k] - 3*dvDotR_dSq*r[k]))
				);
				jerk[j].addFn(inline function(k) return
					-fcj*mass[i]*((dv[k] - 3*dvDotR_dSq*r[k]))
				);

				//Normalize r
				r *= 1/d;
				acceleration[i].addProduct(r, fc*mass[j]);
				acceleration[j].addProduct(r, -fc*mass[i]);
			}
		}
	}

	inline function spaceDifference(p1:Vec3, p2:Vec3){
		Vec3.difference(p1, p2, r);
	}

	override function get_params():Dynamic{
		return {dt:dt};
	}	

	override function initalize(){
		super.initalize();

		position        = new Array<Vec3>();
		velocity        = new Array<Vec3>();
		acceleration    = new Array<Vec3>();
		jerk            = new Array<Vec3>();
		mass            = new Array<Float>();

		oldPosition     = new Array<Vec3>();
		oldVelocity     = new Array<Vec3>();
		oldAcceleration = new Array<Vec3>();
		oldJerk         = new Array<Vec3>();
	}

	//Variable pool
	var dv:Vec3 = new Vec3();
}

