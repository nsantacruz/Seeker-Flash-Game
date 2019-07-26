package seeker
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Point;

	public class Compass extends MovieClip
	{
		private var allInstances:Vector.<MovieClip>;
		public var activityIndex:int;
		public var activeCompass:MovieClip;
		private var secretCompass:MovieClip;
		private var it:int,j:int;
		
		public function Compass(mov:MovieClip)
		{
			getAll(mov);
			activityIndex = -1;
			setActive();
		}
		
		public function getAll(mov:MovieClip) {
			allInstances = new Vector.<MovieClip>();
			var tempNum:uint = mov.numChildren;
			trace(tempNum);
			for (it = 0; it < tempNum; it++) {
				var tempChild = mov.getChildAt(it) as UnitCompass;
				if (tempChild.color == 'blue') allInstances.push(tempChild);
				else secretCompass = tempChild;
			}
		}
		
		public function get compasses() {
			return allInstances;
		}
		
		public function checkDistance(cPoint:Point, missilePoint:Point):int {
			var dx = (missilePoint.x - cPoint.x) * (missilePoint.x - cPoint.x);
			var dy = (missilePoint.y - cPoint.y) * (missilePoint.y - cPoint.y);
			var distance = Math.round(Math.sqrt(dx + dy)/10);
			return distance;
		}
		
		public function checkAngle(cPoint:Point,mPoint:Point):Number {
			var tempX = mPoint.x - cPoint.x;
			var tempY = cPoint.y - mPoint.y;
			var tempAngle = Math.atan2(tempY,tempX) * (180/Math.PI);
			if (tempAngle < 0) {
				tempAngle += 360;
			} 
			
			if (tempAngle < 180) {
				tempAngle += 180;
			} else {
				tempAngle -= 180;
			}
			return Math.round(tempAngle);	
		}
		
		public function setActive(st=null) {
			if (activityIndex >= allInstances.length) {
				st.dispatchEvent(new Event('win'));
				return;
			}
			activityIndex++;
			if (activityIndex != allInstances.length) {
				activeCompass = allInstances[activityIndex];
			}
			var tempLength:uint = allInstances.length;
			for (it = 0; it < tempLength; it++) {
				allInstances[it].visible = false;
			}
			for (j = activityIndex-2; j < activityIndex+2; j++) {
				if (!(j < 0) && !(j > allInstances.length-1)) {
					allInstances[j].visible = true;
					if (j == activityIndex) allInstances[j].alpha = 1;
					if (j > activityIndex) allInstances[j].alpha = 0.5;
				}
			}
			
		}
		public function get activeC():MovieClip {
			return activeCompass;
		}
		
		public function checkCollision(m:Missile):Boolean {
			if (secretCompass) {
				if (secretCompass.hitTestObject(m)) {
					secretCompass.makeVisible('grey');
					m.stage.dispatchEvent(new Event('secret'));
					//handle this EVENT!! =O
				}
			}
			if (activeCompass.hitTestObject(m)) {
				activeCompass.makeVisible('grey');
				setActive(m.stage);
				return true;
			}
			return false;
		}
	}
}
