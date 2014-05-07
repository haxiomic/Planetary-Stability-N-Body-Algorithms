package;

import geom.Vec3;
import haxe.ds.Vector;

import simulator.Body;
import simulator.Simulator;
import BodyDatum;
import sysUtils.Console;

class Experiment{
	//Core
	public var name:String = "";
	public var simulator:Simulator;
	public var bodies(default, null):Array<BodyDatum> = new Array<BodyDatum>();
	//Required:
	public var timescale:Float;
	//Optional:
	public var analysisInterval:Null<Int> = null;	//iterations
	public var analysisTimeInterval:Null<Float> = null;	//same units as timescale
	//callback during experiment
	public var runtimeCallback:Experiment->Void = null;//runtimeCallback(this)
	public var runtimeCallbackInterval:Null<Int> = null;
	public var runtimeCallbackTimeInterval:Null<Float> = null; //same units as timescale
	//ignore from analysis
	public var ignoredBodies(default, null):Array<Body> = new Array<Body>();
	
	//Read-write simulation variables
	public var timeStart:Float;
	public var timeEnd:Float;
	public var time:Float;
	//Read-only simulation variables
	//Guaranteed: 
	//algorithm runtime
	public var algorithmStartTime (default, null):Float;
	public var algorithmEndTime   (default, null):Float;
	//experiment simulation time
	public var totalCPUTime    (default, null):Float;
	public var totalIterations (default, null):Float;

	//Method Dependant:
	//system energy
	public var initialEnergy (default, null):Float;
	public var currentEnergy (default, null):Float;
	//keplerian elements
	public var semiMajorArray           (default, null):Vector<Float>;
	public var eccentricityArray        (default, null):Vector<Float>;
	public var semiMajorErrorArray      (default, null):Array<Float>;
	public var semiMajorErrorAverageAbs (default, null):Float;
	//iteration
	public var i (default, null):UInt;
	//results
	public var results (default, null):ExperimentResults;

	//Experiment params information
	public var params (get, null):ExperimentInformation;


	public function new(simulatorClass:Class<Dynamic>, simArgs:Array<Dynamic>, ?name:String = ""){
		this.simulator = Type.createInstance(simulatorClass, simArgs);
		this.name = name=="" || name == null ? Type.getClassName(simulatorClass).split(".").pop() : name;
	}

	public function addBody(bd:BodyDatum):Body{
		bodies.push(bd);
		return simulator.addBody(new Body(bd.position.clone(), bd.velocity.clone(), bd.mass));
	}

	public function addbodies(bodies:Array<BodyDatum>){
		var added:Array<Body> = new Array<Body>();
		for(bd in bodies)
			added.push(addBody(bd));
		return added;
	}

	public function zeroDift(){
		var totalMomentum:Vec3 = new Vec3();
		var totalMass:Float = 0;
		for (b in simulator.bodies){
			totalMomentum.addProduct(b.v, b.m);
			totalMass += b.m;
		}

		var diftVelocity:Vec3 = totalMomentum/totalMass;
		for (b in simulator.bodies){
			b.v -= diftVelocity;
		}

	}

	@:noStack
	public function performEnergyTest():ExperimentResults{
		simulator.prepare();

		//return control callback
		var runtimeCallbackEnabled = (runtimeCallback!=null && runtimeCallbackInterval != null);
		var cbI:Int = runtimeCallbackInterval;
		//analysis interval
		var analysisEnabled = (analysisInterval != null);
		var aI:Int = analysisInterval;
		//system energy
		initialEnergy = simulator.totalEnergy();
		currentEnergy = initialEnergy;
		var energyChange:Float = 0;
		//time
		timeStart = simulator.time;
		timeEnd = time+timescale;
		time = timeStart;
		//iteration
		i = 0;
		//
		var analysis = new Map<String, Array<Dynamic>>();
		analysis["Iteration"] = new Array<Int>();
		analysis["Time"] = new Array<Float>();
		analysis["Energy Error"] = new Array<Float>();

		results = {
			totalIterations: 0,
			cpuTime: 0,
			analysis: analysis,
		}

		//run simulation
		algorithmStartTime = Sys.cpuTime();
		while(time<timeEnd){
			//Step simulation
			simulator.step();	

			//Analyze system
			if(analysisEnabled){
				if(i%analysisInterval==0){
					//update energy
					currentEnergy = simulator.totalEnergy();
					energyChange = Math.abs((currentEnergy - initialEnergy))/initialEnergy;

					analysis["Iteration"].push(i);
					analysis["Time"].push(time);
					analysis["Energy Error"].push(energyChange);
				}
			}

			//Callback to return control
			if(runtimeCallbackEnabled) 
				if(i%cbI==0) runtimeCallback(this);

			//Progress loop
			time = simulator.time;
			i++;
		}
		algorithmEndTime = Sys.cpuTime();
		if(runtimeCallbackEnabled)runtimeCallback(this);

		var totalIterations = i;

		results.totalIterations = totalIterations;
		results.cpuTime = (algorithmEndTime - algorithmStartTime);
		return results;
	}

