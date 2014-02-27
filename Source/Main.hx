package;

import geom.Vec3;
import renderer.NBodyRenderer;
import simulator.Body;
import simulator.NBodySimulator;

class Main {

	var renderer:NBodyRenderer;
	var simulator:NBodySimulator;

	public function new () {
		simulator = new NBodySimulator();
		renderer = new NBodyRenderer(flash.Lib.current.stage);

		//Create bodies 
		var b:Body;
		for (i in 0...20) {
			b = simulator.addBody(new Body(new Vec3( Math.random() * 700-350 , Math.random() * 350, Math.random() * 700-350)));
			b.vx = Math.random()*1-0.5;
			b.vy = Math.random()*1-0.5;
			b.vz = Math.random()*1-0.5;

			renderer.addSphericalBody(b, 10, 0x4AC9FF);
		}

		var stepTimer:haxe.Timer = new haxe.Timer(15);
		stepTimer.run = function():Void{
			simulator.step(1);
		};
	}

}