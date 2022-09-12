const { BN, constants, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');
const { ZERO_ADDRESS } = constants;

const {
  shouldBehaveLikeERC20,
  shouldBehaveLikeERC20Transfer,
  shouldBehaveLikeERC20Approve,
} = require('./ERC20.behavior');

const ERC20Mock = artifacts.require('ERC20');

contract('ERC20', function (accounts) {
  const [ initialHolder, recipient, anotherAccount ] = accounts;

  const name = 'My Token';
  const symbol = 'MTKN';

  const decimals = 18;

  const initialSupply = new BN(50);

  beforeEach(async function () {
    this.token = await ERC20Mock.new(name, symbol, decimals);
  });

  it('has a name', async function () {
    expect(await this.token.name()).to.equal(name);
  });

  it('has a symbol', async function () {
    expect(await this.token.symbol()).to.equal(symbol);
  });

  it('has 18 decimals', async function () {
    expect(await this.token.decimals()).to.be.bignumber.equal('18');
  });

  shouldBehaveLikeERC20('ERC20', initialSupply, initialHolder, recipient, anotherAccount);

  describe('_mint', function () {
    const amount = new BN(50);
    it('rejects a null account', async function () {
      await expectRevert(
        this.token.mintTo(ZERO_ADDRESS, amount), 'ERC20: mint to the zero address',
      );
    });

    describe('for a non zero account', function () {
      beforeEach('minting', async function () {
        this.receipt = await this.token.mintTo(recipient, amount);
      });

      it('increments totalSupply', async function () {
        const expectedSupply = initialSupply.add(amount);
        expect(await this.token.totalSupply()).to.be.bignumber.equal(expectedSupply);
      });

      it('increments recipient balance', async function () {
        expect(await this.token.balanceOf(recipient)).to.be.bignumber.equal(amount);
      });

      it('emits Transfer event', async function () {
        const event = expectEvent(
          this.receipt,
          'Transfer',
          { from: ZERO_ADDRESS, to: recipient },
        );

        expect(event.args.value).to.be.bignumber.equal(amount);
      });
    });
  });

  describe('_burn', function () {
    it('rejects a null account', async function () {
      await expectRevert(this.token.burnFrom(ZERO_ADDRESS, new BN(1)),
        'ERC20: burn from the zero address');
    });

    describe('for a non zero account', function () {
      it('rejects burning more than balance', async function () {
        await expectRevert(this.token.burnFrom(
          initialHolder, initialSupply.addn(1)), 'ERC20: burn amount exceeds balance',
        );
      });

      const describeBurn = function (description, amount) {
        describe(description, function () {
          beforeEach('burning', async function () {
            this.receipt = await this.token.burnFrom(initialHolder, amount);
          });

          it('decrements totalSupply', async function () {
            const expectedSupply = initialSupply.sub(amount);
            expect(await this.token.totalSupply()).to.be.bignumber.equal(expectedSupply);
          });

          it('decrements initialHolder balance', async function () {
            const expectedBalance = initialSupply.sub(amount);
            expect(await this.token.balanceOf(initialHolder)).to.be.bignumber.equal(expectedBalance);
          });

          it('emits Transfer event', async function () {
            const event = expectEvent(
              this.receipt,
              'Transfer',
              { from: initialHolder, to: ZERO_ADDRESS },
            );

            expect(event.args.value).to.be.bignumber.equal(amount);
          });
        });
      };

      describeBurn('for entire balance', initialSupply);
      describeBurn('for less amount than balance', initialSupply.subn(1));
    });
  });

  describe('_transfer', function () {
    shouldBehaveLikeERC20Transfer('ERC20', initialHolder, recipient, initialSupply, function (from, to, amount) {
      return this.token.transferInternal(from, to, amount);
    });

    describe('when the sender is the zero address', function () {
      it('reverts', async function () {
        await expectRevert(this.token.transferInternal(ZERO_ADDRESS, recipient, initialSupply),
          'ERC20: transfer from the zero address',
        );
      });
    });
  });

  describe('_approve', function () {
    shouldBehaveLikeERC20Approve('ERC20', initialHolder, recipient, initialSupply, function (owner, spender, amount) {
      return this.token.approveInternal(owner, spender, amount);
    });

    describe('when the owner is the zero address', function () {
      it('reverts', async function () {
        await expectRevert(this.token.approveInternal(ZERO_ADDRESS, recipient, initialSupply),
          'ERC20: approve from the zero address',
        );
      });
    });
  });
});