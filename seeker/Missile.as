package seeker {
	import flash.display.MovieClip;

	public class Missile extends MovieClip {
		private var rads:Number;
		
		
		public function Missile() {
			rads = 0;
		}
		
		public function set degrees(degs:Number):void {
			rads = degs;
			
		}
		
		public function get degrees():Number {
			return rads;
		}
		
		
	}
}