	public function performStabilityTest():Bool{
		simulator.prepare();
		//Enable runtime callback & analysis
		//analysis
		var analysisEnabled = (analysisTimeInterval != null);
		var lastATime:Float = 0;
		//runtime
		var runtimeCallbackEnabled = (runtimeCallback != null && runtimeCallbackTimeInterval != null);
		var lastRTTime:Float = 0;
		//initial system energy
		initialEnergy = simulator.totalEnergy();
		currentEnergy = initialEnergy;
		var energyChange:Float = 0;
		//initial keplerian elements
		computeKeplerianElements();
		var initialSemiMajorArray = new Vector(semiMajorArray.length);
		Vector.blit(semiMajorArray, 0, initialSemiMajorArray, 0, semiMajorArray.length);
		//time
		timeStart = simulator.time;
		timeEnd = time+timescale;
		time = timeStart;
		//iteration
		i = 0;

		function stablityCheck():Bool{
			computeKeplerianElements();
			//check all have eccentricity < 1
			for (e in eccentricityArray)
				if(e>=1){//planet ejected
					return false;
				}
			return true;
		}

		//Step loop
		//analysis before start
		if(analysisEnabled)stablityCheck();
		if(runtimeCallbackEnabled)runtimeCallback(this);

		function stabilityLoop():Bool{
			while(time<timeEnd){
				//step simulation
				simulator.step();	

				//analyze system
				if(analysisEnabled)
					if( time - lastATime >= analysisTimeInterval){
						if(!stablityCheck())return false;
						lastATime = time;
					}
				

				//runtime callback
				if(runtimeCallbackEnabled)
					if( time - lastRTTime >= runtimeCallbackTimeInterval){
						runtimeCallback(this);
						lastRTTime = time;
					}

				//progress loop
				time = simulator.time;
				i++;
			}

			return true;
		}
		algorithmStartTime = Sys.cpuTime();
		var isStable = stabilityLoop();
		algorithmEndTime = Sys.cpuTime();

		totalIterations = i;
		totalCPUTime = algorithmEndTime - algorithmStartTime;

		//run once again at end
		if(analysisEnabled)stablityCheck();
		if(runtimeCallbackEnabled)runtimeCallback(this);

		//Determine magnitude of perturbation
		semiMajorErrorArray = new Array<Float>();
		semiMajorErrorAverageAbs = 0;

		for (i in 0...semiMajorArray.length){
			semiMajorErrorArray[i] = (semiMajorArray[i] - initialSemiMajorArray[i])/initialSemiMajorArray[i];
		}
		
		var te:Float = 0;
		var n = 0;
		for (e in semiMajorErrorArray) {
			if(Math.isNaN(e))continue;
			te+=Math.abs(e);
			n++;
		}
		semiMajorErrorAverageAbs = te/n;

		return isStable;
	}

	//Requires orbit central body to be at index[0]
	public function computeKeplerianElements(){
		//Loop through bodies, find eccentricity and semi-major axis
		//'Osculating' - ignore perturbations
		semiMajorArray = new Vector(simulator.bodies.length);
		eccentricityArray = new Vector(simulator.bodies.length);

		var mostMassiveBody:Body = simulator.bodies[0];

		for (i in 0...simulator.bodies.length) {
			var A = simulator.bodies[i];
			if(A==mostMassiveBody || ignoredBodies.indexOf(A)>-1){
				semiMajorArray[i] = 0;
				continue;
			}

			Vec3.difference(A.p, mostMassiveBody.p, r);
			var r_COM:Float = r.length();

			//find gravitational parameter, u:
			var M_r:Float = A.m;//mass within r_COM
			for (B in simulator.bodies) {
				if(A==B)continue;
				if(Vec3.distance(B.p, mostMassiveBody.p) < r_COM)
					M_r += B.m;
			}
			var u = simulator.G * M_r;

			//semi-major
			var v = A.v.length();
			var semiMajor:Float = 1/(2/r_COM - v*v/u);

			//eccentricity
			var hSq:Float = Vec3.cross(r, A.v, L).lengthSquared();
			var eccentricity = Math.sqrt(1 - hSq/(semiMajor*u));

			//store
			semiMajorArray[i] = semiMajor;
			eccentricityArray[i] = eccentricity;
		}
	}
	var r:Vec3 = new Vec3();
	var L:Vec3 = new Vec3();

	public function get_params():ExperimentInformation{
		return {
			experimentName: this.name,
			timescale: this.timescale,
			analysisInterval: this.analysisInterval,
			bodies: this.bodies,
			simulatorParams: simulator.params,
			algorithmName: simulator.algorithmName,
			algorithmDetails: simulator.algorithmDetails,
		}
	}
}

typedef ExperimentResults = {
	var totalIterations:UInt;
	var cpuTime:Float;
	var analysis:Map<String, Array<Dynamic>>;
}

typedef ExperimentInformation = {
	var experimentName:String;
	var timescale:Float;
	var analysisInterval:Float;
	var bodies:Array<BodyDatum>;
	var simulatorParams:Dynamic;
	var algorithmName:String;
	var algorithmDetails:String;
}
