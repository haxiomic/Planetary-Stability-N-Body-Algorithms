//Pre-step jerk and acceleration

package simulator;

import geom.VPointer;
import simulator.Body;
import simulator.NBodySimulator;
import geom.Vec3;
import haxe.ds.Vector;

class Hermite4thOrder extends NBodySimulator{
	public var dt:Float;

	var bodyCount:Int = 0;

	var position        : FlatVec3Array;
	var velocity        : FlatVec3Array;
	var acceleration    : FlatVec3Array;
	var jerk            : FlatVec3Array;
	var oldPosition     : FlatVec3Array;
	var oldVelocity     : FlatVec3Array;
	var oldAcceleration : FlatVec3Array;
	var oldJerk         : FlatVec3Array;

	var mass            : Vector<Float>;

	public function new(G:Float, dt:Float){
		super(G);
		this.algorithmName = "Hermite 4th Order";
		this.algorithmDetails = "";
		this.dt = dt;
	}

	@:noStack
	override public function prepare(){
		super.prepare();
		position       	= new FlatVec3Array(this.bodies.length);
		velocity       	= new FlatVec3Array(this.bodies.length);
		acceleration   	= new FlatVec3Array(this.bodies.length);
		jerk           	= new FlatVec3Array(this.bodies.length);
		oldPosition    	= new FlatVec3Array(this.bodies.length);
		oldVelocity    	= new FlatVec3Array(this.bodies.length);
		oldAcceleration	= new FlatVec3Array(this.bodies.length);
		oldJerk        	= new FlatVec3Array(this.bodies.length);
		mass 			= new Vector<Float>(this.bodies.length);

		var b:Body;
		for (i in 0...this.bodies.length) {
			b = this.bodies[i];
			position.setVec3(i, b.p);
			velocity.setVec3(i, b.v);
			mass[i] = b.m;

			//repoint body vectors to their new home in the flat array
			var vpoint:VPointer;
			vpoint = cast b.p;
			vpoint.index = i*3;
			vpoint.array = cast position;
			vpoint = cast b.v;
			vpoint.index = i*3;
			vpoint.array = cast velocity;
		}

		evaluate();
	}

	override public function addBody(b:Body):Body{
		super.addBody(b);
		bodyCount++;
		return b;
	}

	@:noStack 
	override function step(){
		for(i in 0...bodyCount*3){
			oldPosition[i] = position[i];
			oldVelocity[i] = velocity[i];
			oldAcceleration[i] = acceleration[i];
			oldJerk[i] = jerk[i];
		}

		predict();
		for(i in 0...2){
			evaluate();
			correct();
		}

		time+=dt; 
	}
	
	@:noStack
	inline function predict(){
			for (i in 0...bodyCount){
				//x1 = x0 + v*dt + (1/2)a*dt^2 + (1/6)j*dt^3
				position.addFn(i, inline function(k) return
					velocity.get(i, k)*dt +
					acceleration.get(i, k)*dt*dt/2 + 
					jerk.get(i, k)*dt*dt*dt/6
				);
				//v1 = v0 + a*dt + (1/2)j*dt^2
				velocity.addFn(i, inline function(k) return
					acceleration.get(i, k)*dt +
					jerk.get(i, k)*dt*dt/2
				);
			}
	}
	
	@:noStack
	inline function correct(){
		for (i in 0...bodyCount){
			velocity.setFn(i, inline function(k) return
				oldVelocity.get(i, k) + 
				(oldAcceleration.get(i, k) + acceleration.get(i, k))*dt/2 +
				(oldJerk.get(i, k) - jerk.get(i, k))*dt*dt/12
			);

			position.setFn(i, inline function(k) return
				oldPosition.get(i, k) + 
				(oldVelocity.get(i, k) + velocity.get(i, k))*dt/2 + 
				(oldAcceleration.get(i, k) - acceleration.get(i, k))*dt*dt/12
			);
		}
	}

	
	@:noStack//compute acceleration and jerk
	inline function evaluate(){
		var d          : Float;
		var dSq        : Float;
		var dCu        : Float;
		var dvDotR_dSq : Float;
		var fcj        : Float;
		//reset accelerations and jerks
		for (i in 0...bodyCount){
			acceleration.zero(i); 
			jerk.zero(i);
		}

		//Pairwise interaction a & a dot
		for (i in 0...bodyCount) {
			for(j in i+1...bodyCount){
				position.difference(i, j, r);
				velocity.difference(i, j, dv);

				dSq  = r.lengthSquared();
				d    = Math.sqrt(dSq);
				dCu  = d*dSq;

				dvDotR_dSq = dv.dot(r)/dSq;

				//Force factor
				fc  = G / dSq;
				fcj = fc / d;

				jerk.addFn(i, inline function(k) return
					fcj*mass[j]*((dv[k] - 3*dvDotR_dSq*r[k]))
				);
				jerk.addFn(j, inline function(k) return
					-fcj*mass[i]*((dv[k] - 3*dvDotR_dSq*r[k]))
				);

				//Normalize r
				r *= 1/d;
				acceleration.addProduct(i, r, fc*mass[j]);
				acceleration.addProduct(j, r, -fc*mass[i]);
			}
		}
	}
	//Variable pool
	var dv:Vec3 = new Vec3();

