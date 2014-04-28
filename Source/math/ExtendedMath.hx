package math;

class ExtendedMath {
	static public inline function log2(x:UInt):Int{
		var br = 0;
		while((x >>= 1) > 0) ++br;
		return br;
	}
}