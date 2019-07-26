package seeker {
	//debug
	//import com.demonsters.debugger.MonsterDebugger;
	//
	import com.greensock.events.LoaderEvent;
	import com.greensock.loading.*;
	import com.jacksonkr.ui.IOSScrollArea;
	
	import fl.motion.MatrixTransformer;
	
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.events.*;
	import flash.events.TransformGestureEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.net.SharedObject;
	import flash.net.URLRequest;
	import flash.utils.*;
	import flash.ui.Multitouch;
	import flash.ui.MultitouchInputMode;
	import flash.text.TextField;
	
	public class Main extends MovieClip {
		public static const MISSILE_X:uint = 160;
		public static const MISSILE_Y:uint = 200;
		public static const MISSILE_POINT:Point = new Point(MISSILE_X,MISSILE_Y);
		private var RAD_V = 0.2;
		private var MISSILE_V:uint = 15;
		public static const FLAMES_D:uint = 24;
		//real x coords of corners is 121 but to make collision detection a bit less annoying...
		public static const MISSILE_CORNERS:Vector.<Point> = Vector.<Point>([new Point(165,189.5),new Point(165,210.5),new Point(199,210.5),new Point(199,189.5)]);
		public static const BOUNDARY_RADIUS:uint = 300;
		public static const BRAKE_OUT:uint = 0;
		public static const BRAKE_IN:uint = 45;
		public static const NUM_EXPLOSIONS:uint = 6;
		//load
		private var loader:SWFLoader, swfcontent:MovieClip, theswf:String, loaded:Boolean, currLvl:String, swipeEngine:SwipeEngine;
		//missile/accesories
		private var flames:Vector.<MovieClip>, degsList:Vector.<Number>, missile:Missile,deltaDegs:Number;
		//score
		private var score:uint, pauseScore:uint, scoreDate:Date, scoreInit:uint;
		//collision/grids
		private var boundaryHit:Boolean, collider:CollisionDetector, tunnelTimer:Timer, levelGrid:LevelGrid, compassGrid:Compass, collisionStatus:String;
		//brakes
		private var braking:Boolean, brakeInit:Boolean, brakeOut:Boolean;
		//feedback strings
		private var winStringArray:Vector.<String>, loseStringArray:Vector.<String>, secretsStringArray:Vector.<String>;
		//hud and stuff
		private var paused:Boolean, beforeZoomMatrix, hudFadeTimer:Timer, xrayOn:Boolean;
		//for loops
		private var it:uint,j:uint,k:uint;
		//random
		private var explosionArray:Vector.<Explosion>;
		private var playingTunnel:Boolean;
		private var tunnelDirection:String;
		private var currSignRotation = '+';
		private var currQuadrant = 1;
		//debug
		private var swfArray:Vector.<String>;
		//temp colliderController stuff
		private var cgc
		private var cgcso:ColliderGrids;
		
		public static var INPUT_METHOD = "mouse";
		
		public function Main() {
			addEventListener('prepareGame',startListener, false, 0, true);
			//debug
			swfArray = Vector.<String>(['lvl1.swf','lvl2.swf','lvl3.swf','lvl4.swf','lvl5.swf','lvl6.swf','lvl7.swf','lvl8.swf','lvl9.swf','lvl10.swf','lvl11.swf','lvl12.swf'
			,'lvl13.swf','lvl14.swf','lvl15.swf','lvl16.swf','lvl17.swf','lvl18.swf','lvl19.swf','lvl20.swf','lvl21.swf','lvl22.swf','lvl23.swf']);
			//MonsterDebugger.initialize(this);
			//
			//winStringArray = Vector.<String>(['You Won!','Barely Made It','Lucky','=D','Smooth','Took you long enough','Good job, Nerd','B)','That\'s a win!','Seeker FTW','The next level is impossible','Yo, sweet stuff!']);
			//loseStringArray = Vector.<String>(['You Crashed (duh)','N00B','You\'re an alchoholic','pwned','Turns out you\'re flamable',':@','...','You have failed me',':o','That\'s a Fail','No one was looking','This isn\'t rocket science','What a bunch of balls!','Stop throwing up, bro']);
			winStringArray = Vector.<String>(['You Won!']);
			loseStringArray = Vector.<String>(['You Crashed!']);
			secretsStringArray = Vector.<String>(['Oooh, shiny','It took you how long?','Found it!','That\'s where I put it','Time for an upgrade']);
			theswf = '';
			explosionArray = new Vector.<Explosion>;
			PersistantStorage.init();
			//cgc
			cgc = new ColliderGridController();
			cgcso = new ColliderGrids();
			//cgc.saveTwoDeeArray(,'lvl17');
			
		}

		private function toggleInput(e) {
			if (INPUT_METHOD == 'mouse') INPUT_METHOD = 'keyboard';
			else if (INPUT_METHOD == 'keyboard') INPUT_METHOD = 'mouse';
			trace(INPUT_METHOD);
		}
		//1a----FIRST STEP IN LOADING
		//used when loading swf lvl. captures loaded swf and sets it to class var. this is called in frame 3 in playUp()
		public function setSWF(swf:String) {
			theswf = swf;
			currLvl = swf.split('.')[0];
			//trace(currLvl);
			//trace(so.data.levels[currLvl].won);
			//trace(so.data.levels[currLvl].lowScore);
		}
		//1b----SECOND STEP IN LOADING
		//dispatched when game is loading (currently frame 10). Initializes actual loading
		private function startListener(e:Event):void {
			if (theswf != '') {
				loadSWF(theswf,lvl);
			} else {
				trace('swf not set fool!');
			}
		}
		//1c----THIRD STEP IN LOADING
		//Start loading full level. This starts at minilevel screen. Uses SWFLoader (third party). Hopefully more memory efficient...
		private function loadSWF(swf,mov) {
			loader = new SWFLoader(swf, 
				{container:mov, alpha:1, onComplete:completeHandler, onError:errorHandler});
			loader.load();
		}
		//1d----FOURTH STEP IN LOADING
		//Finish loading full level, ready to hit final play button and start game
		private function completeHandler(e:LoaderEvent):void{
			if (loadingText) { //this refers to text 'loading'
				loadingText.visible = false;
				playBtn.visible = true;
				playBtn.addEventListener(MouseEvent.MOUSE_DOWN,playDown, false, 0, true);
				function playDown(e) {
					playBtn.gotoAndStop(2);
					playBtn.addEventListener(MouseEvent.MOUSE_UP,playUp, false, 0, true);
					
				}
				function playUp(e) {
					playBtn.removeEventListener(MouseEvent.MOUSE_UP,playUp);
					playBtn.removeEventListener(MouseEvent.CLICK,playDown);
					swipeEngine.destroy();
					playBtn.visible = false;
					init();
				}
			} else {
				init();
			}
		}
		//2----INITIALIZE GAME
		//
		private function init() {
			gotoAndStop('game');
			addEventListener(Event.ENTER_FRAME,onEnter, false, 0, true);
			tunnelTimer = new Timer(500,1);
			hudFadeTimer = new Timer(3000,1);
			hudFadeTimer.addEventListener(TimerEvent.TIMER,hudFade, false, 0, true);
			hudFadeTimer.start();
			missile = new Missile();
			missile.x = MISSILE_X;
			missile.y = MISSILE_Y;
			missile.gotoAndStop(PersistantStorage.so.data.currMissile);
			addChild(missile);
			warningText.backgroundColor = 0xF8931C;
			//initialize class vars
			flames = new Vector.<MovieClip>();
			flames.push(addons.fl1,addons.fl2,addons.fl3,addons.fl4);
			for (it = 0; it < flames.length; it++) {
				flames[it].gotoAndStop(PersistantStorage.so.data.currFlame);
			}
			initVariableVars();
			//add listeners to hud
			stage.addEventListener(KeyboardEvent.KEY_DOWN,brakeDown, false, 0, true);
			stage.addEventListener(KeyboardEvent.KEY_DOWN,zoomDown, false, 0, true);
			stage.addEventListener(KeyboardEvent.KEY_DOWN,xrayDown,false,0,true);
			stage.addEventListener(KeyboardEvent.KEY_DOWN,keySteer,false,0,true);
			this.addEventListener(MouseEvent.MOUSE_DOWN,gameClick, false, 0, true);
			missile.stage.addEventListener('win',winHandler, false, 0, true);
			stage.addEventListener('lose',loseHandler, false, 0, true);
			stage.addEventListener('secret',winHandler,false,0,true);
			stage.addEventListener('won game',wonGameHandler,false,0,true);
			addons.flap1.visible = false;
			addons.flap2.visible = false;
			pauseMenu.visible = false;
			xrayOverlay.visible = false;
			if (!PersistantStorage.so.data.wonGame) hud.xray.visible = false;
			//1e----REALLY FINISH LOADING
			//get loaded content
			swfcontent = loader.rawContent;
			swfcontent.gotoAndStop(1);
			var colliderDataObj:Object = findColliderData();
			var colliderGrid = colliderDataObj.grid;
			//triggers onEnter to start working
			loaded = true;
			//beta code for secret levels
			if (colliderDataObj.extraCollision) collider = new CollisionDetector(colliderGrid,colliderDataObj.nc,colliderDataObj.nr,colliderDataObj.name,swfcontent.laser,swfcontent);
			else collider = new CollisionDetector(colliderGrid,colliderDataObj.nc,colliderDataObj.nr);
			swfcontent.tunnelGrid.visible = false;
			missile.cacheAsBitmap = true;
			//initialize collision system
			collider.setTunnelCollisions(swfcontent.level,swfcontent.tunnelGrid);               
			compassGrid = new Compass(swfcontent.compasses);
			levelGrid = new LevelGrid(swfcontent.level);
			//draw boundary rectangles for levels
			var boundaryRect:Shape = new Shape();
			var swflevel = swfcontent.level;
			swfcontent.level.addChild(boundaryRect);
			boundaryRect.graphics.lineStyle(5, 0x00FF00, 1,false,"normal",null,"miter");
			boundaryRect.graphics.drawRect(300, 300, swflevel.width-600,  swflevel.height-600);
			
		}
		//3----PLAY GAME
		//I-level rotation |||| II-tunnel animation |||| III-update score
		//IV-braking |||| V-compasses |||| VI-levelgrid |||| VII-collision detection
		private function onEnter(e:Event):void {
			if (loaded) {
				lvl.x -= MISSILE_V;
				//I----level rotation
				if (INPUT_METHOD == 'mouse') {
					var mX = mouseX - MISSILE_X;
					var mY = mouseY - MISSILE_Y;
					deltaDegs = -1 * Math.atan(mY/mX)*(180/Math.PI);
					if (deltaDegs < 0 && currSignRotation == '+') {
						currSignRotation = '-';
						//not random. in order to prove which quadrant you switched to. e.g. now in 2nd if originally in 1st
						if (Math.abs(deltaDegs) > 45) currQuadrant += 1; 
							else currQuadrant += 3;
					} else if (deltaDegs >= 0 && currSignRotation == '-') {
						currSignRotation = '+';
						if (Math.abs(deltaDegs) > 45) currQuadrant += 3;
							else currQuadrant += 1;
					}
					if (currQuadrant > 4) currQuadrant -= 4;
					deltaDegs *= RAD_V;
					//make deltaRotation max if in 2nd or 3rd quadrant
					if (currQuadrant == 2) deltaDegs = 18;
					else if (currQuadrant == 3) deltaDegs = -18;
				}
				//accounting for the arctan() issue...
				missile.degrees = deltaDegs;


				checkBoundary();
				if (!boundaryHit) {
					hud.nArrow.rotation -= missile.degrees;
				}
				var matrix:Matrix = lvl.transform.matrix;
				MatrixTransformer.rotateAroundExternalPoint(matrix, MISSILE_X, MISSILE_Y, missile.degrees);
				lvl.transform.matrix = matrix;
				
				//II----tunnel animation
				if (playingTunnel) {
					if (swfcontent.currentFrame == 11) {
						swfcontent.stop();
						playingTunnel = false;
					} else if (swfcontent.currentFrame == 20) {
						swfcontent.gotoAndStop(1);
						playingTunnel = false;
					}
				}
				//III----update score
				score = (new Date().getTime()) - scoreInit;
				score = Math.round((score/20))*10 + pauseScore;
				scoreText.text = String(score);
				animateFlames();
				//IV----braking
				if (braking) {
					if (!(hud.brakeMask.height - 6 < 0)) {
						hud.brakeMask.height -= 6;
						MISSILE_V = 8;
						RAD_V = 0.12;
						addons.fl4.visible = false;
						addons.flap1.visible = true;
						addons.flap2.visible = true;
						if (brakeInit) {
							rotateTo(addons.flap2,-BRAKE_IN,BRAKE_OUT);
							rotateTo(addons.flap1,BRAKE_IN,BRAKE_OUT);
						}
						brakeInit = false;
						//fl3.visible = false
					} else {
						MISSILE_V = 15;
						RAD_V = 0.2;
						braking = false;
						rotateTo(addons.flap1,BRAKE_OUT,BRAKE_IN,true);
						rotateTo(addons.flap2,BRAKE_OUT,-BRAKE_IN,true);
						addons.fl4.visible = true;
						//fl3.visible = true;
					}
				} else {
					MISSILE_V = 15;
					RAD_V = 0.2;
					if (brakeOut) {
						rotateTo(addons.flap1,BRAKE_OUT,BRAKE_IN,true);
						rotateTo(addons.flap2,BRAKE_OUT,-BRAKE_IN,true);
					}
					brakeOut = false;
					addons.fl4.visible = true;
					//fl3.visible = true;
					if (!(hud.brakeMask.height + 3 > 300)) {
						hud.brakeMask.height += 3;
					}
				}
				//V----compasses
				var localCompassPoint:Point = new Point(compassGrid.activeC.x, compassGrid.activeC.y);
				var globalCompassPoint:Point = swfcontent.compasses.localToGlobal(localCompassPoint);
				var compassDistance = compassGrid.checkDistance(globalCompassPoint,MISSILE_POINT);
				var compassAngle = compassGrid.checkAngle(globalCompassPoint,MISSILE_POINT);
				var compassCollided = compassGrid.checkCollision(missile);
				addons.compassArrow.rotation = -1 * compassAngle;
				addons.compassArrow.aText.text = String(compassDistance);
				compassText.text = String((compassGrid.activityIndex) +'/'+compassGrid.compasses.length);
				//VI----levelgrid
				var localLevelPoint:Point = swfcontent.level.globalToLocal(MISSILE_POINT);
				var visibleArray:Array = levelGrid.getVisibleBoxes(localLevelPoint);
				levelGrid.setVisibleBoxes(visibleArray);
				//VII----collision detection
				var localCorners = new Array();
				var MCL:uint = MISSILE_CORNERS.length;
				for (it = 0; it < MCL; it++) {
					localCorners.push(swfcontent.level.globalToLocal(MISSILE_CORNERS[it]));
				}
				var localMissile:Point = swfcontent.level.globalToLocal(MISSILE_POINT);
				var collisionArray:Array = collider.getSurroundingCircles(localMissile.x,localMissile.y);
				collisionStatus = collider.checkCollisions(collisionArray,localCorners,missile,MISSILE_CORNERS);
				if (collisionStatus == 'collided') { //crashed
					missile.visible = false;
					for (j = 0; j < NUM_EXPLOSIONS; j++) {
						var tempExp = new Explosion();
						tempExp.x = (MISSILE_X+39)+(Math.random()*100-40);
						tempExp.y = (MISSILE_Y)+(Math.random()*70-35);
						addChild(tempExp);
						explosionArray.push(tempExp);
					}
					pause();
					
				} 
				if (collisionStatus == 'tunnel' && tunnelTimer.running == false) { //hit tunnel after specified timelimit
						swfcontent.addEventListener(Event.ENTER_FRAME,animateTunnel,false,0,true);
						function animateTunnel(e) {
							if (tunnelDirection == "forward") {
								e.target.nextFrame();
								if (e.target.currentFrame == e.target.totalFrames) {
									e.target.stop();
									e.target.removeEventListener(Event.ENTER_FRAME,animateTunnel);
								}
							} else if (tunnelDirection == "reverse") {
								e.target.prevFrame();
								if (e.target.currentFrame == 1) {
								       	e.target.stop();
									e.target.removeEventListener(Event.ENTER_FRAME,animateTunnel);
								}
							}
						}
						playingTunnel = true;
						if (swfcontent.currentFrame == 1) tunnelDirection = "forward";
						else if (swfcontent.currentFrame == swfcontent.totalFrames) tunnelDirection = "reverse";
						tunnelTimer.start();
				}
			}
		}
		/*3----EVENT HANDLERS
		II-winHandler |||| III-loseHandler
		IV-gameClick |||| V-pauseDown |||| VI-pauseUp
		VII-errorHandler |||| VIII-brakeDown |||| IX-brakeUp
		X-zoomDown |||| XI-zoomUp |||| XII-hudFade |||| XIII-removeAllListeners
		*/
		//II----winHandler
		private function winHandler(e:Event):void {
			pause();
			hud.visible = false;
			addons.visible = false;
			missile.visible = false;
			pauseMenu.visible = true;
			pauseMenu.resume.visible = false;
			xrayOverlay.visible = false;
			pauseMenu.restart.addEventListener(MouseEvent.MOUSE_DOWN,pauseDown, false, 0, true);
			pauseMenu.home.addEventListener(MouseEvent.MOUSE_DOWN,pauseDown, false, 0, true);
			var randIndex;
			if (e.type == 'win') {
				//only make 'next' visible if you win
				pauseMenu.next.visible = true;
				pauseMenu.next.addEventListener(MouseEvent.MOUSE_DOWN,pauseDown,false,0,true);
				PersistantStorage.saveData(true,currLvl,score);
				PersistantStorage.levelsWon = PersistantStorage.checkLevelsWon(missile.stage);
				//trace(so.data.levels[currLvl].lowScore);
				randIndex = Math.round(Math.random()*(winStringArray.length-1));
				warningText.text = winStringArray[randIndex];
				warningText.background = true;
			} else if (e.type == 'secret') {
				//do something
				PersistantStorage.saveData(false,currLvl);
				randIndex = Math.round(Math.random()*(secretsStringArray.length-1));
				warningText.text = secretsStringArray[randIndex];
				warningText.background = true;
			}
		}

		private function wonGameHandler(e:Event):void {
			trace("yay! you won!");
		}
		//III----loseHandler
		private function loseHandler(e:Event):void {
			var randIndex = Math.round(Math.random()*(loseStringArray.length-1));
			warningText.text = loseStringArray[randIndex];
			warningText.background = true;
			
			hud.visible = false;
			addons.visible = false;
			missile.visible = false;
			pauseMenu.visible = true;
			pauseMenu.resume.visible = false;
			pauseMenu.next.visible = false;
			xrayOverlay.visible = false;
			pauseMenu.restart.addEventListener(MouseEvent.MOUSE_DOWN,pauseDown, false, 0, true);
			pauseMenu.home.addEventListener(MouseEvent.MOUSE_DOWN,pauseDown, false, 0, true);
		}
		//IV----gameClick
		//activated when game screen is clicked and NOT anything else. pause game
		private function gameClick(e:MouseEvent):void {
			var name = e.target.name;
			if (name != 'hud' && name != 'brake' && name != 'xray' && name != 'resume' && name != 'restart' && name != 'home' && name != 'next') {
				if (paused) {
					
				} else {
					pause();
					pauseMenu.visible = true;
					pauseMenu.resume.visible = true;
					pauseMenu.next.visible = false;
					missile.visible = false;
					pauseMenu.resume.addEventListener(MouseEvent.MOUSE_DOWN,pauseDown, false, 0, true);
					pauseMenu.restart.addEventListener(MouseEvent.MOUSE_DOWN,pauseDown, false, 0, true);
					pauseMenu.home.addEventListener(MouseEvent.MOUSE_DOWN,pauseDown, false, 0, true);
				}	
			}
		}
		//V----pauseDown
		private function pauseDown(e:MouseEvent):void {
			e.target.gotoAndStop(2);
			e.target.addEventListener(MouseEvent.MOUSE_UP,pauseUp, false, 0, true);
		}
		//VI----pauseUp
		private function pauseUp(e:MouseEvent):void {
			e.target.gotoAndStop(1);
			e.target.removeEventListener(MouseEvent.MOUSE_UP,pauseUp);
			var name = e.target.name;
			if (name == 'resume' || name == 'restart' || name == 'next') {
				unpause();
				hud.visible = true;
				addons.visible = true;
				missile.visible = true;
				pauseMenu.resume.removeEventListener(MouseEvent.MOUSE_DOWN,pauseDown);
				pauseMenu.restart.removeEventListener(MouseEvent.MOUSE_DOWN,pauseDown);
				pauseMenu.home.removeEventListener(MouseEvent.MOUSE_DOWN,pauseDown);
				pauseMenu.visible = false;
				if (name == 'restart') {
					restart();
				} else if (name == 'next') {
					restart(true);	
				}
			} else if (name == 'home') {
				unpause();
				pauseMenu.resume.removeEventListener(MouseEvent.MOUSE_DOWN,pauseDown);
				pauseMenu.next.removeEventListener(MouseEvent.MOUSE_DOWN,pauseDown);
				pauseMenu.restart.removeEventListener(MouseEvent.MOUSE_DOWN,pauseDown);
				pauseMenu.home.removeEventListener(MouseEvent.MOUSE_DOWN,pauseDown);
				removeAllListeners();
				loaded = false;
				removeChild(missile);
				degsList = Vector.<Number>([0,0,0,0]);
				loader.unload();
				gotoAndStop('playBtn');
			}
			/*hud.visible = false;
			addons.visible = false;
			missile.visible = false;*/
		}
		//VII----errorHandler
		private function errorHandler(e):void {
			trace('this sucks!');
		}
		//VIII----brakeDown
		private function brakeDown(e:KeyboardEvent):void {
			if (e.keyCode == 16 && !braking) { //shift
				undoHUDFade();
				braking = true;
				brakeInit = true;
				stage.addEventListener(KeyboardEvent.KEY_UP,brakeUp, false, 0, true);
			} 
		}
		//IX----brakeUp
		private function brakeUp(e:KeyboardEvent):void {
			if (e.keyCode == 16) {
				hudFadeTimer.start();
				braking = false;
				brakeOut = true;
				stage.removeEventListener(KeyboardEvent.KEY_UP,brakeUp);
			}  
		}

		private function zoomDown(e:KeyboardEvent):void {
			if (!paused && e.keyCode == 90) { //z
				pause();
				addons.visible=true;
				beforeZoomMatrix = lvl.transform.matrix;
				var lvlR = lvl.rotation;
				var matrix:Matrix = lvl.transform.matrix;
				MatrixTransformer.rotateAroundExternalPoint(matrix, MISSILE_X, MISSILE_Y, -lvlR);
				lvl.transform.matrix = matrix;
				var lvlX = lvl.x;
				var lvlY = lvl.y;
				lvl.scaleX = 0.5;
				lvl.scaleY = 0.5;
				lvl.x = (lvlX)/2+80;
				lvl.y = (lvlY)/2+80;
				var matrix2:Matrix = lvl.transform.matrix;
				MatrixTransformer.rotateAroundExternalPoint(matrix2, MISSILE_X, MISSILE_Y, lvlR);
				lvl.transform.matrix = matrix2;
				missile.scaleX = 0.5;
				missile.scaleY = 0.5;
				missile.x = MISSILE_X;
				missile.y = MISSILE_Y;
				stage.addEventListener(KeyboardEvent.KEY_UP,zoomUp, false, 0, true);
			}
		}

		private function zoomUp(e:KeyboardEvent):void {
			if (paused && e.keyCode == 90) {
				lvl.transform.matrix = beforeZoomMatrix;
				missile.scaleX = 1;
				missile.scaleY = 1;
				missile.x = MISSILE_X;
				missile.y = MISSILE_Y;
				unpause();
				stage.removeEventListener(KeyboardEvent.KEY_UP,zoomUp);
			}
		}
		//XII----hudFade
		private function hudFade(e:TimerEvent):void {
			addEventListener(Event.ENTER_FRAME,fadeEnter, false, 0, true);
			function fadeEnter(e:Event):void {
				if (!(hud.alpha <= 0.3)) {
					hud.alpha -= 0.1;
				} else {
					removeEventListener(Event.ENTER_FRAME,fadeEnter);
				}
			}
		}
		//XIII----removeAllListeners
		private function removeAllListeners() {
			this.removeEventListener(MouseEvent.MOUSE_DOWN,gameClick);
			stage.removeEventListener(KeyboardEvent.KEY_DOWN,brakeDown);
			stage.removeEventListener(KeyboardEvent.KEY_DOWN,zoomDown);
			stage.removeEventListener(KeyboardEvent.KEY_DOWN,xrayDown);
			stage.removeEventListener(KeyboardEvent.KEY_DOWN,keySteer);
			hudFadeTimer.removeEventListener(TimerEvent.TIMER,hudFade);
			missile.stage.removeEventListener('win',winHandler);
			stage.removeEventListener('won game',wonGameHandler);
			this.removeEventListener('lose',loseHandler);
			removeEventListener(Event.ENTER_FRAME,onEnter);
		}
		//XIV----xrayDown
		private function xrayDown(e:KeyboardEvent):void {
			undoHUDFade();
			hudFadeTimer.start();
			if (xrayOn && e.keyCode == 88) { //x
				xrayOn = false;
				hud.xray.gotoAndStop(1);
				xrayOverlay.visible = false;
				if (swfcontent.xray) swfcontent.xray.visible = true;
			}
			else if (e.keyCode == 88 && PersistantStorage.so.data.wonGame){
				xrayOn = true;
				hud.xray.gotoAndStop(2);
				xrayOverlay.visible = true;
				if (swfcontent.xray) swfcontent.xray.visible = false;
			}
		}

		private function keySteer(e:KeyboardEvent):void {
			if (INPUT_METHOD == 'keyboard') {
				if (e.keyCode == 38) { //up
					deltaDegs = 6;	
					stage.addEventListener(KeyboardEvent.KEY_UP,steerUp);
				} else if (e.keyCode == 40) { //down
					deltaDegs = -6;
					stage.addEventListener(KeyboardEvent.KEY_UP,steerUp);
				}
			}
		}

		private function steerUp(e:KeyboardEvent):void {
			if (e.keyCode == 38 || e.keyCode == 40) {
				deltaDegs = 0;
			}
		}
		
		private function animateFlames() {
			degsList.unshift(missile.degrees);
			degsList.pop();
			var flamesLength = flames.length;
			for (it = 0; it < flamesLength; it++) {
				var compoundRotation:Number = 0;
				for (j = 0; j < (it+1); j++) {
					compoundRotation += degsList[j];
				}
				var tempFlame = flames[it];
				tempFlame.rotation = compoundRotation;
				if (it != 0) {
					tempFlame.x = flames[it-1].x - FLAMES_D * Math.cos(flames[it-1].rotation * (Math.PI/180));
					tempFlame.y = flames[it-1].y - FLAMES_D * Math.sin(flames[it-1].rotation * (Math.PI/180));
				}
			}
		}
		
		private function checkBoundary() {
			var localLevel:Point = swfcontent.level.globalToLocal(MISSILE_POINT);
			var w = swfcontent.level.width - BOUNDARY_RADIUS;
			var h = swfcontent.level.height - BOUNDARY_RADIUS;
			if (localLevel.x >= w || localLevel.x <= BOUNDARY_RADIUS ||
				localLevel.y >= h || localLevel.y < BOUNDARY_RADIUS) {
				boundaryHit = true;
				missile.degrees += 30;
				hud.nArrow.rotation -= missile.degrees;
				warningText.text = "There's No Escape";
				warningText.background = true;
			} else {
				boundaryHit = false;
				warningText.text = '';
				warningText.background = false;
			}
		}
	
		private function rotateTo(mc:MovieClip,begin,end,invisible:Boolean = false) {
			addEventListener(Event.ENTER_FRAME,onEnter, false, 0, true);
			var counter = 0;
			var frames = 6;
			var delta = end - begin;
			var increment = delta / frames;
			mc.rotation = begin;
			function onEnter(e:Event):void {
				if (counter < frames) {
					mc.rotation += increment;
					counter++;
				} else {
					if (invisible) {
						mc.rotation = 0;
						mc.visible = false;
					}
					removeEventListener(Event.ENTER_FRAME,onEnter);
				}
			}
		}
		
		private function pause() {
			paused = true;
			hud.visible = false;
			addons.visible = false;
			undoHUDFade();
			removeEventListener(Event.ENTER_FRAME,onEnter);
			if (collider.extraColl) {
				collider.extraObj.pause();
			}
		}
		
		private function unpause() {
			paused = false;
			hud.visible = true;
			addons.visible = true;
			hudFadeTimer.start();
			if (collider.extraColl) {
				collider.extraObj.unpause();
			}
			pauseScore = score;
			//keep score constant
			scoreDate = new Date();
			score = 0;
			scoreInit = scoreDate.getTime();
			addEventListener(Event.ENTER_FRAME,onEnter, false, 0, true);
		}
		private function undoHUDFade() {
			hud.alpha = 1;
			hudFadeTimer.reset();
		}
		//looks for object with current level's collider data in cgcso
		private function findColliderData():Object {
			var found:Boolean = false;
			var tempObj:Object = new Object();
			for (it = 0; it < cgcso.colliderData.length && !found; it++) {
				if (cgcso.colliderData[it].name == currLvl) {
					tempObj = cgcso.colliderData[it];
					found = true;
				}
			}
			return tempObj;
		}
		
		private function initVariableVars() {
			loaded = false;
			boundaryHit = false;
			braking = false;
			xrayOn = false;
			xrayOverlay.visible = false;
			paused = false;
			playingTunnel = false;
			//score
			score = 0;
			scoreDate = new Date();
			scoreInit = scoreDate.getTime();
			pauseScore = 0;
			//hud
			degsList = Vector.<Number>([0,0,0,0]);
			deltaDegs = 0;
			hud.nArrow.rotation = 90;
			hud.brakeMask.height = 300;
			hud.xray.gotoAndStop(1);
			warningText.background = false;
			//level
			lvl.x = 0;
			lvl.y = 0;
			lvl.rotation = 0;
			currSignRotation = '+';
			currQuadrant = 1;
		}
		
		private function restart(isNext=false) {
			removeAllListeners();
			removeChild(missile);
			initVariableVars();
			loader.unload();
			if (isNext) {
				var nextLvlNum = int(currLvl.split('l')[2])+1;
				if (nextLvlNum <= 20) {
					currLvl = "lvl"+nextLvlNum;
					theswf = currLvl + ".swf";
				}
			}
			loadSWF(theswf,lvl);
		}
	}
}
