package;

import geom.Vec3;
import simulator.Body;
import simulator.NBodySimulator;
import SolarBodyData.BodyDatum;

import renderer.BasicRenderer;

class Main {

	var renderer:BasicRenderer;
	var simulator:NBodySimulator;

	public function new () {
		simulator = new NBodySimulator();
		renderer = new BasicRenderer();

		//currently using length: AU 	time: days 		mass: kg
		var rCV = 0.0000006; //radiusConversionFactor

		var sun = addBodyFromDatum(SolarBodyData.sun, 15, 0xFFA21F);
		var earth = addBodyFromDatum(SolarBodyData.earth, SolarBodyData.earth.radius*rCV, 0xBB1111);

		var jupiter = addBodyFromDatum(SolarBodyData.jupiter, SolarBodyData.jupiter.radius*rCV, 0xBB1111);
		var saturn = addBodyFromDatum(SolarBodyData.saturn, SolarBodyData.saturn.radius*rCV, 0xFFE26E);
		var uranus = addBodyFromDatum(SolarBodyData.uranus, SolarBodyData.uranus.radius*rCV, 0xA7D6DC);
		var neptune = addBodyFromDatum(SolarBodyData.neptune, SolarBodyData.neptune.radius*rCV, 0x2A45FD);

		//run simulation
		//1 day = 86400 seconds
		/*var dt = 1/24;
		var time:Float = 0;
		var endTime = 1000;
		var i:Int = 0;
		while(time<=endTime){
			simulator.step(dt);
			if(i%100 == 0)trace(simulator.computeTotalEnergy());

			time+=dt;
			i++;
		}*/

		var stepTimer:haxe.Timer = new haxe.Timer(10);
		stepTimer.run = function():Void{
			simulator.step(1);
			renderer.render();
		};
	}

	function addBodyFromDatum(bd:BodyDatum, displayRadius:Float = 10, displayColor:Int = 0xFF0000):Body{
		var b = addBodyToSimulation(bd);
		renderer.addBody(b, displayRadius, displayColor);
		return b;
	}

	inline function addBodyToSimulation(bd:BodyDatum){
		return simulator.addBody(new Body(bd.position, bd.velocity, bd.mass));
	}
}