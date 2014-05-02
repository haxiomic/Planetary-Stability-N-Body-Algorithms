package;

import geom.Vec3;
import haxe.ds.Vector;

import simulator.Body;
import simulator.Simulator;
import BodyDatum;
import sysUtils.Console;

class Experiment{

	public var name:String = "";
	public var simulator:Simulator;
	public var bodies(default, null):Array<BodyDatum>;

	//Experiment input params
	public var timescale(default, set):Float;
	public var analysisInterval(default, set):Null<Int> = null;	//iterations
	//callback during experiment
	public var runtimeCallback:Experiment->Void = null;
	public var runtimeCallbackInterval:Null<Int> = null;

	//Information
	public var information(get, null):ExperimentInformation;
	
	public function new(simulatorClass:Class<Dynamic>, simArgs:Array<Dynamic>, name:String = ""){
		this.bodies = new Array<BodyDatum>();
		this.simulator = Type.createInstance(simulatorClass, simArgs);
		this.name = name=="" ? Type.getClassName(simulatorClass).split(".").pop() : name;
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

	//Read-only simulation variables
	//data
	//algorithm runtime
	public var algorithmStartTime(default, null):Float;
	public var algorithmEndTime(default, null):Float;
	//system Energy
	public var initalEnergy(default, null):Float;
	public var currentEnergy(default, null):Float;
	//experiment simulation time
	public var timeStart(default, null):Float;
	public var timeEnd(default, null):Float;
	public var time(default, null):Float;
	//iteration
	public var i(default, null):UInt;
	//results
	public var results(default, null):ExperimentResults;
	@:noStack
	public function perform():ExperimentResults{
		simulator.prepare();

		//return control callback
		var runtimeCallbackEnabled = (runtimeCallback!=null && runtimeCallbackInterval != null);
		var cbI:Int = runtimeCallbackInterval;
		//analysis interval
		var analysisEnabled = (analysisInterval != null);
		var aI:Int = analysisInterval;
		//system energy
		initalEnergy = simulator.totalEnergy();
		currentEnergy = initalEnergy;
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
					energyChange = Math.abs((currentEnergy - initalEnergy))/initalEnergy;

					analysis["Iteration"].push(i);
					analysis["Time"].push(time);
					analysis["Energy Error"].push(energyChange);
				}
			}

			//Callback to return control
			if(runtimeCallbackEnabled){
				if(i%cbI==0) runtimeCallback(this);
			}

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

	public function kepler(){
		//Loop through bodies, find eccentricity and semi-major axis
		//'Osculating' - ignore perturbations
		var semiMajorArray = new Array<Float>();
		var eccentricityArray = new Array<Float>();
		
		var mostMassiveBody:Body = simulator.bodies[0];
		for (A in simulator.bodies)
			if(A.m > mostMassiveBody.m)mostMassiveBody = A;

		for (i in 0...simulator.bodies.length) {
			var A = simulator.bodies[i];
			if(A==mostMassiveBody){
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

			var v = A.v.length();
			var semiMajor:Float = 1/(2/r_COM - v*v/u);

			var hSq:Float = Vec3.cross(r, A.v, L).lengthSquared();
			var eccentricity = Math.sqrt(1 - hSq/(semiMajor*u));

			semiMajorArray[i] = semiMajor;
			eccentricityArray[i] = eccentricity;
		}
		trace(eccentricityArray);
	}
	var r:Vec3 = new Vec3();
	var L:Vec3 = new Vec3();

	public function get_information():ExperimentInformation{
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

	function set_timescale(v:Float):Float return timescale = v;
	function set_analysisInterval(v:Int):Int return analysisInterval = v;
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
