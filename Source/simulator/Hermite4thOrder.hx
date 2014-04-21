//Pre-step jerk and acceleration

package simulator;

import simulator.Body;
import simulator.NBodySimulator;
import geom.Vec3;
import haxe.ds.Vector;

class Hermite4thOrder extends NBodySimulator{
	public var dt:Float;

	var bodyCount:Int = 0;

	var position        : Array<Vec3>;
	var velocity        : Array<Vec3>;
	var acceleration    : Array<Vec3>;
	var jerk            : Array<Vec3>;
	
	var oldPosition     : Array<Vec3>;
	var oldVelocity     : Array<Vec3>;
	var oldAcceleration : Array<Vec3>;
	var oldJerk         : Array<Vec3>;

	var _f_position        : FlatVec3Array;
	var _f_velocity        : FlatVec3Array;
	var _f_acceleration    : FlatVec3Array;
	var _f_jerk            : FlatVec3Array;
	var _f_oldPosition     : FlatVec3Array;
	var _f_oldVelocity     : FlatVec3Array;
	var _f_oldAcceleration : FlatVec3Array;
	var _f_oldJerk         : FlatVec3Array;

	var mass            : Vector<Float>;

	public function new(G:Float, dt:Float){
		super(G);
		this.algorithmName = "Hermite 4th Order";
		this.algorithmDetails = "";
		this.dt = dt;
	}

	override public function prepare(){
		super.prepare();
		_f_position       	= new FlatVec3Array(this.bodies.length);
		_f_velocity       	= new FlatVec3Array(this.bodies.length);
		_f_acceleration   	= new FlatVec3Array(this.bodies.length);
		_f_jerk           	= new FlatVec3Array(this.bodies.length);
		_f_oldPosition    	= new FlatVec3Array(this.bodies.length);
		_f_oldVelocity    	= new FlatVec3Array(this.bodies.length);
		_f_oldAcceleration	= new FlatVec3Array(this.bodies.length);
		_f_oldJerk        	= new FlatVec3Array(this.bodies.length);
		mass 				= new Vector<Float>(this.bodies.length);

		var b:Body;
		for (i in 0...this.bodies.length) {
			b = this.bodies[i];
			_f_position.setVec3(i, b.p);
			_f_velocity.setVec3(i, b.v);
			mass[i] = b.m;
		}

		evaluate();
	}

	override public function addBody(b:Body):Body{
		super.addBody(b);

		position.push(b.p);
		velocity.push(b.v);
		acceleration.push(new Vec3());
		jerk.push(new Vec3());

		oldPosition.push(new Vec3());
		oldVelocity.push(new Vec3());
		oldAcceleration.push(new Vec3());
		oldJerk.push(new Vec3());

		bodyCount++;
		return b;
	}

	@:noStack 
	override function step(){
		for(i in 0...bodyCount*3){
			_f_oldPosition[i] = _f_position[i];
			_f_oldVelocity[i] = _f_velocity[i];
			_f_oldAcceleration[i] = _f_acceleration[i];
			_f_oldJerk[i] = _f_jerk[i];
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
				position[i].addFn(inline function(k) return
					velocity[i][k]*dt +
					acceleration[i][k]*dt*dt/2 + 
					jerk[i][k]*dt*dt*dt/6
				);
				//v1 = v0 + a*dt + (1/2)j*dt^2
				velocity[i].addFn(inline function(k) return
					acceleration[i][k]*dt +
					jerk[i][k]*dt*dt/2
				);
			}
	}
	
	@:noStack
	inline function correct(){
		for (i in 0...bodyCount){
			velocity[i].setFn(inline function(k) return
				oldVelocity[i][k] + 
				(oldAcceleration[i][k] + acceleration[i][k])*dt/2 +
				(oldJerk[i][k] - jerk[i][k])*dt*dt/12
			);

			position[i].setFn(inline function(k) return
				oldPosition[i][k] + 
				(oldVelocity[i][k] + velocity[i][k])*dt/2 + 
				(oldAcceleration[i][k] - acceleration[i][k])*dt*dt/12
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
			acceleration[i].zero(); 
			jerk[i].zero();
		}

		//Pairwise interaction a & a dot
		for (i in 0...bodyCount) {
			for(j in i+1...bodyCount){
				Vec3.difference(position[i], position[j], r);
				Vec3.difference(velocity[i], velocity[j], dv);

				dSq  = r.lengthSquared();
				d    = Math.sqrt(dSq);
				dCu  = d*dSq;

				dvDotR_dSq = dv.dot(r)/dSq;

				//Force factor
				fc  = G / dSq;
				fcj = G / dCu;

				jerk[i].addFn(inline function(k) return
					fcj*mass[j]*((dv[k] - 3*dvDotR_dSq*r[k]))
				);
				jerk[j].addFn(inline function(k) return
					-fcj*mass[i]*((dv[k] - 3*dvDotR_dSq*r[k]))
				);

				//Normalize r
				r *= 1/d;
				acceleration[i].addProduct(r, fc*mass[j]);
				acceleration[j].addProduct(r, -fc*mass[i]);
			}
		}
	}
	
	@:noStack
	inline function spaceDifference(p1:Vec3, p2:Vec3){
		Vec3.difference(p1, p2, r);
	}

	override function get_params():Dynamic{
		return {dt:dt};
	}	

	override function initalize(){
		super.initalize();

		position        = new Array<Vec3>();
		velocity        = new Array<Vec3>();
		acceleration    = new Array<Vec3>();
		jerk            = new Array<Vec3>();
		oldPosition     = new Array<Vec3>();
		oldVelocity     = new Array<Vec3>();
		oldAcceleration = new Array<Vec3>();
		oldJerk         = new Array<Vec3>();
	}

	//Variable pool
	var dv:Vec3 = new Vec3();
}


abstract FlatVec3Array(Vector<Float>){
	static inline var VEC_SIZE:Int = 3;

	public inline function new(count:Int){
		this = new Vector<Float>(count*VEC_SIZE);
	}

	@:arrayAccess
	@:extern public inline function getI(i:Int):Float
		return this[i];
	@:arrayAccess
	@:extern public inline function setI(i:Int, value:Float):Float
		return this[i] = value;

	@:extern public inline function get(index:Int, k:Int):Float
		return this[index*VEC_SIZE + k];

	@:extern public inline function set(index:Int, k:Int, value:Float):Float
		return this[index*VEC_SIZE + k] = value;

	@:extern public inline function getX(index:Int):Float
		return this[index*VEC_SIZE];
	@:extern public inline function getY(index:Int):Float
		return this[index*VEC_SIZE+1];
	@:extern public inline function getZ(index:Int):Float
		return this[index*VEC_SIZE+2];
	@:extern public inline function setX(index:Int, value:Float):Float
		return this[index*VEC_SIZE] = value;	
	@:extern public inline function setY(index:Int, value:Float):Float
		return this[index*VEC_SIZE + 1] = value;	
	@:extern public inline function setZ(index:Int, value:Float):Float
		return this[index*VEC_SIZE + 2] = value;

	@:extern public inline function setVec3(index:Int, v:Vec3):Void{
		for (k in 0...VEC_SIZE)
			this.set(index, v[k]);
	}

	//Vec3 Mirror
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