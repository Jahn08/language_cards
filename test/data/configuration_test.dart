import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/data/configuration.dart';
import 'package:language_cards/src/models/app_params.dart';
import '../mocks/root_widget_mock.dart';
import '../utilities/test_asset_bundle.dart';
import '../utilities/randomiser.dart';

void main() {
    testWidgets('Loads configuration preferring secret parameteres', (tester) async {
        final expectedSecretApiKey = Randomiser.nextString();
        
        AppParams params;
        await tester.pumpWidget(
            new MaterialApp(
                home: new DefaultAssetBundle(
                    bundle: new TestAssetBundle.params(
                        _buildAppParams(Randomiser.nextString()), 
                        secretParams: _buildAppParams(expectedSecretApiKey)),
                    child: new RootWidgetMock(onBuilding: (context) async =>
                        params = await Configuration.getParams(context)),
                )
            )
        );

        expect(params.dictionary?.apiKey, expectedSecretApiKey);
    });

     testWidgets('Loads configuration without secret parameteres', (tester) async {
        final expectedApiKey = Randomiser.nextString();
        
        AppParams params;
        await tester.pumpWidget(
            new MaterialApp(
                home: new DefaultAssetBundle(
                    bundle: new TestAssetBundle.params(
                        _buildAppParams(expectedApiKey)),
                    child: new RootWidgetMock(onBuilding: (context) async =>
                        params = await Configuration.getParams(context, reload: true)),
                )
            )
        );

        expect(params.dictionary?.apiKey, expectedApiKey);
    });

    testWidgets('Throws an error when there is no configuration found', (tester) async {
        Error expectedError;
        await tester.pumpWidget(
            new MaterialApp(
                home: new DefaultAssetBundle(
                    bundle: new TestAssetBundle.params(null),
                    child: new RootWidgetMock(onBuilding: (context) async {
                        try {
                            await Configuration.getParams(context, reload: true);
                        }
                        catch (err) {
                            expectedError = err;
                        }
                    })
                )   
            )
        );

        expect(expectedError is StateError, true);
    });
}

AppParams _buildAppParams(String apiKey) => 
    new AppParams(dictionary: new DictionaryParams(apiKey: apiKey));
