import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Crypto Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  Future<String> _loadContractAbi() async {
    final contractCode =
        await rootBundle.loadString('contracts/artifacts/Logic.json');
    final abi = jsonDecode(contractCode)['abi'];
    debugPrint(abi.toString());

    return jsonEncode(abi);
  }

  Future<Uint8List> _loadContractData() async {
    final contractCode =
        await rootBundle.loadString('contracts/artifacts/Logic.json');
    final bytecode = jsonDecode(contractCode)['data']['bytecode']['object'];

    //final data = jsonEncode(bytecode);
    debugPrint(bytecode);

    return hexToBytes(bytecode);
  }

  @override
  Widget build(BuildContext context) {
    var apiUrl = "http://localhost:8545"; //Replace with your API

    final ethClient = Web3Client(apiUrl, Client());

    EthPrivateKey credentials = EthPrivateKey.fromHex(
        '0xc526ee95bf44d8fc405a158bb884d9d1238d99f0612e9f33d006bb0789009aaa');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Web3Dart Test',
               style: Theme.of(context).textTheme.headlineMedium
            ),
            ElevatedButton(
              onPressed: () async {
                callAddFunction(contractAdressTemp!, credentials, ethClient);
              },
              child: const Text('Transac'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          debugPrint('hey');

          deployContractTransact(ethClient, credentials);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  EthereumAddress? contractAdressTemp;

  // deploy smart contract using web3dart methods
  void deployContractTransact(
      Web3Client client, Credentials credentials) async {

    // load contract data from Remix json     
    final transaction = Transaction(data: await _loadContractData());

  
    final transactionHash =
        await client.sendTransaction(credentials, transaction, chainId: 31337);

      // output transactionReceipt
    final transactionReceipt =
        await client.getTransactionReceipt(transactionHash);
    debugPrint('receipt: $transactionReceipt');

    // output deployed contract address
    debugPrint('contract address: ${transactionReceipt?.contractAddress}');

    contractAdressTemp = transactionReceipt?.contractAddress;
  }

  // calls add function from Logic.sol file
  void callAddFunction(EthereumAddress contractAddress, Credentials credentials,
      Web3Client client) async {

    // load contract from abi    
    DeployedContract contract = DeployedContract(
        ContractAbi.fromJson(await _loadContractAbi(), 'logic'),
        contractAddress);

    final transaction = Transaction.callContract(
      // don't need to specify address will take from credential
      //from: EthereumAddress.fromHex('0xdf3e18d64bc6a983f673ab319ccae4f1a57c7097'),
      contract: contract,
      function: contract.function('add'),
      parameters: [],
      value: EtherAmount.fromBigInt(EtherUnit.ether, BigInt.one),
      // will let the network estimate the gas price
      //gasPrice: EtherAmount.inWei(BigInt.from(1000000000)),
      // I won't set a limit for gas price
      //maxGas: 300000,
    );

    final transactionHash = await client.sendTransaction(
        credentials, transaction,
        chainId: 31337 //hardhat chain id
        );

    // output transactionHash
    debugPrint('transactionHash: $transactionHash');

    // output transaction receipt
    final receipt = await client.getTransactionReceipt(transactionHash);
    debugPrint('receipt: $receipt');

    // output contract balance
    final logicContractBalance = await client.getBalance(contractAddress);
    debugPrint('logicContractBalance: $logicContractBalance');

    // output account balance
    final accountBalance = await client.getBalance(credentials.address);
    debugPrint('accountBalance: $accountBalance');
  }
}
