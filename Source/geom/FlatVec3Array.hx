package geom;

import haxe.ds.Vector;

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