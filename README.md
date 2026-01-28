## Rapport final — Projet MEV Arbitrage (Sepolia)

### 1) Objectif
Construire une mini “chaîne MEV” complète :
- détecter un écart de prix entre deux pools,
- exécuter un arbitrage atomique on-chain,
- prouver l’exécution sur Sepolia.

### 2) Théorie MEV (résumé)
- MEV = valeur extractible par un producteur de bloc en manipulant l’ordre / l’inclusion des transactions.
- Mempool = “dark forest” : observation, copie, frontrunning, gas wars.
- Exemples : Maker 2020 (liquidations), sandwiching, Salmonella.
- Flashbots : bundles ordonnés, invisibles à la mempool, gas price 0, paiement direct au mineur si bundle inclus.

### 3) Architecture du projet
- `MockUSD6.sol` / `MockUSD18.sol` : tokens de test (6 et 18 decimals).
- `DualPoolAMM.sol` : AMM minimal avec 2 pools indépendants (écart de prix).
- `ArbExecutor.sol` : exécution atomique, protections `minOut` et `minProfit`.
- Bot off-chain (Node.js) : lit les prix, calcule la rentabilité, déclenche l’exécution.

### 4) Tests locaux
- Commande : `forge test -vv`
- Résultat : 3 tests OK (prix différents, arbitrage profitable, revert si `minProfit` trop élevé).

### 5) Déploiement Sepolia
Déploiement via Foundry : `DeployAll.s.sol`

Adresses :
- MockUSD6: `0xaeBf95847EE37Ff8A1564052c87a2A5E9fB539B6`
- MockUSD18: `0xAA9d268f1902e0eedCF65eeb51DC2a4e2C068695`
- DualPoolAMM: `0x7E0cDd82a0F22382B18dCdB1c52F5F3fa99C7147`
- ArbExecutor: `0x8A95e6b889542a9077787a1a9240161d4A5E5375`

### 6) Exécution (preuve MEV)
Transaction d’arbitrage réussie :
- Tx hash : `0x5d01ab1be19c112f9ba826b2c8d294c204b6cb51bb6f653f327cb5c40c59c46d`
- Profit affiché : **2 (token1 / stable 6 decimals)**

### 7) Conclusion
Le projet démontre bien le MEV par arbitrage :
- un écart de prix est créé entre deux pools,
- le bot détecte l’opportunité,
- le contrat exécute l’arbitrage en une transaction,
- la transaction Sepolia prouve l’extraction de profit.
