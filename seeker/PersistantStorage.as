package seeker {
	import flash.net.SharedObject;
	import flash.events.Event;
	
	public class PersistantStorage {
		public static var so:SharedObject;
		public static var levelsWon:Array;
		public static const NUM_LEVELS = 23;
		public static const MISSILE_NAMES = ['Classic','Black','Green','Gold','White','Seeker','Skull','Stripes',
												'Flames','Camo','Seeker_Bill','Rocket_Ship','Sub','Dragon','Robot',
												'Red_Flames','Green_Flames','Blue_Flames','Black_Flames'];
		//the order of lvl_cats is orange then green then purple orbs
		public static const SECRET_LVLS_CATS = [['lvl2','lvl10','lvl11','lvl17'],
												['lvl3','lvl13','lvl16','lvl19','lvl20'],
												['lvl5','lvl7','lvl9','lvl12','lvl18'],
												['blah','lvl21','lvl22','lvl23']];
		public static const SECRET_LVLS = ['lvl2','lvl3','lvl5','lvl7','lvl9','lvl10',
											'lvl11','lvl12','lvl13','lvl16','lvl17',
											'lvl18','lvl19','lvl20','lvl21','lvl22','lvl23'];
		public static const MISSILES_TO_LEVELS = missileLevelPairing();
		
		public function PersistantStorage() {
			throw Error ('Don"t instantiate!');
			init();
		}
		
		public static function missileLevelPairing() {
			var counter = 1; //skip 'Classic' missile...
			var tempMtoL = {};
			for (var i = 0; i < SECRET_LVLS_CATS.length; i ++) {
				for (var j = 0; j < SECRET_LVLS_CATS[i].length; j++) {
					tempMtoL[SECRET_LVLS_CATS[i][j]] = MISSILE_NAMES[counter];
					//trace(MISSILE_NAMES[counter] + ': ' + SECRET_LVLS_CATS[i][j]);
					counter++;
					
				}
			}
			return tempMtoL;
		}

		private static function getJustUnlockedObj() {
			var justUnlockedObj  = {};
			for (var i = 0; i < MISSILE_NAMES.length; i++) {
				justUnlockedObj[MISSILE_NAMES[i]] = false;
			}
			return justUnlockedObj;
		}
		
		public static function init() {
			so = SharedObject.getLocal('savedData');
			if (!so.data.playedBefore) {
				trace('first post!');
				so.data.playedBefore = true;
				so.data.wonGame = false;
				so.data.levels = new Object();
				so.data.secLvlOrbCount = [0,0,0]; //corresponding to 3 difficulties of secret orb
				so.data.currMissile = 'Classic';
				so.data.currFlame = 'Red_Flames';
				for (var i = 1; i <= NUM_LEVELS; i++) {
					var tempLvl = 'lvl'+i;
					so.data.levels[tempLvl] = new Object();
					var sdlt = so.data.levels[tempLvl];
					sdlt.won = false;
					sdlt.qualifiedName = 'Level ' + i;
					sdlt.shortName = 'lvl' + i;
					sdlt.lowScore = 'N/A';
					//secretOrb can be "Yeah!" or "No"
					if (i >= 21) { //bonus levels...
						sdlt.unlocked = false;
					}
					if (SECRET_LVLS.indexOf(tempLvl) != -1) sdlt.secretOrb = 'Not Yet';
					else sdlt.secretOrb = 'N/A';
				}
				levelsWon = checkLevelsWon();
				so.data.justUnlockedObj  = getJustUnlockedObj();
				so.flush();
			} else {
				//so.clear();
				levelsWon = checkLevelsWon();
				so.data.justUnlockedObj  = getJustUnlockedObj();
				so.data.wonGame = true;
				//so.flush();
			}
		}
		
		public static function get sharedObject():SharedObject {
			return so;
		}
		
		//checks why you finished: was it a win a secret. uses this to save correct data
		public static function saveData(isWin:Boolean,currLvl:String,score:int = 0):void {
			if (isWin) {
				if (int(currLvl.split('l')[2]) < 21) { //don't save if you've beaten a bonus level...helpful for finding out if you've won the game
					so.data.levels[currLvl].won = true;
				} else {
					//unlock flames
					so.data.levels[currLvl].secretOrb = "Yeah!";
				}
				
				if (score < so.data.levels[currLvl].lowScore || so.data.levels[currLvl].lowScore == 'N/A') {
					so.data.levels[currLvl].lowScore = score;
				}
				
			} else {
				if (!so.data.justUnlockedObj[MISSILES_TO_LEVELS[currLvl]]) so.data.justUnlockedObj[MISSILES_TO_LEVELS[currLvl]] = true;
				for (var i = 0; i < SECRET_LVLS_CATS.length; i++) {
					if (SECRET_LVLS_CATS[i].indexOf(currLvl) != -1 && so.data.levels[currLvl].secretOrb == "Not Yet") {
									
						so.data.secLvlOrbCount[i]++;
						if (so.data.secLvlOrbCount[i] == SECRET_LVLS_CATS[i].length) {
							//you've found all the secrets in a category!
							//unlock corresponding secret level
							//syntax: lvl2 + (i+1) should give you lvl21 lvll22 lvl23
							so.data.levels["lvl2" + (i+1)].unlocked = true;

						}
					}
				}
				//unlocks corresponding missile. See build page.
				so.data.levels[currLvl].secretOrb = "Yeah!";
			}
		}
		
		public static function checkLevelsWon(stage=null):Array {
			var wonArray = [];
			
			for (var lvl in so.data.levels) {
				if (so.data.levels[lvl].won) {
					wonArray.push(lvl);
				}
			}
			wonArray.sort();
			//because bonus levels aren't counted as wins
			if (wonArray.length >= 20 && stage && !so.data.wonGame) {
				stage.dispatchEvent(new Event("won game"));
				so.data.wonGame = true;
			}
			return wonArray;
		}
	}
}
