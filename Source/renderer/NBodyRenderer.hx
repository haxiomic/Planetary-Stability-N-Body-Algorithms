package renderer;

import flash.display.Sprite;
import flash.events.Event;
import simulator.Body;
import simulator.NBodySimulator;

class NBodyRenderer {
	public var beforeDraw:Void->Void = null;
	public var afterDraw:Void->Void = null;
	public var stage:Sprite;
	public var display:Sprite;
	public var simulator:NBodySimulator;


	public function new(simulator:NBodySimulator, stage:Sprite){
		this.simulator = simulator;
		this.stage = stage;

		this.display = new Sprite();
		this.stage.addChild(this.display);

		//Render loop
		this.stage.addEventListener(Event.ENTER_FRAME, draw);
	}
	
	public function draw(?e:Event){
		if(beforeDraw != null)beforeDraw();

		display.graphics.clear();

		var red:Float, green:Float, blue:Float, depth:Float;
		for(b in simulator.bodies){
			depth = Math.atan(1000/(5*b.z+1000));

			red = green = blue = Std.int( 0xFF*1*depth );
			//red *= red*.1;
			//green *= green*10;
			if(red>0xFF)red = 0xFF;if(red<0x00) red = 0x00;
			if(green>0xFF)green = 0xFF;if(green<0x00) green = 0x00;
			if(blue>0xFF)blue = 0xFF;if(blue<0x00) blue = 0x00;

			display.graphics.beginFill(Std.int( red*0x10000 + green*0x100 + blue ), 1);
			display.graphics.drawCircle(b.x, b.y, 10*depth );
			display.graphics.endFill();
		}

		if(afterDraw != null)afterDraw();
	}
}

/*class RendererBody{
	public var body:Body;
	public var spr:Sprite;

	public function new(b:Body){
		this.body = b;
		spr = new Sprite();
	}

	private function draw(){
		spr.graphics.beginFill(0xFFFFFF, 1);
		spr.graphics.drawCircle(0,0,10);
		spr.graphics.endFill();
	}
}*/