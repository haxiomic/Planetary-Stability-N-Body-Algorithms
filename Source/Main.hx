package;

import geom.Vec3;
import simulator.*;
import renderer.*;
import Experiment.ExperimentResults;
import Experiment.ExperimentInformation;

import sysUtils.compileTime.*;
import sysUtils.*;

class Main {
	var renderer:BasicRenderer;

	var units:Dynamic = {
		time: "days",
		length: "AU",
		mass: "kg"
	};
	static inline var G:Float = Constants.G_AU_kg_D;

	/* --- File Config --- */
	var dataOutDirectory = Build.dir()+"/Output Data/";
	/* ------------------- */

	public function new () {
		renderer = new BasicRenderer();
		
		var dt:Float = 1 << 7;//300;
		var timescale = 1E7*365.0;

		var isStable = false;

		var exp:Experiment;
		var name = "Long-term LF Stability";
		Console.printTitle(name, false);
		while(!isStable){
			exp = new Experiment(Leapfrog, [G, dt], name);
			addSolarSystem(exp);
			exp.zeroDift();
			
			Console.printConcern('Timescale: ${timescale/365} years, dt: $dt ${units.time}, ${exp.bodies.length-1} planets');

			//set experiment conditions
			exp.timescale = timescale;
			exp.analysisTimeInterval = 10000*365;
			exp.runtimeCallbackTimeInterval = 30000*365;
			exp.runtimeCallback = function (exp:Experiment){
				//eta
				var runtime = Sys.cpuTime() - exp.algorithmStartTime;
				var fractionComplete = (exp.time-exp.timeStart)/exp.timescale;
				var totalRequiredTime = runtime/fractionComplete;
				var secondsRemaining = totalRequiredTime - runtime;

				var timeStr = secondsToMM_SS(secondsRemaining);
				var percent = Math.round(fractionComplete*100*100)/100;
				Console.print('\r$percent %\tTime Remaining: $timeStr        ', false);
				//printProgress(exp);
			}
			

			isStable = exp.performStabilityTest();

			Console.newLine();
			if(isStable){
				Console.printSuccess('Stable');
				Console.printStatement('Average semi-major error: ${exp.semiMajorErrorAverageAbs}');
				printBasicSummary(exp);
			}else{
				Console.printFatalConcern('System unstable at time ${exp.time} ${units.time}');
				dt *= 0.75;
			}

			Console.newLine();
		}

		visualize(exp);
	}

	function visualize(exp:Experiment){
		for (b in exp.simulator.bodies)renderer.addBody(b, 0.5, 0xFFFFFF);
		renderer.preRenderCallback = inline function() exp.simulator.step();	
		renderer.startAutoRender();
	}

	/* --- Planetary System Schemes --- */
	function addSolarSystem(exp:Experiment){
		var sun:Body = exp.addBody(SolarBodyData.sun);

		//var mercury = exp.addBody(SolarBodyData.mercury);
		//var venus = exp.addBody(SolarBodyData.venus);
		var earth = exp.addBody(SolarBodyData.earth);
		var mars = exp.addBody(SolarBodyData.mars);
		
		var jupiter = exp.addBody(SolarBodyData.jupiter);
		var saturn = exp.addBody(SolarBodyData.saturn);
		var uranus = exp.addBody(SolarBodyData.uranus);
		var neptune = exp.addBody(SolarBodyData.neptune);
	}

	function addTwoBodyEccentricOrbit(exp:Experiment){
		var sunData:BodyDatum = {
			name: "Sun",
			position: {x:0, y:0, z:0},
			velocity: {x:0, y:0, z:0},
			mass: 1.988544E30,
		};
		var planetData:BodyDatum = {
			name: "Test Planet (Earth-like)",
			position: {x:1.5, y:0, z:0},
			velocity: {x:0, y:0, z:0.008},
			mass: 5.97219E28,
		};
		
		var sun = exp.addBody(sunData); 
		var planet = exp.addBody(planetData);
		sun.v.z = -planet.v.z*planet.m/sun.m;
	}

	/* --- Logging --- */
	inline function printProgress(exp:Experiment){
		var progress = 100*(exp.time-exp.timeStart)/exp.timescale;
		Console.print('\r$progress%          ', false);
	}

	inline function printBasicSummary(exp:Experiment){
		Console.printStatement('CPU Time: ${exp.totalCPUTime} s, Iterations: ${exp.totalIterations}');
	}
/*	inline function experimentSummaryLog(r:ExperimentResults){
		var millionIterationTime = 1000*1000*(r.cpuTime/r.totalIterations);

		var sumE:Float = 0;
		for(e in r.analysis["Energy Error"]) sumE+=e;

		var avgE = sumE/r.analysis["Energy Error"].length;
		Console.printTitle("Average energy error: "+avgE);

		Console.print("Total Iterations: "+r.totalIterations+" | CPU Time: "+r.cpuTime+" s  |  1M Iteration: "+millionIterationTime+" s");
		Console.newLine();
	}*/

	inline function secondsToMM_SS(seconds:Float){
		var minutes = seconds/60;
		var minuteSeconds = (minutes - Math.floor(minutes))*60;

		//var hours = minutes/60;
		//var hourMinute = (hours - Math.floor(hours))*60;

		var timeStr = (minutes < 9.5 ? '0' : '')+Math.round(minutes)+':'+(minuteSeconds < 9.5 ? '0' : '')+Math.round(minuteSeconds)+' s';
		return timeStr;
	}

	/* --- File Output --- */
	function saveExperiment(e:Experiment, filePrefix:String = ""){
		var params = e.params;
		var results = e.results;

		//Construct object to save
		//params.json
		var fileSaveData = {
			metadata:{
				date: Build.date(),
				git: Git.lastCommit(),
				gitHash: Git.lastCommitHash(),
				units: units,
			},
			params: params,
			results: {
				totalIterations: results.totalIterations,
				cpuTime: results.cpuTime,
			},
		}

		//data.csv
		var csv:sysUtils.HackyCSV = new sysUtils.HackyCSV();
		for(key in results.analysis.keys()){
			csv.addColumn(results.analysis.get(key), key);
		}
		/*for( fieldName in Reflect.fields(results.analysis) ){
			csv.addColumn(Reflect.field(results.analysis, fieldName), fieldName+" ("+filePrefix+")");
		}*/

		filePrefix = (new haxe.io.Path(filePrefix)).file;//parse filePrefix to make it safe for paths
		if(filePrefix!="")filePrefix+=" - ";

		var parsedAlgorithmName = (new haxe.io.Path(params.algorithmName)).file;
		var namespace = filePrefix+Math.round(params.timescale/365)+" years, "+params.bodies.length+" bodies";
		var path = haxe.io.Path.join([dataOutDirectory, parsedAlgorithmName, namespace]);

		try{

			//save file
			FileTools.save(haxe.io.Path.join([path, "params.json"]), haxe.Json.stringify(fileSaveData), function (dir:String){
				return true;//return Console.askYesNoQuestion("Directory '"+dir+"' doesn't exist, create it?", null, false);
			}, false);
			FileTools.save(haxe.io.Path.join([path, "data - "+(csv.rowCount-1)+" rows.csv"]), csv.toString(), function (dir:String){
				return true;//return Console.askYesNoQuestion("Directory '"+dir+"' doesn't exist, create it?", null, false);
			}, false);

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

	static function main() new Main();
}