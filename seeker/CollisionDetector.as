package seeker
{
	import flash.display.Shape;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Point;

	public class CollisionDetector extends MovieClip
	{
		private static const COLL_RADIUS = 4.5;
		public static const LARGE_INCREMENT:uint = 9;
		public static const SMALL_INCREMENT:uint = 3; //BETA: used for moving zoom...
		public static const RADIUS:uint = 8;
		private var nc:uint;
		private var nr:uint;
		private var theGrid:Vector.<uint>;
		private var bigCollider:MovieClip;
		public var extraColl:Boolean;
		public var extraObj:ExtraCollision;
		private var tunnelCoords:Vector.<uint>;
		private var it:int,j:int,k:int;
		public var increment:uint;
		
		public function CollisionDetector(collArray:Vector.<uint>,nc:uint,nr:uint,lvlName:String = null,extra:MovieClip = null, swfcontent = null) {
			tunnelCoords = new Vector.<uint>();
			theGrid = collArray;
			this.nc = nc;  //which is basically width
			this.nr = nr;  //which is height
			extraColl = false;
			increment = LARGE_INCREMENT;
			if (extra) {
				if (extra.hit) {
					extra.hit.visible = false; //lvl21 has a separate hit area
					bigCollider = extra.hit;
				} else {
					bigCollider = extra;
				}
				extraColl = true;
				extraObj = new ExtraCollision(lvlName,swfcontent);
			}
		}
		
		public function setTunnelCollisions(lvl:MovieClip,tunnel:MovieClip) {
			var tempNum = tunnel.numChildren;
			for (it = 0; it < tempNum; it++) {
				var tempChild = tunnel.getChildAt(it);
				var tempGlobalPoint:Point = tunnel.localToGlobal(new Point(tempChild.x,tempChild.y));
				var tempLocalPoint:Point = lvl.globalToLocal(tempGlobalPoint);
				tempLocalPoint.x = Math.round(tempLocalPoint.x/increment);
				tempLocalPoint.y = Math.round(tempLocalPoint.y/increment);
				var tunnelCombo:uint = (tempLocalPoint.x*100000) + tempLocalPoint.y; //combine to create unique number, multiply by really big num
				tunnelCoords.push(tunnelCombo);
				setElementState(theGrid,calcIndex(tempLocalPoint.y,tempLocalPoint.x,nc),1);
			}
		}
		
		public function checkCollisions(collArray:Array,pointArray:Array,missile:Missile,globalCorners:Vector.<Point>) {
			var collided:Boolean = false
			var collLength = collArray.length;
			for (it = 0; it < collArray.length && !collided; it++) {
				var tempColl:Point = collArray[it];
				var tempX = tempColl.x;
				var tempY = tempColl.y;
				var tempUnique:uint = ((tempX/increment)*100000) + (tempY/increment);
				var pointLength:uint = pointArray.length;
				for (j = 0; j < pointLength; j++) {
					var tempPoint = pointArray[j];
					var xSquare = (tempX - tempPoint.x) * (tempX - tempPoint.x);
					var ySquare = (tempY - tempPoint.y) * (tempY - tempPoint.y);
					if (Math.sqrt(xSquare + ySquare) <= COLL_RADIUS && tunnelCoords.indexOf(tempUnique) != -1) {
						collided = true;
						return 'tunnel';
					} else if (Math.sqrt(xSquare + ySquare) <= COLL_RADIUS) {
						collided = true;
						return 'collided';
					}
				}
			}
			
			if (extraColl) {
				for (k = 0; k < globalCorners.length; k++) {
					if (bigCollider.hitTestPoint(globalCorners[k].x,globalCorners[k].y,true) && (bigCollider.visible || bigCollider.name == 'hit')) {
						return 'collided';
					}
				}
			}
			return 'no collision';
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
		
		private function calcIndex(y,x,n) {
			return y*n+x;
		}
		
		public function getSurroundingCircles(X,Y):Array {
			var tempX:uint = Math.round(X/increment) - 1;
			var tempY:uint = Math.round(Y/increment) - 1;
			var surroundArray:Array = new Array();
			for (it = -RADIUS; it <= RADIUS; it++) {
				if ((tempX + it) >= (nc) || (tempX + it) < 0) {
					continue;
				}
				for(j = -RADIUS; j <= RADIUS; j++) {
					if ((tempY + j) >= (nr) || (tempY + j) < 0) {
						continue;
					}
					var tempElement:uint = getElementState(theGrid,calcIndex(tempY+j,tempX+it,nc));
					if (tempElement == 1) {                   
						surroundArray.push(new Point((tempX + it)*increment,(tempY + j)*increment));	
					}
				}
			}
			return surroundArray;
		}
	}
}