	//Faster
	override public inline function totalEnergy():Float{
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

	override function get_params():Dynamic{
		return {dt:dt};
	}	
}

abstract FlatVec3Array(Vector<Float>){
	static inline var VEC_SIZE:Int = 3;

	public inline function new(count:Int){
		this = new Vector<Float>(count*VEC_SIZE);
	}

	@:arrayAccess
	@:extern public inline function _getI(i:Int):Float
		return this[i];
	@:arrayAccess
	@:extern public inline function _setI(i:Int, value:Float):Float
		return this[i] = value;

	@:extern public inline function get(index:Int, k:Int):Float
		return this[index*VEC_SIZE + k];
	@:extern public inline function set(index:Int, k:Int, value:Float):Float
		return this[index*VEC_SIZE + k] = value;
	@:extern public inline function getX(index:Int):Float
		return this[index*VEC_SIZE];
	@:extern public inline function getY(index:Int):Float
		return this[index*VEC_SIZE + 1];
	@:extern public inline function getZ(index:Int):Float
		return this[index*VEC_SIZE + 2];
	@:extern public inline function setX(index:Int, value:Float):Float
		return this[index*VEC_SIZE] = value;	
	@:extern public inline function setY(index:Int, value:Float):Float
		return this[index*VEC_SIZE + 1] = value;	
	@:extern public inline function setZ(index:Int, value:Float):Float
		return this[index*VEC_SIZE + 2] = value;
	@:extern public inline function getVec3(index:Int):Vec3{
		return cast new VPointer(cast this, index*3);
	}
	@:extern public inline function setVec3(index:Int, v:Vec3):Void{
		for (k in 0...VEC_SIZE)
			set(index, k, v[k]);
	}

	// --- Mirror Vec3 ---
	@:extern public inline function length(index:Int):Float
		return Math.sqrt(lengthSquared(index));

	@:extern public inline function lengthSquared(index:Int):Float
		return dot(index, index);

	@:extern public inline function dot(indexI:Int, indexJ:Int):Float
		return 	getX(indexI) * getX(indexJ) +
				getY(indexI) * getY(indexJ) +
				getZ(indexI) * getZ(indexJ);

	@:extern public inline function dotVec3(index:Int, prod:Vec3):Float
		return 	getX(index) * prod.x +
				getY(index) * prod.y +
				getZ(index) * prod.z;

	@:extern public inline function normalize(index:Int ):Int{
		var d:Float = length(index);
		setX(index, getX(index)/d);
		setY(index, getY(index)/d);
		setZ(index, getZ(index)/d);
		return index;
	}

	@:extern public inline function zero(index:Int){
		setX(index, 0);
		setY(index, 0);
		setZ(index, 0);
	}

	@:extern public inline function setFn(index:Int, fn:Int->Float){
		setX(index, fn(0));
		setY(index, fn(1));
		setZ(index, fn(2));
	}

	@:extern public inline function addFn(index:Int, fn:Int->Float){
		setX(index, fn(0) + getX(index));
		setY(index, fn(1) + getY(index));
		setZ(index, fn(2) + getZ(index));
	}

	@:extern public inline function setProduct(index, v:Vec3, mul:Float){
		setX(index, mul*v.x);
		setY(index, mul*v.y);
		setZ(index, mul*v.z);
	}

	@:extern public inline function addProduct(index, v:Vec3, mul:Float){
		setX(index, mul*v.x + getX(index));
		setY(index, mul*v.y + getY(index));
		setZ(index, mul*v.z + getZ(index));
	}

	// --- Static ---
	@:extern public inline function difference(indexI:Int, indexJ:Int, r:Vec3){
		r.x = getX(indexJ) - getX(indexI);
		r.y = getY(indexJ) - getY(indexI);
		r.z = getZ(indexJ) - getZ(indexI);
	}

	static public inline function fromArrayVec3(array:Array<Vec3>){
		var r = new FlatVec3Array(array.length*VEC_SIZE);
		for(i in 0...array.length){
			for(k in 0...VEC_SIZE){
				r.set(i, k, array[i][k]);
			}
		}
		return r;
	}
}