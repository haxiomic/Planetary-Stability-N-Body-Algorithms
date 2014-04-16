//References http://arxiv.org/pdf/1205.2288.pdf

/*
	n         
	0	|    | 
	1 	|
	2   |    |   |   |   | 4
	3   | |  | | |
	    abc 
*/

package simulator;

import geom.Vec3;
import simulator.Body;
import simulator.NBodySimulator;

class LeapfrogAdaptive extends NBodySimulator{
	var max_dt(default, null):Float;
	var min_dt(default, null):Float;

	//var max_n(default, null):Float;
	var max_s:Int; 

	var smallestSS:Int = 1;

	/*#! maybe change min_dt argument to scaling factor, ie 0.25 (of max_dt) */
	public function new(G:Float, max_dt:Float, min_dt:Float = 0){
		super(G);
		this.algorithmName = "Leapfrog Adaptive Block Timesteps (unsymmetrized)";
		this.algorithmDetails = "Euler integration used to interpolate positions of lower-rung bodies";
		this.max_dt = max_dt;

		/*var n = min_dt>=0 ? log2(this.max_dt/this.min_dt) : 31;
		if(n>31)n=31;//maximum ratio between min_dt and max_dt = 2^31 (must be stored in UInt!) 
		this.max_n = n;*/

		var ratio:UInt = Math.ceil(this.max_dt/this.min_dt);

		var max_s:Int = math.ExtendedMath.log2(ratio);
		//find nearest power of 2 ceiling
		if((1<<max_s)/ratio < 1)max_s++;

		this.min_dt = max_dt/max_s;

		//max_n = log2(max_s);
	}

	override public function addBody(b:Body):Body{
		//#! should definitly set smallestSS here!!!
		//#! update accelerations
		var bAd:BodyAdaptive = new BodyAdaptive(b);
		//updateAccelerations()
		return super.addBody(bAd);
	}

	var s:Int = 1;//step count
	@:noStack 
	override function step(){
		smallestSS = max_s;

		for (i in 0...bodies.length) {
			AAd = untyped bodies[i]; 
			//find a new timestep (via step size) if necessary
			AAd.ss = bestStepSize(AAd);
			//is it time to step body? (Continue if not)
			if(s%AAd.ss!=0)continue;

			dt = dtForSS(AAd.ss);

			//Pairwise Kick
			for(j in i+1...bodies.length){
				BAd = untyped bodies[j];	
				//#! don't visit lower bodies
				
				//find step difference
				stepDifference = (s-1)%BAd.ss;
				B_dt = dtForSS(stepDifference);

				predictAccelerationsDueToGravity(AAd, BAd, B_dt);

				//find midpoint velocity
				AAd.v.addProduct(r, accelA*dt*.5);
				BAd.v.addProduct(r, accelB*dt*.5);
			}

			//Each-Body Drift
			AAd.p.addProduct(AAd.v, dt);
		}

		//Loop again for final kick
		for (i in 0...bodies.length) {
			AAd = untyped bodies[i]; 
			//is it time to step body? (Continue if not)
			if(s%AAd.ss!=0)continue;

			AAd.a.zero();//reset acceleration for recalculation at new position
			//Pairwise Kick
			for(j in i+1...bodies.length){
				B = bodies[j];	

				//find step difference
				stepDifference = s%BAd.ss;
				B_dt = dtForSS(stepDifference);

				predictAccelerationsDueToGravity(AAd, BAd, B_dt);

				//update acceleration
				AAd.a.addProduct(r, accelA);

				//find midpoint velocity
				AAd.v.addProduct(r, accelA*dt*.5);
				BAd.v.addProduct(r, accelB*dt*.5);
			}

			//set base stepping size
			if(AAd.ss<smallestSS)smallestSS = AAd.ss;		
		}

		//#! order so that 0 has smallest timestep and the last has the longest

		time += dtForSS(smallestSS);
		s += smallestSS;
		if(s>max_s)s = 1;
	}
	var dt:Float;var B_dt:Float;
	var stepDifference:Int;
	var AAd:BodyAdaptive;var BAd:BodyAdaptive;

	inline function dtForSS(ss:Int){
		return ss*min_dt;
	}

	inline function bestStepSize(b:BodyAdaptive):Int{
		//some minimum timestep 
		//how does timestep relate to rung? 
		//how does rung relate to step size
		return 1;
	}

	inline function predictAccelerationsDueToGravity(A:BodyAdaptive, B:BodyAdaptive, B_dt:Float){
		//Distance vector and its magnitudes
		predictedBPosition.x = B.x + B.vx*B_dt + 0.5*B.ax*B_dt*B_dt;
		predictedBPosition.y = B.y + B.vy*B_dt + 0.5*B.ay*B_dt*B_dt;
		predictedBPosition.z = B.z + B.vz*B_dt + 0.5*B.az*B_dt*B_dt;

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

	override function get_params():Dynamic{
		return {
			max_dt:max_dt,
			min_dt:min_dt,
		};
	}	

	override function poolInitialization(){
		predictedBPosition = new Vec3();
		super.poolInitialization();
	}
}

class BodyAdaptive extends Body{
	public var ss:Int;//step size
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
}
