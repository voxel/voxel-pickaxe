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

    #game.plugins?.get('voxel-carry').inventory.give new ItemPile('pickaxeWood', 1, {damage:5})
    #game.plugins?.get('voxel-carry').inventory.give new ItemPile('pickaxeStone', 1, {damage:10})
    #game.plugins?.get('voxel-carry').inventory.give new ItemPile('plankOak', 10)

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


      recipes.register new RepairRecipe('pickaxeWood', 'plankOak', 4)
      recipes.register new RepairRecipe('pickaxeStone', 'cobblestone', 20)

  disable: () ->
    # TODO


class RepairRecipe extends Recipe
  constructor: (@toolItem, @repairingItem, @repairAmount) ->

  findMatchingSlots: (inventory) ->
    # tool + repairing item, side by side in that order
    foundIndices = {}
    if inventory.get(0)?.item == @toolItem   # TODO: thesaurus
      foundIndices.tool = 0
    else
      return undefined

    if inventory.get(1)?.item == @repairingItem  # TODO: thesaurus
      foundIndices.repairing = 1
    else
      return undefined

    return foundIndices

  computeOutput: (inventory) ->
    slots = @findMatchingSlots(inventory)
    return undefined if not slots?

    tool = inventory.get(slots.tool)
    repairedTool = tool.clone()
    oldDamage = repairedTool.tags.damage ? 0
    newDamage = oldDamage - @repairAmount
    newDamage = 0 if newDamage < 0
    repairedTool.tags.damage = newDamage

    return repairedTool

  # TODO: refactor with craftingrecipes module
  craft: (inventory) ->
    slots = @findMatchingSlots(inventory)
    return undefined if !slots?

    inventory.takeAt slots.tool, 1 # TODO: check return
    inventory.takeAt slots.repairing, 1 # TODO: check return

    return @computeOutput(inventory)
