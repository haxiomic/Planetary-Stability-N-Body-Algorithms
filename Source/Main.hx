package;

import geom.Vec3;
import simulator.Body;
import simulator.NBodySimulator;
import SolarBodyData.BodyDatum;

import renderer.BasicRenderer;

import sysUtils.Log;

class Main {
	var renderer:BasicRenderer;
	var simulator:NBodySimulator;

	var initalEnergy:Float;
	var currentEnergy:Float;
	var lastEnergy:Float;

	public function new () {
		simulator = new NBodySimulator();
		renderer = new BasicRenderer();

		//currently using length: AU 	time: days 		mass: kg
		var rCV = 0.0000006; //radiusConversionFactor

		function addBodyFromDatum(bd:BodyDatum, displayRadius:Float = 10, displayColor:Int = 0xFF0000):Body{
			var b = simulator.addBody(new Body(bd.position, bd.velocity, bd.mass));
			renderer.addBody(b, displayRadius, displayColor);
			return b;
		}

		var sun = addBodyFromDatum(SolarBodyData.sun, 15, 0xFFA21F);
		var earth = addBodyFromDatum(SolarBodyData.earth, SolarBodyData.earth.radius*rCV, 0xBB1111);
		var jupiter = addBodyFromDatum(SolarBodyData.jupiter, SolarBodyData.jupiter.radius*rCV, 0xBB1111);
		var saturn = addBodyFromDatum(SolarBodyData.saturn, SolarBodyData.saturn.radius*rCV, 0xFFE26E);
		var uranus = addBodyFromDatum(SolarBodyData.uranus, SolarBodyData.uranus.radius*rCV, 0xA7D6DC);
		var neptune = addBodyFromDatum(SolarBodyData.neptune, SolarBodyData.neptune.radius*rCV, 0x2A45FD);

		initalEnergy = simulator.computeTotalEnergy();
		currentEnergy = initalEnergy;
		lastEnergy = currentEnergy;

		var systemStartTime:Float = timeStamp();
		//run simulation
		//1 day = 86400 seconds
		var dt = 1;
		var runtime = 1000;//years
		var outputCount = 100;

		var time:Float = 0;
		var endTime = runtime*365;//days
		var requiredItterations:Float = endTime/dt;
		var outputDivisions = Math.round(requiredItterations/outputCount);
		var i:Int = 0;
		while(time<=endTime){
			//step simulation
			simulator.step(dt);	
			time+=dt;
			i++;

			//output progress
			if(i%outputDivisions==0){
				f = updateEnergy();
				trace(100*(i/requiredItterations)+"% total energy: "+currentEnergy+" error: "+f+" itteration: "+i);
			}
		}

		var systemWallTime = timeStamp() - systemStartTime;

		trace("Walltime: "+systemWallTime+"  |  1M iterations: "+1000*1000*(systemWallTime/requiredItterations));

		if(exportData(null)){
			exit();
		}

		steadyStep();
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

	//system functions
	/* --- Config --- */
	var fileOutDirectory = "./OutputData";
	/* -------------- */

	function exportData(data:haxe.Json):Bool{
		//Pick a file out directory

		//Check if out directory exists
		if(!sys.FileSystem.exists(fileOutDirectory)){
			//create out directory
			Log.printQuestion("\nDirectory "+Sys.getCwd()+fileOutDirectory+" doesn't exist, create it?");
			var char:Int = Sys.getChar(true);
			Log.newLine();
			if(char == "y".charCodeAt(0)){
				Log.printResult("Directory created");
			}
		}

		return false;
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