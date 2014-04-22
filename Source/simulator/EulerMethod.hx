package simulator;

import haxe.ds.Vector;
import geom.Vec3;
import geom.FlatVec3Array;
import geom.VPointer;
import simulator.NBodySimulator;


class EulerMethod extends NBodySimulator {
	public var dt:Float;

	public function new(G:Float, dt:Float){
		super(G);
		this.algorithmName = "Euler Method";
		this.algorithmDetails = "Since velocity is updated before position it's the 'Semi-Implicit Euler Method'";
		this.dt = dt;
	}

	@:noStack
	override public inline function step(){
		var d          : Float;
		var dSq        : Float;
		var fc         : Float;
		for (i in 0...bodyCount){
			//pairwise
			for (j in i+1...bodyCount) {
				position.difference(i, j, r);
				dSq  = r.lengthSquared();
				d    = Math.sqrt(dSq);
				fc   = G / dSq;
				//Normalize r
				r *= 1/d;
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