package renderer;

import away3d.cameras.Camera3D;
import away3d.containers.View3D;
import away3d.controllers.HoverController;
import away3d.entities.Mesh;
import away3d.entities.SegmentSet;
import away3d.lights.DirectionalLight;
import away3d.materials.ColorMaterial;
import away3d.materials.lightpickers.StaticLightPicker;
import away3d.materials.TextureMaterial;
import away3d.primitives.LineSegment;
import away3d.primitives.PlaneGeometry;
import away3d.primitives.SphereGeometry;
import away3d.utils.Cast;
import flash.display.Stage;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Vector3D;

import simulator.Body;
import simulator.NBodySimulator;

class NBodyRenderer {
	static inline public var displayUnitsPerSimulationUnitLength = 300;
	public var beforeDraw:Void->Void = null;
	public var afterDraw:Void->Void = null;

	public var stage:Stage;

	public var simulator:NBodySimulator;

	private var renderables:Array<IUpdateable>;

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
		//stage.scaleMode = StageScaleMode.NO_SCALE;
		//stage.align = StageAlign.TOP_LEFT;

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
	public function addSphericalBody(body:Body, radius:Float = 50, color:Int = 0x00FF00):SphericalBody{
		var rb:SphericalBody = new SphericalBody(body, radius, color);
		//set lights
		rb.mesh.material.lightPicker = lightPicker;

		view.scene.addChild(rb.mesh);
		renderables.push(rb);
		return rb;
	}

	public function addTrail(body:Body, segmentCount:Int = 20, thickness:Float = 1, color:Int = 0xFFFFFF):Trail{
		var tr:Trail = new Trail(body, segmentCount, thickness, color);

		view.scene.addChild(tr.segSet);
		renderables.push(tr);
		return tr;
	}
	/**
	/* ---------- Private Methods ----------
	*/
	private function initClassVariables(){
		renderables = new Array<IUpdateable>();
	}

	private function initEngine(){
		//Away 3D setup
		view = new View3D();
		view.antiAlias = 0;

		camera = new Camera3D();
		view.camera = camera;

		cameraController = new HoverController(camera);
		cameraController.minTiltAngle = 0;
		cameraController.maxTiltAngle = 90;
		cameraController.distance = 1000;
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
		
		#if flash
			var grid = new away3d.primitives.WireframePlane(1000,1000,10,10,0x333333,.25,'xz');
			view.scene.addChild(grid);
		#else
			//Setup plane
			plane = new Mesh(new PlaneGeometry(1000,1000));
			plane.material = new ColorMaterial(0x1C1D1F,0.1);
			plane.material.lightPicker = lightPicker;
			view.scene.addChild(plane);
		#end
	}

	private function initListeners(){
		//render loop
		view.stage3DProxy.setRenderCallback(render);

		//mouse events
		stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);

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

		for(rb in renderables){
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

	private function onMouseWheel(event:MouseEvent):Void{
		if(cameraController.distance+event.delta*10<=0)return;//you've gone too far!
		cameraController.distance += event.delta*10;
	}

	/**
	/* ---------- Static Methods ----------
	*/
	static inline public function sToR(v:Float):Float{
		return v*displayUnitsPerSimulationUnitLength;
	}
}

typedef NBR = NBodyRenderer;

interface IUpdateable{
	public var body:Body;
	public function update():Void;
}

interface IRenderableBody extends IUpdateable{
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

		var sphere = new Mesh(new SphereGeometry(radius));
		sphere.material = new ColorMaterial(color, 1);

		this.mesh = sphere;
	}

	public inline function update(){
		this.mesh.x = NBR.sToR(this.body.x); //conversion factor = units per AU (or what ever unit length is being used)
		this.mesh.y = NBR.sToR(this.body.y);
		this.mesh.z = NBR.sToR(this.body.z);
	}
}

//#! currently Segments are not supported; needs rewrite.
class Trail implements IUpdateable{
	public var body:Body;
	public var segSet:SegmentSet;

	var segs:Array<LineSegment>;
	var si:Int = 0;
	var lastV3:Vector3D;

	public function new(b:Body, segmentCount:Int = 20, thickness:Float = 1, color:Int = 0xFFFFFF){
		this.body = b;
		this.segSet = new SegmentSet();
		this.lastV3 = new Vector3D(0,0,0);

		var bx = NBR.sToR(this.body.x);
		var by = NBR.sToR(this.body.y);
		var bz = NBR.sToR(this.body.z);
		this.lastV3.x = bx;
		this.lastV3.y = by;
		this.lastV3.z = bz;
		//Initialize line segments
		segs = new Array<LineSegment>();
		for (i in 0...segmentCount) {
			var ls = new LineSegment(new Vector3D(bx,by,bz), new Vector3D(bx,by,bz), color, color, thickness);
			this.segSet.addSegment(ls);
			segs.push(ls);
		}
	}

	public inline function update(){
		if(si>=segs.length)si=0;//wrap around

		var bx = NBR.sToR(this.body.x);
		var by = NBR.sToR(this.body.y);
		var bz = NBR.sToR(this.body.z);

		segs[si].start.x = this.lastV3.x;
		segs[si].start.y = this.lastV3.y;
		segs[si].start.z = this.lastV3.z;
		segs[si].end.x = bx;
		segs[si].end.y = by;
		segs[si].end.z = bz;
		
		this.lastV3.x = bx;
		this.lastV3.y = by;
		this.lastV3.z = bz;

		si++;
	}
}