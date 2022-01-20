# PoolTogether V4 Periphery Contracts

![Tests](https://github.com/pooltogether/v4-periphery/actions/workflows/main.yml/badge.svg)
[![Coverage Status](https://coveralls.io/repos/github/pooltogether/v4-periphery/badge.svg?branch=master)](https://coveralls.io/github/pooltogether/v4-periphery?branch=master)
[![built-with openzeppelin](https://img.shields.io/badge/built%20with-OpenZeppelin-3677FF)](https://docs.openzeppelin.com/)
[![GPLv3 license](https://img.shields.io/badge/License-GPLv3-blue.svg)](http://perso.crans.org/besson/LICENSE.html)

<strong>Have questions or want the latest news?</strong>
<br/>Join the PoolTogether Discord or follow us on Twitter:

[![Discord](https://badgen.net/badge/icon/discord?icon=discord&label)](https://discord.gg/JFBPMxv5tr)
[![Twitter](https://badgen.net/badge/icon/twitter?icon=twitter&label)](https://twitter.com/PoolTogether_)

**Documentation**<br>
- [PrizeDistributionFactory](https://v4.docs.pooltogether.com/protocol/reference/v4-periphery/PrizeDistributionFactory)
- [PrizeFlush](https://v4.docs.pooltogether.com/protocol/reference/v4-periphery/PrizeFlush)
- [PrizeTierHistory](https://v4.docs.pooltogether.com/protocol/reference/v4-periphery/PrizeTierHistory)
- [TwabRewards](https://v4.docs.pooltogether.com/protocol/reference/v4-periphery/TwabRewards)

**Deployments**<br>
- [Ethereum](https://v4.docs.pooltogether.com/protocol/reference/deployments/mainnet#mainnet)
- [Polygon](https://v4.docs.pooltogether.com/protocol/reference/deployments/mainnet#polygon)
- [Avalanche](https://v4.docs.pooltogether.com/protocol/reference/deployments/mainnet#avalanche)

# Getting Started

The project is made available as a NPM package.

```sh
$ yarn add @pooltogether/v4-periphery
```

The repo can be cloned from Github for contributions.

```sh
$ git clone https://github.com/pooltogether/v4-periphery
```

```sh
$ yarn
```

We use [direnv](https://direnv.net/) to manage environment variables.  You'll likely need to install it.

```sh
cp .envrc.example .envrv
```

# Testing

We use [Hardhat](https://hardhat.dev) and [hardhat-deploy](https://github.com/wighawag/hardhat-deploy)

To run unit tests:

```sh
$ yarn test
```

To run coverage:

```sh
$ yarn coverage
```
