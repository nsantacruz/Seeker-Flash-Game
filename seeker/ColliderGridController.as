package seeker {
	import flash.display.MovieClip;
	import flash.net.SharedObject;
	
	public class ColliderGridController extends MovieClip {
		
		public static const FILE_NAME:String = 'Collider_Grids';
		public var cgcso:SharedObject;
		
		public function ColliderGridController() {
			cgcso = SharedObject.getLocal(FILE_NAME);
			init();
			/*for (var i = 0; i < cgcso.data.colliderData.length; i++) {
				trace(i + ' ' + cgcso.data.colliderData[i].grid.length);
			}
			trace(getElementState(cgcso.data.colliderData[0].grid,127000));*/
			//printAllLevels();
			var yo = new ColliderGrids();
		}
		
		private function printAllLevels() {
			var obj = "[";
			for (var j = 0; j < cgcso.data.colliderData.length; j++) {
				var tempLine = "";
				if (j != 0) tempLine += ",";
				tempLine+="{";
				for (var i in cgcso.data.colliderData[j]) {
					if (i == "grid") {
						tempLine+=""+i+":[";
						for (var k = 0; k < cgcso.data.colliderData[j][i].length; k++) {
							if (k != 0) tempLine += ",";
							tempLine+=cgcso.data.colliderData[j][i][k];
						}
						tempLine+="]";
					}
					else if (i == "name") tempLine+=","+i+':"'+cgcso.data.colliderData[j][i] + '"';
					//else if (i == "nr") tempLine+=i+":"+cgcso.data.colliderData[j][i];
					else tempLine+=","+i+":"+cgcso.data.colliderData[j][i];
				}
				tempLine+="}\n";
				obj  += tempLine;
			}
			obj  += "]";
			trace(obj);
		}

		private function init() {
			if (!cgcso.data.inited) {
				trace("finallY!");
				cgcso.data.colliderData = new Vector.<Object>();
				cgcso.data.inited = true;
			}
		}
		
		private function getElementState(state:Vector.<uint>, index:uint) : uint {
			var ci:uint = index >>> 5; // chunk index
			var bi:uint = index % 32; // bit position
			return (state[ci] >> bi) & 1;
		}
		
		private function setElementState(state:Vector.<uint>, index:uint, on:uint) : void {
			var ci:uint = index >>> 5; // chunk index
			var bi:uint = index % 32; // bit position
			state[ci] = state[ci] & ~(1 << bi) | (on << bi); 
		}
		
		public function saveTwoDeeArray(array:Array,levelName:String) {
			var nc:uint = array[0].length;  //numColumns
			var nr:uint = array.length;
			trace(nc + ' ' + nr);
			var vectLength:uint = Math.ceil((array[0].length * array.length)/32);
			trace('vectLength: ' + vectLength);
			var tempVect:Vector.<uint> = new Vector.<uint>(vectLength);
			for (var i:uint = 0; i < array.length; i++) {
				for (var j:uint = 0; j < array[0].length; j++) {
					var isTrue:uint = array[i][j];
					setElementState(tempVect,calcIndex(i,j,nc),isTrue);
				}
			}
			var levelGridObj:Object = new Object();
			levelGridObj.name = levelName;
			levelGridObj.nc = nc;
			levelGridObj.nr = nr;
			levelGridObj.grid = tempVect;
			cgcso.data.colliderData.push(levelGridObj);
		}
		
		private function calcIndex(y,x,n) {
			return y*n+x;
		}
		
	}
	
}
