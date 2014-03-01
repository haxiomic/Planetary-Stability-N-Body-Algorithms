package;

import geom.Vec3;
import renderer.NBodyRenderer;
import simulator.Body;
import simulator.NBodySimulator;
import SolarBodyData.BodyDatum;

class Main {

	var renderer:NBodyRenderer;
	var simulator:NBodySimulator;

	public function new () {
		simulator = new NBodySimulator();
		renderer = new NBodyRenderer(flash.Lib.current.stage);

		//currently using length: AU
		//				  time:	  days
		//				  mass:	  kg

		//Sun
		var rCV = .000001562; //radiusConversionFactor
		makeBodyFromDatum(SolarBodyData.sun, 40, 0xFFA21F);
		makeBodyFromDatum(SolarBodyData.mercury, SolarBodyData.mercury.radius*rCV, 0xFFE26E);
		makeBodyFromDatum(SolarBodyData.venus, SolarBodyData.venus.radius*rCV, 0xB55D16);
		makeBodyFromDatum(SolarBodyData.earth, SolarBodyData.earth.radius*rCV, 0x13B3F2);
		makeBodyFromDatum(SolarBodyData.mars, SolarBodyData.mars.radius*rCV, 0xBB1111);
		//makeBodyFromDatum(SolarBodyData.jupiter, SolarBodyData.jupiter.radius*rCV, 0xBB1111);
		//makeBodyFromDatum(SolarBodyData.saturn, SolarBodyData.saturn.radius*rCV, 0xBB1111);
		//makeBodyFromDatum(SolarBodyData.uranus, SolarBodyData.uranus.radius*rCV, 0xBB1111);
		//makeBodyFromDatum(SolarBodyData.neptune, SolarBodyData.neptune.radius*rCV, 0xBB1111);

		var stepTimer:haxe.Timer = new haxe.Timer(10);
		stepTimer.run = function():Void{
			simulator.step(0.1);
		};
	}

	inline function makeBodyFromDatum(bd:BodyDatum, displayRadius:Float = 10, displayColor:Int = 0xFF0000){
		var b = simulator.addBody(new Body(bd.position, bd.velocity, bd.mass));
		renderer.addSphericalBody(b, displayRadius, displayColor);
	}

}