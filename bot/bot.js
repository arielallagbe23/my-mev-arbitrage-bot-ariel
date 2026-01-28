import "dotenv/config";
import { ethers } from "ethers";

const RPC_URL = process.env.SEPOLIA_RPC_URL;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const AMM = process.env.AMM_ADDRESS;
const BOT = process.env.BOT_ADDRESS;

if (!RPC_URL || !PRIVATE_KEY || !AMM || !BOT) {
  throw new Error("Missing env: SEPOLIA_RPC_URL, PRIVATE_KEY, AMM_ADDRESS, BOT_ADDRESS");
}

const ABI_AMM = [
  "function poolPrice(uint256) view returns (uint256)",
  "function quoteOut(uint256,address,uint256) view returns (uint256)"
];

const ABI_BOT = [
  "function run(uint256 amountInToken1, uint256 minProfitToken1) returns (uint256)"
];

const TOKEN0 = process.env.TOKEN0;
const TOKEN1 = process.env.TOKEN1;

if (!TOKEN0 || !TOKEN1) {
  throw new Error("Missing env: TOKEN0, TOKEN1");
}

const provider = new ethers.JsonRpcProvider(RPC_URL);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

const amm = new ethers.Contract(AMM, ABI_AMM, provider);
const bot = new ethers.Contract(BOT, ABI_BOT, wallet);

async function main() {
  const priceA = await amm.poolPrice(1);
  const priceB = await amm.poolPrice(2);

  const amountIn = ethers.parseUnits("100", 6); // 100 token1

  let poolBuy = 1;
  let poolSell = 2;
  if (priceA >= priceB) {
    poolBuy = 2;
    poolSell = 1;
  }

  const out0 = await amm.quoteOut(poolBuy, TOKEN1, amountIn);
  const out1 = await amm.quoteOut(poolSell, TOKEN0, out0);

  const profit = out1 > amountIn ? out1 - amountIn : 0n;
  console.log("Estimated profit:", ethers.formatUnits(profit, 6));

  if (profit === 0n) return;

  const minProfit = ethers.parseUnits("1", 6); // 1 token1 minimum
  const tx = await bot.run(amountIn, minProfit);
  console.log("Tx sent:", tx.hash);
  await tx.wait();
  console.log("Done");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
