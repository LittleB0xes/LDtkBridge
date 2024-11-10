module LDtk
  @folder = ''
  @definitions = {}

  # Return a Hash with hash tilesets and hash levels
  def self.load_world(folder, file_name)
    @folder = folder

    ldtk_file = $gtk.parse_json_file(folder + '/' + file_name)

    @definitions = create_definitions(ldtk_file['defs'])

    # Transform raw data in DR friendly hash
    levels = create_levels(ldtk_file['levels'], @definitions)

    {
      folder: folder + '/',
      levels: levels,
      definitions: @definitions
    }
  end

  # Definitions contains :
  # - A more practical Hash of tilesets data with uid as keys
  # - Other stuffs...later
  def self.create_definitions(definitions)
    all_tilesets = Hash[definitions['tilesets'].map{ |t|
      [
        t['uid'],
        { uid: t['uid'], rel_path: t['relPath'], px_wid: t['pxWid'], px_hei: t['pxHei'], enum_tags: tileset_enum_tag(t['enumTags'])}
      ]}
    ]


    {  tilesets: all_tilesets }
  end

  def self.tileset_enum_tag(enum_tags)
    enum_tags.map do |t|
      {
        enum_id: t['enumValueId'].to_sym,
        tile_ids: t['tileIds']
      }

    end

  end

  # each level have field
  # {
  #   identifier: `symbol`, name of the level
  #   px_hei:     `int`, height of the level in px,
  #   px_wid:     `int`, width of the level in px,
  #   world_x:    `int`, x position of the level in the world in px,
  #   world_y:    `int`, y position of the level in the world in px,
  #   layers:  `hash of layer hash`
  #   field_instances:  `array of field hash`
  # }
  def self.create_levels(levels, defs)
    all_levels = {}
    levels.each do |l|
      layers = self.create_layers(l["layerInstances"], defs)
      level_fields = Hash[l['fieldInstances'].map do |f|
        value = f['__value']

        ### Just transform hash value with symbol keys instead
        ### string keys
        if value.is_a?(Hash)
          value = value.transform_keys(&:to_sym)
        end
        [f['__identifier'].to_sym, value]
      end
    ]
      level = {
        identifier:   l["identifier"].to_sym,
        px_hei:       l['pxHei'],
        px_wid:       l['pxWid'],
        world_x:      l['worldX'],
        world_y:      l['worldY'],
        uid:          l['uid'],
        iid:          l['iid'],
        layers:       Hash[layers.map{|layer| [layer[:identifier], layer]}],
        fields:       level_fields 
      }
      all_levels[level[:identifier]] = level
    end

    all_levels
  end

  # each layer have field
  # {
  #   cell_width:            `int`,        width in cells
  #   cell_height:            `int`,        height in cells
  #   grid_size:        `int`         cell size in px
  #   identifier        `symbol`      name of the layer
  #   type:             `symbol`      Layer type (possible values: :IntGrid,
  #   #                               :Entities, :Tiles or :AutoLayer)
  #   tileset_def_uid:  `int`         definition id of the layer's tileset
  #   tileset_rel_path: `string`      relative path of tileset
  #   grid_tiles        `array<Hash>` array of tiles's hash (dr friendly)
  #   int_grid          'array<Int>'  array of int in 'dr-friendly' orientation 
  # }
  def self.create_layers(layers, defs)
    all_layers = []

    layers.each do |l|
      layer = {
        cell_width:       l['__cWid'],
        cell_height:      l['__cHei'], 
        grid_size:        l['__gridSize'],
        identifier:       l['__identifier'].to_sym,
        type:             l['__type'].to_sym,
        iid:              l['iid'],
        tileset_def_uid:  l['__tilesetDefUid'],
        tileset_rel_path: l['__tilesetRelPath'],
        grid_tiles:       [],
        entities:         [],
        int_grid:         [],

      }


      # -----------------------------
      # Generate the grid tiles layer
      # -----------------------------
      layer[:grid_tiles] = l['gridTiles'].map do |tile|
        position = { x: 0, y: 0 }
        position.x =  tile['px'][0]
        position.y =  layer.cell_height * layer.grid_size - tile['px'][1] - layer.grid_size

        source = { x: 0, y: 0 }
        source.x = tile['src'][0]
        source.y = defs[:tilesets][layer[:tileset_def_uid]][:px_hei] - tile['src'][1] - layer[:grid_size]

        flip_h = tile['f'] == 1 || tile['f'] == 3
        flip_v = tile['f'] == 2 || tile['f'] == 3
        tile_id = tile['t']


        # Add all tags of tile
        tags = []
        defs.tilesets[layer[:tileset_def_uid]][:enum_tags].each do |v|
          tags.push(v[:enum_id]) if v[:tile_ids].include?(tile_id)
        end

        # Create the tile
        create_dr_friendly_tile(position,source, layer[:grid_size], flip_h, flip_v).merge({tile_id: tile_id, enum_tags: tags})
      end

      # -------------------------
      # generate the entity layer
      # -------------------------
      layer[:entities] = l['entityInstances'].map do |e|
        entity = {
          iid: e['iid'],
          identifier:     e['__identifier'].to_sym,
          grid_pos:     { x: e['__grid'][0] , y: (layer[:cell_height] - 1 - e['__grid'][1] )},
          pos:          { x: e['px'][0] - e['__pivot'][0] * layer[:grid_size], y: layer[:cell_height] * layer[:grid_size] - e['height'] + e['__pivot'][1] * layer[:grid_size] - e['px'][1]},

          size:         { w: e['width'], h: e['height'] },
          pivot:        { x: e['__pivot'][0], y: e['__pivot'][1] },
          tile:         {}
        }

        ## Format the value of fields
        entity[:fields] = Hash[e['fieldInstances'].map do |f|
          value = f['__value']

          ### Just transform hash value with symbol keys instead
          ### string keys
          value = value.transform_keys(&:to_sym) if value.is_a?(Hash)
          [f['__identifier'].to_sym, value]
        end
        ]
        entity[:fields_type] = Hash[e['fieldInstances'].map do |f|
          [f['__identifier'].to_sym, f['__type']]
        end
        ]


        # In some case, fields needs to be rewrite
        entity[:fields].each do |k, v|
          if entity[:fields_type][k] == 'Array<Point>'
            entity[:fields][k] = v.map do |point|
              {
                cx: point['cx'],
                cy: layer.cell_height - point['cy'] - 1
              }
            end

            # Perhaps other specific type later...
          end
        end

        # Set the tile rectangle if exist
        if e['__tile']
          entity[:tile] = {
            x: e['__tile']['x'],
            y: defs[:tilesets][e['__tile']['tilesetUid']][:px_hei] - e['__tile']['y'] - e['__tile']['h'],
            w: e['__tile']['w'],
            h: e['__tile']['h'],
            tileset_uid: e['__tile']['tilesetUid']
          }
        end
        entity
      end

      # -------------------------------
      # generate the integer grid layer
      # -------------------------------
      if layer[:type] == :IntGrid
        layer[:int_grid] = Array.new(l['__cWid'] * l['__cHei'], 0)
        l['intGridCsv'].each.with_index do |value, index|
          x = index % l['__cWid']
          y = (l['__cHei'] - 1) - (index / l['__cWid']).to_i
          layer[:int_grid][x + y * l['__cWid']] = value
        end
      end

      all_layers.push(layer)
    end

    all_layers
  end

  def self.create_dr_friendly_tile(position, source, grid_size, flip_h, flip_v)
    {
      x: position.x, y: position.y,
      w: grid_size, h: grid_size,
      source_x: source.x, source_y: source.y,
      source_w: grid_size, source_h: grid_size,
      flip_horizontally: flip_h, flip_vertically: flip_v
    }
  end

  # Return the level's size
  # @return {w: width, h:height} [Hash]
  # @param level [LDtk.Level]
  def self.level_size(level)
    { w: level[:px_wid], h: level[:px_hei] }
  end

  # Return the relative path of a tileset
  # @return [String]
  # @param world [Hash] LDtkBridge's world data
  # @param uid [Integer] uid of the tileset
  def self.tileset_path(world, uid)
    world.folder + world.definitions[:tilesets][uid][:rel_path]
  end

  # return all named entities
  def self.all(layer, entity_identifier)
    layer[:entities].select { |e| e.identifier == entity_identifier }
  end

  def self.entities(layer)
    layer[:entities]
  end

  def self.get_int(layer, position_x, position_y)
    layer[:int_grid][position_x + position_y * layer[:cell_width]]
  end

  def self.level(world, level_name)
    world.levels[level_name]
  end

  def self.layer(world, level_name, layer_name)
    world.levels[level_name].layers[layer_name]
  end

  def self.level_field(world, level_name, field_name)
    world.levels[level_name].fields[field_name]
  end

  def self.entity_rect(entity)
    {
      x: entity.pos.x,
      y: entity.pos.y,
      w: entity[:size].w,
      h: entity[:size].h
    }

  end
  

  def self.entity_ref_field(world, entity_ref)
    level_identifier = world.levels
      .select { |_k, v| v.iid == entity_ref[:levelIid] }
      .values
      .first
      .identifier

    layer_identifier = world.levels[level_identifier]
      .layers
      .select { |_k, v| v.iid == entity_ref[:layerIid] }
      .values
      .first
      .identifier

    entity = world.levels[level_identifier]
      .layers[layer_identifier]
      .entities
      .select { |e| e.iid == entity_ref[:entityIid] }
      .first

    {
      level: level_identifier,
      layer: layer_identifier,
      entity: entity
    }

  end

  def self.tile_enum(world, tile)
    world.definitions[tile]

  end
end
