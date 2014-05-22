package simulator;

import geom.FlatVec3Array;
import haxe.ds.Vector;

class LeapfrogAdaptive extends Simulator{

	var acceleration:FlatVec3Array;
	var stepSize:Vector<Int>;

	var orderedIndicies:Array<Int>;

	var dtBase:Float;//length of time for a step size of 1

	var maxSS:Int;

	var mostMassiveIndex:Int = 0;
	var mostMassiveMass:Float;

	var accuracyParameter:Float;

	public function new(G:Float, minimumTimestep:Float, accuracyParameter:Float = 0.03, maxStepSize = (1<<11)){
		super(G);
		this.algorithmName = "Leapfrog Adaptive";
		this.algorithmDetails = "Block timesteps, schedule approach. Time-symmetrized DSKD scheme. Timestep set by Kepler orbit about most massive body";

		this.dtBase = minimumTimestep;
		this.accuracyParameter = accuracyParameter;
		this.maxSS = maxStepSize;
	}

	override public function prepare(){
		super.prepare();

		acceleration   	 = new FlatVec3Array(this.bodies.length);
		stepSize         = new Vector<Int>(this.bodies.length);
		orderedIndicies  = new Array<Int>();
	
		//Initialize		
		for (i in 0...this.bodies.length){
			acceleration.zero(i);
			orderedIndicies[i] = i;
			stepSize[i] = 1;
			//find most massive body
			if(mass[i]>mass[mostMassiveIndex])mostMassiveIndex = i;
		}

		mostMassiveMass = mass[mostMassiveIndex];
	}


	override function step(){
		//Step until synchronised
		do{
			subStep();
		}while(closedCount!=bodyCount);
	}

	var s:Int = 0;//current step
	var prevSmallestSS = 1;
	var closedCount:Int = 0;
	@:noStack
	inline function subStep(){
		var smallestSS = maxSS;
		var dt;
		var reorder:Bool = false;

		//Open
		for (i in 0...bodyCount){
			var ssOld = stepSize[i];
			if(s % ssOld != 0) continue;//continue if it's not time to step body

			var dtOld = dtFromSS(ssOld);

			//drift forward
			position.addFn(i, inline function(k) return
				velocity.get(i,k)*dtOld*.5
			);

			//Select
			var ssNew;
			if(i == mostMassiveIndex){
				ssNew = 16;
				stepSize[i] = ssNew;
			}else{
				ssNew = pickSS(i);
				if(s % ssNew == 0 && ssNew != ssOld){//both bodies are 'closed' - step size can only change at points of synchronization
					stepSize[i] = ssNew;

					//correct position
					dt = dtFromSS(ssNew);
					position.addFn(i, inline function(k) return
						velocity.get(i,k)*(dt-dtOld)*.5
					);
				}
			}

			if(ssNew != ssOld)reorder = true;

			if(stepSize[i] < smallestSS)
				smallestSS = stepSize[i];
		}

		// trace(stepSize);

		//Order
		if(reorder)orderedIndicies.sort(ssAscending);

		//Pairwise kick, from smallest to largest step size
		var dSq        : Float;
		var fc         : Float;
		for (k in 0...bodyCount) {
			var i = orderedIndicies[k];
			if(s % stepSize[i] != 0) continue;//continue if it's not time to step body

			dt = dtFromSS(stepSize[i]);

			for (l in k+1...bodyCount) {
				var j = orderedIndicies[l];

				position.difference(i, j, r);
				dSq  = r.lengthSquared();
				fc   = G / dSq;
				r *= 1/Math.sqrt(dSq);//normalize

				velocity.addProductVec3(i, r,  fc*mass[j]*dt);
				velocity.addProductVec3(j, r, -fc*mass[i]*dt);
			}
		}

		closedCount = 0;
		//Close
		for (i in 0...bodyCount){
			if(Std.int(s+smallestSS) % stepSize[i] != 0) continue;//continue if it's not time to step body

			//Each-Body Drift
			dt = dtFromSS(stepSize[i]);
			position.addFn(i, inline function(k) return
				velocity.get(i,k)*dt*.5
			);

			closedCount++;
		}

		time += dtFromSS(smallestSS);
		s += smallestSS;
		s = s%maxSS;//wrap around
		prevSmallestSS  = smallestSS;
	}

	@:noStack
	inline function pickSS(i:Int){
		var dSq     : Float;
		var dCu     : Float;
		var idealDt : Float;
		var idealSS : Float;

		position.difference(i, mostMassiveIndex, r);
		dSq = r.lengthSquared();
		dCu = dSq*Math.sqrt(dSq);
		idealDt = accuracyParameter*Math.sqrt(dCu/(G*mostMassiveMass));

		idealSS = idealDt/dtBase;

		return idealSS < maxSS ? floorBase2(idealSS) : maxSS;
	}

	inline function dtFromSS(ss:Int):Float return ss*dtBase;

	inline function floorBase2(x:Float):Int{
		var br:Int = 0;
		var y:Int = Std.int(x);
		while((y >>= 1) > 0) ++br;
		return 1 << br;
	}

	inline function ssAscending(i:Int, j:Int):Int 
		return stepSize[i] - stepSize[j];//a-b => smallest to largest

	override function get_params():Dynamic{
		return {
			minimumTimestep:dtBase,
			accuracyParameter:accuracyParameter,
			maxStepSize:dtFromSS(maxSS),
		};
	}
}