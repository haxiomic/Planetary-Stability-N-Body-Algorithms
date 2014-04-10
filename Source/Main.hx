package;

import geom.Vec3;
import simulator.Body;
import simulator.NBodySimulator;
import SolarBodyData.BodyDatum;

import renderer.BasicRenderer;

import sysUtils.CompileTime;
import sysUtils.Log;
import sysUtils.FileTools;

class Main {
	var renderer:BasicRenderer;
	var simulator:NBodySimulator;

	var initalEnergy:Float;
	var currentEnergy:Float;
	var lastEnergy:Float;

	var units:Dynamic;
	var addedBoddies:Array<BodyDatum>;

	/* --- Config --- */
	var dataOutDirectory = CompileTime.buildDir()+"/Output Data/";
	/* -------------- */

	public function new () {
		simulator = new NBodySimulator();
		renderer = new BasicRenderer();

		//currently using length: AU 	time: days 		mass: kg
		units = {
			time: "days",
			length: "AU",
			mass: "kg"
		}

		setupSimulation();

		var systemStartTime:Float = timeStamp();

		var dt = 1;
		var runtime = 1;
		var iterationCount = performSimulation(dt, runtime);

		//Results
		var systemWallTime = timeStamp() - systemStartTime;
		var megaIterationTime = 1000*1000*(systemWallTime/iterationCount);

		//Handle results
		Log.newLine();
		Log.print("Walltime: "+systemWallTime+" s  |  1M iterations: "+megaIterationTime+" s");

		//Construct object to save
		var fileSaveData = {
			date: CompileTime.buildDate(),
			algorithmName: simulator.algorithmName,
			algorithmDescription: simulator.algorithmDescription,
			walltime: systemWallTime+" s",
			millionIterationTime: megaIterationTime+" s",
			iterations: iterationCount,
			boddies: addedBoddies,
			units: units,
			git: sysUtils.GitTools.lastCommit(),
		};

		//Create filename
		var filename = "dt="+dt+" "+units.time+", iterations="+iterationCount+", runtime="+runtime+" years"+".json";
		var fileDir = dataOutDirectory+"/"+simulator.algorithmName;

		try{
			saveAsJSON(fileSaveData, fileDir+"/"+filename);
		}catch(msg:String){
			Log.printError(msg);
			Log.newLine();

			Log.printTitle("Dumping data to console");
			Log.newLine();
			Log.print(haxe.Json.stringify(fileSaveData));
			Log.newLine();
		}


		Log.newLine();
		Log.printStatement("Press any key to close");
		Sys.getChar(false);
		Log.newLine();

		// exit(0);
		steadyStep();
	}

	function setupSimulation(){
		addedBoddies = new Array<BodyDatum>();
		function addBodyFromDatum(bd:BodyDatum, displayRadius:Float = 10, displayColor:Int = 0xFF0000):Body{
			var b = simulator.addBody(new Body(bd.position, bd.velocity, bd.mass));
			renderer.addBody(b, displayRadius, displayColor);

			addedBoddies.push(bd);
			return b;
		}

		var rCV = 0.0000006; //radiusConversionFactor for display
		var sun = addBodyFromDatum(SolarBodyData.sun, 15, 0xFFA21F);
		var earth = addBodyFromDatum(SolarBodyData.earth, SolarBodyData.earth.radius*rCV, 0xBB1111);
		var jupiter = addBodyFromDatum(SolarBodyData.jupiter, SolarBodyData.jupiter.radius*rCV, 0xBB1111);
		var saturn = addBodyFromDatum(SolarBodyData.saturn, SolarBodyData.saturn.radius*rCV, 0xFFE26E);
		var uranus = addBodyFromDatum(SolarBodyData.uranus, SolarBodyData.uranus.radius*rCV, 0xA7D6DC);
		var neptune = addBodyFromDatum(SolarBodyData.neptune, SolarBodyData.neptune.radius*rCV, 0x2A45FD);
	}

	@:noStack
	function performSimulation(dt:Float = 1, runtime:Float = 1):Int{
		//Compute energy
		initalEnergy = simulator.computeTotalEnergy();
		currentEnergy = initalEnergy;
		lastEnergy = currentEnergy;

		//run simulation
		//1 day = 86400 seconds
		var time:Float = 0;
		var endTime = runtime*365;//days
		var requiredIterations:Float = endTime/dt;

		var outputCount = 20;
		var outputDivisions = Math.round(requiredIterations/outputCount);

		var i:Int = 0;
		while(time<=endTime){
			//step simulation
			simulator.step(dt);	
			time+=dt;
			i++;

			//output progress
			if(i%outputDivisions==0){
				f = updateEnergy();
				Log.print(100*(i/requiredIterations)+"% total energy: "+currentEnergy+" error: "+f+" itteration: "+i);
			}
		}
		return i;
	}

	var f:Float;
	function updateEnergy():Float{
		currentEnergy = simulator.computeTotalEnergy();
		f = fractionalError();
		lastEnergy = currentEnergy;
		return Math.abs(f);
	}

	function fractionalError():Float{
		return (currentEnergy-lastEnergy)/initalEnergy;
	}

	function steadyStep(){
		var stepTimer:haxe.Timer = new haxe.Timer(10);
		stepTimer.run = function():Void{
			simulator.step(1);

			updateEnergy();

			renderer.render();
		};
	}

	/* -------------------------*/
	/* --- System Functions --- */

	static public function saveAsJSON(data:Dynamic, path:String):Bool{
		var hxPath = new haxe.io.Path(path);

		var filename = hxPath.file;
		//Assess file out directory
		var outDir = hxPath.dir;
		// outDir = haxe.io.Path.normalize(outDir);

		//Check if out directory exists
		if(!sys.FileSystem.exists(outDir)){
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

		//Check the file doesn't already exist, if it does, find a free suffix -xx
		var filePath = FileTools.findFreeFile(hxPath.toString());
		filePath = haxe.io.Path.normalize(filePath);//normalize path

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

	inline function timeStamp():Float{
		//return Sys.cpuTime()*1000;
		return haxe.Timer.stamp();
	}
}