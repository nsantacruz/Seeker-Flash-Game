package seeker {
	
	import flash.display.MovieClip;
	import flash.events.Event;
	
	public class UnitCompass extends MovieClip {
		
		public static const COLOR_INDEXES = ['purple','orange','green','blue','grey'];
		public var color:String;
		/*child order should be 
		-0: purple
		-1: orange
		-2: green
		-3: blue
		-4: grey
		*/
		public function UnitCompass() {
			if (this.name == 'orange') makeVisible('orange'), color = 'orange';
			else if (this.name == 'purple') makeVisible('purple'), color = 'purple';
			else if (this.name == 'green') makeVisible('green'), color = 'green';
			else makeVisible('blue'), color = 'blue';
		}
		
		public function makeVisible(mcName:String) {
			for (var i = 0; i < this.numChildren; i++) {
				this.getChildAt(i).visible = false;
			}
			var tempCompass = this.getChildAt(getIndexByColor(mcName)) as MovieClip;
			tempCompass.visible = true;
			tempCompass.gotoAndPlay(1);
			if (mcName == 'grey') addEventListener(Event.ENTER_FRAME,enterFrame);
			function enterFrame(e) {
				var yo = e.target as UnitCompass;
				var tempGrey = yo.getChildAt(getIndexByColor("grey"));
				if (tempGrey.currentFrame == tempGrey.totalFrames) tempGrey.stop(), removeEventListener(Event.ENTER_FRAME,enterFrame);
			}
		}
		
		public function getIndexByColor(mcColor:String):int {
			for (var i = 0; i < COLOR_INDEXES.length; i++) {
				var tempColor = COLOR_INDEXES[i];
				if (mcColor == tempColor) {
					return i;
				}
			}
			return -1;
		}
	}
}
