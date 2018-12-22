const assetTracker = artifacts.require("AssetTracker");

contract("AssetTracker contract test", async accounts => {
  let item1 = {
    identifier: "Barcode",
    code: "13456-fgs",
    description: "This is the first dummy item."
  }

  it("should register an item", async () => {
    let instance = await assetTracker.deployed();
    await instance.registerItem(item1.identifier, item1.code, item1.description);
    let pass = await instance.getItemByToken(1);
    assert.equal(pass[0], item1.identifier, "identifiers are not equal");
    assert.equal(pass[1], item1.code, "codes are not equal");
    // assert.equal(instance.ownerOf(1), accounts[0], "token is not owned by any or the correct user");
  });

  it("should be able to validate if an item already exists", async () => {
    let instance = await assetTracker.deployed();
    assert.equal(await instance.doesItemExist(item1.identifier,item1.code), true, "item does not exist.")
  })

  it("should allow the owner to put the item on sale", async () => {
    let instance = await assetTracker.deployed();
    await instance.putOnSale(1, 501010, {from: accounts[0]});
    let result = await instance.isOnSale(1)
    assert.equal(result[0] , true, "is not on sale");
  })

  it("should allow the owner to put a reserved address", async () => {
    let instance = await assetTracker.deployed();
    await instance.setReserved(1, accounts[1]);
    let result = await instance.getReserved(1);
    assert.equal(result, accounts[1], "is not equal to the reserved account");
  })

});
