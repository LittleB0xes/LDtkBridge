# LDtkBridge
A bridge between LDtk and DragonRuby

⚠️ Not all capabilities of LDtk 0.9.3 are supported, this is a work in progress. I add things to it according to my needs

~~Currently~~ Now, LDtkBridge ~~only supports one tileset (which will evolve later)~~ several tilesets, but it still a work in progress...

## Sample app
There is now a sample app. This is very basic and not optimized. The purpose of this app is just to show how to use some LDtkBrige functions.



## Usage

### LDtk project init
First you need to init your map

```ruby
my_world = LDtk::LDtkBridge.new('your_ldtk_file.ldtk')
```

### Loading Levels and Layers

#### Levels
If in your LDtk file, your level is named "Level1", this level can be load like this

```ruby
my_level = my_world.get_level(:Level1)
```
Levels have some properties :

```
name
width
height
x_world
y_world
level_data
```
#### Layers

⚠️ ***Important***
> All tile and sprite coordinates use the DragonRuby standard (origin bottom left). LDtkBridge converts up-left origin to bottom-left origin

You can now access to each layer of your level with the Level method `get_layer(:name_of_the_layer)`

For a layer named "layer_one" in LDtk, do :


```ruby
my_layer = my_level.get_layer(:layer_one)
```

Layers have some properties

```
name
cell_width (width of the layer in tile)
cell_height (height of the layer in tile)
cell_size (size of a tile, in px)
layer_data
```

▶️ **Case of Tile Layer**

For tile layer, `layer_data` is an Array of Tile Hash with fields
```ruby
{
	x: 			# x position on map
	y:			# y position on map
	sx:			# source_x on tileset
	sy:			# source_y on tileset
	w:			# width of the tile
	h:			# height of the tile
	f:			# flip poperty (0 = none, 1 = h_flip, 2 = v_flip, 3 = both)
	flip_vertically:	# true or false (flip property but adapted for DragonRuby convenience)
	flip_horizontally:	# true or false (flip property but adapted for DragonRuby convenience)
}
```


▶️ **Case of intGrid Layer**

For `intGrid`, layer_data is an Array of Int

You can access to an intGrid value with `my_layer.get_int(x, y)`


▶️ **Case of Entities Layer**

If your layer is a LDtk Entities type layer you can access to all items of a specific type of entity, like this : `my_layer.get_all(:monster)`

With LDtk, you can add some fields of data to your entities.

`Point` and `Array<Point>` are usable with this bridge.
When your layer is an Enities layer, `layer_data` is an Array of entity Hash like this :

```ruby
{
	:name => :identifier_of_the_entity,
	:pos => {x: x_of_you_entity, y: y_of_your_entity},
	:source_rect => [sx, sy, sw, sh],				#Coordinate and dimension of your tile in the tileset
	:fields => [{:field_1 => value}, {:field_2 => value},...]	#Array of fields
}
	
```



 ***Point and Array<Point>***


... Work in progress ...
