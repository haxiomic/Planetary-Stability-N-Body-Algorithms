package;

import haxe.ds.Vector;

import geom.Vec3;
import simulator.Body;
import simulator.NBodySimulator;
import SolarBodyData.BodyDatum;

import sysUtils.CompileTime;
import sysUtils.Log;
import sysUtils.FileTools;

// import renderer.BasicRenderer;
// import hxcpp.StaticRegexp;

class Main {
	// var renderer:BasicRenderer;
	var simulator:NBodySimulator;

	var units:Dynamic;
	var addedBoddies:Array<BodyDatum>;

	/* --- File Config --- */
	var dataOutDirectory = CompileTime.buildDir()+"/Output Data/";
	/* -------------- */

	public function new () {
		simulator = new NBodySimulator();
		// renderer = new BasicRenderer();

		units = {
			time: "days",
			length: "AU",
			mass: "kg"
		}

		// --- Setup Simulation ---
		simulator.clear();
		addedBoddies = new Array<BodyDatum>();

		function addBodyFromDatum(bd:BodyDatum, displayRadius:Float = 10, displayColor:Int = 0xFF0000):Body{
			var b = simulator.addBody(new Body(bd.position, bd.velocity, bd.mass));
			addedBoddies.push(bd);

			// renderer.addBody(b, displayRadius, displayColor); //add to renderer
			return b;
		}

		var rCV = 0.0000006; //radiusConversionFactor for display
		var sun = addBodyFromDatum(SolarBodyData.sun, 15, 0xFFA21F);
		var earth = addBodyFromDatum(SolarBodyData.earth, SolarBodyData.earth.radius*rCV, 0xBB1111);
		var jupiter = addBodyFromDatum(SolarBodyData.jupiter, SolarBodyData.jupiter.radius*rCV, 0xBB1111);
		var saturn = addBodyFromDatum(SolarBodyData.saturn, SolarBodyData.saturn.radius*rCV, 0xFFE26E);
		var uranus = addBodyFromDatum(SolarBodyData.uranus, SolarBodyData.uranus.radius*rCV, 0xA7D6DC);
		var neptune = addBodyFromDatum(SolarBodyData.neptune, SolarBodyData.neptune.radius*rCV, 0x2A45FD);
		// --- Perform Simulation ---
		var experimentSetup:SimulationSetup = {
			dt: 1,	//days
			timescale: 10000 *365, //days
			analysisInterval: 100, //iterations, as total interval count: (timescale)
			boddies: addedBoddies,
			units: units,
		}var s = experimentSetup;

		var r:SimulationResults = performSimulation(simulator, s.dt, s.timescale, s.analysisInterval);

		// --- Handle Results ---
		var millionIterationTime = 1000*1000*(r.cpuTime/r.totalIterations);

		Log.newLine();
		Log.print("CPU Time: "+r.cpuTime+" s  |  1M iterations: "+millionIterationTime+" s");
		Log.newLine();

		// --- Save Results ---
		saveResults(simulator, s, r);

		//steadyStep();

		Log.newLine();
		Log.printStatement("Press any key to continue");
		Sys.getChar(false);
		Log.newLine();

		exit(0);
	}

	@:noStack
	function performSimulation(simulation:NBodySimulator, dt:Float = 1, timescale:Float = 1, analysisInterval:Float = 100):SimulationResults{
		//Data
		var energyChangeArray:Array<SimulationDataPoint> = new Array<SimulationDataPoint>();

		//Algorithm runtime
		var algorithmStartTime:Float, algorithmEndTime:Float;

		//System Energy
		var initalEnergy:Float = simulator.computeTotalEnergy();
		var currentEnergy:Float = initalEnergy;
		var energyChange:Float = 0;

		//run simulation
		//1 day = 86400 seconds
		var time:Float = 0;
		var requiredIterations:Int = Math.ceil(timescale/dt);

		var i:UInt = 0;//iteration

		algorithmStartTime = cpuTime();
		while(time<=timescale){
			//Step simulation
			simulator.step(dt);	

			//Analyze system
			if(i%analysisInterval==0){
				//update energy
				currentEnergy = simulator.computeTotalEnergy();
				energyChange = Math.abs((currentEnergy - initalEnergy))/initalEnergy;

				energyChangeArray.push(new SimulationDataPoint(energyChange, time, i));
			}

			//Report progress
			if(i%300000==0){
				var millionIterationTime = 1000*1000*(cpuTime() - algorithmStartTime)/(i+1);
				Log.print(100*(i/requiredIterations)+"% error: "+energyChange+" iteration: "+i+" 1M Iteration Time: "+millionIterationTime+" s \r", false);
			}

			//Progress loop
			time+=dt;
			i++;
		}
		algorithmEndTime = cpuTime();

		var totalIterations = i;

		return {
			totalIterations: totalIterations,
			cpuTime: (algorithmEndTime - algorithmStartTime),
			energyChange: energyChangeArray,
		};
	}

