package simulator;

import haxe.ds.Vector;
import geom.Vec3;
import geom.FlatVec3Array;
import geom.VPointer;
import simulator.Body;

class NBodySimulator {
	public var algorithmName(default, null):String = "";
	public var algorithmDetails(default, null):String = "";
	public var params(get, null):Dynamic;

	public var bodies:Array<Body> = new Array<Body>();
	var position        : FlatVec3Array;
	var velocity        : FlatVec3Array;
	var mass            : Vector<Float>;

	public var time(default, null):Float = 0;

	public var G:Float;

	var bodyCount:Int = 0;
	var totalMass:Float;

	public function new(G:Float){
		this.G = G;
	}

	@:noStack
	public function prepare(){
		position       	= new FlatVec3Array(this.bodies.length);
		velocity       	= new FlatVec3Array(this.bodies.length);
		mass            = new Vector<Float>(this.bodies.length);

		var b:Body;
		for (i in 0...bodyCount) {
			b = this.bodies[i];
			position.setVec3(i, b.p);
			velocity.setVec3(i, b.v);
			mass[i] = b.m;

			//repoint body vectors to their new home in the flat array
			var vpoint:VPointer;
			vpoint       = cast b.p;
			vpoint.index = i*3;
			vpoint.array = cast position;
			vpoint       = cast b.v;
			vpoint.index = i*3;
			vpoint.array = cast velocity;
		}
	}

	public function addBody(b:Body):Body{
		totalMass+=b.m;
		bodies.push(b);
		bodyCount = bodies.length;
		return b;
	}

	public function step(){}
	var A:Body;var B:Body;//#! remove

	public inline function totalEnergy():Float{
		var E:Float = 0, d:Float;
		var k:Float = 0;
		var p:Float = 0;
		for(i in 0...bodyCount){
			E += 0.5*mass[i]*velocity.lengthSquared(i);//kinetic energy

			for(j in i+1...bodyCount){
				position.difference(i, j, r);
				d = r.length();
				E -= G*mass[i]*mass[j]/d;//potential energy
			}

		}
		return E;
	}

	//reconsider
	//sets variables
	var r:Vec3 = new Vec3();
	var d:Float;
	var dSq:Float;
	var fc:Float;
	var accelA:Float;var accelB:Float;
	private inline function accelerationsDueToGravity(A:Body, B:Body){
		//Distance vector and its magnitudes
		Vec3.difference(A.p, B.p, r);
		dSq = r.lengthSquared();
		d = Math.sqrt(dSq);
		//Normalize r
		r *= 1/d;
		//Force factor
		fc = 1 * G / dSq;
		//Acceleration on A & B
		accelA = fc*B.m;
		accelB = -fc*A.m;
	}


	private function get_params():Dynamic{
		return {};
	}
}