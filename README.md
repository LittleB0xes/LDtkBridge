# LDtkBridge
A bridge between LDtk and DragonRuby


⚠️  construction in progress ⚠️  

Documentation in progress too !


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
#### Level
If in your LDtk file, your level is named "Level_1" in LDtk, LDtkBridge converts it to a symbol `:Level_1`.

This level can be load like this

```ruby
my_level = LDtk.level(my_world, :Level_1)
```

Each level is a hash with keys :
```ruby
{
  identifier:       # Symbol        name of the level
  uid:              # Integer       Unique integer identifier
  iid:              # String        Unique instance identifier
  px_hei:           # Integer       height of the level in px,
  px_wid:           # Integer       width of the level in px,
  world_x:          # Integer       x position of the level in the world in px,
  world_y:          # Integer       y position of the level in the world in px,
  layers:           # Hash          hash of layer with layer identifier as key
  field:            # Array<Hash>   array of field hash`
}
```

#### Layers
In the same way, you can load a layer named "Ground" in "Level_1" with

```ruby
my_layer = LDtk.layer(my_world, :Level_1, :Ground)
```
Each layer is a hash with keys
```ruby
{
     cell_width:        # Integer           width in cells
     cell_height:       # Integer           height in cells
     grid_size:         # Integer           cell size in px
     identifier         # Symbol            name of the layer
     type:              # Symbol            Layer type
                        #                   (possible values: :IntGrid,:Entities, :Tiles or :AutoLayer)
     iid:               # String            Unique instance identifier
     tileset_def_uid:   # Integer           definition id of the layer's tileset
     tileset_rel_path:  # String            relative path of tileset
     grid_tiles         # Array<Hash>       array of tiles's hash (dr friendly)
     entities           # Array<Hash>       array of entity's hash 
     int_grid           # Array<Integer>    array of int in 'dr-friendly' orientation 
}
```

### Tile Layer
When the layer is a tiles layer (id `type: :Tiles), `grid_tiles` key link to an array of tile.
LDtkBridge make DR friendly tiles (plus some useful fields). So tiles have this format :
```ruby
{
    x:
    y:
    w:
    h:
    source_x:
    source_y:
    source_w:
    source_h:
    flip_horizontally:
    flip_vertically:

    tile_id:
    enum_tags
}
```
### Entities Layer

### Int Grid Layer

