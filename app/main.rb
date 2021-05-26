require 'lib/LDtkBridge.rb'


class Demo
  attr_accessor :world
  def initialize args
    @scale = 4
    # set a very basic camera, just  for the sample, to move on the map
    @camera_x = 0
    @camera_y = 0


    # World initialisation
    @world = LDtk::LDtkBridge.new('assets/level.ldtk')

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

      args.render_target(:tiles_back).sprites << tile
    end

    # We can now add the tile Layer
    #

    @level_one.get_layer(:Tiles).layer_data.each do |t|
      tile = SampleSprite.new(t[:x], t[:y], t[:sx], t[:sy], t[:w], t[:h], 0)

      args.render_target(:tiles_back).sprites << tile
    end



  end

  def tick args

    args.outputs.background_color= [0,0,0]

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

    if args.inputs.keyboard.key_down.right
      camera_x += 1
    end
  
    debug args
  end

  def debug args
    if args.inputs.keyboard.key_down.a
      $gtk.reset
    end
  end


end

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

    @path = "assets/tileset.png"

  end
end

def tick args
  args.state.demo ||= Demo.new(args)
  args.state.demo.tick(args)
end
