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

		//Create planets
		var b:Body;
		var position:Vec3;
		var velocity:Vec3;
		var mass:Float;
		//Sun
		position = new Vec3(0,0,0);
		velocity = new Vec3(0,0,0);
		mass = 100;
		b = simulator.addBody(new Body(position, velocity, mass));
		renderer.addSphericalBody(b, 20, 0xFFA21F);

		//Mercury
		position = new Vec3(100,0,0);
		velocity = new Vec3(0,0,4);
		mass = 1;
		b = simulator.addBody(new Body(position, velocity, mass));
		renderer.addSphericalBody(b, 5, 0xFFE26E);

		//Venus
		position = new Vec3(200,0,0);
		velocity = new Vec3(0,0,-2.4);
		mass = 1;
		b = simulator.addBody(new Body(position, velocity, mass));
		renderer.addSphericalBody(b, 5, 0xB55D16);

		//Earth
		position = new Vec3(300,0,0);
		velocity = new Vec3(0,0,1.8);
		mass = 1;
		b = simulator.addBody(new Body(position, velocity, mass));
		renderer.addSphericalBody(b, 5, 0x13B3F2);


		for (i in 0...10) {
			b = simulator.addBody(new Body(new Vec3( Math.random() * 700-350 , Math.random() * 350, Math.random() * 700-350)));
			b.vx = Math.random()*1-0.5;
			b.vy = Math.random()*1-0.5;
			b.vz = Math.random()*1-0.5;

			renderer.addSphericalBody(b, 3, 0x4AC9FF);
		}

		var stepTimer:haxe.Timer = new haxe.Timer(10);
		stepTimer.run = function():Void{
			simulator.step(1);
		};
	}

}