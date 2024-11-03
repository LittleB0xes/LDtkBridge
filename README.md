# LDtkBridge
A bridge between LDtk and DragonRuby


⚠️  construction in progress ⚠️  

Documentation in progrss too !


## Usage

### LDtk project init
First you need to init your map

```ruby
my_world = LDtk.create_world('path_to_your_file', 'your_ldtk_file.ldtk')
```
my_world is a `Hash` and has this structure :
```ruby
{
    folder: 'path_to_your_file/',
    levels: {},             # Hash with all levels
    definitions: {}         # some useful information about tilesets
}
```

### Loading Levels and Layers
If in your LDtk file, your level is named "Level_1" in LDtk, LDtkBridge converts it to a symbol `:Level_1`.

This level can be load like this

```ruby
my_level = LDtk.level(my_world, :Level_1)
```

In the same way, you can load a layer named "Ground" in "Level_1" with

```ruby
my_layer = LDtk.layer(my_world, :Level_1, :Ground)
```

