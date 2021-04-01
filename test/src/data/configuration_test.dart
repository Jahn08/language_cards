import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/data/configuration.dart';
import 'package:language_cards/src/models/app_params.dart';
import '../../mocks/root_widget_mock.dart';
import '../../utilities/test_asset_bundle.dart';
import '../../utilities/randomiser.dart';

void main() {

    testWidgets('Loads configuration preferring secret parameteres', (tester) async {
        final expectedSecretApiKey = Randomiser.nextString();
        final expectedEmail = Randomiser.nextString();
        final expectedFbUserId = Randomiser.nextString();
        final expectedAppStoreId = Randomiser.nextString();
        
        AppParams params;
        await _pumpApp(tester, new DefaultAssetBundle(
			bundle: new TestAssetBundle(
				params: _buildAppParams(
					Randomiser.nextString(), 
					appStoreId: expectedAppStoreId,
					email: expectedEmail, 
					fbUserId: Randomiser.nextString()
				), 
				secretParams: _buildAppParams(
					expectedSecretApiKey, 
					fbUserId: expectedFbUserId
				)),
			child: new RootWidgetMock(onBuilding: (context) async =>
				params = await Configuration.getParams(context)),
		));

        expect(params.dictionary?.apiKey, expectedSecretApiKey);
        expect(params.contacts?.appStoreId, expectedAppStoreId);
        expect(params.contacts?.email, expectedEmail);
        expect(params.contacts?.fbUserId, expectedFbUserId);
    });

     testWidgets('Loads configuration without secret parameteres', (tester) async {
        final expectedApiKey = Randomiser.nextString();
        final expectedEmail = Randomiser.nextString();
        final expectedFbUserId = Randomiser.nextString();
        final expectedAppStoreId = Randomiser.nextString();
        
        AppParams params;
        await _pumpApp(tester, new DefaultAssetBundle(
			bundle: new TestAssetBundle(params: _buildAppParams(
				expectedApiKey, 
				appStoreId: expectedAppStoreId,
				email: expectedEmail, 
				fbUserId: expectedFbUserId
			)),
			child: new RootWidgetMock(onBuilding: (context) async =>
				params = await Configuration.getParams(context, reload: true)),
		));

        expect(params.dictionary?.apiKey, expectedApiKey);
        expect(params.contacts?.appStoreId, expectedAppStoreId);
        expect(params.contacts?.email, expectedEmail);
        expect(params.contacts?.fbUserId, expectedFbUserId);
    });

    testWidgets('Throws an error when there is no configuration found', (tester) async {
        Error expectedError;
        await _pumpApp(tester, new DefaultAssetBundle(
			bundle: new TestAssetBundle(params: null),
			child: new RootWidgetMock(onBuilding: (context) async {
				try {
					await Configuration.getParams(context, reload: true);
				}
				catch (err) {
					expectedError = err;
				}
			})
		));

        expect(expectedError is StateError, true);
    });
}

AppParams _buildAppParams(String apiKey, {
	String email, String fbUserId, String appStoreId
}) => new AppParams(
	dictionary: new DictionaryParams(apiKey: apiKey),
	contacts: new ContactsParams(
		appStoreId: appStoreId,
		email: email,
		fbUserId: fbUserId
	)
);

Future<void> _pumpApp(WidgetTester tester, Widget home) => 
	tester.pumpWidget(RootWidgetMock.buildAsAppHome(child: home));
