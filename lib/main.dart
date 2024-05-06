import 'dart:convert';

import 'package:cryptofont/cryptofont.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:web3modal_flutter/web3modal_flutter.dart';
import 'package:http/http.dart' as http;

const projectID = String.fromEnvironment('PROJECT_ID');

const _chainId = '31337'; //hardhat default chainId

final _hardHatChain = W3MChainInfo(
  chainName: 'Hardhat',
  namespace: 'eip155:$_chainId',
  chainId: _chainId,
  tokenName: 'ETH',
  rpcUrl: 'http://localhost:8545',
);

final _themeData = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
);

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Web3ModalTheme(
      themeData: Web3ModalThemeData(
        lightColors: Web3ModalColors.lightMode.copyWith(
          accent100: _themeData.colorScheme.primary,
          background125: _themeData.colorScheme.background,
        ),
      ),
      child: MaterialApp(
        title: 'Flutter Dapp Demo',
        theme: _themeData,
        home: const MyHomePage(title: 'Flutter Dapp Demo'),
      ),
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
  late final W3MService _w3mService;
  final client = Web3Client(_hardHatChain.rpcUrl, http.Client());

  var _contractAbi = '';
  var _contractData = Uint8List(0);
  var _contractAddress = '';

  var _etherUnitValue = EtherUnit.values.first;
  final _textEditAmount = TextEditingController();
  var _currentContractBalance = BigInt.zero;

  @override
  initState() {
    super.initState();
    _initWalletConnect();
    _loadContract();
  }

  void _initWalletConnect() async {
    _w3mService = W3MService(
      projectId: projectID,
      //logLevel: LogLevel.debug,
      metadata: const PairingMetadata(
        name: 'Web3Modal Flutter Example',
        description: 'Web3Modal Flutter Example',
        url: 'https://www.walletconnect.com/',
        icons: ['https://walletconnect.com/walletconnect-logo.png'],
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

    debugPrint(bytecode);
    debugPrint(abi.toString());

    _contractAbi = jsonEncode(abi);
    _contractData = hexToBytes(bytecode);
  }

  // to learn more about rpc methods:
  // https://ethereum.org/en/developers/docs/apis/json-rpc/
  void _deployContract() async {
    final transaction = Transaction(
      // you need to define the from when doing transaction to push contract code
      from: EthereumAddress.fromHex(_w3mService.session!.address!),
      data: _contractData,
    );

    debugPrint(_w3mService.selectedChain!.namespace);
    debugPrint(_w3mService.session!.topic!);
    debugPrint(_w3mService.session!.address);

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

    //web3modal doesn't support `eth_getTransactionHash` with _w3mService.request(). However, you have the Web3dart
    // bundle in Web3Modal so you can use it to get the package like so.
    // you can list what available with _w3mService.session!.getApprovedMethods()
    final transactionReceipt =
        await client.getTransactionReceipt(transactionHash);
    final transactionInformation =
        await client.getTransactionByHash(transactionHash);
    final networkId = await client.getNetworkId();

    debugPrint('transactionReceipt: $transactionReceipt');
    debugPrint('transactionInformation: $transactionInformation');
    debugPrint('network: $networkId');

    debugPrint(
        'calulate cost gasUnits X gasPriceForOneUnit ${transactionInformation!.gas * transactionInformation.gasPrice.getInWei.toInt()}');
    debugPrint('transaction cost: ${transactionReceipt!.gasUsed}');

    _contractAddress = transactionReceipt.contractAddress!.hex;
  }

  void _addEtherRequest() async {
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
        value: EtherAmount.fromInt(
            _etherUnitValue, int.parse(_textEditAmount.text)),
      ),
    );

    final transactionReceipt =
        await client.getTransactionReceipt(transactionHash);

    print('ADD Transaction: $transactionReceipt');

    _updateContractAmount();
  }

  void _retrieveEtherRequest() async {
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

    print('Retrieve Transaction: $transactionReceipt');
    _updateContractAmount();
  }

  void _updateContractAmount() async {
    final contractAmount =
        await client.getBalance(EthereumAddress.fromHex(_contractAddress));

    setState(() {
      _currentContractBalance = contractAmount.getInEther;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ImageIcon(
                  const AssetImage('assets/logo_wc.png'),
                  color: Theme.of(context).colorScheme.primary,
                  size: 48,
                ),
                W3MConnectWalletButton(service: _w3mService),
              ],
            ),
            const SizedBox(height: 32),
            // connect your wallet buttons
            W3MNetworkSelectButton(service: _w3mService),
            W3MAccountButton(service: _w3mService),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _deployContract,
              icon: const Icon(Icons.rocket_launch),
              label: const Text('Deploy Contract'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DropdownButtonHideUnderline(
                    child: DropdownButton(
                        iconEnabledColor: Theme.of(context).colorScheme.primary,
                        value: _etherUnitValue,
                        items: EtherUnit.values
                            .map(
                              (e) => DropdownMenuItem<EtherUnit>(
                                value: e,
                                child: Text(e.name.toUpperCase()),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _etherUnitValue = value!;
                          });
                        }),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textEditAmount,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          CryptoFontIcons.eth,
                          color: Theme.of(context).primaryColor,
                        ),
                        labelText: 'Amount',
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _addEtherRequest,
                    //icon: const Icon(CryptoFontIcons.eth),
                    child: const Text('Deposit'),
                  )
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _retrieveEtherRequest,
              icon: const Icon(Icons.savings),
              label: const Text('Retrieve Savings'),
            ),
            const SizedBox(height: 16),
            Text(
              'Contract Balance\n $_currentContractBalance ETH',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}
