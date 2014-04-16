package math;

class ExtendedMath {
	static public inline function log2(x:UInt):Int{
		br = 0;
		while(x>>=1)++br;
		return br;
	}static var br:Int;
}