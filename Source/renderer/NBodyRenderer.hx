package renderer;

import away3d.cameras.Camera3D;
import away3d.containers.View3D;
import away3d.controllers.HoverController;
import away3d.entities.Mesh;
import away3d.lights.DirectionalLight;
import away3d.materials.ColorMaterial;
import away3d.materials.lightpickers.StaticLightPicker;
import away3d.materials.TextureMaterial;
import away3d.primitives.PlaneGeometry;
import away3d.utils.Cast;
import flash.display.Sprite;
import flash.display.Stage;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Vector3D;

import simulator.Body;
import simulator.NBodySimulator;

class NBodyRenderer {
	public var beforeDraw:Void->Void = null;
	public var afterDraw:Void->Void = null;

	public var stage:Stage;

	public var simulator:NBodySimulator;

	private var renderBodies:Array<IRenderableBody>;

	//3D engine
	private var view:View3D;
	private var camera:Camera3D;
	private var cameraController:HoverController;
	//	camera navigation
	private var move:Bool = false;
	private var lastPanAngle:Float;
	private var lastTiltAngle:Float;
	private var lastMouseX:Float;
	private var lastMouseY:Float;
	//Scene
	private var plane:Mesh;
	private var lightPicker:StaticLightPicker;

	public function new(stage:Stage){
		this.stage = stage;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;

		initClassVariables();

		//3d engine
		initEngine();
		initScene();
		initListeners();

		onResize();//set view size to window size

		var fps = new openfl.display.FPS(0, 0, 0xffffff);
		stage.addChild(fps);
	}

	/**
	/* ---------- Public Methods ----------
	*/
	public function addSphericalBody(body:Body, radius:Float = 50, color:Int = 0x00FF00):IRenderableBody{
		var rb:IRenderableBody = new SphericalBody(body, radius, color);
		//set lights
		rb.mesh.material.lightPicker = lightPicker;

		view.scene.addChild(rb.mesh);
		renderBodies.push(rb);
		return rb;
	}

	/**
	/* ---------- Private Methods ----------
	*/
	private function initClassVariables(){
		renderBodies = new Array<IRenderableBody>();
	}

	private function initEngine(){
		//Away 3D setup
		view = new View3D();
		view.antiAlias = 0;

		camera = new Camera3D();
		view.camera = camera;

		cameraController = new HoverController(camera);
		cameraController.distance = 1000;
		cameraController.minTiltAngle = 0;
		cameraController.maxTiltAngle = 90;
		cameraController.panAngle = 45;
		cameraController.tiltAngle = 20;
	}

	private function initScene(){
		//setup lights
		var light = new DirectionalLight();
		light.direction = new Vector3D(0, -1, 0);
		light.ambient = 0.6;
		light.diffuse = 0.7;

		view.scene.addChild(light);

		//light picker for materials
		lightPicker = new StaticLightPicker([light]);

		//Setup plane
		plane = new Mesh(new PlaneGeometry(700,700));
		plane.material = new ColorMaterial(0x1C1D1F,1);
		plane.material.lightPicker = lightPicker;

		view.scene.addChild(plane);
	}

	private function initListeners(){
		//render loop
		view.stage3DProxy.setRenderCallback(render);

		//mouse events
		stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);

		//window resize
		stage.addEventListener(Event.RESIZE, onResize);
	}
	
	private function render(?e:Event){
		if(beforeDraw != null)beforeDraw();

		//Camera control
		if (move) {
		 	cameraController.panAngle = 0.3*(Math.isNaN(stage.mouseX)?0:stage.mouseX - lastMouseX) + lastPanAngle;
		 	cameraController.tiltAngle = 0.3*(Math.isNaN(stage.mouseY)?0:stage.mouseY - lastMouseY) + lastTiltAngle;
		}

		for(rb in renderBodies){
			//update positions
			rb.update();
		}

		view.render();

		if(afterDraw != null)afterDraw();
	}


	/**
	/* ---------- Event Listeners ----------
	*/
	private function onResize(?event:Event):Void{
		view.width = stage.stageWidth;
		view.height = stage.stageHeight;
	}

	private function onMouseDown(event:MouseEvent):Void{
		lastPanAngle = cameraController.panAngle;
		lastTiltAngle = cameraController.tiltAngle;
		lastMouseX = Math.isNaN(stage.mouseX)?0:stage.mouseX ;
		lastMouseY = Math.isNaN(stage.mouseY)?0:stage.mouseY ;
		move = true;
		stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
	}
	
	private function onMouseUp(event:MouseEvent):Void{
		move = false;
		stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
	}

	private function onStageMouseLeave(event:Event):Void{
		move = false;
		stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
	}
}

interface IRenderableBody{
	public var body:Body;
	public var mesh:Mesh;
	public function update():Void;
}

class RenderableBody implements IRenderableBody{
	public var body:Body;
	public var mesh:Mesh;

	public function new(b:Body, mesh:Mesh){
		this.body = b;
		this.mesh = mesh;
	}

	public inline function update(){}
}

class SphericalBody implements IRenderableBody{
	public var body:Body;
	public var mesh:Mesh;

	public function new(b:Body, radius:Float, color:Int){
		this.body = b;

		var sphere = new Mesh(new away3d.primitives.SphereGeometry(radius));
		sphere.material = new ColorMaterial(color, 1);

		this.mesh = sphere;
	}

	public inline function update(){
		this.mesh.x = body.x;
		this.mesh.y = body.y;
		this.mesh.z = body.z;
	}
}