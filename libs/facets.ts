import { ethers } from "hardhat";
import { BigNumber } from "ethers";

const GMXPFacetList: string[] = ["Stake", "Query", "Settings", "Create"];

const Amounts: BigNumber[] = [
  ethers.utils.parseEther("40000"),
  ethers.utils.parseEther("60000"),
  ethers.utils.parseEther("80000"),
  ethers.utils.parseEther("100000"),
  ethers.utils.parseEther("120000"),
  ethers.utils.parseEther("140000"),
  ethers.utils.parseEther("160000"),
  ethers.utils.parseEther("180000"),
  ethers.utils.parseEther("200000"),
  ethers.utils.parseEther("220000"),
  ethers.utils.parseEther("320000"),
  ethers.utils.parseEther("420000"),
  ethers.utils.parseEther("520000"),
  ethers.utils.parseEther("620000"),
  ethers.utils.parseEther("720000"),
  ethers.utils.parseEther("820000"),
  ethers.utils.parseEther("920000"),
  ethers.utils.parseEther("1000000"),
];
const AmountMultipliers: number[] = [
  10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 150, 200, 250, 300, 350, 400, 450,
  500,
];
// 2678400,
const Times: number[] = [
  300, 7862400, 15638400, 31190400, 62294400, 93398400, 124502400, 155606400,
];
const TimeMultiplers: number[] = [10, 15, 20, 40, 80, 120, 160, 200];

exports.FacetList = GMXPFacetList;

exports.Amounts = Amounts;
exports.AmountMultipliers = AmountMultipliers;
exports.Times = Times;
exports.TimeMultiplers = TimeMultiplers;
