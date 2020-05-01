# About

Rewriting MMCZP to be better and less gay

## Setting up gun rigs

(make a plugin for this dumbass)

Models are located in assets/Weapons/Models - A model can
be FirstPerson (high-poly) or ThirdPerson (low-poly, optimized for en masse use)

A gun rig is set up with the following tree structure:

```txt

+ ModelName                The weapon asset name
|-- Animate                Place all Motor6D's here (not neccessary, but preferred)
|-- Parts                  All design parts here (not neccessary, but preferred)
|-+ Rig                    Required parts and location of arms
  |-+ LeftArm              R15 arm with 0.75 width and depth
  | |-+ LeftHannd
  | |-+ LeftLowerArm
  |   |-+ LeftUpperArm    Motor6D Part1 to LeftUpperArm
  | |-+ LeftUpperArm
  |   |-+ LeftUpperArm    Motor6D Part1 to LeftUpperArm
  |-+ RightArm             R15 arm with 0.75 width and depth
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
* ContextActionService will be used. UserInputService will be used on cases where we need pure input.
* Remember to plan ahead for VR interactions.

## Code stylization

A lot of this follows <https://roblox.github.io/lua-style-guide/>.  
Here's a quick rundown:

Variables, functions are **camelCase**
Methods in classes are defined with a colon ``:`` and are **camelCase**

```lua
function Class:method()
    -- self exists in this context due to the : token
end
```

## External Tools

* Trello Todo - <https://trello.com/b/vLcRXfah/new-shooter-project-todo>
* Moon Animation Suite (new)
