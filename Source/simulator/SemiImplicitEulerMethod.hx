package simulator;

import geom.Vec3;
import geom.FlatVec3Array;
import simulator.Simulator;

class SemiImplicitEulerMethod extends Simulator {
	public var dt:Float;

	public function new(G:Float, dt:Float){
		super(G);
		this.algorithmName = "Semi-Implicit Euler Method";
		this.algorithmDetails = "Euler method variation where velocity is updated before position";
		this.dt = dt;
	}

	@:noStack
	override public inline function step(){
		var dSq        : Float;
		var fc         : Float;
		for (i in 0...bodyCount){
			//pairwise
			for (j in i+1...bodyCount) {
	
				position.difference(i, j, r);
				dSq  = r.lengthSquared();
				fc   = G / dSq;
				r *= 1/Math.sqrt(dSq);//normalize

				velocity.addProductVec3(i, r, fc*mass[j]*dt);
				velocity.addProductVec3(j, r, -fc*mass[i]*dt);
			}

			position.addFn(i, inline function(k) return
				velocity.get(i,k)*dt
			);
		}

		time+=dt;
	}

	override function get_params():Dynamic{
		return {dt:dt};
	}
}