# About

Rewriting MMCZP to be better and less gay

## Setting up gun rigs

(make a plugin for this dumbass)

Models are located in assets/Weapons/Models (not mounted)
Animations are located in assets/Weapons/Animations (not mounted)
Configurations are located in assets/Weapons/Configuration

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

See <https://trello.com/c/hT4utJbj/2-development-kits> for an image.

## Design patterns

* When loading objects by configuration - do not modify configuration values as they should be final.
  Instead, copy the value and make it a state.
* OOP is not enforced, but borrow the polymorphism concept.
* ContextActionService will be used. UserInputService will be used on cases where we need more raw input.

## Code stylization

**UTF-8, LF, 4 spaces**

A lot of this follows <https://roblox.github.io/lua-style-guide/>.  
Here's a quick rundown:

Variables, functions are **camelCase**  
Properties in objects are **PascalCase**  
Internal properties in objects are **_camelCase**  
Methods in classes are defined with a colon ``:`` and are **camelCase**  

```lua
function Class:method()
    local pain
    self.PublicProperty = "hi"
    self._privateProperty = "do not touch me"
    -- self exists in this context due to the : token
end
```

## Data specifications

### Particle Configuration

``Type`` specifices whether to read configurations for 2D elements or 3D elements.  
**Expects:** string ``2D``, string ``3D``  
``Default`` specifies a ClassName-based behaviour for objects inside the effect.  
**Expects:** table ``{}`` with the instance's ClassName and an instance-specific property table  
``Specification`` declares properties for objects by **name** inside the effect.
**Expects:** table ``{}`` with the instance's name and an instance-specific property table

### Gun Configuration

TODO

## External Tools

* Trello Todo - <https://trello.com/b/vLcRXfah/new-shooter-project-todo>
* Moon Animation Suite
* Blender