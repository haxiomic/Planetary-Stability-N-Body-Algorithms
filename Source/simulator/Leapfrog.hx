package simulator;

import simulator.NBodySimulator;

class Leapfrog extends NBodySimulator{
	public var dt:Float;
	var needsKickoff:Bool = true;

	public function new(G:Float, dt:Float){
		super(G);
		this.algorithmName = "Leapfrog";
		this.algorithmDetails = "";
		this.dt = dt;
		this.needsKickoff = true;
	}

	@:noStack 
	override function step(){
		stepKDK();
	}

	@:noStack
	public inline function stepKDK(){
		for(i in 0...bodies.length){
			A = bodies[i];

			//Kick
			for(j in i+1...bodies.length){
				B = bodies[j];	

				accelerationsDueToGravity(A, B); 

				//Find change in velocity over half a timestep
				aA*=dt*.5;
				aB*=dt*.5;
				A.v.addProduct(r, aA);
				B.v.addProduct(r, aB);
			}

			//Drift
			A.p.addProduct(A.v, dt);
		}

		time+=dt*.5;

		for(i in 0...bodies.length){
			A = bodies[i];

			//Kick
			for(j in i+1...bodies.length){
				B = bodies[j];	

				accelerationsDueToGravity(A, B); 

				//Find change in velocity over half a timestep
				aA*=dt*.5;
				aB*=dt*.5;
				A.v.addProduct(r, aA);
				B.v.addProduct(r, aB);
			}
		}
		time+=dt*.5;

	}

	@:noStack
	public inline function stepDKD(){
		//Drift
		for(i in 0...bodies.length){
			A = bodies[i];
			A.p.addProduct(A.v, dt*0.5);
		}

		time+=dt*.5;

		for(i in 0...bodies.length){
			A = bodies[i];

			//Kick
			for(j in i+1...bodies.length){
				B = bodies[j];	

				accelerationsDueToGravity(A, B); 

				//Find change in velocity over half a timestep
				aA*=dt;
				aB*=dt;
				A.v.addProduct(r, aA);
				B.v.addProduct(r, aB);
			}

			//Drift
			A.p.addProduct(A.v, dt*0.5);
		}

		time+=dt*.5;
	}

	override function get_params():Dynamic{
		return {dt:dt};
	}	
}

