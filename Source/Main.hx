package;

import geom.Vec3;
import simulator.*;
import renderer.*;
import Experiment.ExperimentResults;
import Experiment.ExperimentInformation;

import simulator.Leapfrog;
import simulator.EulerMethod;

import sysUtils.compileTime.Build;
import sysUtils.compileTime.Git;
import sysUtils.Console;
import sysUtils.FileTools;

class Main {
	var renderer:BasicRenderer;

	var units:Dynamic = {
		time: "days",
		length: "AU",
		mass: "kg"
	};

	/* --- File Config --- */
	var dataOutDirectory = Build.dir()+"/Output Data/";
	/* -------------- */

	public function new () {
		renderer = new BasicRenderer();
		
		//Basic Test
		function basicTest(simulator:Class<Dynamic>, dt:Float = 5, timescale:Float = 1000, analysisCount:Int = 100, color:Int = 0x2288CC){
			var exp = new Experiment(simulator, [Constants.G_AU_kg_D, dt], "Basic Test SS");
			Console.printStatement(exp.simulator.algorithmName);
			Console.print(exp.simulator.params);

			//add bodies
			addSolarSystem(exp);

			//set experiment conditions
			exp.timescale = timescale;
			exp.analysisInterval = Math.ceil((exp.timescale/dt)/analysisCount);

			//enable runtime logging
			exp.runtimeCallback = runtimeLog;
			exp.runtimeCallbackInterval = exp.analysisInterval*8;

			//perform experiment
			var r:ExperimentResults = exp.perform();

			experimentSummaryLog(r);

			saveExperiment(exp, exp.name+", dt="+dt);
			return exp;
		}

		var dt = 1;
		var timescale = 10000*365;
		var analysisCount = 100;

		basicTest(EulerMethod, dt, timescale, analysisCount, 0x2288CC);
		basicTest(Leapfrog, dt, timescale, analysisCount, 0xFF0000);
		var exp = basicTest(simulator.LeapfrogAdaptive, dt, timescale, analysisCount, 0xFF0000);

		renderer.preRenderCallback = inline function(){
			exp.simulator.step();		
		}
		renderer.startAutoRender();
/*
		renderer.reset();

		var euler = new Experiment(EulerMethod, [Constants.G_AU_kg_D, dt]);
		var leap = new Experiment(Leapfrog, [Constants.G_AU_kg_D, dt]);

		addTwoBodyEccentricOrbit(euler);
		addTwoBodyEccentricOrbit(leap);

		renderer.preRenderCallback = inline function(){
			euler.simulator.step();	
			leap.simulator.step();	
		}
		renderer.startAutoRender();*/

		//Finish program
		/*Console.newLine();
		Console.printStatement("Press any key to continue");
		Sys.getChar(false);
		Console.newLine();*/

		//exit(0);
	}


	/* --- Planetary System Schemes --- */
	inline function addSolarSystem(exp:Experiment){
		var sun:Body = exp.addBody(SolarBodyData.sun); renderer.addBody(sun, 5, 0xFFFF00);
		var earth:Body = exp.addBody(SolarBodyData.earth); renderer.addBody(earth, 5, 0x2288CC);
		var jupiter:Body = exp.addBody(SolarBodyData.jupiter); renderer.addBody(jupiter, 5, 0xFF0000);
		var saturn:Body = exp.addBody(SolarBodyData.saturn); renderer.addBody(saturn, 5, 0xFFFFFF);
		var uranus:Body = exp.addBody(SolarBodyData.uranus); renderer.addBody(uranus, 5, 0xFFFFFF);
		var neptune:Body = exp.addBody(SolarBodyData.neptune); renderer.addBody(neptune, 5, 0xFFFFFF);
	}

	inline function addTwoBodyEccentricOrbit(exp:Experiment){
		var sunData:BodyDatum = {
			name: "Sun",
			position: {x:0, y:0, z:0},
			velocity: {x:0, y:0, z:0},
			mass: 1.988544E30,
		};
		var planetData:BodyDatum = {
			name: "Test Planet (Earth-like)",
			position: {x:1, y:0, z:0},
			velocity: {x:0, y:0, z:0.01},
			mass: 5.97219E24,
		};
		var sun = exp.addBody(sunData); renderer.addBody(sun, 5, 0xFFFF00);
		var planet = exp.addBody(planetData); renderer.addBody(planet, 2.5, 0x2288CC);
	}


	/* --- Logging --- */
	inline function runtimeLog(e:Experiment){
		var progress = 100*(e.time-e.timeStart)/e.timescale;
		Console.printStatement(progress+"% "+"\r", false);
	}

	inline function experimentSummaryLog(r:ExperimentResults){
		var millionIterationTime = 1000*1000*(r.cpuTime/r.totalIterations);

		var sumE:Float = 0;
		for(e in r.energyChange) sumE+=e.value;

		var avgE = sumE/r.energyChange.length;
		Console.printTitle("Average energy error: "+avgE);

		Console.print("Total Iterations: "+r.totalIterations+" | CPU Time: "+r.cpuTime+" s  |  1M Iteration: "+millionIterationTime+" s");
		Console.newLine();
	}

	/* --- File Output --- */
	function saveExperiment(e:Experiment, filePrefix:String = ""){
		var info = e.information;
		var results = e.results;
		var r:Dynamic = Reflect.copy(results);
		r.millionIterationTime = 1000*1000*(r.cpuTime/r.totalIterations)+" s";//add extra field
		//Construct object to save
		var fileSaveData = {
			metadata:{
				date: Build.date(),
				git: Git.lastCommit(),
				gitHash: Git.lastCommitHash(),
				units: units,
			},
			info: info,
			results: results,
		}

		filePrefix = (new haxe.io.Path(filePrefix)).file;//parse filePrefix to make it safe for paths
		if(filePrefix!="")filePrefix+=" - ";

		var parsedAlgorithmName = (new haxe.io.Path(info.algorithmName)).file;
		var filename = filePrefix+info.bodies.length+" bodies, timescale="+Math.round(info.timescale/365)+" years"+".json";
		var fileDir = haxe.io.Path.join([dataOutDirectory, parsedAlgorithmName]);//dataOutDir/parsedAlgorithmName
		var path = haxe.io.Path.join([fileDir, filename]);
		try{
			//Create filename
			FileTools.saveAsJSON(fileSaveData, path, function (dir:String){
				return Console.askYesNoQuestion("Directory "+dir+" doesn't exist, create it?", null, false);
			});
		}catch(msg:String){
			Console.printError(msg);
			Console.newLine();
			if(Console.askYesNoQuestion("Shall I dump the data to the console?")){
				Console.printTitle("Dumping data to console");
				Console.newLine();
				Console.print(haxe.Json.stringify(fileSaveData));
				Console.newLine();
			}
		}
	}

	/* -------------------------*/
	/* --- System Functions --- */

	inline function exit(?code:Int)
		Sys.exit((code==null ? 0 : code));//return successful if code == null

	static function main(){new Main();}
}