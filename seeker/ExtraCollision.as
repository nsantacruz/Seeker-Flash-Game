package seeker
{
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import Date;


	public class ExtraCollision
	{

		private var vel:int;
		private var timer:Timer;
		private var timerTime:int;
		private var startTime:int;
		private var swfcontent;
		private var lvlName;

		public function ExtraCollision(lvlName:String,swfcontent)
		{
			this.swfcontent = swfcontent;
			this.lvlName = lvlName;
			if (lvlName == "lvl21")
			{
				swfcontent.addEventListener(Event.ENTER_FRAME,yo,false,0,true);
				vel = 20;
			}
			else if (lvlName == "lvl23")
			{
				swfcontent.laser.visible = false;
				timer = new Timer(1450);
				timerTime = 0;
				startTime = (new Date()).getTime();
				timer.addEventListener(TimerEvent.TIMER,shootLaser,false,0,true);
				swfcontent.addEventListener(Event.ENTER_FRAME,preLaser,false,0,true);
				timer.start();

			}
		}

		private function yo(e)
		{
			if (swfcontent.laser.x >= 1180 && vel > 0)
			{
				vel = -20;
			}
			else if (swfcontent.laser.x <= 340 && vel < 0)
			{
				vel = 20;
			}
			swfcontent.laser.x +=  vel;
			trace(swfcontent.laser.x);

		}


		private function shootLaser(e)
		{
			if (swfcontent.laser.visible)
			{
				swfcontent.laser.visible = false;
			}
			else
			{
				swfcontent.laser.visible = true;
			}
			startTime = (new Date()).getTime();
		}
		private function preLaser(e)
		{
			timerTime = (new Date()).getTime() - startTime;
			trace(timerTime);
			swfcontent.beforeLaser.alpha = timerTime / timer.delay * 0.5;
		}
		
		public function pause() {
			if (lvlName == "lvl21") {
				swfcontent.removeEventListener(Event.ENTER_FRAME,yo);
			} else if (lvlName == "lvl23") {
				timer.removeEventListener(TimerEvent.TIMER,shootLaser);
				swfcontent.removeEventListener(Event.ENTER_FRAME,preLaser);
			}
		}
		
		public function unpause() {
			if (lvlName == "lvl21") {
				swfcontent.addEventListener(Event.ENTER_FRAME,yo,false,0,true);
			} else if (lvlName == 'lvl23') {
				timer.addEventListener(TimerEvent.TIMER,shootLaser,false,0,true);
				swfcontent.addEventListener(Event.ENTER_FRAME,preLaser,false,0,true);
			}
		}


	}

}