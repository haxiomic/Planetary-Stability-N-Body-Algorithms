package simulator;

import simulator.NBodySimulator;

class Leapfrog extends NBodySimulator{
	public var dt:Float;

	public function new(G:Float, dt:Float){
		super(G);
		this.algorithmName = "Leapfrog";
		this.algorithmDetails = "Fixed timestep, 'Kick Drift Kick' variation.";
		this.dt = dt;
	}

	@:noStack 
	override function step(){
		stepKDK();
	}

	@:noStack
	inline function stepKDK(){
		for(i in 0...bodies.length){
			A = bodies[i];

			//Pairwise kick
			for(j in i+1...bodies.length){
				B = bodies[j];	

				accelerationsDueToGravity(A, B); 

				//Find change in velocity over half a timestep
				A.v.addProduct(r, accelA*dt*.5);
				B.v.addProduct(r, accelB*dt*.5);
			}

			//Each-Body Drift
			A.p.addProduct(A.v, dt);
		}

		for(i in 0...bodies.length){
			A = bodies[i];

			//Pairwise Kick
			for(j in i+1...bodies.length){
				B = bodies[j];	

				accelerationsDueToGravity(A, B); 

				//Find change in velocity over half a timestep
				A.v.addProduct(r, accelA*dt*.5);
				B.v.addProduct(r, accelB*dt*.5);
			}
		}

		time+=dt;

	}

	@:noStack
	inline function stepDKD(){
		//Each-Body Drift
		for(i in 0...bodies.length){
			A = bodies[i];
			A.p.addProduct(A.v, dt*0.5);
		}

		for(i in 0...bodies.length){
			A = bodies[i];

			//Pairwise Kick
			for(j in i+1...bodies.length){
				B = bodies[j];	

				accelerationsDueToGravity(A, B); 

				//Find change in velocity over half a timestep
				A.v.addProduct(r, accelA*dt);
				B.v.addProduct(r, accelB*dt);
			}

			//Each-Body Drift
			A.p.addProduct(A.v, dt*0.5);
		}

		time+=dt;
	}

	override function get_params():Dynamic{
		return {dt:dt};
	}	
}

