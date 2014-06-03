# Shiny Adventure

Your generic description of an awesome Shiny project goes here.


# TODO

## Features / code polishing for the demo

### P1
* iOS support

### P2
* Spawn code needs to be added
* Somehow get the char to move in iOS (touch control)
	* Missing movement code in Character
	* UI responder

### P3
* Handling methods like +loadSharedResources —> Doug will ping Argyrios to see if we can get this in a usable build soon
* Code comments
	* Point out things that shouldn't be the way they are
	* Add radar # when applicable
* Getting rid of Sign f
* Finish README

## Language features we'd like to highlight
* Generics
* Bitmask
* Infix

## Style issues
* Casts, e.g. `emitter = (sSharedLeafEmitterA.copy() as SKEmitterNode)!` -> `emitter = sSharedLeafEmitterA.copy()!`
* CGFloat vs Float
