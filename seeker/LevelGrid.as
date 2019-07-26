package seeker
{
	import flash.display.Shape;
	import flash.display.MovieClip;
	import flash.geom.Point;

	public class LevelGrid extends MovieClip
	{
		public static const INCREMENT:uint = 480;
		public static const ANGLE_ARRAY:Vector.<Array> = Vector.<Array>([[1,0],[1,-1],[0,-1],[0,0],[1,1],[0,1],[-1,1],[-1,0],[-1,-1],[2,0],[2,1],[2,-1],[-1,-2],[0,-2],[1,-2],[-2,1],[-2,0],[-2,-1],[-1,2],[0,2],[1,2]]);
		public static const A_ARRAY_L = ANGLE_ARRAY.length;
		private var w:uint;
		private var h:uint;
		private var theGrid:Array;
		private var level:MovieClip
		private var allInstances:Array;
		private var angleArray:Array;
		private var prevVisArray:Array;
		private var it:uint,j:uint;
		
		public function LevelGrid(lvl:MovieClip) {
			prevVisArray = new Array();
			level = lvl;
			w = Math.ceil(lvl.width/INCREMENT);
			h = Math.ceil(lvl.height/INCREMENT);
			theGrid = new Array(w);
			for (it = 0; it < w; it++) {
				theGrid[it] = new Array(h);
			}
			setBoxes();
			//trace('w ' + w + ' h '+ h);
			//makeAllInvisible();
		}
		
		public function getCoords(mPoint:Point) {
			var tempX = Math.round(mPoint.x/INCREMENT);
			var tempY = Math.round(mPoint.y/INCREMENT);
			return new Point(tempX,tempY);
		}
		
		public function setBoxes() {
			getInstances();
			var tempLength = allInstances.length;
			for (it = 0; it < tempLength; it++) {
				var tempBox = allInstances[it];
				var tempX:int = Math.round(tempBox.x/INCREMENT);
				var tempY:int = Math.round(tempBox.y/INCREMENT);
				//trace(tempX + ' ' + tempY);
				theGrid[tempX][tempY] = tempBox;
			}
		}
		
		public function getInstances() {
			allInstances = new Array();                        //Change to vector when done converting...
			var tempNum = level.numChildren;
			for (it = 0; it < tempNum; it++) {
				allInstances.push(level.getChildAt(it));
			}
		}
		
		private function checkValidCoords(coord:Point) {
			var lengthX = theGrid.length;
			var lengthY = theGrid[0].length;
			if ((coord.x >= lengthX) || (coord.x < 0) 
				|| (coord.y >= lengthY) || (coord.y < 0)) {
				return false
			}
			return true;
		}
		
		public function getVisibleBoxes(mPoint:Point):Array {
			if (!checkValidCoords(getCoords(mPoint))) {
				return new Array();
			}
			var currentCoords = getCoords(mPoint);
			var visibleArray = new Array();
			for (it = 0; it < A_ARRAY_L; it++) {
				var deltaX = ANGLE_ARRAY[it][0];
				var deltaY = ANGLE_ARRAY[it][1];
				if (!checkValidCoords(new Point(currentCoords.x + deltaX, currentCoords.y + deltaY))) {
					continue
				}
				visibleArray.push(new Point(currentCoords.x + deltaX, currentCoords.y + deltaY));
			}
			return visibleArray;
		}
		
		public function makeAllInvisible() {
			var tempGridL = theGrid.length
			for (it = 0; it < tempGridL; it++) {
				var tempGridIL = theGrid[it].length;
				for (j = 0; j < tempGridIL; j++) {
					theGrid[it][j].visible = false;
				}
			}
		}
		
		public function setVisibleBoxes(visArray:Array) {
			var tempPrevVisL = prevVisArray.length;
			for (it = 0; it < tempPrevVisL; it++) {
				theGrid[prevVisArray[it].x][prevVisArray[it].y].visible = false;
			}
			var tempVisArrayL = visArray.length
			for (j = 0; j < tempVisArrayL; j++) {
				theGrid[visArray[j].x][visArray[j].y].visible = true;
			}
			prevVisArray = visArray;
		}
	}
}