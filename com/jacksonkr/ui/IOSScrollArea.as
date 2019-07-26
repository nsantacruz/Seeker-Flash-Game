﻿package com.jacksonkr.ui {
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.display.DisplayObject;
	import flash.geom.Point;
	import flash.events.Event;
	import flash.utils.getTimer;
	import flash.utils.setInterval;
	import flash.utils.clearInterval;

	public class IOSScrollArea extends Sprite {
		public static const VERTICAL:int = 1; // default
		public static const HORIZONTAL:int = 2;
		protected static const END_PAD:Number = 0.0;
		protected var DEFAULT_SPEED:Number = 0.2;
		protected var STRESS_SPEED:Number = 0.1;
		protected static const START:int = 1;
		protected static const END:int = 2;
		protected static const X:String = "x";
		protected static const Y:String = "y";
		protected var MOMENTUM_DEFAULT:Number = 0.276;
		protected var MOMENTUM_HASTE:Number = 1.84;
		protected var MOMENTUM_CHUNK:Number = 20;
		
		protected var _down:Point;
		protected var _start:Point;
		protected var _item:DisplayObject;
		protected var _type:int = IOSScrollArea.VERTICAL;
		protected var _mask:Sprite;
		protected var _zero:Point;
		protected var _thumbV:IOSScrollThumb;
		protected var _thumbH:IOSScrollThumb;
		protected var _intervalX:int;
		protected var _intervalY:int;
		protected var _moves:Array;
		protected var _speed:Object;
		protected var _signs:Object;
		
		public function IOSScrollArea() {
			var w:Number = this.width;
			var h:Number = this.height;
			this.scaleX = this.scaleY = 1.0;
			
			// edit, then hide the green
			var g:DisplayObject = this.getChildAt(0);
			g.width = w;
			g.height = h;
			g.visible = false;
			
			this.stage.addEventListener(MouseEvent.MOUSE_DOWN, this.mouseDownHandler,false,0,true);
		}
		
		protected function mouseDownHandler(event:MouseEvent):int {
			clearInterval(this._intervalX);
			clearInterval(this._intervalY);
			
			if(this.stress(X) == START) this._item.x = this._zero.x;
			if(this.stress(Y) == START) this._item.y = this._zero.y;
			
			this._down = null;
			this._start = null;
			this._speed = {x:DEFAULT_SPEED, y:DEFAULT_SPEED};
			this._signs = {x:null, y:null};
			
			if(this._item && this.stage) {
				this._moves = [[0,0]];
				
				var xy:Point = this.localToGlobal(new Point(this.x, this.y));
				var wh:Point = this.localToGlobal(new Point(this.width, this.height));
				
				var hit:Boolean = this.hitTestPoint(this.stage.mouseX, this.stage.mouseY, false);
				if(hit) {
					this._down = new Point(this.stage.mouseX, this.stage.mouseY);
					this._start = new Point(this._item.x - this.x + this._zero.x, this._item.y - this.y + this._zero.y);
				}
				
				if(!this._down || !this._start) return 1;
				
				this.stage.addEventListener(Event.ENTER_FRAME, this.enterFrameHandler,false,0,true);
				this.stage.addEventListener(MouseEvent.MOUSE_UP, this.mouseUpHandler,false,0,true);
			}
			
			return 0;
		}
		/**
		 * use this when checking for directional flags (eg. VERTICAL and HORIZONTAL)
		 */
		protected function hasFlag(val:int):Boolean {
			return (this.type & val) == val;
		}
		/**
		 * This is used while you are the active mouse button is down. I'm using ENTER_FRAME instead of mouse move as this is much more granular.
		 */
		protected function enterFrameHandler(event:Event):void {
			// coordinates
			var cx:Number = this._item.x;
			var cy:Number = this._item.y;
			
			if(this.hasFlag(HORIZONTAL))  {
				cx = (this.stage.mouseX - this._down.x);
				if(this.stress(X) && this.at(X) == START) cx -= (this._item.x - this._zero.x) * 0.5;
				else if(this.stress(X) && this.at(X) == END) cx -= ((this._item.x - this._zero.x) - (0 - this._item.width + this.width)) * 0.5;
			}
			
			if(this.hasFlag(VERTICAL)) {
				cy = this.stage.mouseY - this._down.y;
				if(this.stress(Y) && this.at(Y) == START) cy -= (this._item.y - this._zero.y) * 0.5;
				else if(this.stress(Y) && this.at(Y) == END) cy -= ((this._item.y - this._zero.y) - (0 - this._item.height + this.height)) * 0.5;
			}
			
			this._moves.push([this._start.x + cx - this._item.x, this._start.y + cy - this._item.y]);
			if(this.hasFlag(HORIZONTAL)) this.itemX = this._start.x + cx;
			if(this.hasFlag(VERTICAL)) this.itemY = this._start.y + cy;
		}
		protected function mouseUpHandler(event:MouseEvent):void {
			this.stage.removeEventListener(Event.ENTER_FRAME, this.enterFrameHandler);
			this.stage.removeEventListener(MouseEvent.MOUSE_UP, this.mouseUpHandler);
			
			var mom:Vector.<Number> = Vector.<Number>([0, 0]); // momentum
			var v:Array = this._moves.slice(-2);
			var len:int = v.length;
			
			for each(var o:Array in v) {
				if(this.hasFlag(HORIZONTAL)) mom[0] += o[0];
				if(this.hasFlag(VERTICAL)) mom[1] += o[1];
			}
			
			if(this.hasFlag(HORIZONTAL)) mom[0] /= len;
			if(this.hasFlag(VERTICAL)) mom[1] /= len;
			
			if(Math.abs(mom[0]) < 3) mom[0] = 0;
			if(Math.abs(mom[1]) < 3) mom[1] = 0;
			
			if(this.stress(X)) mom[0] /= 2;
			if(this.stress(Y)) mom[1] /= 2;
			
			this._signs.x = this.sign(mom[0]);
			this._signs.y = this.sign(mom[1]);
			
			this.momentum({x:mom[0]});
			this.momentum({y:mom[1]});
		}
		/**
		 * Lets you know if there is stress on the scrollable content
		 */
		protected function stress(prop:String):int {
			if(this._item[prop] > this._zero[prop]) return START;
			if(prop == Y && this._item.y < this._zero.y - this._item.height + this.height) return END;
			if(prop == X && this._item.x < this._zero.x - this._item.width + this.width) return END;
			return 0;
		}
		protected function at(prop:String):int {
			switch(true) {
				case prop == Y:
					if(this._item.y > this._zero.y - (this._item.height - this.height) / 2) return START;
					return END;
				break;
				case prop == X:
					if(this._item.x > this._zero.x - (this._item.width - this.width) / 2) return START;
					return END
				break;
			}
			
			return 0;
		}
		protected function sign(val:Number):int {
			if(val < 0) return -1;
			if(val > 0) return 1;
			return 0;
		}
		/**
		 * the momentum effect after MOUSE_UP
		 */
		protected function momentum(obj:Object):void {
			for(var i:String in obj) {
				if(hasFlag(VERTICAL) && i == Y
					|| hasFlag(HORIZONTAL) && i == X)
				{
					var i_:String = i.toUpperCase();
					var self:IOSScrollArea = this;
					this["_interval" + i_] = setInterval(function():void {
						var sign:int = sign(obj[i]);
						var stress_:int = stress(i);
						var at_:int = at(i);
						
						var amt:Number = MOMENTUM_DEFAULT * _signs[i];
						if(stress_ == START) {
							amt = MOMENTUM_HASTE;
							if(obj[i] > MOMENTUM_CHUNK) obj[i] /= MOMENTUM_HASTE;
						} else if(stress_ == END) {
							amt = -MOMENTUM_HASTE;
							if(obj[i] < -MOMENTUM_CHUNK) obj[i] /= MOMENTUM_HASTE;
						}
						if(amt == 0) {
							if(stress_ == START) amt = MOMENTUM_HASTE;
							else if(stress_ == END) amt = -MOMENTUM_HASTE;
							else amt = obj[i] = 0;
						}
						
						self["item" + i_] += obj[i] -= amt;
						
						switch(true) {
							// snap at the finish of START stress
							case stress_ == START && (_signs[i] > 0 || (_signs[i] == 0 && at_ == START)) && _item[i] + obj[i] < _zero[i]:
								if(at_ == START && stress_ == START) self["item" + i_] = _zero[i];
							// vertical snap at the finish of END stress
							case i == Y && stress_ == END && (_signs[i] < 0 || (_signs[i] == 0 && at_ == END)) && _item[i] + obj[i] > _zero[i] - (_item.height - height) - END_PAD:
								if(i == Y && at_ == END && hasFlag(VERTICAL)) itemY = _zero[i] - (_item.height - height) - END_PAD;
							// herizontal snap at the finish of END stress
							case i == X && stress_ == END && (_signs[i] < 0 || (_signs[i] == 0 && at_ == END)) && _item[i] + obj[i] > _zero[i] - (_item.width - width) - END_PAD:
								if(i == X && at_ == END && hasFlag(HORIZONTAL)) itemX = _zero[i] - (_item.width - width) - END_PAD;
							case !stress_ && _signs[i] > 0 && obj[i] <= 0.1:
							case !stress_ && _signs[i] < 0 && obj[i] >= -0.1:
							case !stress_ && !obj[i] && !amt:
								clearInterval(self["_interval" + i_]);
							break;
						}
					}, 8.3);
				}
			}
		}
		
		protected function set itemX(val:Number):void {
			this._item.x = val;
			this._thumbH.percent = (this._zero.x - this._item.x) / (this._item.width - this.width + END_PAD);
		}
		protected function get itemX():Number {
			return this._item.x;
		}
		protected function set itemY(val:Number):void {
			this._item.y = val;
			this._thumbV.percent = (this._zero.y - this._item.y) / (this._item.height - this.height + END_PAD);
		}
		protected function get itemY():Number {
			return this._item.y;
		}
		
		/**
		 * The item to be scrolled
		 */
		public function get item():DisplayObject {
			return this._item;
		}
		public function set item(val:*):void {
			switch(true) {
				case val is String:
					if(!this.parent[val] || !(this.parent[val] is DisplayObject)) throw new ArgumentError(val + " is not a valid DisplayObject");
					this._item = this.parent[val];
				break;
				case val is DisplayObject:
					this._item = val;
				break;
			}
			
			this._zero = new Point(this._item.x, this._item.y);
			
			this._mask = new Sprite();
			this._mask.x = this.x;
			this._mask.y = this.y;
			this._mask.graphics.beginFill(0x00ff00);
			this._mask.graphics.drawRect(0, 0, this.width, this.height);
			this._mask.graphics.endFill();
			this.parent.addChildAt(this._mask, this.parent.getChildIndex(this._item)+1);
			this._item.mask = this._mask;
			
			if(this.hasFlag(HORIZONTAL)) {
				this._thumbH = new IOSScrollThumb(this, HORIZONTAL);
				this.parent.addChildAt(this._thumbH, this.parent.getChildIndex(this));
			}
			
			if(this.hasFlag(VERTICAL)) {
				this._thumbV = new IOSScrollThumb(this, VERTICAL);
				this.parent.addChildAt(this._thumbV, this.parent.getChildIndex(this));
			}
		}
		public function get type():int {
			return this._type;
		}
		public function get zero():Point {
			return this._zero;
		}
		/**
		 * The type or direction on the scroll
		 */
		public function set type(val:int):void {
			if(val < 1 || val > 3) throw new ArgumentError("Type must be 1, 2, or 1 | 2 (eg. 3)");
			
			this._type = val;
		}
	}
}