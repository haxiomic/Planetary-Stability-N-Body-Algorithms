package;

class Constants{
	//Physical Law Constants in SI units
	static public var G:Float       	= 6.673840E-11;	//m^3 kg^-1 s^-2

	//Conversions from wolfram eg: 'newtons gravitational constant in AU^3 per earth mass per days^2'
	static public var G_AU_kg_s:Float   = 1.993E-44;	//1.488×10^-34 au^3/(kg day^2)  	(astronomical units cubed per kilogram day squared)
	static public var G_AU_kg_D:Float   = 1.488E-34;	//1.488×10^-34 au^3/(kg day^2)  	(astronomical units cubed per kilogram day squared)
	static public var G_AU_ME_D:Float   = 8.890E-10;	//8.89×10^-10 au^3/(M_(+) day^2)  	(astronomical units cubed per Earth mass day squared)

	//Length Constants
	static public var AU:Float 			= 1.495978707E11;
}