const { expect } = require("chai");

describe('Staking', () => {
  beforeEach(async () => {
    [owner, signer2] = await ethers.getSigners();
    Staking = await ethers.getContractFactory('Staking', owner);
    staking = await Staking.deploy(
      187848,
      {
        value: ethers.utils.parseEther('100')
      }
    );
    Chainlink = await ethers.getContractFactory('Chainlink', signer2);
    chainlink = await Chainlink.deploy();
    staking.connect(owner).addToken(
      'Chainlink',
      'LINK',
      chainlink.address,
      867,
      1500
    )
    await chainlink.connect(signer2).approve(
      staking.address,
      ethers.utils.parseEther('100')
    );
    staking.connect(signer2).stakeTokens(
      'LINK',
      ethers.utils.parseEther('100')
    )
  });

  describe('addToken', () => {
    it('adds a token symbol', async () => {
      const tokenSymbols = await staking.getTokenSymbols()
      expect(tokenSymbols).to.eql(['LINK'])
    })

    it('adds token information', async () => {
      const token = await staking.getToken('LINK')
      
      expect(token.tokenId).to.equal(1)
      expect(token.name).to.equal('Chainlink')
      expect(token.symbol).to.equal('LINK')
      expect(token.tokenAddress).to.equal(chainlink.address)
      expect(token.usdPrice).to.equal(867)
      expect(token.ethPrice).to.equal(0)
      expect(token.apy).to.equal(1500)
    })

    it('increments currentTokenId', async () => {
      expect( await staking.currentTokenId() ).to.equal(3)
    })
  })

  describe('stakeToken', () => {
    it('transfers tokens', async () => {
      const signerBalance = await chainlink.balanceOf(signer2.address)
      expect(signerBalance).to.equal( ethers.utils.parseEther('4900') )
      const contractBalance = await chainlink.balanceOf(staking.address)
      expect(contractBalance).to.equal( ethers.utils.parseEther('100') )
    })

    it('creates a position', async () => {
      const positionIds = await staking.connect(signer2).getPositionIdsForAddress()
      expect(positionIds.length).to.equal(1)

      const position = await staking.connect(signer2).getPositionIdsForId(positionIds[0])

      expect(position.positionId).to.equal(1)
      expect(position.walletAddress).to.equal(signer2.address)
      expect(position.name).to.equal('Chainlink')
      expect(position.symbol).to.equal('LINK')
      expect(position.apy).to.equal(1500)
      expect(position.tokenQuantity).to.equal( ethers.utils.parseEther('100') )
      expect(position.open).to.equal(true)
    })

    it('increments positionId', async () => {
      expect(await staking.currentPositionId()).to.equal(1)
    })
    it('increases total amount of staked token', async () => {
      expect(await staking.stakedTokens('LINK')).to.equal( ethers.utils.parseEther('100') )
    })
  })

  describe('calculateInterest', () => {
    it('returns interest accrued to a position', async () => {
      const apy = 150
      const value = ethers.utils.parseEther('100')
      const days = 365
      
      const interestRate = await staking.calculateInterest(apy, value, days)
      expect( String(interestRate) ).to.equal( String(ethers.utils.parseEther('15')) )
    })
  })

  describe('calculateNumberDays', () => {
    it('returns the number of days since createdDate', async () => {
      const provider = waffle.provider;
      const block = await provider.getBlock()
      const oneYearAgo = block.timestamp - (86400 * 101)
      const days = await staking.connect(owner).calculateInterestDays(oneYearAgo)

      expect(days).to.be.equal(101)
    })
  })

  describe('closePosition', () => {
    beforeEach(async () => {
      provider = waffle.provider;
      contractEthbalanceBefore = await provider.getBalance(staking.address)
      signerEthBalanceBefore = await provider.getBalance(signer2.address)

      const block = await provider.getBlock()
      const newCreatedDate = block.timestamp - (86400 * 365)
      await staking.connect(owner).modifyCreatedDate(1, newCreatedDate)
      await staking.connect(signer2).closePosition(1)
    })
    
    it('returns tokens to wallet', async () => {
      const signerBalance = await chainlink.balanceOf(signer2.address)
      expect(signerBalance).to.equal( ethers.utils.parseEther('5000') )
      const contractBalance = await chainlink.balanceOf(staking.address)
      expect(contractBalance).to.equal( ethers.utils.parseEther('0') )
    })

    it('sends ether interest to wallet', async () => {
      const contractEthBalanceAfter = await provider.getBalance(staking.address)
      const signerEthBalanceAfter = await provider.getBalance(signer2.address)
      expect(contractEthBalanceAfter).to.be.below(contractEthbalanceBefore)
      expect(signerEthBalanceAfter).to.be.above(signerEthBalanceBefore)
    })
    
    it('closes position', async () => {
      const position = await staking.connect(signer2).getPositionIdsForId(1)
      expect(position.open).to.equal(false)
    })
  })
})