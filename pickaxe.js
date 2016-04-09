'use strict';

const ItemPile = require('itempile');
const craftingrecipes = require('craftingrecipes');

const Recipe = craftingrecipes.Recipe;
const AmorphousRecipe = craftingrecipes.AmorphousRecipe;
const PositionalRecipe = craftingrecipes.PositionalRecipe;
const CraftingThesaurus = craftingrecipes.CraftingThesaurus;
const RecipeLocator = craftingrecipes.RecipeLocator;

module.exports = (game, opts) => new ToolsPlugin(game, opts);

module.exports.pluginInfo = {
  loadAfter: ['voxel-recipes', 'voxel-registry']
};

class ToolsPlugin {
  constructor(game, opts) {
    this.game = game;
    
    this.registry = game.plugins.get('voxel-registry');
    if (!this.registry) throw new Error('voxel-pickaxe requires "voxel-registry" plugin');

    //  TODO: require/warning if voxel-mine missing? without, 'speed' property won't have any effect
    this.enable();
  }

  enable() {
    this.registry.registerBlock('plankOak', {displayName: 'Oak Planks', texture: 'planks_oak'});

    this.registry.registerItem('stick', {itemTexture: 'items/stick'});

    this.registry.registerItem('pickaxeWood', {displayName: 'Wooden Pickaxe', itemTexture: 'items/wood_pickaxe', speed: 5.0, maxDamage:8, toolClass: 'pickaxe'});
    this.registry.registerItem('pickaxeStone', {displayName: 'Stone Pickaxe', itemTexture: 'items/stone_pickaxe', speed: 10.0, maxDamage:128, toolClass: 'pickaxe'});
    this.registry.registerItem('pickaxeIron', {displayName: 'Iron Pickaxe', itemTexture: 'items/iron_pickaxe', speed: 25.0, maxDamage:512, toolClass: 'pickaxe'});

    this.registry.registerItem('spadeWood', {displayName: 'Wooden Spade', itemTexture: 'items/wood_shovel', speed: 5.0, maxDamage:8, toolClass: 'spade'});
    this.registry.registerItem('spadeStone', {displayName: 'Stone Spade', itemTexture: 'items/stone_shovel', speed: 10.0, maxDamage:128, toolClass: 'spade'});
    this.registry.registerItem('spadeIron', {displayName: 'Iron Spade', itemTexture: 'items/iron_shovel', speed: 25.0, maxDamage:512, toolClass: 'spade'});

    this.registry.registerItem('axeWood', {displayName: 'Wooden Axe', itemTexture: 'items/wood_axe', speed: 5.0, maxDamage:8, toolClass: 'axe'});
    this.registry.registerItem('axeStone', {displayName: 'Stone Axe', itemTexture: 'items/stone_axe', speed: 10.0, maxDamage:128, toolClass: 'axe'});
    this.registry.registerItem('axeIron', {displayName: 'Iron Axe', itemTexture: 'items/iron_axe', speed: 25.0, maxDamage:512, toolClass: 'axe'});

 
    // recipes
    const recipes = this.game.plugins.get('voxel-recipes');
    if (recipes) {
      recipes.thesaurus.registerName('wood.plank', 'plankOak');

      recipes.register(new AmorphousRecipe(['wood.log'], new ItemPile('plankOak', 2)));
      recipes.register(new AmorphousRecipe(['wood.plank', 'wood.plank'], new ItemPile('stick', 4)));

      recipes.register(this.pickaxeRecipe('wood.plank', 'pickaxeWood'));
      recipes.register(this.pickaxeRecipe('cobblestone', 'pickaxeStone'));
      recipes.register(this.pickaxeRecipe('ingotIron', 'pickaxeIron'));

      recipes.register(new RepairRecipe('pickaxeWood', 'plankOak', 4));
      recipes.register(new RepairRecipe('pickaxeStone', 'cobblestone', 20));
      recipes.register(new RepairRecipe('pickaxeIron', 'ingotIron', 200));


      recipes.register(this.spadeRecipe('wood.plank', 'spadeWood'));
      recipes.register(this.spadeRecipe('cobblestone', 'spadeStone'));
      recipes.register(this.spadeRecipe('ingotIron', 'spadeIron'));

      recipes.register(this.axeRecipe('wood.plank', 'axeWood'));
      recipes.register(this.axeRecipe('cobblestone', 'axeStone'));
      recipes.register(this.axeRecipe('ingotIron', 'axeIron'));
    }
  }


  pickaxeRecipe(headMaterial, toolMaterial, handleMaterial) {
    if (handleMaterial === undefined) handleMaterial = 'stick';
    return new PositionalRecipe([
      [headMaterial, headMaterial, headMaterial],
      [undefined, handleMaterial, undefined],
      [undefined, handleMaterial, undefined]], new ItemPile(toolMaterial, 1, {damage:0}));
  }

  spadeRecipe(headMaterial, toolMaterial, handleMaterial) {
    if (handleMaterial === undefined) handleMaterial = 'stick';
    return new PositionalRecipe([
      [headMaterial],
      [handleMaterial],
      [handleMaterial]],
      new ItemPile(toolMaterial, 1, {damage:0}));
  }

  axeRecipe(headMaterial, toolMaterial, handleMaterial) {
    if (handleMaterial === undefined) handleMaterial = 'stick';
    // TODO: support mirrored recipe
    return new PositionalRecipe([
      [headMaterial, headMaterial],
      [handleMaterial, headMaterial],
      [handleMaterial, undefined]], new ItemPile(toolMaterial, 1, {damage:0}));
  }

  disable() {
    // TODO
  }
}

class RepairRecipe extends Recipe {
  constructor(toolItem, repairingItem, repairAmount) {
    this.toolItem = toolItem;
    this.repairingItem = repairingItem;
    this.repairAmount = repairAmount;
  }

  findMatchingSlots(inventory) {
    // tool + repairing item, side by side in that order
    const foundIndices = {};
    if (inventory.get(0) !== undefined && inventory.get(0).item === this.toolItem) {   // TODO: thesaurus
      foundIndices.tool = 0;
    } else {
      return undefined;
    }

    if (inventory.get(1) !== undefined && inventory.get(1).item === this.repairingItem) {  // TODO: thesaurus
      foundIndices.repairing = 1;
    } else {
      return undefined;
    }

    return foundIndices;
  }

  computeOutput(inventory) {
    const slots = this.findMatchingSlots(inventory);
    if (slots === undefined) return undefined;

    const tool = inventory.get(slots.tool);
    const repairedTool = tool.clone();
    const oldDamage = repairedTool.tags.damage !== undefined ? repairedTool.tags.damage : 0;
    let newDamage = oldDamage - this.repairAmount
    if (newDamage < 0) newDamage = 0;
    repairedTool.tags.damage = newDamage;

    return repairedTool;
  }

  // TODO: refactor with craftingrecipes module
  craft(inventory) {
    const slots = this.findMatchingSlots(inventory);
    if (slots === undefined) return undefined;

    inventory.takeAt(slots.tool, 1); // TODO: check return
    inventory.takeAt(slots.repairing, 1); // TODO: check return

    return this.computeOutput(inventory);
  }
}

