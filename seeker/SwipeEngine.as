package seeker {
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;

	public class SwipeEngine {
		//speed that the mc slows down after letting go
		public static const FRICTION:Number = 0.9;
		//acceleration mc returns to set boundary
		public static const BOUNDARY_ACCELERATION:Number = 40;
		
		//array that keeps tracks of previous mouseY positions to average later
		private var mouseArrayX:Array;
		private var mouseArrayY:Array;
		//the movieClip being acted upon
		private var mc:MovieClip;
		//the immediately previous mouseY
		private var prevMouseX:Number
		private var prevMouseY:Number;
		//current velocity of mc. only applies when you let go of mouse
		private var mcVX:Number;
		private var mcVY:Number;
		private var clicked:Boolean;
		//a string that keeps track whether or not the mc crossed a min or max and which one. possible values are 'none' 'top' and 'bottom'
		private var fixBoundary:String;
		private var deltaX:Number;
		private var deltaY:Number;
		private var MinX:Number;
		private var MaxX:Number;
		private var MinY:Number;
		private var MaxY:Number;
		public function SwipeEngine(mov:MovieClip,minX:Number,maxX:Number,minY:Number,maxY:Number) {
			clicked = false;
			fixBoundary = 'none';
			mcVX = 0;
			mcVY = 0;
			mc = mov;
			mc.addEventListener(MouseEvent.MOUSE_DOWN,mouseDown,false,0,true);
			mc.addEventListener(MouseEvent.MOUSE_UP,mouseUp,false,0,true);
			mc.addEventListener(MouseEvent.MOUSE_OUT,mouseOut,false,0,true);
			mc.addEventListener(Event.ENTER_FRAME,enterFrame,false,0,true);
			mouseArrayX = [0,0,0,0,0];
			mouseArrayY = [0,0,0,0,0];
			prevMouseX = 0;
			prevMouseY = 0;
			this.MinX = minX;
			this.MaxX = maxX;
			this.MinY = minY;
			this.MaxY = maxY;
		}
		
		private function mouseDown(e:MouseEvent):void {
			clicked = true;
		}
		
		private function mouseOut(e:MouseEvent):void {
			if (clicked)
				mouseUp(e);
		}
		
		private function enterFrame(e:Event):void {
			deltaX = mc.localToGlobal(new Point(mc.mouseX,mc.mouseY)).x - prevMouseX;
			deltaY = mc.localToGlobal(new Point (mc.mouseX,mc.mouseY)).y - prevMouseY;
			prevMouseX = mc.localToGlobal(new Point (mc.mouseX,mc.mouseY)).x;
			prevMouseY = mc.localToGlobal(new Point (mc.mouseX,mc.mouseY)).y;
			mouseArrayX.unshift(deltaX);
			mouseArrayY.unshift(deltaY);
			mouseArrayX.pop();
			mouseArrayY.pop();
			setV();
			if (fixBoundary != 'none') {
				fixBoundaryCollision(fixBoundary);
			}
			checkBoundaries();
		}
		//average the previous mouse positions to get estimate of how fast mc should move
		private function mouseUp(e:MouseEvent):void {
			clicked = false;
			var totalX:Number = 0;
			for (var i:int = 0; i < mouseArrayX.length; i++) {
				totalX += mouseArrayX[i];
			}
			var averageX:Number = totalX/mouseArrayX.length;
			mcVX = averageX;
			
			var totalY:Number = 0;
			for (var j:int = 0; j < mouseArrayY.length; j++) {
				totalY += mouseArrayY[j];
			}
			var averageY:Number = totalY/mouseArrayY.length;
			mcVY = averageY;
		}
		
		// if clicked, only follow mouse. otherwise, use average and slowly decrease it
		private function setV():void {
			if (clicked) {
				mc.y += deltaY;
				mc.x += deltaX;
			} else {
				mcVX *= FRICTION;
				mcVY *= FRICTION;
				//once below a certain point, it may as well be zero
				if (Math.abs(mcVX) <= 0.05) {
					mcVX = 0;
				}
				if (Math.abs(mcVY) <= 0.05) {
					mcVY = 0;
				}
				mc.x += mcVX
				mc.y += mcVY;
			}
		}
		//check whether the mc passed either boundary
		private function checkBoundaries() {
			if (mc.y > MaxY) {
				fixBoundary = 'top';
			}
			if ((mc.y + mc.height) < MinY) {
				fixBoundary = 'bottom';
			}
			if (mc.x > MaxX) {
				fixBoundary = 'left';
			}
			if ((mc.x + mc.width) < MinX) {
				fixBoundary = 'right';
			}
		}
		//oposite of previous function. check whether or not the acceleration added to mc is too much. if so set it to the boundary and set mcV to zero
		private function fixBoundaryCollision(dir:String) {
			if (dir == 'top') {
				if (mc.y < MaxY) {
					mc.y = MaxY;
					mcVY = 0;
					fixBoundary = 'none';
				} else {
					mcVY -= BOUNDARY_ACCELERATION;
				}
			} else if (dir == 'bottom') {
				if ((mc.y + mc.height) > MinY) {
					mc.y = MinY - mc.height;
					mcVY = 0;
					fixBoundary = 'none';
				} else {
					mcVY += BOUNDARY_ACCELERATION;
				}
			} else if (dir == 'left') {
				if (mc.x < MaxX) {
					mc.x = MaxX;
					mcVX = 0;
					fixBoundary = 'none';
				} else {
					mcVX -= BOUNDARY_ACCELERATION;
				}
			} else if (dir == 'right') {
				if ((mc.x + mc.width) > MinX) {
					mc.x = MinX - mc.width;
					mcVX = 0;
					fixBoundary = 'none';
				} else {
					mcVX += BOUNDARY_ACCELERATION;
				}
			}
		}
		
		public function destroy() {
			mc.removeEventListener(MouseEvent.MOUSE_DOWN,mouseDown);
			mc.removeEventListener(MouseEvent.MOUSE_UP,mouseUp);
			mc.removeEventListener(MouseEvent.MOUSE_OUT,mouseOut);
			mc.removeEventListener(Event.ENTER_FRAME,enterFrame);
			trace("DESTROYED");
		}
	}
}