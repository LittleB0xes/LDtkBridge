module LDtk
  DEFAULT_CAMERA = { x: 0, y: 0, scale: 4 }

  # Render
  def self.render_layer(world, level_name, layer_name, camera = DEFAULT_CAMERA)
    layer = layer(world, level_name, layer_name)
    tileset_path = world.folder + layer.tileset_rel_path
    $gtk.args.outputs.sprites << layer.grid_tiles.map do |tile|

      {
        x: (tile.x - camera.x) * camera.scale,
        y: (tile.y - camera.y) * camera.scale,
        w: tile.w * camera.scale,
        h: tile.h * camera.scale,
        path: tileset_path,
        source_x: tile.source_x,
        source_y: tile.source_y,
        source_w: tile.source_w,
        source_h: tile.source_h,
        flip_horizontally: tile.flip_horizontally,
        flip_vertically: tile.flip_vertically
      }
    end
  end 

  def self.layer_as_rt(world, layer, rt_name)
    $gtk.args.render_target(rt_name).width = layer.cell_width * layer.grid_size 
    $gtk.args.render_target(rt_name).height = layer.cell_height * layer.grid_size

    tileset_path = world.folder + layer.tileset_rel_path

    $gtk.args.render_target(rt_name).sprites << layer.grid_tiles.map do |tile|

      {
        x: tile.x,
        y: tile.y,
        w: tile.w,
        h: tile.h,

        path: tileset_path,
        source_x: tile.source_x,
        source_y: tile.source_y,
        source_w: tile.source_w,
        source_h: tile.source_h,
        flip_horizontally: tile.flip_horizontally,
        flip_vertically: tile.flip_vertically
      }
    end
  end


  # Render a layer in static_sprite with draw override
  # link to a camera
  def self.render_layer_as_static(layer, camera = DEFAULT_CAMERA)
    tileset_path = @folder + layer.tileset_rel_path
    $gtk.args.outputs.static_sprites << layer.grid_tiles.map do |tile|
      LDtkTile.new(tile, tileset_path, camera)
    end
  end

  def self.get_tiles(layer, scale=1,  dx=0, dy=0)
    tileset_path = @folder + layer.tileset_rel_path

    layer.grid_tiles.map do |tile| 
      {
        x: (tile.x - dx) * scale,
        y: (tile.y - dy) * scale,
        w: tile.w * scale,
        h: tile.w * scale,
        path: tileset_path,
        source_x: tile.source_x,
        source_y: tile.source_y,
        source_w: tile.source_w,
        source_h: tile.source_h,
        flip_horizontally: tile.flip_horizontally,
        flip_vertically: tile.flip_vertically
      }
    end
  end

  def self.render_debug_int_grid(world, level_name, layer_name, camera = DEFAULT_CAMERA)
    layer = layer(world, level_name, layer_name)
    color_definition = {
      1 => { r: 255, g: 0, b: 0 },
      2 => { r: 0, g: 0, b: 0 },
      3 => { r: 0, g: 0, b: 255 },
      4 => { r: 255, g: 255, b: 0 }
    }

    $gtk.args.outputs.primitives << layer[:int_grid].map.with_index do |value, index|
      grid_size = layer[:grid_size]
      if value != 0
        x = index % layer[:cell_width]
        y = (index / layer[:cell_width]).to_i

        {
          x: (x * grid_size - camera.x) * camera.scale,
          y: (y * grid_size - camera.y) * camera.scale,
          w: grid_size * camera.scale,
          h: grid_size * camera.scale,
          path: :pixel,
          source_x: 0,
          source_y: 0,
          source_w: 1,
          source_h: 1,
          a: 125
        }.merge(color_definition[value]).sprite
      end
    end
  end

  def self.drawable_entities(world, level_name, layer_name, camera = DEFAULT_CAMERA)
    # cell_width = world.levels[level_name].layers[layer_name].cell_width
    # cell_height = world.levels[level_name].layers[layer_name].cell_height
    entities = world.levels[level_name].layers[layer_name].entities

    entities.select { |e| e.key?(:tile) && e[:tile].key?(:tileset_uid) }
            .map do |e|
              {
                x: e.pos.x * camera.scale,
                y: e.pos.y * camera.scale,
                w: e.tile.w * camera.scale,
                h: e.tile.h * camera.scale,
                source_x: e.tile.x,
                source_y: e.tile.y,
                source_w: e.tile.w,
                source_h: e.tile.h,
                path: "#{world.folder}#{world.definitions.tilesets[e.tile.tileset_uid].rel_path}"
              }
            end
  end
end



class LDtkTile
  attr_sprite

  def initialize(tile, path, camera)
    @camera = camera
    @x = tile.x
    @y = tile.y
    @w = tile.w
    @h = tile.w
    @path = path
    @source_x = tile.source_x
    @source_y = tile.source_y
    @source_w = tile.source_w
    @source_h = tile.source_h
    @flip_horizontally = tile.flip_horizontally
    @flip_vertically = tile.flip_vertically
  end

  def draw_override ffi_draw
    scale = @camera.scale
    ffi_draw.draw_sprite_3(
      (@x.to_i - @camera.x) * scale, (@y.to_i - @camera.y) * scale, @w * scale, @h * scale,
      @path,
      0,
      @a, 255, 255, 255,
      nil, nil, nil, nil,
      @flip_horizontally, @flip_vertically,
      nil, nil,
      @source_x, @source_y, @source_w, @source_h
    )
    # The argument order for ffi_draw.draw_sprite_4 is:
    # x, y, w, h,
    # path,
    # angle,
    # alpha, red_saturation, green_saturation, blue_saturation
    # tile_x, tile_y, tile_w, tile_h,
    # flip_horizontally, flip_vertically,
    # angle_anchor_x, angle_anchor_y,
    # source_x, source_y, source_w, source_h,
    # blendmode_enum
  end
end
