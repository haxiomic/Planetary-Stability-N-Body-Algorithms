package simulator;

import simulator.Simulator;

class Leapfrog extends Simulator{
	public var dt:Float;

	public function new(G:Float, dt:Float){
		super(G);
		this.algorithmName = "Leapfrog";
		this.algorithmDetails = "Symplectic, fixed timestep, includes 'kick drift kick' & 'drift kick drift' variations.";
		this.dt = dt;
	}

	@:noStack 
	override public function step(){
		stepDKD();
	}

	@:noStack
	inline function stepKDK(){
		var dSq        : Float;
		var fc         : Float;
		for (i in 0...bodyCount){
			//Pairwise kick
			for (j in i+1...bodyCount) {
				position.difference(i, j, r);
				dSq  = r.lengthSquared();
				fc   = G / dSq;
				r *= 1/Math.sqrt(dSq);//normalize

				velocity.addProductVec3(i, r, fc*mass[j]*dt*.5);
				velocity.addProductVec3(j, r, -fc*mass[i]*dt*.5);
			}

			//Each-Body Drift
			position.addFn(i, inline function(k) return
				velocity.get(i,k)*dt
			);
		}

		for (i in 0...bodyCount){
			//Pairwise kick
			for (j in i+1...bodyCount) {
				position.difference(i, j, r);
				dSq  = r.lengthSquared();
				fc   = G / dSq;
				r *= 1/Math.sqrt(dSq);//normalize

				velocity.addProductVec3(i, r, fc*mass[j]*dt*.5);
				velocity.addProductVec3(j, r, -fc*mass[i]*dt*.5);
			}
		}

		time+=dt;
	}

	@:noStack
	inline function stepDKD(){
		var dSq        : Float;
		var fc         : Float;
		for (i in 0...bodyCount){
			//Each-Body Drift
			position.addFn(i, inline function(k) return
				velocity.get(i,k)*dt*.5
			);
		}
		
		for (i in 0...bodyCount){
			//Pairwise kick
			for (j in i+1...bodyCount) {
				position.difference(i, j, r);
				dSq  = r.lengthSquared();
				fc   = G / dSq;
				r *= 1/Math.sqrt(dSq);//normalize
				
				velocity.addProductVec3(i, r, fc*mass[j]*dt);
				velocity.addProductVec3(j, r, -fc*mass[i]*dt);
			}

			//Each-Body Drift
			position.addFn(i, inline function(k) return
				velocity.get(i,k)*dt*.5
			);
		}

		time+=dt;
	}

	override function get_params():Dynamic{
		return {dt:dt};
	}	
}

