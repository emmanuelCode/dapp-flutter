import 'package:cryptofont/cryptofont.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dapp_sample/models/wallet_transactions.dart';
import 'package:web3modal_flutter/web3modal_flutter.dart';

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
  late final WalletTransactions walletTransactions;

  var _etherUnitValue = EtherUnit.values.first;
  final _textEditAmount = TextEditingController();
  var _currentContractBalance = 0.0;

  @override
  initState() {
    super.initState();
    walletTransactions = WalletTransactions();
  }

  void _addEtherRequest() async {
    walletTransactions.addEtherRequest(
      etherUnitValue: _etherUnitValue,
      amount: int.parse(_textEditAmount.text),
    );

    final contractAmount = await walletTransactions.deployedContractBalance;
    setState(() {
      _currentContractBalance = contractAmount.getValueInUnit(EtherUnit.ether);
    });
  }

  void _retrieveEtherRequest() async {
    walletTransactions.retrieveEtherRequest();

    final contractAmount = await walletTransactions.deployedContractBalance;
    setState(() {
      _currentContractBalance = contractAmount.getValueInUnit(EtherUnit.ether);
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
                W3MConnectWalletButton(service: walletTransactions.w3MService),
              ],
            ),
            const SizedBox(height: 32),
            // connect your wallet buttons
            W3MNetworkSelectButton(service: walletTransactions.w3MService),
            W3MAccountButton(service: walletTransactions.w3MService),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: walletTransactions.deployContract,
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
                                child: Text(
                                  e.name.toUpperCase(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge!
                                      .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary),
                                ),
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
