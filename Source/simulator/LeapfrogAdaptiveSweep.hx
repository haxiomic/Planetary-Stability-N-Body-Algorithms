//References http://arxiv.org/pdf/1205.2288.pdf

package simulator;

import geom.Vec3;
import math.ExtendedMath;
import simulator.Body;
import simulator.NBodySimulator;

class LeapfrogAdaptiveSweep extends NBodySimulator{
	var max_dt(default, null):Float;
	var min_dt(default, null):Float;

	//var max_n(default, null):Float;
	var max_s:Int; 

	var currentBaseSS:Int;

	/*#! maybe change min_dt argument to scaling factor, ie 0.25 (of max_dt) */
	public function new(G:Float, max_dt:Float, min_dt:Float = 0){
		super(G);
		this.algorithmName = "Leapfrog Adaptive Block Timesteps, Sweep (unsymmetrized)";
		this.algorithmDetails = "Testing";
		this.max_dt = max_dt;

		/*var n = min_dt>=0 ? log2(this.max_dt/this.min_dt) : 31;
		if(n>31)n=31;//maximum ratio between min_dt and max_dt = 2^31 (must be stored in UInt!) 
		this.max_n = n;*/

		//#! this needs sorting out
		this.max_s = Math.ceil(this.max_dt/min_dt);

		/*//find nearest power of 2 ceiling
		if((1<<max_s)/ratio < 1)max_s++;*/

		this.min_dt = this.max_dt/this.max_s;

		this.currentBaseSS = this.max_s;
	}

	override public function addBody(b:Body):Body{
		AAd = new BodyAdaptive(b);
		A = super.addBody(AAd);
		updateAccelerations();
		//AAd.ss = (bodies.length < 3 ? 1 : 2);//bestStepSize(AAd);
		//if(bodies.length > 4)AAd.ss = 8;
		//if(bodies.length == 1)AAd.ss = 8;
		switch(bodies.length){
			case 1:
				AAd.ss = 128;
			case 2:
				AAd.ss = 32;
			case 3:
				AAd.ss = 64;
			case 4:
				AAd.ss = 128;
			case 5:
				AAd.ss = 256;
		}
		trace(AAd.ss);
		if(AAd.ss<currentBaseSS)currentBaseSS = AAd.ss;
		bodies.sort(sortBodiesBySSAscending);
		return A;
	}

	var s:Int = 0;//step count
	@:noStack 
	override function step(){
		newBaseSS = max_s;

		// sysUtils.Console.newLine();
		// sysUtils.Console.print("Drift:"+s);
		//Drift dt*.5
		for (i in 0...bodies.length) {
			AAd = untyped bodies[i]; 
			//is it time to step body? (Continue if not)
			if((s)%AAd.ss!=0)continue;

			dt = dtForSS(AAd.ss);

			// sysUtils.Console.print("A"+i+" ss:"+AAd.ss);

			//Each-Body Drift
			AAd.p.addProduct(AAd.v, dt*.5);
			AAd.t += dt*.5;
		}

		// sysUtils.Console.newLine();
		// sysUtils.Console.print("Kick:"+s);

		//Kick
		for (i in 0...bodies.length) {
			AAd = untyped bodies[i]; 
			if((s)%AAd.ss!=0)continue;

			dt = dtForSS(AAd.ss);

			//Pairwise Kick
			for(j in i+1...bodies.length){
				BAd = untyped bodies[j];
				// sysUtils.Console.print("A"+i+" ss:"+AAd.ss, false);
				// sysUtils.Console.print("<->B"+j+" ss:"+BAd.ss+" B_dt:",false);

				//if ordered correctly B will never have a shorter step size than A
				//find step difference
				//B_dt = -(0.5)*dtForSS((AAd.ss-BAd.ss));
				//B_dt = (BAd.t-AAd.t);
				// sysUtils.Console.print((BAd.t-AAd.t));

				predictAccelerationsDueToGravity(AAd, BAd, 0);			

				//find midpoint velocity
				AAd.v.addProduct(r, accelA*dt);
				//perturb B, but not necessarily with the midpoint velocity
				BAd.v.addProduct(r, accelB*dt);//#! unsure about this kick, maybe it should use acceleration from starting side of AAd.ss
			}
		}

		//Drift dt*.5
		for (i in 0...bodies.length) {
			AAd = untyped bodies[i]; 
			//is it time to step body? (Continue if not)
			if((s)%AAd.ss!=0)continue;

			dt = dtForSS(AAd.ss);

			//Each-Body Drift
			AAd.p.addProduct(AAd.v, dt*.5);
			AAd.t += dt*.5;

			//Update smallest step size
			if(AAd.ss<newBaseSS)newBaseSS = AAd.ss;
		}

		//order so that 0 has smallest timestep and the last has the longest
		bodies.sort( sortBodiesBySSAscending );

		time += dtForSS(currentBaseSS);
		s += newBaseSS;
		if(s>=max_s)s = 0;
		currentBaseSS = newBaseSS;
	}
	var newBaseSS:Int;
	var dt:Float;var B_dt:Float;
	var stepDifference:Int;
	var AAd:BodyAdaptive;var BAd:BodyAdaptive;

