package;

import geom.Vec3;
import BodyDatum;

class SolarBodyData {
	/* 
	** Data soruced from NASA 'HORIZONS Web-Interface' http://ssd.jpl.nasa.gov/horizons.cgi?s_loc=1#top 
	** Data is for the state of the bodies on 28-February-2014
	** Position vectors are taken with respect to the Solar Systems's Barycenter - or center of mass
	---- Units ----
	** Position and velocity values are in AU-Days
	** Mass and radius are in kg-m
	*/

	//Planets
	static public var sun:BodyDatum = {
		name: 'sun',
		position:{x: 0.001330792341824893, y: -0.0001010446497381145, z: -0.002123747720042084},	//AU	
		velocity:{x: 0.000005762801387971368, y: -1.32730965648254e-7, z: 0.000002961540749393402},	//AU-D
		mass: 1.988544E30,//kg
		radius: 6.955E8//m
	}

	static public var mercury:BodyDatum = {
		name: 'mercury',
		position:{x: -0.3914364337806105, y: 0.02556656353465974, z: -0.1290209240089754},			//AU
		velocity:{x: 0.002824616835177268, y: -0.002346980221837403, z: -0.02555436134356727},		//AU-D
		mass:	3.302E23,	
		radius: 2.440E06	
	}

	static public var venus:BodyDatum = {
		name: 'venus',
		position:{x: -0.7110667256260059, y: 0.03962610944161164, z: -0.1031977197346438},
		velocity:{x: 0.002720037640970891, y: -0.0004324435582657765, z: -0.02011200369386666},
		mass: 48.685E23,
		radius: 6.051893E6
	}

	static public var earth:BodyDatum = {
		name: 'earth',
		position:{x: -0.9241405598125328, y: -0.000112406892382986, z: 0.3509698101696127},
		velocity:{x: -0.006411573449421955, y: 6.46159556195739e-7, z: -0.01614179117896427},
		mass: 5.97219E24,
		radius: 6.37814E6
	}

	static public var mars:BodyDatum = {
		name: 'mars',
		position: {x: -1.647915567384758, y:0.03967058490688047, z:-0.03602082524394252},
		velocity: {x: 0.0008159448146320931, y:-0.000288110083953532, z:-0.01279189434581369},
		mass: 6.4185e+23,
		radius: 3394000,
	} 

	static public var jupiter:BodyDatum = {
		name: 'jupiter',
		position: {x: -1.76017268095229, y:0.01893483662849167, z:4.905202730391766},
		velocity: {x: -0.007194464970577564, y:0.000170087238660987, z:-0.002191466905103835},
		mass: 1.89813e+27,
		radius: 66854000,
	} 

	static public var saturn:BodyDatum = {
		name: 'saturn',
		position: {x: -6.662549654989915, y:0.3921588858102791, z:-7.304280374353323},
		velocity: {x: 0.003816908833184273, y:-0.00008621276987292585, z:-0.003774192620922422},
		mass: 5.68319e+26,
		radius: 54364000,
	} 

	static public var uranus:BodyDatum = {
		name: 'uranus',
		position: {x: 19.59763277785229, y:-0.2385304941521605, z:4.136816057617167},
		velocity: {x: -0.0008410124150776637, y:0.00002437469311164974, z:0.003664941495769801},
		mass: 8.68103e+25,
		radius: 24973000,
	} 

	static public var neptune:BodyDatum = {
		name: 'neptune',
		position: {x: 27.14234566134094, y:-0.3634637822783738, z:-12.72558944550596},
		velocity: {x: 0.001311265824901803, y:-0.00008887746340071865, z:0.002860785136542651},
		mass: 1.0241e+26,
		radius: 24342000,
	} 
}

//Extractor in Javascript
/*
function extract(){
	var str = document.body.innerText;
	//regex
	var nameReg = /Target body name:\s*(\w*)\b/im;
	var massReg = /Mass.*10\^([0-9.]*)\s*kg\s*\)\s*=\s*([0-9.]+)/im;//1 = exponent 2 = coefficient	
	var radiusReg = /Eq.*?Radius.*\=\s*([0-9.]+)/im;
	var pvReg = /\$\$SOE\n[+-]?[0-9.]+,.*?,(.*?),(.*?),(.*?),(.*?),(.*?),(.*?),\n/im;
	//result
	var r = new Object();var name = '';
	//regex extraction
	var a;
	a = str.match(nameReg);name = a[1];
	a = str.match(pvReg);r.p = {x:parseFloat(a[1]),y:parseFloat(a[3]),z:parseFloat(a[2])};r.v = {x:parseFloat(a[4]),y:parseFloat(a[6]),z:parseFloat(a[5])};
	a = str.match(massReg);r.mass = a[2]*Math.pow(10, a[1]);
	a = str.match(radiusReg);r.radius = a[1]*1000;

	//construct result
	ostr = "static public var "+name.toLowerCase()+":BodyDatum = {\n";
	name: '=',
	ostr+= "\tposition: {x: "+r.p.x+", y:"+r.p.y+", z:"+r.p.z+"},\n";
	ostr+= "\tvelocity: {x: "+r.v.x+", y:"+r.v.y+", z:"+r.v.z+"},\n";
	ostr+= "\tmass: "+r.mass+",\n";
	ostr+= "\tradius: "+r.radius+",\n";
	ostr+= "}";

	console.log(ostr);
}extract();
*/

/* HORIZON set to:
Ephemeris Type [change] : 	VECTORS
Target Body [change] : 	Mars [499]
Coordinate Origin [change] : 	Solar System Barycenter (SSB) [500@0]
Time Span [change] : 	Start=2014-03-01, Stop=2014-03-31, Step=1 d
Table Settings [change] : 	quantities code=2; labels=YES; CSV format=YES
Display/Output [change] : 	plain text
*/