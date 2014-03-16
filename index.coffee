ItemPile = require 'itempile'
{Recipe, AmorphousRecipe, PositionalRecipe, CraftingThesaurus, RecipeLocator} = require 'craftingrecipes'

module.exports = (game, opts) ->
  return new ToolsPlugin(game, opts)

module.exports.pluginInfo =
  loadAfter: ['voxel-recipes', 'voxel-registry']

class ToolsPlugin
  constructor: (@game, opts) ->
    @registry = game.plugins?.get('voxel-registry') ? throw new Error('voxel-pickaxe requires "voxel-registry" plugin')

    # TODO: require/warning if voxel-mine missing? without, 'speed' property won't have any effect
    @enable()

  enable: () ->
    @registry.registerBlock 'plankOak', {displayName: 'Oak Planks', texture: 'planks_oak'}

    @registry.registerItem 'stick', {itemTexture: 'items/stick'}

    @registry.registerItem 'pickaxeWood', {displayName: 'Wooden Pickaxe', itemTexture: 'items/wood_pickaxe', speed: 5.0, maxDamage:8}
    @registry.registerItem 'pickaxeStone', {displayName: 'Stone Pickaxe', itemTexture: 'items/stone_pickaxe', speed: 10.0, maxDamage:128}
    @registry.registerItem 'pickaxeIron', {displayName: 'Iron Pickaxe', itemTexture: 'items/iron_pickaxe', speed: 25.0, maxDamage:512}
    @registry.registerItem 'spadeWood', {displayName: 'Wooden Spade', itemTexture: 'items/wood_shovel', speed: 2.0, maxDamage:5} # TODO: effectiveness 'classes'
    @registry.registerItem 'spadeStone', {displayName: 'Stone Spade', itemTexture: 'items/stone_shovel', speed: 3.0, maxDamage:50}
    @registry.registerItem 'spadeIron', {displayName: 'Iron Spade', itemTexture: 'items/iron_shovel', speed: 4.0, maxDamage:500}

    # recipes
    recipes = @game.plugins?.get('voxel-recipes')
    if recipes?
      recipes.thesaurus.registerName 'wood.plank', 'plankOak'

      recipes.register new AmorphousRecipe(['wood.log'], new ItemPile('plankOak', 2))
      recipes.register new AmorphousRecipe(['wood.plank', 'wood.plank'], new ItemPile('stick', 4))

      recipes.register @pickaxeRecipe('wood.plank', 'pickaxeWood')
      recipes.register @pickaxeRecipe('cobblestone', 'pickaxeStone')
      recipes.register @pickaxeRecipe('ingotIron', 'pickaxeIron')

      recipes.register new RepairRecipe('pickaxeWood', 'plankOak', 4)
      recipes.register new RepairRecipe('pickaxeStone', 'cobblestone', 20)
      recipes.register new RepairRecipe('pickaxeIron', 'ingotIron', 200)


      recipes.register @spadeRecipe('wood.plank', 'spadeWood')
      recipes.register @spadeRecipe('cobblestone', 'spadeStone')
      recipes.register @spadeRecipe('ingotIron', 'spadeIron')


  pickaxeRecipe: (headMaterial, toolMaterial, handleMaterial='stick') ->
    return new PositionalRecipe([
      [headMaterial, headMaterial, headMaterial],
      [undefined, handleMaterial, undefined],
      [undefined, handleMaterial, undefined]], new ItemPile(toolMaterial, 1, {damage:0}))

  spadeRecipe: (headMaterial, toolMaterial, handleMaterial='stick') ->
    return new PositionalRecipe([
    # TODO: use 1x3 not 3x3, so can position in any column - but craftingrecipes only lets you place in 1st
    #  https://github.com/deathcap/craftingrecipes/issues/2
    #  [headMaterial],
    #  [handleMaterial],
    #  [handleMaterial]],
      [undefined, headMaterial, undefined],
      [undefined, handleMaterial, undefined],
      [undefined, handleMaterial, undefined]],
      new ItemPile(toolMaterial, 1, {damage:0}))


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
