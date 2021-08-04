// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

import {IStableDebtToken} from '../../../interfaces/IStableDebtToken.sol';
import {IVariableDebtToken} from '../../../interfaces/IVariableDebtToken.sol';
import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {SafeERC20} from '../../../dependencies/openzeppelin/contracts/SafeERC20.sol';
import {Helpers} from '../helpers/Helpers.sol';
import {ValidationLogic} from './ValidationLogic.sol';
import {ReserveLogic} from './ReserveLogic.sol';
import {DataTypes} from './../types/DataTypes.sol';
import {UserConfiguration} from './../configuration/UserConfiguration.sol';

/**
 * @title PoolHelperLogic library
 * @author Aave
 * @notice Implements the helper logic for the POOL
 */
library PoolHelperLogic {
  using ReserveLogic for DataTypes.ReserveCache;
  using ReserveLogic for DataTypes.ReserveData;
  using UserConfiguration for DataTypes.UserConfigurationMap;
  using SafeERC20 for IERC20;

  // See `IPool` for descriptions
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

  function setUserUseReserveAsCollateral(
    mapping(address => DataTypes.ReserveData) storage reserves,
    DataTypes.UserConfigurationMap storage userConfig,
    address asset,
    bool useAsCollateral,
    mapping(uint256 => address) storage reservesList,
    uint256 reservesCount,
    address priceOracle
  ) public {
    DataTypes.ReserveData storage reserve = reserves[asset];
    DataTypes.ReserveCache memory reserveCache = reserve.cache();

    uint256 userBalance = IERC20(reserveCache.aTokenAddress).balanceOf(msg.sender);

    ValidationLogic.validateSetUseReserveAsCollateral(reserveCache, userBalance);

    userConfig.setUsingAsCollateral(reserve.id, useAsCollateral);

    if (useAsCollateral) {
      emit ReserveUsedAsCollateralEnabled(asset, msg.sender);
    } else {
      ValidationLogic.validateHFAndLtv(
        asset,
        msg.sender,
        reserves,
        userConfig,
        reservesList,
        reservesCount,
        priceOracle
      );

      emit ReserveUsedAsCollateralDisabled(asset, msg.sender);
    }
  }

  function dropReserve(
    mapping(address => DataTypes.ReserveData) storage reserves,
    mapping(uint256 => address) storage reservesList,
    address asset
  ) public {
    ValidationLogic.validateDropReserve(reserves[asset]);
    reservesList[reserves[asset].id] = address(0);
    delete reserves[asset];
  }

}
