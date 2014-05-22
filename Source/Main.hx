package;

import geom.Vec3;
import simulator.*;
import renderer.*;
import Experiment.ExperimentResults;
import Experiment.ExperimentInformation;

import sysUtils.compileTime.*;
import sysUtils.*;

class Main {
	var renderer:BasicRenderer = new BasicRenderer(2);

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
		//25 runs
		//perturbationMapTest([50, 50, 300], [10,1,10], 20, 5, "Globular Custer VEMJSUN PerturbationMapTest");
		//50 runs
		// perturbationMapTest([500, 100, 1500], [0.5,1,0.5], 20, 5, "Open Custer VEMJSUN PerturbationMapTest");
		//60 runs
		//perturbationMapTest([0, 25, 300], [30,1,30], 20, 5, "Solar Neighbourhood VEMJSUN PerturbationMapTest");

		// isolatedStabilityTest(simulator.Leapfrog, 96, 1E6*365.0, 1);

		//getAnExamplePerturbation(100, 2, 0.5*SolarBodyData.sun.mass, 20, 21987*365, 1, 1000);
		//exit();

		//integratorEnergyTest(simulator.LeapfrogAdaptive, 80, 1E6*365, )
		leapfrogAdaptiveTest();
	}

	@:noStack
	function getAnExamplePerturbation(d_au:Float, v_kms:Float, mass:Float, dt:Float, timescale:Float, semiMajorErrorThreshold:Null<Float>, ri:Float = 10000){
		var d:Float = d_au;
		var exp:Experiment;
		var v:Float = v_kms*Constants.secondsInDay/(Constants.AU/1000);//to AU/day
		var f = Math.sqrt(ri*ri + d*d);

		Console.printConcern('Target closest approach: $d AU, velocity: $v_kms km/s');
		//estimate how long it'll take star to reach its target unperturbed
		Console.printStatement('The star should take ~ ${Math.round((f/v)/365.0)} years to reach closest approach');

			exp = new Experiment(simulator.Leapfrog, [G, dt]);
			exp.timescale = timescale;
			exp.analysisTimeInterval = 5000*365;
			exp.runtimeCallbackTimeInterval = 1;

			//Add solar system
			var sun = exp.addBody(SolarBodyData.sun);
			var venus = exp.addBody(SolarBodyData.venus);
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
			var passingVelocity:Float = 0;
			var planetsAdded = false;

			var sunX = new Array<Dynamic>();//sunX.push('sunX');
			var sunY = new Array<Dynamic>();//sunY.push('sunY');
			var sunZ = new Array<Dynamic>();//sunZ.push('sunZ');
			var neighbourX = new Array<Dynamic>();//neighbourX.push('neighbourX');
			var neighbourY = new Array<Dynamic>();//neighbourY.push('neighbourY');
			var neighbourZ = new Array<Dynamic>();//neighbourZ.push('neighbourZ');
			var venusX = new Array<Dynamic>();//venusX.push('venusX');
			var venusY = new Array<Dynamic>();//venusY.push('venusY');
			var venusZ = new Array<Dynamic>();//venusZ.push('venusZ');
			var earthX = new Array<Dynamic>();//earthX.push('earthX');
			var earthY = new Array<Dynamic>();//earthY.push('earthY');
			var earthZ = new Array<Dynamic>();//earthZ.push('earthZ');
			var marsX = new Array<Dynamic>();//marsX.push('marsX');
			var marsY = new Array<Dynamic>();//marsY.push('marsY');
			var marsZ = new Array<Dynamic>();//marsZ.push('marsZ');
			var jupiterX = new Array<Dynamic>();//jupiterX.push('jupiterX');
			var jupiterY = new Array<Dynamic>();//jupiterY.push('jupiterY');
			var jupiterZ = new Array<Dynamic>();//jupiterZ.push('jupiterZ');
			var saturnX = new Array<Dynamic>();//saturnX.push('saturnX');
			var saturnY = new Array<Dynamic>();//saturnY.push('saturnY');
			var saturnZ = new Array<Dynamic>();//saturnZ.push('saturnZ');
			var uranusX = new Array<Dynamic>();//uranusX.push('uranusX');
			var uranusY = new Array<Dynamic>();//uranusY.push('uranusY');
			var uranusZ = new Array<Dynamic>();//uranusZ.push('uranusZ');
			var neptuneX = new Array<Dynamic>();//neptuneX.push('neptuneX');
			var neptuneY = new Array<Dynamic>();//neptuneY.push('neptuneY');
			var neptuneZ = new Array<Dynamic>();//neptuneZ.push('neptuneZ'); 

			var offset = sun.p;
			function pushPoints3(){
				uranusX.push(uranus.x-offset.x);
				uranusY.push(uranus.z-offset.z);
				uranusZ.push(uranus.y-offset.y);
				neptuneX.push(neptune.x-offset.x);
				neptuneY.push(neptune.z-offset.z);
				neptuneZ.push(neptune.y-offset.y);
				neighbourX.push(nearbyStar.x-offset.x);
				neighbourY.push(nearbyStar.z-offset.z);
				neighbourZ.push(nearbyStar.y-offset.y);
			}
			function pushPoints2(){
				marsX.push(mars.x-offset.x);
				marsY.push(mars.z-offset.z);
				marsZ.push(mars.y-offset.y);
				jupiterX.push(jupiter.x-offset.x);
				jupiterY.push(jupiter.z-offset.z);
				jupiterZ.push(jupiter.y-offset.y);
				saturnX.push(saturn.x-offset.x);
				saturnY.push(saturn.z-offset.z);
				saturnZ.push(saturn.y-offset.y);
				pushPoints3();
			}
			function pushPoints(){
				sunX.push(0);
				sunY.push(0);
				sunZ.push(0);
				venusX.push(venus.x-offset.x);
				venusY.push(venus.z-offset.z);
				venusZ.push(venus.y-offset.y);
				earthX.push(earth.x-offset.x);
				earthY.push(earth.z-offset.z);
				earthZ.push(earth.y-offset.y);
				pushPoints2();
			}

			exp.runtimeCallback = function(exp){
				//calculate distance to sun
				var r = Vec3.distance(nearbyStar.p, sun.p);//AU
				if(r<d_au){
					//record coordinates
					if(!planetsAdded){
						addPlanetsToRenderer(exp); 
						renderer.centerBody = exp.simulator.bodies[0];
						planetsAdded = true;
					}
				}
				if(planetsAdded)pushPoints();
				//end simulation
				if(planetsAdded && r > d_au*1.5){
					planetsAdded = false;
					exp.time = exp.timeEnd;
				}

				//wait until the star has passed the sun at its closest point before starting timescale
				if(!firstApproachCompleted){				
					// trace('$r, $last_r');
					if(r>last_r){//receding
						exp.timeEnd = exp.time+timescale;//extend time another timescale
						passingVelocity = nearbyStar.v.length()*(Constants.AU/1000)/Constants.secondsInDay; //in km/s
						Console.newLine();
						Console.printStatement('First approach completed, r: ${Math.round(r)} AU, time: ${Math.round(exp.time/365.0)} years, end time: ${Math.round(exp.timeEnd/365.0)} years, passing velocity: $passingVelocity km/s');
						firstApproachCompleted = true;
					}
					last_r = r;
				}

				printProgressAndTimeRemaining(exp);
				renderer.render();
			}
			
			//execute
			var isStable = exp.performStabilityTest(semiMajorErrorThreshold);

			//handle result
			Console.newLine();
			if(isStable){
				Console.printSuccess('Stable');
				Console.printStatement('Average semi-major error: ${exp.semiMajorErrorAverageAbs}');
				printBasicSummary(exp);
			}else{
				Console.printFatalConcern('System unstable at time ${exp.time/365} years');
			}

			Console.newLine();


		//Save data
		saveGridData([sunX, sunY, sunZ], 'sun.txt', 'Example Perturbation', true);
		saveGridData([venusX, venusY, venusZ], 'venus.txt', 'Example Perturbation', true);
		saveGridData([earthX, earthY, earthZ], 'earth.txt', 'Example Perturbation', true);
		saveGridData([marsX, marsY, marsZ], 'mars.txt', 'Example Perturbation', true);
		saveGridData([jupiterX, jupiterY, jupiterZ], 'jupiter.txt', 'Example Perturbation', true);
		saveGridData([saturnX, saturnY, saturnZ], 'saturn.txt', 'Example Perturbation', true);
		saveGridData([uranusX, uranusY, uranusZ], 'uranus.txt', 'Example Perturbation', true);
		saveGridData([neptuneX, neptuneY, neptuneZ], 'neptune.txt', 'Example Perturbation', true);
		saveGridData([neighbourX, neighbourY, neighbourZ], 'neighbour.txt', 'Example Perturbation', true);

		//Debug visualization
		//center on sun
		//renderer.reset();
		//renderer.centerBody = exp.simulator.bodies[0];
		//visualize(exp);
	}











	/* --- Tests --- */
	function cputime_errorTest(){
		var name = "CPU Time vs Energy Error";
		var timescale:Float = 1E6*365;
		var timescaleYears = Math.round(timescale/365);
		var startDt;
		var endDt;
		var stepDt;
		Console.printTitle('$timescaleYears  years');
		//Leapfrog
		var error = new Array<Dynamic>(); error.push("lf error");
		var cputime = new Array<Dynamic>(); cputime.push("lf cputime");
		var dtArray = new Array<Dynamic>(); dtArray.push("lf dtArray");
		var aArray = new Array<Dynamic>(); aArray.push("lf a");
		startDt = 5;
		endDt = 135;
		stepDt = 5;
		var dt = startDt;
		while(dt<=endDt){
			var r = cputime_errorSingleTest(simulator.Leapfrog, dt, timescale, [], name);
			error.push(r[0]);
			cputime.push(r[2]);
			dtArray.push(dt);
			aArray.push(r[3]);
			dt+=stepDt;
		}
		saveGridData([error, cputime, dtArray, aArray], 'leapfrog.$timescaleYears.csv', name, true);
		//Hermite
		var error = new Array<Dynamic>(); error.push("her error");
		var cputime = new Array<Dynamic>(); cputime.push("her cputime");
		var dtArray = new Array<Dynamic>(); dtArray.push("her dtArray");
		var aArray = new Array<Dynamic>(); aArray.push("her a");
		var dt = startDt;
		startDt = 20;
		endDt = 80;
		stepDt = 5;
		dt = startDt;
		while(dt<=endDt){
			var r = cputime_errorSingleTest(simulator.Hermite4thOrder, dt, timescale, [], name);
			error.push(r[1]);
			cputime.push(r[2]);
			dtArray.push(dt);
			aArray.push(r[3]);
			dt+=stepDt;
		}
		saveGridData([error, cputime, dtArray, aArray], 'hermite.$timescaleYears.csv', name, true);
	}

	function cputime_errorSingleTest(?simulatorClass:Class<Dynamic>, dt:Float = 20, timescale:Float = 1E6*365, ?additionalParams:Array<Dynamic>, name:String = "Cputime vs Energy Error"):Array<Dynamic>{
		if(simulatorClass==null)simulatorClass = simulator.Leapfrog;
		if(additionalParams==null)additionalParams = [];
		
		var params:Array<Dynamic> = [G, dt];
		params = params.concat(additionalParams);
		var exp = new Experiment(simulatorClass, params);
		exp.timescale = timescale;
		exp.analysisTimeInterval = timescale/1000;
		exp.runtimeCallbackTimeInterval = timescale/1000;

		Console.printInfo('${exp.name} dt = $dt', false);
		Console.newLine();

		var sun = exp.addBody(SolarBodyData.sun);
		//var mercury = exp.addBody(SolarBodyData.mercury);
		//var venus = exp.addBody(SolarBodyData.venus);
		//var earth = exp.addBody(SolarBodyData.earth);
		//var mars = exp.addBody(SolarBodyData.mars);
		var jupiter = exp.addBody(SolarBodyData.jupiter);
		var saturn = exp.addBody(SolarBodyData.saturn);
		var uranus = exp.addBody(SolarBodyData.uranus);
		var neptune = exp.addBody(SolarBodyData.neptune);
		exp.zeroDift();

		var energyChange = new Array<Dynamic>();energyChange.push('${exp.name}_energyChange');
		exp.runtimeCallback = function(exp){
			//get vars
			energyChange.push(exp.energyChange);

			printProgressAndTimeRemaining(exp);
		}
		exp.performAnalysis();

		var energyChangeAvg:Float = 0;
		for (ec in energyChange)energyChangeAvg+=ec/energyChange.length;

		Console.printStatement('Average dE: $energyChangeAvg');

		var timescaleYears = Math.round(timescale/365);

		//realtime draw
		renderer.reset();
		renderer.centerBody = exp.simulator.bodies[0];
		visualize(exp);

		return [Math.abs(energyChangeAvg), 
				Math.abs(energyChange[energyChange.length-1]), 
				exp.totalCPUTime, 
				Math.abs(exp.semiMajorErrorArray[exp.semiMajorErrorArray.length-1]),
				exp.semiMajorErrorAverageAbs];
	}

	function multiLevelMapTest(){
		var dt:Float = 30;
		var testCount:Int = 5;

		function conditions(start:Float, delta:Float, samples)
			return [start, delta/(samples-1), start+delta];
		function nextConditions(delta:Float, nextSamples:Int, prevEnd:Float, prevDelta:Float, prevSamples:Int):Array<Float>{
			var prevStep = prevDelta/(prevSamples-1);
			var nextStep = prevStep*(prevSamples)/(nextSamples);
			var nextStart = prevEnd + 0.5*prevStep + 0.5*nextStep;
			var nextEnd = nextStart+nextStep*(nextSamples-1);
			return [nextStart, nextStep, nextEnd];
		}

		var name:String;
		name='bottom-left 4x4';
		//perturbationMapTest(conditions(0, 1000, 4), conditions(0,5,4), dt, testCount, 'VEMJSUN Stability Map $name');

		name='top-right 2x2';
		//perturbationMapTest(nextConditions(1000, 2, 1000, 1000, 4), nextConditions(5, 2, 5, 5, 4), dt, testCount, 'VEMJSUN Stability Map $name');

		//Buggy:
		name='top-left 2x2';
		//perturbationMapTest(nextConditions(1000, 2, -(1000/(4-1)), 1000, 4), nextConditions(5, 2, 5, 5, 4), dt, testCount, 'VEMJSUN Stability Map $name');

		name='bottom-right 2x2';
		perturbationMapTest(nextConditions(1000, 2, 1000, 1000, 4), nextConditions(5, 2, -5/(4-1), 5, 4), dt, testCount, 'VEMJSUN Stability Map $name');
	}

	function taylor1VsSemiEulerEnergyTest(){
		var name = "Low Order Energy Conservation";
		var dt = 11;
		var timescale = 1E4*365;

		var integrators:Array<Class<Dynamic>> = [Taylor2ndDerivative, SemiImplicitEulerMethod];
		for (i in integrators)	integratorEnergyTest(i, dt, timescale, null, name);
	}

	function higherOrderEnergyTest(){
		var name = "High Order Energy Conservation";
		var dt = 11;
		var timescale = 1E4*365;

		var integrators:Array<Class<Dynamic>> = [simulator.SemiImplicitEulerMethod, Leapfrog, Hermite4thOrder];
		for (i in integrators)	integratorEnergyTest(i, dt, timescale, null, name);
		integratorEnergyTest(LeapfrogAdaptive, 5, timescale, [0.04], name);
	}

	function leapfrogAdaptiveTest(){
		var name = "Leapfrog vs LeapfrogAdaptive";
		var timescale:Float;
		timescale = 1E6*365;
		integratorEnergyTest(Leapfrog, 80, timescale, null, name);
		integratorEnergyTest(LeapfrogAdaptive, 100, timescale, [0.03], name);
	}

	function integratorEnergyTest(?simulatorClass:Class<Dynamic>, dt:Float = 20, timescale:Float = 1E6*365, ?additionalParams:Array<Dynamic>, name:String = "Integrator Energy Conservation"){
		if(simulatorClass==null)simulatorClass = simulator.Leapfrog;
		if(additionalParams==null)additionalParams = [];

		Console.printTitle(name, false);
		Console.newLine();
		
		var params:Array<Dynamic> = [G, dt];
		params = params.concat(additionalParams);
		var exp = new Experiment(simulatorClass, params);
		exp.timescale = timescale;
		exp.analysisTimeInterval = timescale/2000;
		exp.runtimeCallbackTimeInterval = timescale/2000;

		Console.printInfo(exp.name, false);
		Console.newLine();

		var sun = exp.addBody(SolarBodyData.sun);
		//var mercury = exp.addBody(SolarBodyData.mercury);
		//var venus = exp.addBody(SolarBodyData.venus);
		//var earth = exp.addBody(SolarBodyData.earth);
		//var mars = exp.addBody(SolarBodyData.mars);
		var jupiter = exp.addBody(SolarBodyData.jupiter);
		var saturn = exp.addBody(SolarBodyData.saturn);
		var uranus = exp.addBody(SolarBodyData.uranus);
		var neptune = exp.addBody(SolarBodyData.neptune);
		exp.zeroDift();

		var time = new Array<Dynamic>();time.push('${exp.name}_time');
		var energyChange = new Array<Dynamic>();energyChange.push('${exp.name}_energyChange');
		exp.runtimeCallback = function(exp){
			//get vars
			time.push(exp.simulator.time);
			energyChange.push(Math.abs(exp.energyChange));
			printProgressAndTimeRemaining(exp);
		}

		exp.performAnalysis();

		var energyChangeAvg:Float = 0;
		for (ec in energyChange)energyChangeAvg+=ec/energyChange.length;
		Console.printStatement('Average dE: $energyChangeAvg');

		var timescaleYears = Math.round(timescale/365);
		saveInfo({
			name:name,
			dt: dt,
			timescale: '$timescaleYears years',
			units: units,
			buildDate: Build.date(),
			git: Git.lastCommit(),
			gitHash: Git.lastCommitHash(),
			cpuTime: exp.totalCPUTime,
			additionalParams: additionalParams,
			energyChangeAvg: energyChangeAvg,
			integrator: exp.simulator.algorithmName,
		}, 'Info-${exp.name}.$timescaleYears.json', name, true);

		saveGridData([time, energyChange], '${exp.name}.$timescaleYears.csv', name, true);

		//realtime draw
		renderer.reset();
		renderer.centerBody = exp.simulator.bodies[0];
		visualize(exp);
	}

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

		var exp = new Experiment(simulator.Leapfrog, [G, dt]);
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

		saveGridData([pointsX, pointsY], '${exp.name}_xyz.csv', name, true);
		exit();
		//
		//realtime draw
