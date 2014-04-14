package renderer;

import flash.events.Event;
import flash.events.MouseEvent;
import simulator.Body;

import flash.display.Sprite;
import flash.display.Stage;


class BasicRenderer {
	var stage:flash.display.Stage;

	var bodyData:Map<Body, BodyRenderData>;

	var lengthConversion:Float = 100; //how many pixels for each sim unit

	public var preRenderCallback:Void->Void;

	public function new(){
		initalize();
		this.stage = flash.Lib.current.stage;
		stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
	}

	public function startAutoRender(){
		stage.addEventListener(Event.ENTER_FRAME, render);
	}

	public function stopAutoRender(){
		stage.removeEventListener(Event.ENTER_FRAME, render);
	}

	public function addBody(b:Body, drawRadius:Float=5 /*pixels*/, drawColor:Int=0xFFFFFF){
		var s:Sprite = new Sprite();
		var data = new BodyRenderData(s, drawRadius, drawColor);
		bodyData.set(b, data);
		drawBody(b);
		stage.addChild(s);
	}

	public function reset(){
		initalize();
	}

	public function render(?e){
		if(preRenderCallback!=null)preRenderCallback();

		var s:Sprite;
		for(b in bodyData.keys()){
			drawBody(b);
		}
	}

	inline function drawBody(b:Body){
		var data = bodyData.get(b);
		var s:Sprite = data.sprite;
		var r:Float = data.radius;
		var c:Int = data.color;

		var baseLengthConversion = 100;
		r/= baseLengthConversion/lengthConversion;
		if(r<2)r=2;

		s.graphics.clear();
		s.graphics.beginFill(c,1);
		s.graphics.drawCircle(0, 0, r);
		s.graphics.endFill();

		s.x = screenX(b);
		s.y = screenY(b);
	}

	// Events
 	function onMouseWheel(event:MouseEvent):Void{
		lengthConversion += event.delta*5;
		if(lengthConversion<0)lengthConversion=0;
	}

	// Coordinate conversion

	inline function screenX(b:Body)
		return simulationToRendererCoordX(b.x);
	inline function screenY(b:Body)
		return simulationToRendererCoordY(b.z);

	inline function s2r(v:Float)return simulationLengthToRenderLength(v);
	inline function simulationLengthToRenderLength(v:Float)
		return v*lengthConversion;

	inline function s2rX(v:Float)return simulationToRendererCoordX(v);
	inline function simulationToRendererCoordX(v:Float)
		return simulationLengthToRenderLength(v)+stage.stageWidth*.5;

	inline function s2rY(v:Float)return simulationToRendererCoordY(v);
	inline function simulationToRendererCoordY(v:Float)
		return simulationLengthToRenderLength(v)+stage.stageHeight*.5;

	private function initalize(){
		bodyData = new Map<Body, BodyRenderData>();
	}
}

class BodyRenderData{
	public var sprite:Sprite;
	public var radius:Float;
	public var color:Int;
	public function new(s:Sprite, r:Float, c:Int){
		this.sprite = s;
		this.radius = r;
		this.color = c;
	}
}