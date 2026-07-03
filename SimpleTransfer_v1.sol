// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title SimpleTransfer
 * @notice Contrat fil rouge — cours Blockchain & Finance, Master 2, DIT
 * @dev Version 1 — Séance 5 : fonctions, events, mapping, modifier
 */
contract SimpleTransfer {

    // ══════════════════════════════════════════════════
    // VARIABLES D'ÉTAT
    // ══════════════════════════════════════════════════

    address public owner;
    uint256 public totalTransfers;
    uint256 public totalAmountReceived;

    // 'struct' : regroupe plusieurs variables sous un type personnalisé
    // Chaque transfert aura : expéditeur, destinataire, montant, heure, note
    struct Transfer {
        address from;
        address to;
        uint256 amount;     // Montant en wei (1 ETH = 10^18 wei)
        uint256 timestamp;  // Heure Unix du bloc (secondes depuis 01/01/1970)
        string  note;       // Message optionnel (ex. 'Remboursement loyer')
    }

    // Tableau dynamique contenant tous les transferts
    Transfer[] public transfers;

    // mapping : associe chaque adresse à ses identifiants de transferts
    // Syntaxe : mapping(typeClé => typeValeur) nomVariable;
    mapping(address => uint256[]) public transfersByAddress;


    // ══════════════════════════════════════════════════
    // EVENTS
    // 'indexed' sur un paramètre permet de filtrer les logs efficacement
    // ══════════════════════════════════════════════════

    event TransferSent(
        address indexed from,
        address indexed to,
        uint256 amount,
        string  note
    );

    event FundsWithdrawn(address indexed to, uint256 amount);


    // ══════════════════════════════════════════════════
    // MODIFIER
    // '_; ' = corps de la fonction qui utilise ce modifier
    // ══════════════════════════════════════════════════

    modifier onlyOwner() {
        require(msg.sender == owner, 'Acces refuse : vous n etes pas le proprietaire');
        _;
    }


    // ══════════════════════════════════════════════════
    // CONSTRUCTEUR
    // ══════════════════════════════════════════════════

    constructor() {
        owner = msg.sender;
        totalTransfers = 0;
        totalAmountReceived = 0;
    }


    // ══════════════════════════════════════════════════
    // FONCTIONS
    // ══════════════════════════════════════════════════

    /**
     * @notice Envoyer des ETH à une adresse via ce contrat
     * @param _to    Adresse du destinataire
     * @param _note  Note optionnelle (ex. 'Paiement facture n°001')
     * @dev 'payable' : la fonction peut recevoir des ETH
     *      'msg.value' : montant d'ETH envoyé avec la transaction (en wei)
     */
    function sendTransfer(address payable _to, string memory _note)
        public
        payable
    {
        // ── CHECKS ──────────────────────────────
        require(msg.value > 0,          'Le montant doit etre superieur a 0');
        require(_to != address(0),      'Adresse destinataire invalide');

        // ── EFFECTS ─────────────────────────────
        uint256 transferId = transfers.length;
        transfers.push(Transfer({
            from:      msg.sender,
            to:        _to,
            amount:    msg.value,
            timestamp: block.timestamp,
            note:      _note
        }));
        transfersByAddress[msg.sender].push(transferId);
        totalTransfers++;
        totalAmountReceived += msg.value;

        // ── INTERACTIONS ─────────────────────────
        _to.transfer(msg.value);
        emit TransferSent(msg.sender, _to, msg.value, _note);
    }

    /**
     * @notice Nombre total de transferts enregistrés
     * @dev 'view' : lecture seule, gratuit
     */
    function getTransferCount() public view returns (uint256) {
        return transfers.length;
    }

    /**
     * @notice Détails d'un transfert par son identifiant
     * @param _id Identifiant (commence à 0)
     */
    function getTransfer(uint256 _id)
        public
        view
        returns (address, address, uint256, uint256, string memory)
    {
        require(_id < transfers.length, 'Transfert inexistant');
        Transfer memory t = transfers[_id];
        return (t.from, t.to, t.amount, t.timestamp, t.note);
    }

    /**
     * @notice Retirer les fonds restants du contrat
     * @dev Utilise le modifier onlyOwner
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, 'Aucun fonds a retirer');
        payable(owner).transfer(balance);
        emit FundsWithdrawn(owner, balance);
    }

}