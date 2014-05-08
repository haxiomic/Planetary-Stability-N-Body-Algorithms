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
		renderer = new BasicRenderer(170);

		integratorBenchmarkTest();
		//pertubationTest();
	}

	/* --- Tests --- */
	function integratorBenchmarkTest(){
		var name = "Integrator Benchmark";
		var dt = 1;
		var timescale = 20000;

		Console.printTitle(name, false);
		Console.newLine();

		saveInfo({
			name:name,
			dt: dt,
			timescale: timescale,
			units: units,
			buildDate: Build.date(),
			git: Git.lastCommit(),
			gitHash: Git.lastCommitHash(),
		}, 'info.json', name, true);

		var exp = new Experiment(simulator.Hermite4thOrder, [G, dt]);
		exp.timescale = timescale;
		exp.analysisTimeInterval = 0;
		exp.runtimeCallbackTimeInterval = 3;

		Console.printInfo(exp.name, false);
		Console.newLine();

		var sun = exp.addBody(SolarBodyData.sun);
		var planet = exp.addBody({
			name: 'planet',
			position: new Vec3(2, 0, 0),
			velocity: new Vec3(0, 0, 0.004),
			mass: SolarBodyData.earth.mass
		});
		exp.zeroDift();

		var pointsX = new Array<Dynamic>();pointsX.push('${exp.name}_x');
		var pointsY = new Array<Dynamic>();pointsY.push('${exp.name}_y');
		exp.runtimeCallback = function(exp){
			//trace(exp.eccentricityArray);
			renderer.render();
			pointsX.push(planet.x*.5);
			pointsY.push(-planet.z*.5);
			printProgressAndTimeRemaining;
		}

		//drawing
		renderer.reset();
		renderer.addBody(sun, 0.5);
		renderer.addBody(planet, 0.5);
		renderer.centerBody = exp.simulator.bodies[0];

		var isStable = exp.performStabilityTest(null, false);
		if(!isStable)Console.printError("Orbit not stable");


		saveGridData([pointsX, pointsY], '${exp.name}_xyz', name, true);
		exit();
		//
		//realtime draw
/*		renderer.reset();
		renderer.centerBody = exp.simulator.bodies[0];
		visualize(exp);*/
	}

	function pertubationTest(){
		//Main parameters
		var name = "Perturbation Stability Map";
		var dt:Float        = 96;
		var timescale:Float = 1E6*365.0;
		var ri:Float        = 10000;//AU, suitably distant starting point so as not to significantly interact with system
		var testCount:Int   = 10;
		var semiMajorErrorThreshold:Null<Float> = 1;//1 = factor 2 change

		/* DEBUG PARAMS */

		//Build perturbation stability map
		//iterate over range of closest approaches and initial velocities 
		var d:Float, v_kms:Float;
		//AU
		var dStart:Float = 0;
		var dStep:Float  = 100;
		var dEnd:Float   = 1000;

		//km/s
		var vStart:Float = 0;
		var vStep:Float  = 0.2;
		var vEnd:Float   = 5;

		//Print Info
		Console.printTitle(name, false);
		Console.printConcern('Timescale: ${timescale/365} years, dt: $dt ${units.time}, semi-major error threshold: $semiMajorErrorThreshold');
		Console.newLine();

		//Save info
		saveInfo({
			name:name,
			dt: dt,
			timescale: timescale,
			ri: ri,
			testCount: testCount,
			semiMajorErrorThreshold: semiMajorErrorThreshold,
			dStart: dStart,
			dStep: dStep,
			dEnd: dEnd,
			vStart: vStart,
			vStep: vStep,
			vEnd: vEnd,
			units: units,
			buildDate: Build.date(),
			git: Git.lastCommit(),
			gitHash: Git.lastCommitHash(),
		}, 'info.json', name, true);

		//d x v
		var coordinateData = new Array<Array<String>>();
		var stableFractionData = new Array<Array<Float>>();
		var semiMajorErrorData = new Array<Array<Float>>();

		//command line arguments
		if(Sys.args().length>=1) 
			dStart = Std.parseFloat( Sys.args()[0] );
		//collect data
		d = dStart;
		var col:Int = 0, row:Int = 0;
		while(d<=dEnd+dStep*.5){
			//Create columns
			var coordinateColumn = new Array<String>();
			var stableFractionColumn = new Array<Float>();
			var semiMajorErrorColumn = new Array<Float>();

			v_kms = vStart;
			row = 0;
			while(v_kms<=vEnd+vStep*.5){
				var result = testPerturbationStability(d, v_kms, 0.5*SolarBodyData.sun.mass, dt, timescale, semiMajorErrorThreshold, testCount, ri);

				var stableFraction = result[0];
				var averageSemiMajorError = result[1];

				coordinateColumn[row] = '$d AU, $v_kms km/s';
				stableFractionColumn[row] = stableFraction;
				semiMajorErrorColumn[row] = averageSemiMajorError;

				Console.printInfo('Stable fraction: ${stableFraction}, semi-major error: ${averageSemiMajorError}');

				//save partial data
				coordinateData[col] = coordinateColumn;
				stableFractionData[col] = stableFractionColumn;
				semiMajorErrorData[col] = semiMajorErrorColumn;
				saveGridData(coordinateData, 'part.coordinate.$dStart,$vStart.csv', name, true);
				saveGridData(stableFractionData, 'part.stableFraction.$dStart,$vStart.csv', name, true);
				saveGridData(semiMajorErrorData, 'part.semiMajorError.$dStart,$vStart.csv', name, true);

				v_kms+=vStep;
				row++;
			}

			coordinateData[col] = coordinateColumn;
			stableFractionData[col] = stableFractionColumn;
			semiMajorErrorData[col] = semiMajorErrorColumn;

			d+=dStep;
			col++;
		}

		//Save data
		saveGridData(coordinateData, 'coordinate.csv', name);
		saveGridData(stableFractionData, 'stableFraction.csv', name);
		saveGridData(semiMajorErrorData, 'semiMajorError.csv', name);
	}

	function testPerturbationStability(d:Float, v_kms:Float, mass:Float, dt:Float, timescale:Float, semiMajorErrorThreshold:Null<Float>, testCount:Int, ri:Float = 10000):Array<Float>{
		Console.printConcern('Target closest approach: $d AU, velocity: $v_kms km/s');

		var exp:Experiment;
		var v:Float = v_kms*Constants.secondsInDay/(Constants.AU/1000);//AU/day
		var f = Math.sqrt(ri*ri + d*d);
		//estimate how long it'll take star to reach its target unperturbed
		Console.printStatement('The star should take ~ ${Math.round((f/v)/365.0)} years to reach closest approach');

		var averageSemiMajorError:Float = 0;
		var stableFraction:Float = 0;
		var stableCount = 0;
		var testN = 0;

		while(testN < testCount){
			exp = new Experiment(Leapfrog, [G, dt]);
			exp.timescale = timescale;
			exp.analysisTimeInterval = 5000*365;
			exp.runtimeCallbackTimeInterval = 1*365;

			//Add solar system
			var sun = exp.addBody(SolarBodyData.sun);
			//var mercury = exp.addBody(SolarBodyData.mercury);
			//var venus = exp.addBody(SolarBodyData.venus);
			var earth = exp.addBody(SolarBodyData.earth);
			var mars = exp.addBody(SolarBodyData.mars);
			var jupiter = exp.addBody(SolarBodyData.jupiter);
			var saturn = exp.addBody(SolarBodyData.saturn);
			var uranus = exp.addBody(SolarBodyData.uranus);
			var neptune = exp.addBody(SolarBodyData.neptune);
		
			exp.zeroDift();//counter drift

			//Add perturbing star
			//pick a random point on sphere of radius d, closet approach, http://mathworld.wolfram.com/SpherePointPicking.html
			var theta = Math.random()*2*Math.PI;
			var phi = Math.acos(2*Math.random()-1);
			var D = new Vec3(d*Math.cos(theta)*Math.sin(phi),
							 d*Math.sin(theta)*Math.sin(phi),
							 d*Math.cos(phi));
			D += sun.p;
			//find vector perpendicular to D to project forward with
			var perp_D = new Vec3(Math.cos(theta)*Math.sin(phi+Math.PI*.5),
							 	  Math.sin(theta)*Math.sin(phi+Math.PI*.5),
							      Math.cos(phi+Math.PI*.5));
			//find starting position of star by projecting forward
			var P = D.clone();
			P.addProduct(perp_D, f);
			//set velocity to point towards D, along perp_D
			var V = perp_D.clone();
			V *= -1*v;

			//add star to experiment
			var nearbyStar = exp.addBody({
				name: 'nearbyStar',
				position: P,	//AU	
				velocity: V,
				mass: mass
			});
			exp.ignoredBodies.push(nearbyStar);

			//runtime logic
			var firstApproachCompleted:Bool = false;
			var last_r:Float = Vec3.distance(nearbyStar.p, sun.p);
			exp.runtimeCallback = function(exp){
				//wait until the star has passed the sun at its closest point before starting timescale
				if(!firstApproachCompleted){				
					//calculate distance to sun
					var r = Vec3.distance(nearbyStar.p, sun.p);
					// trace('$r, $last_r');
					if(r>last_r){//receding
						exp.timeEnd = exp.time+timescale;//extend time another timescale
						exp.runtimeCallbackTimeInterval = 10000*365;//reduce callback interval
						Console.newLine();
						Console.printStatement('First approach completed, r: ${Math.round(r)} AU, time: ${Math.round(exp.time/365.0)} years, end time: ${Math.round(exp.timeEnd/365.0)} years');
						firstApproachCompleted = true;
					}
					last_r = r;
				}

				printProgressAndTimeRemaining(exp);
			}
			
			//execute
			var isStable = exp.performStabilityTest(semiMajorErrorThreshold);

			//handle result
			Console.newLine();
			if(isStable){
				Console.printSuccess('Stable');
				Console.printStatement('Average semi-major error: ${exp.semiMajorErrorAverageAbs}');
				printBasicSummary(exp);
			}else 
				Console.printFatalConcern('System unstable at time ${exp.time/365} years');

			Console.newLine();

			//progress test loop
			testN++;
			if(isStable)stableCount++;
			averageSemiMajorError += exp.semiMajorErrorAverageAbs/testCount;
		}

		stableFraction = stableCount/testCount;

		//Debug visualization
		//center on sun
		//renderer.centerBody = exp.simulator.bodies[0];
		//visualize(exp);

		return [stableFraction, averageSemiMajorError];
	}

	/* --- Planetary System Schemes --- */
	function addSolarSystem(exp:Experiment){
		var sun = exp.addBody(SolarBodyData.sun);

		//var mercury = exp.addBody(SolarBodyData.mercury);
		//var venus = exp.addBody(SolarBodyData.venus);
		//var earth = exp.addBody(SolarBodyData.earth);
		//var mars = exp.addBody(SolarBodyData.mars);
		
		var jupiter = exp.addBody(SolarBodyData.jupiter);
		var saturn = exp.addBody(SolarBodyData.saturn);
		var uranus = exp.addBody(SolarBodyData.uranus);
		var neptune = exp.addBody(SolarBodyData.neptune);
	}

	function visualize(exp:Experiment, iterations:Int = 1){
		for (b in exp.simulator.bodies)renderer.addBody(b, 0.5, 0xFFFFFF);
		renderer.preRenderCallback = inline function() {
			for (i in 0...iterations)
				exp.simulator.step();	
		}
		renderer.startAutoRender();
	}

	/* --- Logging --- */
	inline function printProgress(exp:Experiment){
		var progress = 100*(exp.time-exp.timeStart)/exp.timescale;
		Console.print('\r$progress%          ', false);
	}

	inline function printProgressAndTimeRemaining(exp:Experiment){
		//eta
		var runtime = Sys.cpuTime() - exp.algorithmStartTime;
		var fractionComplete = (exp.time-exp.timeStart)/(exp.timeEnd - exp.timeStart);
		var totalRequiredTime = runtime/fractionComplete;
		var secondsRemaining = totalRequiredTime - runtime;

		var timeStr = secondsToMM_SS(secondsRemaining);
		var percent = Math.round(fractionComplete*100*100)/100;
		Console.print('\r$percent %\tTime Remaining: $timeStr        ', false);
	}

	inline function printBasicSummary(exp:Experiment){
		Console.printStatement('CPU Time: ${exp.totalCPUTime} s');
	}

	inline function secondsToMM_SS(seconds:Float){
		var minutes = seconds/60;
		var minuteSeconds = (minutes - Math.floor(minutes))*60;

		//var hours = minutes/60;
		//var hourMinute = (hours - Math.floor(hours))*60;

		var timeStr = (minutes < 9.5 ? '0' : '')+Math.round(minutes)+':'+(minuteSeconds < 9.5 ? '0' : '')+Math.round(minuteSeconds)+' s';
		return timeStr;
	}

	/* --- File Output --- */
	function saveGridData(columns:Array<Array<Dynamic>>, filename:String, folderName:String = null, overwrite:Bool = false){
		var csv = new HackyCSV(',', 0);
		for (i in 0...columns.length)csv.addColumn(columns[i]);

		var path = makePath(filename, folderName);
		FileTools.save(path, csv.toString(), true , overwrite);
	}

	function saveInfo(info:Dynamic, filename:String, folderName:String, overwrite:Bool = false){
		var path = makePath(filename, folderName);
		FileTools.save(path, haxe.Json.stringify(info), true , overwrite);
	}

	function makePath(filename:String, folderName:String = null){
		var path = dataOutDirectory;
		if(folderName!=null)path = haxe.io.Path.join([path, '/$folderName/']);
		path = haxe.io.Path.join([path, '$filename']);
		return path;
	}

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