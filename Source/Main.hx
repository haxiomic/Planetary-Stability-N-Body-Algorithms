package;

import geom.Vec3;
import simulator.*;
import renderer.*;
import Experiment.ExperimentResults;
import Experiment.ExperimentInformation;

import simulator.Hermite4thOrder;
import simulator.Leapfrog;
import simulator.EulerMethod;

import simulator.NBodySimulator;
import sysUtils.compileTime.Build;
import sysUtils.compileTime.Git;
import sysUtils.Console;
import sysUtils.FileTools;

using sysUtils.Escape;

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
		function basicTest(exp:Experiment, dt:Float = 5, timescale:Float = 1000, analysisCount:Int = 100, ?c:Int){
			Console.printStatement(exp.simulator.algorithmName);
			Console.print(exp.simulator.params);

			//add bodies
			addSolarSystem(exp, c);

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
			Console.newLine();
			return exp;
		}

		var dt = 30;
		var timescale:Float = 10000*365.0;
		var analysisCount = 200;

		var euler = basicTest(new Experiment(EulerMethod, [Constants.G_AU_kg_D, dt]), dt, timescale, analysisCount, 0x00FF00);
		var leapfrog = basicTest( new Experiment(Leapfrog, [Constants.G_AU_kg_D, dt]), dt, timescale, analysisCount, 0xFF0000);
		var hermite = basicTest( new Experiment(Hermite4thOrder, [Constants.G_AU_kg_D, dt]), dt, timescale, analysisCount, 0x0000FF);
		//var exp = basicTest(simulator.LeapfrogAdaptive, dt, timescale, analysisCount, 0xFF0000);
		//var exp2 = basicTest(new Experiment(simulator.LeapfrogAdaptiveSweep, [Constants.G_AU_kg_D, (1<<4), 1]), 1, timescale, analysisCount);

		sysUtils.Console.suppress = true;
		//start render loop
		renderer.preRenderCallback = inline function(){
		//	euler.simulator.step();		
		//	leapfrog.simulator.step();		
			//hermite.simulator.step();		
		}
		//renderer.startAutoRender();

	}


	/* --- Planetary System Schemes --- */
	function addSolarSystem(exp:Experiment, ?c:Int){
		var sun:Body = exp.addBody(SolarBodyData.sun); renderer.addBody(sun, 5, c==null ? 0xFFFF00 : c);
		//var earth:Body = exp.addBody(SolarBodyData.earth); renderer.addBody(earth, 5, c == null ? 0x2288CC : c);
		var jupiter:Body = exp.addBody(SolarBodyData.jupiter); renderer.addBody(jupiter, 5, c == null ? 0xFF0000 : c);
		var saturn:Body = exp.addBody(SolarBodyData.saturn); renderer.addBody(saturn, 5, c == null ? 0xFFFFFF : c);
		var uranus:Body = exp.addBody(SolarBodyData.uranus); renderer.addBody(uranus, 5, c == null ? 0xFFFFFF : c);
		var neptune:Body = exp.addBody(SolarBodyData.neptune); renderer.addBody(neptune, 5, c == null ? 0xFFFFFF : c);
	}

	function addTwoBodyEccentricOrbit(exp:Experiment, ?c:Int){
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
			mass: 5.97219E28,
		};
		
		var sun = exp.addBody(sunData); 
		var planet = exp.addBody(planetData);
		sun.v.z = -planet.v.z*planet.m/sun.m;
		renderer.addBody(sun, 5, c == null ? 0xFFFF00 : c);
		renderer.addBody(planet, 2.5, c == null ? 0x2288CC : c);
	}

	/* --- Logging --- */
	inline function runtimeLog(e:Experiment){
		var progress = 100*(e.time-e.timeStart)/e.timescale;
		Console.printStatement(progress+"% "+"\r", false);
	}

	inline function experimentSummaryLog(r:ExperimentResults){
		var millionIterationTime = 1000*1000*(r.cpuTime/r.totalIterations);

		var sumE:Float = 0;
		for(e in r.analysis.energyChange) sumE+=e;

		var avgE = sumE/r.analysis.energyChange.length;
		Console.printTitle("Average energy error: "+avgE);

		Console.print("Total Iterations: "+r.totalIterations+" | CPU Time: "+r.cpuTime+" s  |  1M Iteration: "+millionIterationTime+" s");
		Console.newLine();
	}

	/* --- File Output --- */
	function saveExperiment(e:Experiment, filePrefix:String = ""){
		var info = e.information;
		var results = e.results;

		//Construct object to save
		//info.json
		var fileSaveData = {
			metadata:{
				date: Build.date(),
				git: Git.lastCommit(),
				gitHash: Git.lastCommitHash(),
				units: units,
			},
			info: info,
			results: {
				totalIterations: results.totalIterations,
				cpuTime: results.cpuTime,
			},
		}

		//data.csv
		var csv:sysUtils.HackyCSV = new sysUtils.HackyCSV();
		csv.addColumn(results.analysis.iteration, "Iteration ("+filePrefix+")");
		csv.addColumn(results.analysis.time, "Time ("+filePrefix+")");
		csv.addColumn(results.analysis.energyChange, "Energy Error ("+filePrefix+")");

		filePrefix = (new haxe.io.Path(filePrefix)).file;//parse filePrefix to make it safe for paths
		if(filePrefix!="")filePrefix+=" - ";

		var parsedAlgorithmName = (new haxe.io.Path(info.algorithmName)).file;
		var namespace = filePrefix+Math.round(info.timescale/365)+" years, "+info.bodies.length+" bodies";
		var path = haxe.io.Path.join([dataOutDirectory, parsedAlgorithmName, namespace]);

		try{

			//save file
			FileTools.save(haxe.io.Path.join([path, "info.json"]), haxe.Json.stringify(fileSaveData), function (dir:String){
				return Console.askYesNoQuestion("Directory '"+dir+"' doesn't exist, create it?", null, false);
			});
			FileTools.save(haxe.io.Path.join([path, "data - "+(csv.rowCount-1)+" rows.csv"]), csv.toString(), function (dir:String){
				return Console.askYesNoQuestion("Directory '"+dir+"' doesn't exist, create it?", null, false);
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