	function steadyStep(){
		// var stepTimer:haxe.Timer = new haxe.Timer(10);
		// stepTimer.run = function():Void{
		// 	simulator.step(1);

		// 	// renderer.render();
		// };
	}

	function saveResults(simulator:NBodySimulator, setup:SimulationSetup, results:SimulationResults){
		var r:Dynamic = Reflect.copy(results);
		r.millionIterationTime = 1000*1000*(r.cpuTime/r.totalIterations)+" s";
		//Construct object to save
		var fileSaveData = {
			metadata:{
				date: CompileTime.buildDate(),
				algorithmName: simulator.algorithmName,
				algorithmDescription: simulator.algorithmDescription,
				git: sysUtils.GitTools.lastCommit(),
				gitHash: sysUtils.GitTools.lastCommitHash(),
				units: units,
			},
			setup: setup,
			results: results,
		}

		try{
			//Create filename
			var filename = "dt="+setup.dt+" "+setup.units.time+", iterations="+r.totalIterations+", timescale="+setup.timescale/365+" years"+".json";
			var fileDir = dataOutDirectory+"/"+simulator.algorithmName;
			var path = fileDir+"/"+filename;

			saveAsJSON(fileSaveData, path, false);
		}catch(msg:String){
			Log.printError(msg);
			Log.newLine();

			Log.printTitle("Dumping data to console");
			Log.newLine();
			Log.print(haxe.Json.stringify(fileSaveData));
			Log.newLine();
		}
	}

	/* -------------------------*/
	/* --- System Functions --- */

	static public function saveAsJSON(data:Dynamic, path:String, autoCreateDirectory:Bool = true):Bool{
		var hxPath = new haxe.io.Path(path);

		var filename = hxPath.file;
		//Assess file out directory
		var outDir = haxe.io.Path.normalize(hxPath.dir);

		//Check if out directory exists
		if(!sys.FileSystem.exists(outDir)){
			if(autoCreateDirectory){
				sys.FileSystem.createDirectory(outDir);
			}else{
				//create out directory
				Log.printQuestion("Directory "+outDir+" doesn't exist, create it? (y/n)\n-> ", false);
				var char:Int = Sys.getChar(true);
				Log.newLine();
				Log.newLine();
				if(String.fromCharCode(char).toLowerCase() == "y"){
					sys.FileSystem.createDirectory(outDir);
					Log.printSuccess("Directory created");
				}else{
					throw "cannot save data";
					return false;
				}
			}
		}

		//Check the file doesn't already exist, if it does, find a free suffix -xx
		var filePath = FileTools.findFreeFile(hxPath.toString());
		filePath = haxe.io.Path.normalize(filePath);//normalize path for readability

		sys.io.File.saveContent(filePath, haxe.Json.stringify(data));

		Log.printSuccess("Data saved to "+Log.BRIGHT_WHITE+filePath+Log.RESET);

		return true;
	}

	inline function exit(?code:Int){
		if(code==null)code=0;//successful 
		#if cpp
			Sys.exit(code);
		#end
	}

	inline function cpuTime():Float{
		return Sys.cpuTime();
		//return haxe.Timer.stamp();
	}

	static function main(){
		new Main();
	}
}


typedef SimulationResults = {
	var totalIterations:UInt;
	var cpuTime:Float;
	var energyChange:Array<SimulationDataPoint>;
}

typedef SimulationSetup = {
	var dt:Float;
	var timescale:Float;
	var analysisInterval:Float;
	var boddies:Array<BodyDatum>;
	var units:Dynamic;
}

abstract SimulationDataPoint(Vector<Float>) from Vector<Float> to Vector<Float>{
	public inline function new(value:Float, time:Float, iteration:UInt){
		this = new Vector<Float>(3);
		this[0] = value;
		this[1] = time;
		this[2] = iteration;
	}

	public var value(get, set):Float;
	public var time(get, set):Float;
	public var iteration(get, set):UInt;

	public inline function get_value():Float return this[0];
	public inline function get_time():Float return this[1];
	public inline function get_iteration():UInt return Std.int(this[2]);
	public inline function set_value(v:Float):Float return this[0] = v;
	public inline function set_time(v:Float):Float return this[1] = v;
	public inline function set_iteration(v:UInt):UInt return Std.int(this[2] = v);

	public inline function toString() {
	    return "SimulationDataPoint(value: "+value+", time: "+time+", iteration: "+iteration+")";
	}
}
