data:extend({
  {
    type = "splitter",
    name = "smart-splitter",
    icon = "__SmartSplitter__/graphics/icons/smart-splitter.png",
    flags = {"placeable-neutral", "player-creation"},
    minable = {hardness = 0.2, mining_time = 0.5, result = "smart-splitter"},
    max_health = 80,
    corpse = "medium-remnants",
    resistances = 
    {
      {
        type = "fire",
        percent = 60
      }
    },
    collision_box = {{-0.9, -0.1}, {0.9, 0.1}},
    selection_box = {{-0.9, -0.5}, {0.9, 0.5}},
    animation_speed_coefficient = 32,
    structure_animation_speed_coefficient = 0.7,
    structure_animation_movement_cooldown = 10,
    belt_horizontal = basic_belt_horizontal,
    belt_vertical = basic_belt_vertical,
    ending_top = basic_belt_ending_top,
    ending_bottom = basic_belt_ending_bottom,
    ending_side = basic_belt_ending_side,
    starting_top = basic_belt_starting_top,
    starting_bottom = basic_belt_starting_bottom,
    starting_side = basic_belt_starting_side,
    ending_patch = ending_patch_prototype,
    fast_replaceable_group = "splitter",
    speed = 0.03125,
    structure =
    {
      north =
      {
        filename = "__SmartSplitter__/graphics/entity/basic-splitter/smart-splitter-north.png",
        frame_count = 32,
        line_length = 16,
        priority = "extra-high",
        frame_width = 80,
        frame_height = 35,
        shift = {0.225, 0}
      },
      east =
      {
        filename = "__SmartSplitter__/graphics/entity/basic-splitter/smart-splitter-east.png",
        frame_count = 32,
        line_length = 16,
        priority = "extra-high",
        frame_width = 46,
        frame_height = 81,
        shift = {0.075, 0}
      },
      south =
      {
        filename = "__SmartSplitter__/graphics/entity/basic-splitter/smart-splitter-south.png",
        frame_count = 32,
        line_length = 16,
        priority = "extra-high",
        frame_width = 82,
        frame_height = 36,
        shift = {0.075, 0}
      },
      west =
      {
        filename = "__SmartSplitter__/graphics/entity/basic-splitter/smart-splitter-west.png",
        frame_count = 32,
        line_length = 16,
        priority = "extra-high",
        frame_width = 47,
        frame_height = 79,
        shift = {0.25, 0.05}
      },
    },
    ending_patch = ending_patch_prototype
  }
})