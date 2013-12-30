ItemPile = require 'itempile'
{Recipe, AmorphousRecipe, PositionalRecipe, CraftingThesaurus, RecipeLocator} = require 'craftingrecipes'

module.exports = (game, opts) ->
  return new ToolsPlugin(game, opts)

module.exports.pluginInfo =
  loadAfter: ['craftingrecipes', 'voxel-registry']

class ToolsPlugin
  constructor: (@game, opts) ->
    @registry = game.plugins?.get('voxel-registry') ? throw 'voxel-pickaxe requires "voxel-registry" plugin'
    # TODO: require/warning if voxel-mine missing? without, 'speed' property won't have any effect
    @enable()

  enable: () ->
    @registry.registerBlock 'plankOak', {texture: 'planks_oak'}

    @registry.registerItem 'pickaxeWood', {itemTexture: '../items/wood_pickaxe', speed: 2.0, maxDamage:10} # TODO: fix path
    @registry.registerItem 'pickaxeStone', {itemTexture: '../items/stone_pickaxe', speed: 10.0, maxDamage:100}
    @registry.registerItem 'stick', {itemTexture: '../items/stick'}

    # recipes
    recipes = @game.plugins?.get('craftingrecipes')
    if recipes?
      recipes.thesaurus.registerName 'wood.plank', 'plankOak'

      recipes.register new AmorphousRecipe(['wood.log'], new ItemPile('plankOak', 2))
      recipes.register new AmorphousRecipe(['wood.plank', 'wood.plank'], new ItemPile('stick', 4))

      recipes.register new PositionalRecipe([
        ['wood.plank', 'wood.plank', 'wood.plank'],
        [undefined, 'stick', undefined],
        [undefined, 'stick', undefined]], new ItemPile('pickaxeWood', 1, {damage:0}))

      recipes.register new PositionalRecipe([
        ['cobblestone', 'cobblestone', 'cobblestone'],
        [undefined, 'stick', undefined],
        [undefined, 'stick', undefined]], new ItemPile('pickaxeStone', 1, {damage:0}))

  disable: () ->
    # TODO
