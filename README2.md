## MEV Arbitrage Bot (Sepolia) — Foundry + Node.js

Objectif : démontrer un arbitrage MEV complet sur Sepolia avec :
- un AMM minimal à deux pools (écart de prix),
- un contrat d’exécution atomique,
- un bot off-chain qui observe, calcule, exécute.

### Rappel théorique (MEV, Flashbots, Dark Forest)
**Définition MEV** : “valeur extractible par un producteur de bloc en manipulant l’ordre / l’inclusion des transactions.”

**Pourquoi c’est important**
- Les opportunités MEV proviennent de l’ordre des transactions (arbitrage, liquidations, mint, airdrops).
- La mempool est un “dark forest” : tout le monde observe, copie et surenchérit.
- Résultat : gas wars, échecs de transactions, et extraction invisible de valeur.

**Flashbots (idée clé)**
- Envoie de “bundles” : transactions ordonnées, invisibles à la mempool publique.
- Gas price = 0 dans les bundles, et le mineur est payé via un transfert on-chain.
- Le mineur n’est payé que si tout le bundle est inclus et exécuté correctement.
- Réduit les “bidding wars” et les transactions échouées.

**Exemples marquants (cours)**
- Maker 2020 (“heist”) : congestion + liquidation, bots gagnent en bloquant la concurrence.
- Sandwiching : front-run + back-run autour d’un swap pour extraire un profit.
- Salmonella : piège anti-sandwich (token invendable pour le bot).

### Positionnement du projet
Ce repo se concentre sur :
- un **arbitrage on-chain atomique**,
- un **bot off-chain searcher** (détection + exécution),
- un **déploiement Sepolia** avec preuve d’exécution.

Flashbots et bundles peuvent être ajoutés en extension, mais le cœur pédagogique est déjà respecté.

### Architecture
- `DualPoolAMM.sol` : AMM simple avec 2 pools indépendants.
- `ArbExecutor.sol` : contrat qui fait l’arbitrage en une transaction.
- `MockUSD6.sol` / `MockUSD18.sol` : tokens de test.
- `DeployAll.s.sol` : déploiement + seed des pools.
- `RunArb.s.sol` : exécution d’arbitrage on-chain.

### Prérequis
- Foundry
- Node.js (pour le bot)
- Sepolia ETH + RPC

### Installation
```bash
forge install
```

### Config
Créer un `.env` :
```env
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY
PRIVATE_KEY=0x...
```

### Déploiement
```bash
forge script script/DeployAll.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --private-key $PRIVATE_KEY
```

### Exécution on-chain
Remplir les adresses dans `script/RunArb.s.sol`, puis :
```bash
forge script script/RunArb.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --private-key $PRIVATE_KEY
```