	inline function dtForSS(ss:Int):Float{
		return ss*min_dt;
	}

	var ratio_floor:Int;
	inline function ssForDt(dt:Float):Int{
		ratio_floor = Math.floor(dt/min_dt);
		return (ratio_floor < 1 ? 1 : ratio_floor);
	}

	inline function bestStepSize(b:BodyAdaptive):Int{
		//return: the floor power of 2 of nearest ss given ideal dt, which is a function of acceleration and such
		return 2;
	}

	inline function predictAccelerationsDueToGravity(A:BodyAdaptive, B:BodyAdaptive, B_dt:Float){
		//Distance vector and its magnitudes
		predictedBPosition.x = B.x + B.vx*B_dt;// + 0.5*B.ax*B_dt*B_dt;
		predictedBPosition.y = B.y + B.vy*B_dt;// + 0.5*B.ay*B_dt*B_dt;
		predictedBPosition.z = B.z + B.vz*B_dt;// + 0.5*B.az*B_dt*B_dt;

		Vec3.difference(A.p, predictedBPosition, r);
		dSq = r.lengthSquared();
		d = Math.sqrt(dSq);
		//Normalize r
		r *= 1/d;
		//Force factor
		fc = 1 * G / dSq;
		//Acceleration on A & B
		accelA = fc*B.m;
		accelB = -fc*A.m;

	}var predictedBPosition:Vec3;

	inline function updateAccelerations(){
		for (i in 0...bodies.length) {
			AAd = untyped bodies[i]; 
			AAd.a.zero();//reset acceleration for recalculation at new position
			for(j in i+1...bodies.length){
				BAd = untyped bodies[j];
				accelerationsDueToGravity(AAd,BAd);
				AAd.a.addProduct(r, accelA);
				BAd.a.addProduct(r, accelB);
			}
		}
	}

	inline function sortBodiesBySSAscending(a:Body, b:Body):Int{
		return untyped a.ss - b.ss;//a-b = lowest to highest
	}

	override function get_params():Dynamic{
		return {
			max_dt:max_dt,
			min_dt:min_dt,
			max_s:max_s,
		};
	}	

	override function poolInitialization(){
		predictedBPosition = new Vec3();
		super.poolInitialization();
	}
}

class BodyAdaptive extends Body{
	public var ss:Int = 1;//step size
	public var t:Float = 0;
	public var a:Vec3;

	//Acceleration convenience property
	public var ax(get, set):Float;
	public var ay(get, set):Float;
	public var az(get, set):Float;

	public function new(b:Body){
		super(b.p, b.v, b.m);
		a = new Vec3();
	}

	//Acceleration
	public inline function get_ax():Float{return a.x;}
	public inline function set_ax(value:Float):Float{return a.x = value;}
	public inline function get_ay():Float{return a.y;}
	public inline function set_ay(value:Float):Float{return a.y = value;}
	public inline function get_az():Float{return a.z;}
	public inline function set_az(value:Float):Float{return a.z = value;}

	public inline function toString() {
	    return "BodyAdaptive(ss = "+ss+")";
	}
}
