package simulator;

import geom.Vec3;
import math.ExtendedMath;
import simulator.Body;
import simulator.NBodySimulator;

class LeapfrogAdaptive extends NBodySimulator{
	var max_dt:Float;
	var min_dt:Float;

	var max_k:Int; 

	var currentBaseSS:Int;

	var bodyCount:Int = 0;
	var positions:Array<Vec3>;
	var velocities:Array<Vec3>;
	var accelerations:Array<Vec3>;
	var masses:Array<Float>;
	var timesteps:Array<Float>;

	public function new(G:Float, max_dt:Float){
		super(G);
		initalize();

		this.algorithmName = "Leapfrog Adaptive";
		this.algorithmDetails = "WIP: time-symmetric adaptive timestep leapfrog";

		this.max_dt = (1<<3);
		this.min_dt = 1;

		this.max_k = Math.ceil(this.max_dt/this.min_dt);
		this.min_dt = this.max_dt/this.max_k;
		this.currentBaseSS = this.max_k;
	}

	override public function addBody(b:Body):Body{
		positions.push(b.p);
		velocities.push(b.v);
		accelerations.push(new Vec3());
		masses.push(b.m);
		bodyCount++;

		super.addBody(b);
		return b;
	}

	@:noStack
	inline function recursiveSubstep(dt:Float){
		driftAll(dt*.5);
		select(dt);
		if(dt > min_dt){//There are smaller timesteps to compute
			driftAll(-dt*.5);//Reverse drift
			recursiveSubstep(dt*.5);
			kick(dt);
			recursiveSubstep(dt*.5);
			return;
		}
		
		//complete
		kick(dt);
		driftAll(dt*.5);
	}

	@:noStack
	inline function select(dt){
		// sysUtils.Console.print("\tselect:");
		//updateAcceleration();
		//select particle timesteps
		//what does this function actually do?
		for (i in 0...bodyCount){
			//temporary selection
			timesteps[i] = (1 << Math.ceil((i)*.5));
			// sysUtils.Console.printSuccess("\t\t"+i+".dt="+AAd.dt);
		}
	}

	@:noStack
	inline function driftAll(dt:Float){
		// sysUtils.Console.print("\tdrifting:");
		for (i in 0...bodyCount){
			// sysUtils.Console.printSuccess("\t\ti "+i+" by "+dt);
			positions[i].addProduct(velocities[i], dt);
		}
	}

	//kick particles which have a timestep dt
	@:noStack
	inline function kick(dt:Float){
		for (i in 0...bodyCount){
			if(timesteps[i]!=dt)continue;

			for(j in i+1...bodyCount){
				accelerationsDueToGravityExt(positions[i],positions[j],masses[i],masses[j]);
				velocities[i].addProduct(r, accelA*dt);
				velocities[j].addProduct(r, accelB*dt);
			}
		}
	}

	inline function updateAcceleration(){
		for(i in 0...bodyCount) {
			accelerations[i].zero();
		}

		for(i in 0...bodyCount) {
			for(j in i+1...bodyCount){
				accelerationsDueToGravityExt(positions[i],positions[j],masses[i],masses[j]);
				accelerations[i].addProduct(r, accelA);
				accelerations[j].addProduct(r, accelB);
			}
		}
	}

	inline function accelerationsDueToGravityExt(p1:Vec3, p2:Vec3, m1:Float, m2:Float){
		//Distance vector and its magnitudes
		Vec3.difference(p1, p2, r);
		dSq = r.lengthSquared();
		d = Math.sqrt(dSq);
		//Normalize r
		r *= 1/d;
		//Force factor
		fc = 1 * G / dSq;
		//Acceleration on A & B
		accelA = fc*m2;
		accelB = -fc*m1;
	}

	@:noStack 
	override function step(){
		recursiveSubstep(max_dt);

		time+=max_dt;
	}

/*	inline function bestTimestep(b:BodyAdaptive):Float{
//		1/(1/(g(b)*tau)-(1/b.dt));
		return 1;
	}var tau:Float = 1;

	inline function g(b:BodyAdaptive):Float{		
		return 1;
	}*/

	inline function sortBodiesBySSAscending(a:Body, b:Body):Int
		return untyped a.ss - b.ss;
	
	override function get_params():Dynamic{
		return {
			max_dt:max_dt,
			min_dt:min_dt,
			max_k:max_k,
		};
	}

	override function initalize(){
		positions = new Array<Vec3>();
		velocities = new Array<Vec3>();
		accelerations = new Array<Vec3>();
		masses = new Array<Float>();
		timesteps = new Array<Float>();
	}
}