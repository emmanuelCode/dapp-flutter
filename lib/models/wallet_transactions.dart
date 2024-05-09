import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:web3modal_flutter/web3modal_flutter.dart';

const projectID = String.fromEnvironment('PROJECT_ID');

const _chainId = '31337'; //hardhat default chainId

final _hardHatChain = W3MChainInfo(
  chainName: 'Hardhat',
  namespace: 'eip155:$_chainId',
  chainId: _chainId,
  tokenName: 'ETH',
  rpcUrl: 'http://localhost:8545',
);

class WalletTransactions {
  WalletTransactions() {
    _loadContract();
    _initWalletConnect();
  }

  late final W3MService _w3mService;
  late final String _contractAbi;
  late final Uint8List _contractData;
  late final String _contractAddress;

  void _initWalletConnect() async {
    _w3mService = W3MService(
      projectId: projectID,
      // replace with your own info
      metadata: const PairingMetadata(
        name: 'Web3Modal Flutter Example',
        description: 'A Sample Dapp in Flutter',
        url: 'https://flutter.dev/',
        // flutter logo on the web
        icons: ['https://storage.googleapis.com/cms-storage-bucket/0dbfcc7a59cd1cf16282.png'],
        redirect: Redirect(
          native: 'flutterdapp://',
          universal: 'https://www.walletconnect.com',
        ),
      ),
    );

    // add hardhat chain to presets
    W3MChainPresets.chains
        .putIfAbsent(_hardHatChain.chainId, () => _hardHatChain);
    await _w3mService.init();
  }

  // load contract from Remix json
  void _loadContract() async {
    final contractCode =
        await rootBundle.loadString('contracts/artifacts/Logic.json');
    final abi = jsonDecode(contractCode)['abi'];
    final bytecode = jsonDecode(contractCode)['data']['bytecode']['object'];

    debugPrint('contract bytecode: $bytecode');
    debugPrint('contract abi: ${abi.toString()}');

    _contractAbi = jsonEncode(abi);
    _contractData = hexToBytes(bytecode);
  }

  // to learn more about rpc methods:
  // https://ethereum.org/en/developers/docs/apis/json-rpc/
  void deployContract() async {
    final client = Web3Client(_w3mService.selectedChain!.rpcUrl, http.Client());

    final transaction = Transaction(
      // you need to define the from when doing transaction to push contract code
      from: EthereumAddress.fromHex(_w3mService.session!.address!),
      data: _contractData,
    );

    // always launch the wallet before making a Transaction with Web3Modal
    _w3mService.launchConnectedWallet();

    final String transactionHash = await _w3mService.request(
      topic: _w3mService.session!.topic!,
      // we need the namespace format here
      chainId: _w3mService.selectedChain!.namespace,
      request: SessionRequestParams(
        // w3model has string constant to help with request
        method: MethodsConstants.ethSendTransaction,
        params: [transaction.toJson()],
      ),
    );

    debugPrint('hash: $transactionHash');

    // web3modal doesn't support `eth_getTransactionHash` with _w3mService.request(). However, you have the Web3dart
    // bundle in Web3Modal so you can use it to get the package like so.
    // you can list what's available with _w3mService.session!.getApprovedMethods()
    final transactionReceipt =
        await client.getTransactionReceipt(transactionHash);
    final transactionInformation =
        await client.getTransactionByHash(transactionHash);
    final networkId = await client.getNetworkId();

    debugPrint('transactionReceipt: $transactionReceipt');
    debugPrint('transactionInformation: $transactionInformation');
    debugPrint('network: $networkId');

    _contractAddress = transactionReceipt!.contractAddress!.hex;
  }

  void addEtherRequest({
    required EtherUnit etherUnitValue,
    required int amount,
  }) async {
    final client = Web3Client(_w3mService.selectedChain!.rpcUrl, http.Client());

    _w3mService.launchConnectedWallet();
    final String transactionHash = await _w3mService.requestWriteContract(
      rpcUrl: _w3mService.selectedChain!.rpcUrl,
      deployedContract: DeployedContract(
        ContractAbi.fromJson(_contractAbi, 'logic_abi'),
        EthereumAddress.fromHex(_contractAddress),
      ),
      topic: _w3mService.session!.topic!,
      chainId: _w3mService.selectedChain!.namespace,
      functionName: 'add',
      transaction: Transaction(
        from: EthereumAddress.fromHex(_w3mService.session!.address!),
        value: EtherAmount.fromInt(etherUnitValue, amount),
      ),
    );

    final transactionReceipt =
        await client.getTransactionReceipt(transactionHash);

    debugPrint('Add Transaction: $transactionReceipt');
  }

  void retrieveEtherRequest() async {
    final client = Web3Client(_w3mService.selectedChain!.rpcUrl, http.Client());

    _w3mService.launchConnectedWallet();
    final String transactionHash = await _w3mService.requestWriteContract(
      rpcUrl: _w3mService.selectedChain!.rpcUrl,
      deployedContract: DeployedContract(
        ContractAbi.fromJson(_contractAbi, 'logic_abi'),
        EthereumAddress.fromHex(_contractAddress),
      ),
      topic: _w3mService.session!.topic!,
      chainId: _w3mService.selectedChain!.namespace,
      functionName: 'retrieve',
      transaction: Transaction(
        from: EthereumAddress.fromHex(_w3mService.session!.address!),
      ),
    );

    final transactionReceipt =
        await client.getTransactionReceipt(transactionHash);

    debugPrint('Retrieve Transaction: $transactionReceipt');
  }

  Future<EtherAmount> get deployedContractBalance async {
    final client = Web3Client(_w3mService.selectedChain!.rpcUrl, http.Client());
    return client.getBalance(EthereumAddress.fromHex(_contractAddress));
  }

  W3MService get w3MService {
    return _w3mService;
  }
}