/*		renderer.reset();
		renderer.centerBody = exp.simulator.bodies[0];
		visualize(exp);*/
	}

	function benchmarkEnergyConservationTest(?simulatorClass:Class<Dynamic>){
		if(simulatorClass==null)simulatorClass = simulator.Leapfrog;
		var name = "Benchmark Energy Conservation";
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

		var exp = new Experiment(simulatorClass, [G, dt/8, 0.02]);
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

		var time = new Array<Dynamic>();time.push('${exp.name} time');
		var energyChange = new Array<Dynamic>();energyChange.push('${exp.name} error');
		exp.runtimeCallback = function(exp){
			//trace(exp.eccentricityArray);
			renderer.render();
			time.push(exp.time);
			energyChange.push(Math.abs(exp.energyChange));
			printProgressAndTimeRemaining;
		}

		exp.performAnalysis();
		saveGridData([time, energyChange], '${exp.name}_energyChange.csv', name, true);
		//
		//realtime draw
		//drawing
		renderer.reset();
		renderer.addBody(sun, 0.5);
		renderer.addBody(planet, 0.5);
		renderer.reset();
		renderer.centerBody = exp.simulator.bodies[0];
		visualize(exp);
	}

	function singleDVTest(d, v, dt:Float = 30, testCount:Int = 5, name = "VEMJSUN Perturbation Stability Single"){
		var timescale:Float = 1E6*365.0;
		var ri:Float        = 10000;//AU, suitably distant starting point so as not to significantly interact with system
		var semiMajorErrorThreshold:Null<Float> = 1;//1 = factor 2 change

		var results = perturbationStabilityTest(d, v, SolarBodyData.sun.mass*.5, dt, timescale, semiMajorErrorThreshold, testCount);
		saveInfo({
			name:name,
			dt: dt,
			timescale: timescale,
			ri: ri,
			testCount: testCount,
			semiMajorErrorThreshold: semiMajorErrorThreshold,
			d: d,
			v: v,
			stableFraction: results[0],
			averageSemiMajorError: results[1],
			passingVelocity: results[2]+' km/s',
			instabilityAfterTime: results[3]/365+' years',
		}, '$d,$v-dt=$dt, x$testCount.json', name, true);
	}

	function perturbationMapTest(dConditions:Array<Float>, vConditions:Array<Float>, dt:Float = 96, testCount:Int = 10, name:String = "Perturbation Stability Map"){
		//Main parameters
		var timescale:Float = 1E6*365.0;
		var ri:Float        = 10000;//AU, suitably distant starting point so as not to significantly interact with system
		var semiMajorErrorThreshold:Null<Float> = 1;//1 = factor 2 change
		var neighborStarMass:Float = 0.5*SolarBodyData.sun.mass;

		//Build perturbation stability map
		//iterate over range of closest approaches and initial velocities 
		var d:Float, v_kms:Float;
		//AU
		var dStart:Float = dConditions[0];
		var dStep:Float  = dConditions[1];
		var dEnd:Float   = dConditions[2];

		//km/s
		var vStart:Float = vConditions[0];
		var vStep:Float  = vConditions[1];
		var vEnd:Float   = vConditions[2];

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
				var result = perturbationStabilityTest(d, v_kms, neighborStarMass, dt, timescale, semiMajorErrorThreshold, testCount, ri);

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
		saveGridData(coordinateData, 'coordinate.csv', name, false);
		saveGridData(stableFractionData, 'stableFraction.csv', name, false);
		saveGridData(semiMajorErrorData, 'semiMajorError.csv', name, false);
	}

	function perturbationStabilityTest(d_au:Float, v_kms:Float, mass:Float, dt:Float, timescale:Float, semiMajorErrorThreshold:Null<Float>, testCount:Int, ri:Float = 10000):Array<Float>{
		var d:Float = d_au;
		var exp:Experiment;
		var v:Float = v_kms*Constants.secondsInDay/(Constants.AU/1000);//to AU/day
		var f = Math.sqrt(ri*ri + d*d);

		Console.printConcern('Target closest approach: $d AU, velocity: $v_kms km/s');
		//estimate how long it'll take star to reach its target unperturbed
		Console.printStatement('The star should take ~ ${Math.round((f/v)/365.0)} years to reach closest approach');

		var stableFraction:Float          = 0;
		var semiMajorErrorAvg:Float       = 0;
		var passingVelocityAvg:Float      = 0;
		var instabilityAfterTimeAvg:Float = 0;
		var instabilityAfterTimeSum:Float = 0;

		var stableCount = 0;
		var testN = 0;
		while(testN < testCount){
			exp = new Experiment(simulator.Leapfrog, [G, dt]);
			exp.timescale = timescale;
			exp.analysisTimeInterval = 5000*365;
			exp.runtimeCallbackTimeInterval = 1*365;

			//Add solar system
			var sun = exp.addBody(SolarBodyData.sun);
			//var mercury = exp.addBody(SolarBodyData.mercury);
			var venus = exp.addBody(SolarBodyData.venus);
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
			var passingVelocity:Float = 0;
			exp.runtimeCallback = function(exp){
				//wait until the star has passed the sun at its closest point before starting timescale
				if(!firstApproachCompleted){				
					//calculate distance to sun
					var r = Vec3.distance(nearbyStar.p, sun.p);
					// trace('$r, $last_r');
					if(r>last_r){//receding
						exp.timeEnd = exp.time+timescale;//extend time another timescale
						exp.runtimeCallbackTimeInterval = 10000*365;//reduce callback interval
						passingVelocity = nearbyStar.v.length()*(Constants.AU/1000)/Constants.secondsInDay; //in km/s
						Console.newLine();
						Console.printStatement('First approach completed, r: ${Math.round(r)} AU, time: ${Math.round(exp.time/365.0)} years, end time: ${Math.round(exp.timeEnd/365.0)} years, passing velocity: $passingVelocity km/s');
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
				stableCount++;
				Console.printSuccess('Stable');
				Console.printStatement('Average semi-major error: ${exp.semiMajorErrorAverageAbs}');
				printBasicSummary(exp);
			}else{
				instabilityAfterTimeSum += exp.time;
				Console.printFatalConcern('System unstable at time ${exp.time/365} years');
			}

			Console.newLine();

			//progress test loop
			testN++;
			semiMajorErrorAvg += exp.semiMajorErrorAverageAbs/testCount;
			passingVelocityAvg += passingVelocity/testCount;
		}

		stableFraction = stableCount/testCount;

		instabilityAfterTimeAvg = instabilityAfterTimeSum/(testCount - stableCount);
		//Debug visualization
		//center on sun
		renderer.centerBody = exp.simulator.bodies[0];
		visualize(exp);

		return [stableFraction, semiMajorErrorAvg, passingVelocityAvg, instabilityAfterTimeAvg];
	}

	function isolatedStabilityTest(simulatorClass:Class<Dynamic>, dt:Float, timescale:Float, semiMajorErrorThreshold:Null<Float>, ?additionalParams:Array<Dynamic>){
		if(additionalParams==null)additionalParams = [];

		var name = "Isolated Stability";

		Console.printTitle(name, false);
		Console.newLine();

		var params:Array<Dynamic> = [G, dt];
		params = params.concat(additionalParams);
		var exp = new Experiment(simulatorClass, params);
		exp.timescale = timescale;
		exp.analysisTimeInterval = 5000*365;
		exp.runtimeCallbackTimeInterval = timescale/200;

		Console.printInfo(exp.name, false);
		Console.newLine();

		//Add solar system
		var sun = exp.addBody(SolarBodyData.sun);
		//var mercury = exp.addBody(SolarBodyData.mercury);
		//var venus = exp.addBody(SolarBodyData.venus);
		//var earth = exp.addBody(SolarBodyData.earth);
		//var mars = exp.addBody(SolarBodyData.mars);
		var jupiter = exp.addBody(SolarBodyData.jupiter);
		var saturn = exp.addBody(SolarBodyData.saturn);
		var uranus = exp.addBody(SolarBodyData.uranus);
		var neptune = exp.addBody(SolarBodyData.neptune);
		exp.zeroDift();

		exp.runtimeCallback = function(exp){
		//	trace(exp.eccentricityArray);
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

		var timescaleYears = Math.round(timescale/365);
		saveInfo({
			name:name,
			dt: dt,
			timescale: timescale,
			units: units,
			buildDate: Build.date(),
			git: Git.lastCommit(),
			gitHash: Git.lastCommitHash(),
			cpuTime: exp.totalCPUTime,
			semiMajorErrorAvg: exp.semiMajorErrorAverageAbs,
			integrator: exp.simulator.algorithmName,
			additionalParams: additionalParams,
		}, 'Info-${exp.name}.$timescaleYears.json', name, false);

		//Debug visualization
		//center on sun
		renderer.centerBody = exp.simulator.bodies[0];
		visualize(exp);
	}

	/* --- Planetary System Schemes --- */
	/*function addSolarSystem(exp:Experiment){
		var sun = exp.addBody(SolarBodyData.sun);

		//var mercury = exp.addBody(SolarBodyData.mercury);
		//var venus = exp.addBody(SolarBodyData.venus);
		//var earth = exp.addBody(SolarBodyData.earth);
		//var mars = exp.addBody(SolarBodyData.mars);
		
		var jupiter = exp.addBody(SolarBodyData.jupiter);
		var saturn = exp.addBody(SolarBodyData.saturn);
		var uranus = exp.addBody(SolarBodyData.uranus);
		var neptune = exp.addBody(SolarBodyData.neptune);
	}*/

	function addPlanetsToRenderer(exp:Experiment)
		for (b in exp.simulator.bodies)renderer.addBody(b, 0.5, 0xFFFFFF);
	
	function visualize(exp:Experiment, iterations:Int = 1){
		addPlanetsToRenderer(exp);
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
	function saveString(string:String ,filename:String, folderName:String, overwrite:Bool = false){
		var path = makePath(filename, folderName);
		FileTools.save(path, string, true , overwrite);
	}

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