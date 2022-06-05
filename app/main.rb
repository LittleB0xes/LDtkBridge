require 'lib/LDtkBridge.rb'


class Demo
  attr_accessor :world,
                :level_one
  def initialize args
    @scale = 4
    # set a very basic camera, just  for the sample, to move on the map
    @camera_x = 0
    @camera_y = 0


    # World initialisation
    @world = LDtk::LDtkBridge.new('assets/', 'level.ldtk')

    # Load the first level named "Level1" in LDtk
    @level_one = @world.get_level(:Level1)

    # You can access to the layer in LDtk by
    # the get_layer(name) method and iterate to throw all tiles
    # in what you want (here, a render_target)
    # for this sample, level.ldtk contains five layers :
    #   - Enities
    #   - Background
    #   - FgDeco
    #   - IntGrid
    #   - Tiles
    
    # All tiles data are store in layer_data
    # layer_data is an Array of Hash 
    
    # if using render_target, it could be a good idea to set
    # the dimension of the render_target
    #
    # You can get the size of layer with .width and .height methods
    args.render_target(:tiles_back).width = @level_one.width * @scale
    args.render_target(:tiles_back).height = @level_one.height * @scale

    # Now, we get all tiles of "Background" layer

    @level_one.get_layer(:Background).layer_data.each do |t|
      tile = SampleSprite.new(t[:x], t[:y], t[:sx], t[:sy], t[:w], t[:h], 0)
      
      # Each tile in layer_data has a flip_horizontally/vertically field
      # then, you can use it directly with sprite (and attr_sprite class attribute) in DragonRuby
      tile.flip_vertically = t[:flip_vertically]
      tile.flip_horizontally = t[:flip_horizontally]

      args.render_target(:tiles_back).sprites << tile
    end

    # We can now add the tile Layer
    # we can use the same technic like above
    # with this :
    #
    #@level_one.get_layer(:Tiles).layer_data.each do |t|
    #  tile = SampleSprite.new(t[:x], t[:y], t[:sx], t[:sy], t[:w], t[:h], 0)

    #  # Each tile in layer_data has a flip_horizontally/vertically field
    #  # then, you can use it directly with sprite (and attr_sprite class attribute) in DragonRuby
    #  tile.flip_vertically = t[:flip_vertically]
    #  tile.flip_horizontally = t[:flip_horizontally]
    #  args.render_target(:tiles_back).sprites << tile
    #end
    #
    # Or use the render method

    args.render_target(:tiles_back).sprites << @level_one.get_layer(:Tiles).render


    # Let's talk about Entities
    # In this case, all entities are animated or movable
    # So, we need to update them on each tick
    #

    # Her, we choose to use a render target for rendering, but,
    # one more time, feel free to use what you want

    # Size initialisation
    args.render_target(:entities).width = @level_one.width * @scale
    args.render_target(:entities).height = @level_one.height * @scale

    # In an Enitities layer, we can access to all specific entities
    # with the .get_all(entity_name) method. It returns an array
    #
    # For example, in LDtk file, we have a "Torch" Entity, we can do
    @all_entities = @level_one.get_layer(:Entities).get_all(:Torch).map do |ent|
      # In Entities Layer, all properties are store in an Hash
      # Here, in LDtk files, Torch entity have some fields :
      #  - a source_rect field  (a standarized fields with an array 
      #     [sx, sy,sw, sh] if tile is assigned to the entitie
      #     (else, source_rect = Null in LDtk and not exist in LDtkBridge)
      #
      #  - a pos (ie position) field (a standarized LDtk field)
      #
      #  And we added a custom field in our LDtk file :
      #  - a frame field (number of frame for the animation)

      # Standardized fields
      x = ent[:pos][:x]
      y = ent[:pos][:y]
      sx = ent[:source_rect].source_x
      sy = ent[:source_rect].source_y
      w = ent[:source_rect].source_w
      h = ent[:source_rect].source_h

      # Custom fields (access to custom fields with key :field)
      frame = ent[:fields][:frame]

      SampleSprite.new(x, y, sx, sy, w, h, frame)
       
    end

    
    
    args.render_target(:entities).sprites << @all_entities

    puts @all_entities.length
    
    


  end

  def tick args

    args.outputs.background_color= [0,0,0]
    
    # Update Entities
    @all_entities.each{|ent| ent.update args}
    
    # Update the entities render_target
    args.render_target(:entities).width = @level_one.width * @scale
    args.render_target(:entities).height = @level_one.height * @scale
    args.render_target(:entities).sprites << @all_entities

    # Tiles background display
    args.outputs.sprites << {
      x: -@camera_x * @scale, 
      y: -@camera_y * @scale,
      w: @level_one.width * @scale,
      h: @level_one.height * @scale,
      path: :tiles_back,
      source_x: 0,
      source_y: 0,
      source_w: @level_one.width,
      source_h: @level_one.height,
    }

    # Entities Layer display
    args.outputs.sprites << {
      x: -@camera_x * @scale, 
      y: -@camera_y * @scale,
      w: @level_one.width * @scale,
      h: @level_one.height * @scale,
      path: :entities,
      source_x: 0,
      source_y: 0,
      source_w: @level_one.width,
      source_h: @level_one.height,
    }
    # FourFour Layer display
    args.outputs.sprites << {
      x: -@camera_x * @scale, 
      y: -@camera_y * @scale,
      w: @level_one.width * @scale,
      h: @level_one.height * @scale,
      path: :entities,
      source_x: 0,
      source_y: 0,
      source_w: @level_one.width,
      source_h: @level_one.height,
    } 
    args.outputs.labels << [10,700,"Use arrow to move the view",255,255,255]
    args.outputs.labels << [10,680,"Hit a to reset",255,255,255]
    args.outputs.labels << [10,660,"x/c for zoom/dezoom",255,255,255]


    # In this sample, you can move the view (the camera) with arrow key
    #
    if args.inputs.keyboard.key_held.right
      @camera_x += 1
    elsif args.inputs.keyboard.key_held.left
      @camera_x -= 1
    end
    if args.inputs.keyboard.key_held.up
      @camera_y += 1
    elsif args.inputs.keyboard.key_held.down
      @camera_y -= 1
    end

    if args.inputs.keyboard.key_held.x
      @scale += 0.1 if @scale < 10
    elsif args.inputs.keyboard.key_held.c
      @scale -= 0.1 if @scale >= 1
    end

    if args.inputs.keyboard.key_down.a
      $gtk.reset
    end
      
  
  end

  def serialize
    {scale: @scale, world: @world }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end


end

# This is a very archaïc and simple sprite class, just for the sample
class SampleSprite
  attr_sprite
  def initialize x, y, sx, sy, sw, sh, frame
    @x = x
    @y = y
    @w = sw
    @h = sh
    @source_x = sx
    @source_y = sy
    @source_w = sw
    @source_h = sh

    @sx_o = sx
    @path = "assets/tileset.png"

    @max_frame = frame
    @current_frame = 0
  end

  def update args
    if args.tick_count % 8 == 0
      @current_frame += 1
      if @current_frame >= @max_frame
        @current_frame = 0
      end
    end 
    @source_x = @sx_o + @current_frame * @w
  end
end

def tick args
  args.state.demo ||= Demo.new(args)
  args.state.demo.tick(args)
end
