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


		//currently using length: AU 	time: days 		mass: kg
		var rCV = .000001; //radiusConversionFactor
		addBodyFromDatum(SolarBodyData.sun, 20, 0xFFA21F);
		var merucy = addBodyFromDatum(SolarBodyData.mercury, SolarBodyData.mercury.radius*rCV, 0xFFE26E);
		renderer.addTrail(merucy, 22, 2, 0xFFE26E, 4);
		//renderer.addTrail(merucy, 2000, 1, 0xFFE26E, 4);
		
		var venus = addBodyFromDatum(SolarBodyData.venus, SolarBodyData.venus.radius*rCV, 0xB55D16);
		renderer.addTrail(venus, 38, 2, 0xB55D16, 6);

		var earth = addBodyFromDatum(SolarBodyData.earth, SolarBodyData.earth.radius*rCV, 0x13B3F2);
		renderer.addTrail(earth, 92, 6, 0x13B3F2, 4);

		var mars = addBodyFromDatum(SolarBodyData.mars, SolarBodyData.mars.radius*rCV, 0xBB1111);
		renderer.addTrail(mars, 86, 2, 0xBB1111, 8);


		//var stepTimer:haxe.Timer = new haxe.Timer(10);
		//stepTimer.run = function():Void{
		//	simulator.step(1);
		//};

		renderer.beforeRender = function():Void{
			simulator.step(1);
		}
	}

	inline function addBodyFromDatum(bd:BodyDatum, displayRadius:Float = 10, displayColor:Int = 0xFF0000):Body{
		var b = simulator.addBody(new Body(bd.position, bd.velocity, bd.mass));
		renderer.addSphericalBody(b, displayRadius, displayColor);
		return b;
	}

}