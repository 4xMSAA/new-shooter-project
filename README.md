# About

~~Rewriting MMC Zombies Project to be better and less dumb~~

An abandoned project because the Roblox platform is not particularly great for stable projects that don't use the avatar features provided by the platform.
There's really, a bunch of reasons why, but they're also quite opinionated...

Maybe you can salvage parts of this codebase for your own needs? Such as:
* Playing Roblox hierarchy compatible animations (see `shared/Animator`)
* Almost pure-Lua events (or signals) that don't struggle with key/value + array tables and have `:on(signal)`, :once(signal) functionality (see `common/Emitter`)
* Related with the above, `common/NetworkLib` may actually be of interest as well.
* A somewhat of a framework (as much as I hate that word, it kind of forces you to design games in a certain way...) to prototype games. <https://www.roblox.com/games/9249236711/la-bomba-sweeper> was actually made with this.

You might be wondering: "why is everything _wrapped_ around the Roblox instance equivalents???" - because I wish I could augment them. 
I wanted it so should changes to an instance happen, I wouldn't have to replace code in various places, but replace code at a single point where I _wrapped_ around an instance.
I'm not sure if wrapped is the word to use here, but hopefully gets the meaning across.


## Placefile
Grab a copy here and mess around:
<https://www.roblox.com/games/5014349871/gun-sandbox>

## Setting up gun rigs

WIP: make a plugin for this

Models are located in `assets/Weapons/Models` (not mounted)  
Animations are located in `assets/Weapons/Animations` (not mounted)  
Configurations are located in `assets/Weapons/Configuration`  

A gun rig is set up with the following tree structure:

```txt

+ ModelName                The weapon asset name
|-- Animate                Place all Motor6D's here (not neccessary, but preferred)
|-- Parts                  All design parts here (not neccessary, but preferred)
|-+ Rig                    Required parts and location of arms
  |-+ LeftArm              R15 arm with 0.35 width and depth
  | |-+ LeftHand
  | |-+ LeftLowerArm
  |   |-+ LeftUpperArm     Motor6D Part1 to LeftUpperArm
  | |-+ LeftUpperArm
  |   |-+ LeftUpperArm     Motor6D Part1 to LeftUpperArm
  |-+ RightArm             R15 arm with 0.35 width and depth
  | |-+ RightHand
  |   |-+ RightLowerArm    Motor6D Part1 to RightLowerArm
  | |-+ RightLowerArm
  |   |-+ RightUpperArm    Motor6D Part1 to RightUpperArm
  | |-+ RightUpperArm
  |-+ Handle
  | |-+ LeftHand           Motor6D Part0 being Handle, Part1 leading to LeftHand in LeftArm
  | |-+ RightHand          Motor6D Part0 being Handle, Part1 leading to RightHand in RightArm
  
```

## Design patterns

* When loading objects by configuration - do not modify configuration values as they should be final.
  Instead, copy the value and make it a mutable variable.
* OOP is not enforced, but a lot of code is written with "objects".
* ContextActionService will be used. UserInputService will be used on cases where we need more raw input.

## Code stylization

Text encoding is **UTF-8, Line Feed only, 4 indentation spaces**

A lot of this follows <https://roblox.github.io/lua-style-guide/>.  
Here's a quick rundown:

+ **Variables**, functions are **camelCase**  
+ **Properties** in objects are **PascalCase**  
+ **Internal properties** in objects are **_camelCase**  
+ **Methods** in objects are defined with a colon `:` and are **camelCase**  
+ **Static methods** in objects are defined with a full stop `.`
+ Keep **one-line spaces** between functions
+ Constants or configurable values that do not depend on external modules are **top most**
+ Roblox services come second from the top most order
+ Game modules come third from the top most order

```lua
local CONSTANT = 5

local Debris = game:GetService("Debris")

local GameModule = require(shared.Common.NetworkLib)

function Class:method()
    local pain
    self.PublicProperty = "hi"
    self._privateProperty = "do not touch me"
    -- self exists in this context due to the : token
end
```

## Data specifications

### Particle Configuration

`Type` specifices whether to read configurations for 2D elements or 3D elements.  
**Expects:** string `2D`, string `3D`  
`Default` specifies a ClassName-based behaviour for objects inside the effect.  
**Expects:** table `{}` with the instance's ClassName and an instance-specific property table  
`Specification` declares properties for objects by **name** inside the effect.
**Expects:** table `{}` with the instance's name and an instance-specific property table

### Gun Configuration

TODO

## External Tools

* Moon Animation Suite (optional, used initially so the animation code supports Moon animation saves. Superseded by Blender)
* Blender + Den_S's blender import plugin, KeyframeSequences copied from the instance during publish
