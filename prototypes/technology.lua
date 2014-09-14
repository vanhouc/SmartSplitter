data:extend({
	{
		type = "technology",
		name = "smart-splitter-tech",
		icon = "__SmartSplitter__/graphics/icon_smart-splitter_tech.png",
		effects = 
		{
			{
				type = "unlock-recipe",
				recipe = "smart-splitter"
			}
		},
		prerequisites = {"logistics"},
		unit =
		{
		  count = 20,
		  ingredients = {{"science-pack-1", 1}},
		  time = 15
		}
	}
})